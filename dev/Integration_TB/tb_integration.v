`timescale 1ns / 1ps

// Integration testbench: Master_tx<->master_rx (Bus A) and slave_tx<->Master_rx+Master_dec_ham (Bus B)
// Unified DIV=8: both master and slave now use DIV clocks/bit (master-compatible convention)
// T1: Master_tx broadcasts → slave master_rx fires active_edge quickly (Bus A)
// T2: Broadcast fields verified (halt, guard_ticks)
// T3: Broadcast with non-zero fields
// T4/T5: slave_tx sends → Master_rx + Master_dec_ham decodes slot_out correctly (Bus B)
module tb_integration;

    reg clk, rst_n;
    always #5 clk = ~clk;

    localparam DIV = 10'd8;  // unified: both master and slave use DIV clocks/bit

    integer pass_cnt, fail_cnt;

    // ── Bus A: Master broadcasts to Slave ──────────────────────────────────
    reg        bc_trig;
    reg [7:0]  bc_halt_in;
    reg [9:0]  bc_guard_in;
    wire       gpio_out_a;

    Master_tx u_mtx (
        .clk(clk), .resetn(rst_n),
        .tx_trigger(bc_trig),
        .halt_cmd(bc_halt_in), .GUARD_TICKS(bc_guard_in),
        .DIV(DIV),
        .GPIO_out(gpio_out_a)
    );

    // 2-FF synchronizer (mirrors slave_top's chain)
    reg a_ff1, a_ff2;
    always @(posedge clk or negedge rst_n)
        if (!rst_n) {a_ff2, a_ff1} <= 2'b0;
        else        {a_ff2, a_ff1} <= {a_ff1, gpio_out_a};
    wire tx_line_sync_a = a_ff2;

    wire        ae, bc_valid, bc_pok, bc_herr, bc_perr;
    wire [7:0]  bc_halt_out;
    wire [9:0]  bc_guard_out;

    master_rx u_mrx (
        .clk(clk), .rst_n(rst_n), .enable(1'b1),
        .div(DIV), .tx_line_sync(tx_line_sync_a),
        .active_edge(ae), .bc_valid(bc_valid),
        .bc_preamble_ok(bc_pok),
        .bc_halt_cmd(bc_halt_out), .bc_guard_ticks(bc_guard_out),
        .bc_hamming_err(bc_herr), .bc_preamble_err(bc_perr)
    );

    // ── Bus B: Slave sends to Master ───────────────────────────────────────
    reg        sl_trig, sl_en;
    reg [2:0]  sl_addr;
    reg [31:0] sl_data;
    wire       rx_line_b;
    wire       sl_active, sl_sent;

    slave_tx u_stx (
        .clk(clk), .rst_n(rst_n), .div(DIV),
        .tx_trigger(sl_trig), .tx_enable(sl_en),
        .slave_addr(sl_addr), .tx_data(sl_data),
        .rx_line(rx_line_b), .tx_active(sl_active), .data_sent(sl_sent)
    );

    // tristate resolve + 2-FF
    wire rx_raw = (rx_line_b === 1'bz) ? 1'b0 : rx_line_b;
    reg b_ff1, b_ff2;
    always @(posedge clk or negedge rst_n)
        if (!rst_n) {b_ff2, b_ff1} <= 2'b0;
        else        {b_ff2, b_ff1} <= {b_ff1, rx_raw};
    wire rx_line_sync_b = b_ff2;

    wire [41:0] m_data_bus;
    wire        m_out_sig;
    wire        m_preamble_err;

    Master_rx u_mdrx (
        .clk(clk), .resetn(rst_n),
        .DIV(DIV), .GPIO_in(rx_line_sync_b),
        .slot_pre_change(1'b0),
        .data_out(m_data_bus), .out_sig(m_out_sig), .preamble_err(m_preamble_err)
    );

    wire [31:0] sout0,sout1,sout2,sout3,sout4,sout5,sout6,sout7;
    wire [31:0] ecnt0,ecnt1,ecnt2,ecnt3,ecnt4,ecnt5,ecnt6,ecnt7;

    // sl_addr also feeds 'slot' so Master_dec_ham sees no address mismatch
    Master_dec_ham u_mdec (
        .resetn(rst_n), .clk(clk),
        .in_sig(m_out_sig), .GUARD_TICKS(10'd0), .data_in(m_data_bus),
        .SILENT_TH(8'd200), .slot(sl_addr), .preamble_err(m_preamble_err),
        .slot_change(1'b0), .GPIO_in(rx_line_sync_b),
        .rx_stat(2'b00), .halt_cmd(8'h00),
        .slot_out0(sout0), .slot_out1(sout1), .slot_out2(sout2), .slot_out3(sout3),
        .slot_out4(sout4), .slot_out5(sout5), .slot_out6(sout6), .slot_out7(sout7),
        .err_cnt0(ecnt0), .err_cnt1(ecnt1), .err_cnt2(ecnt2), .err_cnt3(ecnt3),
        .err_cnt4(ecnt4), .err_cnt5(ecnt5), .err_cnt6(ecnt6), .err_cnt7(ecnt7)
    );

    // ── Sticky signal monitors ──────────────────────────────────────────────
    reg ae_seen, bc_valid_seen, bc_pok_seen, bc_herr_seen, m_outsig_seen;

    always @(posedge clk) begin
        if (ae)        ae_seen       <= 1;
        if (bc_valid)  bc_valid_seen <= 1;
        if (bc_pok)    bc_pok_seen   <= 1;
        if (bc_herr)   bc_herr_seen  <= 1;
        if (m_out_sig) m_outsig_seen <= 1;
    end

    task clear_flags;
        begin
            ae_seen=0; bc_valid_seen=0; bc_pok_seen=0;
            bc_herr_seen=0; m_outsig_seen=0;
        end
    endtask

    task do_reset;
        begin
            @(posedge clk); #1; rst_n=0;
            repeat(5) @(posedge clk); #1; rst_n=1;
            repeat(3) @(posedge clk);
        end
    endtask

    // Fire one broadcast frame (halt, guard)
    task fire_broadcast;
        input [7:0] halt;
        input [9:0] guard;
        begin
            bc_halt_in = halt; bc_guard_in = guard;
            @(posedge clk); #1; bc_trig=1;
            @(posedge clk); #1; bc_trig=0;
        end
    endtask

    // Trigger slave_tx with given addr/data
    task fire_slave_tx;
        input [2:0]  addr;
        input [31:0] data;
        begin
            sl_addr=addr; sl_data=data; sl_en=1;
            @(posedge clk); #1; sl_trig=1;
            @(posedge clk); #1; sl_trig=0;
        end
    endtask

    initial begin
        clk=0; rst_n=0;
        bc_trig=0; bc_halt_in=0; bc_guard_in=0;
        sl_trig=0; sl_en=0; sl_addr=0; sl_data=0;
        clear_flags; pass_cnt=0; fail_cnt=0;
        do_reset;

        // ════════════════════════════════════════════════════════════════════
        // T1: Master_tx → slave master_rx: active_edge fires immediately
        //     active_edge expected ~4 clks after bc_trig (2-FF sync + 1 reg)
        // ════════════════════════════════════════════════════════════════════
        $display("\n--- T1: active_edge timing after Master_tx starts ---");
        clear_flags;
        fire_broadcast(8'h00, 10'd0);
        repeat(10) @(posedge clk);
        if (ae_seen) begin
            $display("[PASS] T1: active_edge fired within 10 clks"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] T1: active_edge not seen"); fail_cnt=fail_cnt+1;
        end

        // ════════════════════════════════════════════════════════════════════
        // T2: bc_valid and field check (halt=0x00, guard=0)
        //     Frame = 50 bits × 8 clks/bit = 400 clks; wait 450 total
        // ════════════════════════════════════════════════════════════════════
        $display("\n--- T2: bc_valid + fields (halt=0x00, guard=0) ---");
        repeat(450) @(posedge clk);
        if (bc_valid_seen) begin
            $display("[PASS] T2a: bc_valid received"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] T2a: bc_valid not seen"); fail_cnt=fail_cnt+1;
        end
        if (bc_halt_out === 8'h00) begin
            $display("[PASS] T2b: bc_halt_cmd=0x%02h", bc_halt_out); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] T2b: bc_halt_cmd=0x%02h (exp 0x00)", bc_halt_out); fail_cnt=fail_cnt+1;
        end
        if (bc_guard_out === 10'd0) begin
            $display("[PASS] T2c: bc_guard_ticks=%0d", bc_guard_out); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] T2c: bc_guard_ticks=%0d (exp 0)", bc_guard_out); fail_cnt=fail_cnt+1;
        end

        // ════════════════════════════════════════════════════════════════════
        // T3: Non-zero broadcast fields (halt=0x01, guard=512)
        // ════════════════════════════════════════════════════════════════════
        $display("\n--- T3: Broadcast fields (halt=0x01, guard=512) ---");
        clear_flags;
        fire_broadcast(8'h01, 10'd512);
        repeat(500) @(posedge clk);
        if (bc_halt_out === 8'h01) begin
            $display("[PASS] T3a: bc_halt_cmd=0x%02h", bc_halt_out); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] T3a: bc_halt_cmd=0x%02h (exp 0x01)", bc_halt_out); fail_cnt=fail_cnt+1;
        end
        if (bc_guard_out === 10'd512) begin
            $display("[PASS] T3b: bc_guard_ticks=%0d", bc_guard_out); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] T3b: bc_guard_ticks=%0d (exp 512)", bc_guard_out); fail_cnt=fail_cnt+1;
        end

        // ════════════════════════════════════════════════════════════════════
        // T4: slave_tx → Master_rx + Master_dec_ham: slot_out2 = 0xCAFEBABE
        // ════════════════════════════════════════════════════════════════════
        $display("\n--- T4: slave_tx -> Master_rx decode (addr=2, data=0xCAFEBABE) ---");
        do_reset; clear_flags;
        fire_slave_tx(3'd2, 32'hCAFEBABE);
        repeat(500) @(posedge clk);
        if (m_outsig_seen) begin
            $display("[PASS] T4a: Master_rx out_sig received"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] T4a: Master_rx out_sig not seen"); fail_cnt=fail_cnt+1;
        end
        if (sout2 === 32'hCAFEBABE) begin
            $display("[PASS] T4b: slot_out2=0x%08h", sout2); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] T4b: slot_out2=0x%08h (exp 0xCAFEBABE)", sout2); fail_cnt=fail_cnt+1;
        end

        // ════════════════════════════════════════════════════════════════════
        // T5: slave_tx (addr=5, data=0x12345678)
        // ════════════════════════════════════════════════════════════════════
        $display("\n--- T5: slave_tx -> Master_rx decode (addr=5, data=0x12345678) ---");
        clear_flags;
        fire_slave_tx(3'd5, 32'h12345678);
        repeat(500) @(posedge clk);
        if (m_outsig_seen) begin
            $display("[PASS] T5a: Master_rx out_sig received"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] T5a: Master_rx out_sig not seen"); fail_cnt=fail_cnt+1;
        end
        if (sout5 === 32'h12345678) begin
            $display("[PASS] T5b: slot_out5=0x%08h", sout5); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] T5b: slot_out5=0x%08h (exp 0x12345678)", sout5); fail_cnt=fail_cnt+1;
        end

        $display("\n========================================");
        $display("[DONE] integration: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        $display("========================================");
        $finish;
    end

endmodule
