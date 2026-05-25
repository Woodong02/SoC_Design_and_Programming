`timescale 1ns / 1ps

module tb_regfile;

    reg        clk, rst_n;
    reg [4:0]  s_axil_awaddr;
    reg        s_axil_awvalid;
    reg [31:0] s_axil_wdata;
    reg [3:0]  s_axil_wstrb;
    reg        s_axil_wvalid;
    reg        s_axil_bready;
    reg [4:0]  s_axil_araddr;
    reg        s_axil_arvalid;
    reg        s_axil_rready;

    wire        s_axil_awready, s_axil_wready, s_axil_arready;
    wire [1:0]  s_axil_bresp, s_axil_rresp;
    wire        s_axil_bvalid, s_axil_rvalid;
    wire [31:0] s_axil_rdata;

    // Status inputs
    reg [2:0]  fsm_state;
    reg [7:0]  fault_cnt, line_cnt;
    reg        ev_data_sent, ev_no_broadcast, ev_hamming_err, ev_halt_cmd;
    reg [4:0]  irq_status;

    // Config outputs
    wire        enable, soft_rst;
    wire [9:0]  div, guard_ticks;
    wire [2:0]  slave_addr_cfg;
    wire [7:0]  fault_th, line_fault_th;
    wire [31:0] tx_data_out;
    wire [4:0]  irq_clr, irq_mask;

    regfile uut (
        .clk(clk), .rst_n(rst_n),
        .s_axil_awaddr(s_axil_awaddr), .s_axil_awvalid(s_axil_awvalid),
        .s_axil_awready(s_axil_awready),
        .s_axil_wdata(s_axil_wdata), .s_axil_wstrb(s_axil_wstrb),
        .s_axil_wvalid(s_axil_wvalid), .s_axil_wready(s_axil_wready),
        .s_axil_bresp(s_axil_bresp), .s_axil_bvalid(s_axil_bvalid),
        .s_axil_bready(s_axil_bready),
        .s_axil_araddr(s_axil_araddr), .s_axil_arvalid(s_axil_arvalid),
        .s_axil_arready(s_axil_arready),
        .s_axil_rdata(s_axil_rdata), .s_axil_rresp(s_axil_rresp),
        .s_axil_rvalid(s_axil_rvalid), .s_axil_rready(s_axil_rready),
        .fsm_state(fsm_state), .fault_cnt(fault_cnt), .line_cnt(line_cnt),
        .ev_data_sent(ev_data_sent), .ev_no_broadcast(ev_no_broadcast),
        .ev_hamming_err(ev_hamming_err), .ev_halt_cmd(ev_halt_cmd),
        .irq_status(irq_status),
        .enable(enable), .soft_rst(soft_rst),
        .div(div), .guard_ticks(guard_ticks),
        .slave_addr_cfg(slave_addr_cfg),
        .fault_th(fault_th), .line_fault_th(line_fault_th),
        .tx_data(tx_data_out),
        .irq_clr(irq_clr), .irq_mask(irq_mask)
    );

    always #5 clk = ~clk;

    integer pass_cnt, fail_cnt;

    // AXI write (simultaneous awvalid+wvalid)
    task axi_write;
        input [4:0]  addr;
        input [31:0] data;
        begin
            @(posedge clk); #1;
            s_axil_awaddr  = addr;
            s_axil_awvalid = 1;
            s_axil_wdata   = data;
            s_axil_wstrb   = 4'hF;
            s_axil_wvalid  = 1;
            @(posedge clk); #1;
            s_axil_awvalid = 0;
            s_axil_wvalid  = 0;
            s_axil_bready  = 1;
            @(posedge clk); #1;
            s_axil_bready  = 0;
        end
    endtask

    // AXI read: arvalid held for 1 cycle; rvalid registered 1 cycle later; read at that point
    task axi_read;
        input  [4:0]  addr;
        output [31:0] rdata;
        begin
            @(posedge clk); #1;
            s_axil_araddr  = addr;
            s_axil_arvalid = 1;
            s_axil_rready  = 1;
            @(posedge clk); #1;  // UUT latches araddr, sets rvalid/rdata in NBA
            s_axil_arvalid = 0;
            @(posedge clk); #1;  // rvalid=1 at this posedge; rdata stable
            rdata = s_axil_rdata;
            s_axil_rready  = 0;
            @(posedge clk); #1;  // rvalid cleared (rready handshake)
        end
    endtask

    reg [31:0] rdata;

    initial begin
        clk=0; rst_n=0;
        s_axil_awaddr=0; s_axil_awvalid=0;
        s_axil_wdata=0; s_axil_wstrb=4'hF; s_axil_wvalid=0; s_axil_bready=1;
        s_axil_araddr=0; s_axil_arvalid=0; s_axil_rready=1;
        fsm_state=0; fault_cnt=0; line_cnt=0;
        ev_data_sent=0; ev_no_broadcast=0; ev_hamming_err=0; ev_halt_cmd=0;
        irq_status=0;
        pass_cnt=0; fail_cnt=0;
        #30; @(posedge clk); rst_n=1;
        repeat(3) @(posedge clk);

        // ---- Test 1: CTRL write/read ----
        $display("\n--- Test 1: CTRL (0x00) enable=1 ---");
        axi_write(5'h00, 32'h00000001);  // ENABLE=1
        repeat(2) @(posedge clk);
        if (enable === 1'b1) begin $display("[PASS] enable=1"); pass_cnt=pass_cnt+1; end
        else begin $display("[FAIL] enable expected 1, got %b", enable); fail_cnt=fail_cnt+1; end

        // ---- Test 2: CTRL read-back ----
        $display("\n--- Test 2: CTRL readback ---");
        axi_read(5'h00, rdata);
        if (rdata[0] === 1'b1) begin $display("[PASS] CTRL[0]=1"); pass_cnt=pass_cnt+1; end
        else begin $display("[FAIL] CTRL readback: %h", rdata); fail_cnt=fail_cnt+1; end

        // ---- Test 3: LINK_CFG ----
        $display("\n--- Test 3: LINK_CFG div=9, guard=5 ---");
        axi_write(5'h04, 32'h00001409); // guard[19:10]=5=0x14 LSB at 10? wait:
        // LINK_CFG[9:0]=div, [19:10]=guard
        // div=9=0x009, guard=5 → bits[19:10]= 5 << 10 = 0x1400
        // combined: 0x00001409
        axi_write(5'h04, 32'h00001409);
        repeat(2) @(posedge clk);
        if (div === 10'd9 && guard_ticks === 10'd5) begin
            $display("[PASS] div=%0d, guard=%0d", div, guard_ticks);
            pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] div=%0d (exp 9), guard=%0d (exp 5)", div, guard_ticks);
            fail_cnt=fail_cnt+1;
        end

        // ---- Test 4: SLAVE_CFG ----
        $display("\n--- Test 4: SLAVE_CFG addr=3 ---");
        axi_write(5'h08, 32'h00000003);
        repeat(2) @(posedge clk);
        if (slave_addr_cfg === 3'd3) begin $display("[PASS] slave_addr=3"); pass_cnt=pass_cnt+1; end
        else begin $display("[FAIL] slave_addr=%0d", slave_addr_cfg); fail_cnt=fail_cnt+1; end

        // ---- Test 5: FAULT_CFG ----
        $display("\n--- Test 5: FAULT_CFG th=20, line_th=40 ---");
        axi_write(5'h0C, 32'h00002814);  // [7:0]=20=0x14, [15:8]=40=0x28
        repeat(2) @(posedge clk);
        if (fault_th === 8'd20 && line_fault_th === 8'd40) begin
            $display("[PASS] fault_th=%0d, line_fault_th=%0d", fault_th, line_fault_th);
            pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] fault_th=%0d line_th=%0d", fault_th, line_fault_th);
            fail_cnt=fail_cnt+1;
        end

        // ---- Test 6: TX_DATA ----
        $display("\n--- Test 6: TX_DATA ---");
        axi_write(5'h10, 32'hDEADBEEF);
        repeat(2) @(posedge clk);
        if (tx_data_out === 32'hDEADBEEF) begin $display("[PASS] TX_DATA=DEADBEEF"); pass_cnt=pass_cnt+1; end
        else begin $display("[FAIL] TX_DATA=%h", tx_data_out); fail_cnt=fail_cnt+1; end

        // ---- Test 7: STATUS readback (RO fields from inputs) ----
        $display("\n--- Test 7: STATUS readback ---");
        fsm_state = 3'd1;  // NORMAL
        fault_cnt = 8'd15;
        line_cnt  = 8'd5;
        repeat(2) @(posedge clk);
        axi_read(5'h14, rdata);
        if (rdata[2:0]===3'd1 && rdata[10:3]===8'd15 && rdata[18:11]===8'd5) begin
            $display("[PASS] STATUS: state=%0d fc=%0d lc=%0d",
                     rdata[2:0], rdata[10:3], rdata[18:11]);
            pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] STATUS=%h", rdata);
            fail_cnt=fail_cnt+1;
        end

        // ---- Test 8: STATUS W1C bits ----
        $display("\n--- Test 8: STATUS W1C bits ---");
        @(posedge clk); #1; ev_data_sent=1; @(posedge clk); #1; ev_data_sent=0;
        repeat(2) @(posedge clk);
        axi_read(5'h14, rdata);
        if (rdata[19]) begin $display("[PASS] STATUS[19] data_sent set"); pass_cnt=pass_cnt+1; end
        else begin $display("[FAIL] STATUS[19] not set: %h", rdata); fail_cnt=fail_cnt+1; end
        // Clear it
        axi_write(5'h14, 32'h00080000);  // bit 19 = 1 → W1C
        repeat(2) @(posedge clk);
        axi_read(5'h14, rdata);
        if (!rdata[19]) begin $display("[PASS] STATUS[19] cleared by W1C"); pass_cnt=pass_cnt+1; end
        else begin $display("[FAIL] STATUS[19] not cleared: %h", rdata); fail_cnt=fail_cnt+1; end

        // ---- Test 9: IRQ_MASK write/read ----
        $display("\n--- Test 9: IRQ_MASK ---");
        axi_write(5'h1C, 32'h0000001F);  // all bits enabled
        repeat(2) @(posedge clk);
        if (irq_mask === 5'h1F) begin $display("[PASS] irq_mask=0x1F"); pass_cnt=pass_cnt+1; end
        else begin $display("[FAIL] irq_mask=%h", irq_mask); fail_cnt=fail_cnt+1; end

        // ---- Test 10: SOFT_RST auto-clears ----
        $display("\n--- Test 10: SOFT_RST auto-clear ---");
        axi_write(5'h00, 32'h00000003);  // ENABLE=1, SOFT_RST=1
        repeat(2) @(posedge clk);
        if (!soft_rst) begin $display("[PASS] SOFT_RST auto-cleared"); pass_cnt=pass_cnt+1; end
        else begin $display("[FAIL] SOFT_RST still set"); fail_cnt=fail_cnt+1; end

        // ---- Test 11: Default FAULT_CFG after reset ----
        $display("\n--- Test 11: FAULT_CFG defaults = 30 ---");
        @(posedge clk); #1; rst_n=0; @(posedge clk); #1; rst_n=1;
        repeat(3) @(posedge clk);
        if (fault_th===8'd30 && line_fault_th===8'd30) begin
            $display("[PASS] defaults: fault_th=30, line_fault_th=30");
            pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] fault_th=%0d line_th=%0d", fault_th, line_fault_th);
            fail_cnt=fail_cnt+1;
        end

        $display("\n[DONE] regfile: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        $finish;
    end

endmodule
