`timescale 1ns / 1ps

// Loopback test: rx_line (slave TX output) connected to tx_line (master RX input).
// The slave broadcasts its own frame; master_rx inside the UUT receives it back.
// For slave_addr=0, tx_trigger fires 1 clock after active_edge.
// We inject a synthetic active_edge by driving tx_line high briefly (start of a "master frame").
// Then we wait for slave TX, let it loopback, and check: data_sent, irq, STATUS.
module tb_tdma_slave_top;

    reg        clk, rst_n;
    // AXI-Lite
    reg [4:0]  s_axil_awaddr;  reg s_axil_awvalid;
    reg [31:0] s_axil_wdata;   reg [3:0] s_axil_wstrb;  reg s_axil_wvalid;
    reg        s_axil_bready;
    reg [4:0]  s_axil_araddr;  reg s_axil_arvalid;  reg s_axil_rready;

    wire s_axil_awready, s_axil_wready, s_axil_bvalid, s_axil_arready, s_axil_rvalid;
    wire [1:0] s_axil_bresp, s_axil_rresp;
    wire [31:0] s_axil_rdata;

    // TDMA interface (loopback: rx_line → tx_line)
    wire rx_line;
    reg  tx_line_reg;
    wire irq;
    // Loopback: slave TX → slave RX input (via tristate pulldown)
    wire rx_line_val = (rx_line === 1'bz) ? 1'b0 : rx_line;
    wire tx_line_in  = tx_line_reg | rx_line_val; // OR: external drive OR loopback

    tdma_slave_top uut (
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
        .tx_line(tx_line_in),
        .rx_line(rx_line),
        .irq(irq)
    );

    always #5 clk = ~clk;

    integer pass_cnt, fail_cnt;

    task axi_write;
        input [4:0]  addr;
        input [31:0] data;
        begin
            @(posedge clk); #1;
            s_axil_awaddr=addr; s_axil_awvalid=1;
            s_axil_wdata=data; s_axil_wstrb=4'hF; s_axil_wvalid=1;
            @(posedge clk); #1;
            s_axil_awvalid=0; s_axil_wvalid=0; s_axil_bready=1;
            @(posedge clk); #1; s_axil_bready=0;
        end
    endtask

    task axi_read;
        input  [4:0]  addr;
        output [31:0] rdata;
        begin
            @(posedge clk); #1;
            s_axil_araddr=addr; s_axil_arvalid=1; s_axil_rready=1;
            @(posedge clk); #1; s_axil_arvalid=0;
            @(posedge clk); #1; rdata=s_axil_rdata;
            s_axil_rready=0; @(posedge clk); #1;
        end
    endtask

    reg [31:0] rdata;
    reg data_sent_seen;

    // Monitor data_sent via irq / STATUS
    always @(posedge clk) begin
        if (irq) data_sent_seen <= 1;
    end

    initial begin
        clk=0; rst_n=0; tx_line_reg=0;
        s_axil_awaddr=0; s_axil_awvalid=0;
        s_axil_wdata=0; s_axil_wstrb=4'hF; s_axil_wvalid=0; s_axil_bready=1;
        s_axil_araddr=0; s_axil_arvalid=0; s_axil_rready=1;
        data_sent_seen=0;
        pass_cnt=0; fail_cnt=0;
        #30; @(posedge clk); rst_n=1;
        repeat(5) @(posedge clk);

        // ── Configure: enable, div=3, guard=0, slave_addr=0, tx_data=0xA5A5A5A5 ──
        $display("\n--- Configure slave ---");
        axi_write(5'h04, 32'h00000003); // LINK_CFG: div=3, guard=0
        axi_write(5'h08, 32'h00000000); // SLAVE_CFG: addr=0
        axi_write(5'h10, 32'hA5A5A5A5); // TX_DATA
        axi_write(5'h18, 32'h1F);        // clear any IRQ_STATUS
        axi_write(5'h1C, 32'h01);        // IRQ_MASK: enable data_sent IRQ
        axi_write(5'h00, 32'h00000001); // CTRL: enable=1
        repeat(5) @(posedge clk);

        // ── Inject a rising edge on tx_line to trigger active_edge ──
        // Simulate the master preamble: drive tx_line high for 1 bit period (8 clocks)
        $display("\n--- Test 1: Inject active_edge → slave tx_trigger → data_sent ---");
        @(posedge clk); #1; tx_line_reg = 1;
        repeat(8) @(posedge clk); // hold for 1 bit period
        #1; tx_line_reg = 0;
        // The master_rx will see the rising edge and generate active_edge.
        // For slave_addr=0: tx_trigger fires 1 clock after active_edge.
        // slave_tx will transmit 50 bits = 50*8=400 clocks.
        // Wait for transmission to complete (600 clocks to be safe).
        repeat(600) @(posedge clk);

        // Check data_sent via STATUS W1C bit [19]
        axi_read(5'h14, rdata);
        if (rdata[19]) begin
            $display("[PASS] STATUS[19] data_sent set after TX"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] STATUS[19] not set: STATUS=%h", rdata); fail_cnt=fail_cnt+1;
        end

        // Check fsm_state = NORMAL (1) or DATA_RECOVERY due to loopback
        $display("\n--- Test 2: FSM transitioned from IDLE ---");
        if (rdata[2:0] !== 3'd0) begin
            $display("[PASS] FSM left IDLE: state=%0d", rdata[2:0]); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] FSM still in IDLE"); fail_cnt=fail_cnt+1;
        end

        // Check IRQ fired (data_sent IRQ enabled)
        $display("\n--- Test 3: irq asserted for data_sent ---");
        if (data_sent_seen) begin
            $display("[PASS] irq asserted"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] irq not seen"); fail_cnt=fail_cnt+1;
        end

        // ── Test 4: SOFT_RST resets FSM back to IDLE ──
        $display("\n--- Test 4: SOFT_RST resets FSM ---");
        axi_write(5'h00, 32'h00000003); // ENABLE=1, SOFT_RST=1
        repeat(5) @(posedge clk);
        axi_read(5'h14, rdata);
        if (rdata[2:0] === 3'd0) begin
            $display("[PASS] FSM reset to IDLE by SOFT_RST"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] FSM state after SOFT_RST: %0d", rdata[2:0]); fail_cnt=fail_cnt+1;
        end

        $display("\n[DONE] tdma_slave_top: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        $finish;
    end

endmodule
