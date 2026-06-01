`timescale 1ns / 1ps

// tb_tdma_slave_top: parameter-based interface (no AXI-Lite)
// All config via #() parameters on UUT; runtime via direct port drives.
module tb_tdma_slave_top;

    reg        clk, rst_n;
    reg        enable;
    reg        soft_rst_sig;
    reg [31:0] tx_data_sig;
    reg [4:0]  irq_clr_sig;

    wire [4:0] irq_status_sig;
    wire [2:0] fsm_state_sig;

    wire       rx_line;
    reg        tx_line_reg;
    wire       tx_line_in = tx_line_reg;
    wire       irq;

    // ── UUT ────────────────────────────────────────────────────────────────
    tdma_slave_top #(
        .DIV          (10'd8),
        .GUARD_TICKS  (10'd0),
        .SLAVE_ADDR   (3'd0),
        .FAULT_TH     (8'd30),
        .LINE_FAULT_TH(8'd30),
        .IRQ_MASK     (5'b00001)   // data_sent → irq
    ) uut (
        .clk       (clk),           .rst_n     (rst_n),
        .enable    (enable),        .soft_rst  (soft_rst_sig),
        .tx_data   (tx_data_sig),   .irq_clr   (irq_clr_sig),
        .irq_status(irq_status_sig),.fsm_state (fsm_state_sig),
        .tx_line   (tx_line_in),    .rx_line   (rx_line),
        .irq       (irq)
    );

    // Hamming encoder for generating valid broadcast codewords
    reg  [34:0] enc_data;
    wire [41:0] enc_codeword;
    hamming_enc u_enc (.data(enc_data), .codeword(enc_codeword));

    always #5 clk = ~clk;

    localparam DIV_CFG = 10'd8;   // must match UUT .DIV parameter

    integer pass_cnt, fail_cnt;
    reg data_sent_seen;

    always @(posedge clk) begin
        if (irq) data_sent_seen <= 1;
    end

    // ── Broadcast frame driver ──────────────────────────────────────────────
    task drive_bit;
        input bval;
        begin
            tx_line_reg = bval;
            repeat (DIV_CFG) @(posedge clk);
        end
    endtask

    task send_master_frame;
        input [7:0]  halt;
        input [9:0]  guard;
        integer i;
        begin
            enc_data = {halt, guard, 17'b0};
            #1;
            drive_bit(1); drive_bit(0);
            drive_bit(1); drive_bit(0);
            drive_bit(1); drive_bit(0);
            drive_bit(1); drive_bit(0);
            for (i = 41; i >= 0; i = i - 1)
                drive_bit(enc_codeword[i]);
            tx_line_reg = 0;
            repeat (DIV_CFG*5) @(posedge clk);
        end
    endtask

    task do_hard_reset;
        begin
            @(posedge clk); #1; rst_n=0;
            repeat(5) @(posedge clk); #1; rst_n=1;
            repeat(3) @(posedge clk);
        end
    endtask

    task do_soft_rst;
        begin
            @(posedge clk); #1; soft_rst_sig=1;
            @(posedge clk); #1; soft_rst_sig=0;
            repeat(3) @(posedge clk);
        end
    endtask

    task clr_irq;
        begin
            @(posedge clk); #1; irq_clr_sig=5'h1F;
            @(posedge clk); #1; irq_clr_sig=5'd0;
        end
    endtask

    initial begin
        clk=0; rst_n=0; tx_line_reg=0;
        enable=1; soft_rst_sig=0;
        tx_data_sig=32'hA5A5A5A5;
        irq_clr_sig=5'd0;
        data_sent_seen=0; pass_cnt=0; fail_cnt=0;
        enc_data=0;
        #30; @(posedge clk); rst_n=1;
        repeat(5) @(posedge clk);

        // ════════════════════════════════════════════════════════════════════
        // Test 1~3: Basic TX flow (DIV=8, GUARD=0, SLAVE_ADDR=0)
        // ════════════════════════════════════════════════════════════════════
        $display("\n--- Tests 1-3: Basic TX flow (DIV=8, GUARD=0, ADDR=0) ---");
        data_sent_seen = 0;
        // Brief rising edge → active_edge → NORMAL → tx_trigger (addr=0, trig_cnt=0)
        @(posedge clk); #1; tx_line_reg=1;
        repeat(8) @(posedge clk); #1; tx_line_reg=0;
        repeat(600) @(posedge clk);

        if (irq_status_sig[0]) begin
            $display("[PASS] T1: data_sent set after TX"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] T1: data_sent not set: IRQ_STATUS=%b", irq_status_sig); fail_cnt=fail_cnt+1;
        end

        if (fsm_state_sig !== 3'd0) begin
            $display("[PASS] T2: FSM left IDLE (state=%0d)", fsm_state_sig); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] T2: FSM still IDLE"); fail_cnt=fail_cnt+1;
        end

        if (data_sent_seen) begin
            $display("[PASS] T3: irq asserted"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] T3: irq not seen"); fail_cnt=fail_cnt+1;
        end

        // ════════════════════════════════════════════════════════════════════
        // Test 4: SOFT_RST → FSM back to IDLE
        // ════════════════════════════════════════════════════════════════════
        $display("\n--- Test 4: SOFT_RST resets FSM to IDLE ---");
        do_soft_rst;
        if (fsm_state_sig === 3'd0) begin
            $display("[PASS] T4: FSM=IDLE after SOFT_RST"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] T4: FSM=%0d after SOFT_RST", fsm_state_sig); fail_cnt=fail_cnt+1;
        end

        // ════════════════════════════════════════════════════════════════════
        // Test 5: HALT_CMD via broadcast → FSM goes DEAD, stays DEAD
        // ════════════════════════════════════════════════════════════════════
        $display("\n--- Test 5: HALT_CMD via broadcast -> DEAD, no auto-recovery ---");
        do_hard_reset;

        send_master_frame(8'h00, 10'd0);
        repeat(10) @(posedge clk);
        if (fsm_state_sig === 3'd1) begin
            $display("[PASS] T5a: FSM=NORMAL after clean broadcast"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] T5a: FSM=%0d (expected NORMAL=1)", fsm_state_sig); fail_cnt=fail_cnt+1;
        end

        send_master_frame(8'h01, 10'd0); // halt_cmd[0]=1 → targets SLAVE_ADDR=0
        repeat(10) @(posedge clk);
        if (fsm_state_sig === 3'd2) begin
            $display("[PASS] T5b: FSM=DEAD after HALT_CMD"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] T5b: FSM=%0d (expected DEAD=2)", fsm_state_sig); fail_cnt=fail_cnt+1;
        end

        send_master_frame(8'h00, 10'd0);
        send_master_frame(8'h00, 10'd0);
        repeat(20) @(posedge clk);
        if (fsm_state_sig === 3'd2) begin
            $display("[PASS] T5c: FSM stays DEAD (no auto-recovery)"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] T5c: FSM=%0d (expected DEAD=2)", fsm_state_sig); fail_cnt=fail_cnt+1;
        end

        // ════════════════════════════════════════════════════════════════════
        // Test 6: guard_ticks_sync updated from broadcast
        //   GUARD_TICKS param=0; broadcast sends guard=50 → sync updates to 50
        //   slot_ticks=50*8+50=450; trig_cnt=0*450+(50>>1)=25
        // ════════════════════════════════════════════════════════════════════
        $display("\n--- Test 6: guard_ticks_sync updated from broadcast ---");
        do_hard_reset;

        send_master_frame(8'h00, 10'd50);
        repeat(5) @(posedge clk);
        if (fsm_state_sig === 3'd1) begin
            $display("[PASS] T6a: FSM=NORMAL after guard-broadcast"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] T6a: FSM=%0d (expected NORMAL=1)", fsm_state_sig); fail_cnt=fail_cnt+1;
        end

        clr_irq;
        data_sent_seen = 0;
        // Send another broadcast with guard=50; active_edge resets slot_timer
        send_master_frame(8'h00, 10'd50);
        repeat(700) @(posedge clk);
        if (irq_status_sig[0]) begin
            $display("[PASS] T6b: data_sent after guard-sync broadcast"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] T6b: data_sent not set with guard=50"); fail_cnt=fail_cnt+1;
        end

        $display("\n========================================");
        $display("[DONE] tdma_slave_top: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        $display("========================================");
        $finish;
    end

endmodule
