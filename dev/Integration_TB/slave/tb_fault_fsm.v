`timescale 1ns / 1ps

module tb_fault_fsm;

    reg       clk, rst_n;
    reg [7:0] fault_th, line_fault_th;
    reg       active_edge, bc_valid, bc_preamble_ok;
    reg       bc_hamming_err, bc_preamble_err;
    reg       no_broadcast, halt_cmd;

    wire        tx_enable, state_change;
    wire [2:0]  fsm_state;
    wire [7:0]  fault_cnt_out, line_cnt_out;

    localparam IDLE   = 3'd0;
    localparam NORMAL = 3'd1;
    localparam DEAD   = 3'd2;

    fault_fsm uut (
        .clk(clk), .rst_n(rst_n),
        .fault_th(fault_th), .line_fault_th(line_fault_th),
        .active_edge(active_edge), .bc_valid(bc_valid),
        .bc_preamble_ok(bc_preamble_ok), .bc_hamming_err(bc_hamming_err),
        .bc_preamble_err(bc_preamble_err), .no_broadcast(no_broadcast),
        .halt_cmd(halt_cmd),
        .tx_enable(tx_enable), .state_change(state_change),
        .fsm_state(fsm_state),
        .fault_cnt_out(fault_cnt_out), .line_cnt_out(line_cnt_out)
    );

    always #5 clk = ~clk;

    integer pass_cnt, fail_cnt;

    task check_state;
        input [2:0]  exp;
        input [79:0] label;
        begin
            repeat(2) @(posedge clk);
            if (fsm_state === exp) begin
                $display("[PASS] %s: state=%0d", label, fsm_state);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("[FAIL] %s: state=%0d, expected %0d", label, fsm_state, exp);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    task send_active_edge;
        begin
            @(posedge clk); #1; active_edge = 1; @(posedge clk); #1; active_edge = 0;
        end
    endtask
    task send_bc_valid;
        begin
            @(posedge clk); #1; bc_valid = 1; @(posedge clk); #1; bc_valid = 0;
        end
    endtask
    task send_hamming_err;
        begin
            @(posedge clk); #1; bc_hamming_err = 1; @(posedge clk); #1; bc_hamming_err = 0;
        end
    endtask
    task send_preamble_ok;
        begin
            @(posedge clk); #1; bc_preamble_ok = 1; @(posedge clk); #1; bc_preamble_ok = 0;
        end
    endtask
    task send_no_broadcast;
        begin
            @(posedge clk); #1; no_broadcast = 1; @(posedge clk); #1; no_broadcast = 0;
        end
    endtask
    task send_halt_cmd;
        begin
            @(posedge clk); #1; halt_cmd = 1; @(posedge clk); #1; halt_cmd = 0;
        end
    endtask

    // Reset DUT and return to IDLE
    task do_reset;
        begin
            @(posedge clk); #1; rst_n = 0;
            repeat(3) @(posedge clk); #1; rst_n = 1;
            repeat(2) @(posedge clk);
        end
    endtask

    initial begin
        clk=0; rst_n=0;
        fault_th=8'd20; line_fault_th=8'd20;
        active_edge=0; bc_valid=0; bc_preamble_ok=0;
        bc_hamming_err=0; bc_preamble_err=0;
        no_broadcast=0; halt_cmd=0;
        pass_cnt=0; fail_cnt=0;
        #30; @(posedge clk); rst_n=1;
        repeat(3) @(posedge clk);

        // ---- Test 1: IDLE → NORMAL on active_edge ----
        $display("\n--- Test 1: IDLE -> NORMAL on active_edge ---");
        if (fsm_state !== IDLE) begin
            $display("[FAIL] Initial state not IDLE (got %0d)", fsm_state); fail_cnt=fail_cnt+1;
        end else begin
            $display("[PASS] Initial state = IDLE"); pass_cnt=pass_cnt+1;
        end
        send_active_edge;
        check_state(NORMAL, "IDLE->NORMAL");

        // ---- Test 2: NORMAL stays NORMAL when fault_cnt > 0 (no DATA_RECOVERY) ----
        $display("\n--- Test 2: NORMAL stays NORMAL with fault_cnt>0 (no DATA_RECOVERY) ---");
        send_hamming_err; // fault_cnt += 10 → 10 > 0
        check_state(NORMAL, "stays NORMAL (no DR state)");

        // ---- Test 3: NORMAL → DEAD when fault_cnt >= fault_th ----
        $display("\n--- Test 3: NORMAL -> DEAD when fault_cnt >= fault_th ---");
        // fault_cnt=10, need 1 more hamming_err: 10+10=20=fault_th
        send_hamming_err;
        check_state(DEAD, "NORMAL->DEAD (fault_cnt>=fault_th)");
        @(posedge clk); // tx_enable is 1-cycle behind fsm_state; wait one more
        if (tx_enable !== 1'b0) begin
            $display("[FAIL] tx_enable should be 0 in DEAD (got %b)", tx_enable); fail_cnt=fail_cnt+1;
        end else begin
            $display("[PASS] tx_enable=0 in DEAD"); pass_cnt=pass_cnt+1;
        end

        // ---- Test 4: DEAD stays DEAD (no auto-recovery) ----
        $display("\n--- Test 4: DEAD stays DEAD even when counters drop ---");
        // drain both counters fully via preamble_ok and bc_valid
        repeat(20) begin send_preamble_ok; end
        repeat(20) begin send_bc_valid; end
        repeat(5) @(posedge clk);
        if (fsm_state === DEAD) begin
            $display("[PASS] DEAD stays DEAD after counter drain"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] Expected DEAD, got %0d (auto-recovery should not happen)", fsm_state);
            fail_cnt=fail_cnt+1;
        end

        // ---- Test 5: halt_cmd → DEAD directly from NORMAL ----
        $display("\n--- Test 5: halt_cmd -> DEAD directly from NORMAL ---");
        do_reset;
        send_active_edge;
        check_state(NORMAL, "back to NORMAL");
        send_halt_cmd;
        check_state(DEAD, "halt_cmd->DEAD");

        // ---- Test 6: NORMAL → DEAD via line_cnt overflow ----
        $display("\n--- Test 6: NORMAL -> DEAD via line_cnt >= line_fault_th ---");
        do_reset;
        send_active_edge;
        check_state(NORMAL, "back to NORMAL");
        // line_fault_th=20: 2 no_broadcast events (+10 each)
        send_no_broadcast; send_no_broadcast;
        check_state(DEAD, "line_cnt>=line_fault_th->DEAD");

        // ---- Test 7: tx_enable=1 in NORMAL, =0 in DEAD ----
        $display("\n--- Test 7: tx_enable follows state ---");
        do_reset;
        send_active_edge;
        repeat(2) @(posedge clk);
        if (tx_enable === 1'b1) begin
            $display("[PASS] tx_enable=1 in NORMAL"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] tx_enable expected 1 in NORMAL, got %b", tx_enable); fail_cnt=fail_cnt+1;
        end
        send_halt_cmd;
        repeat(3) @(posedge clk);
        if (tx_enable === 1'b0) begin
            $display("[PASS] tx_enable=0 in DEAD"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] tx_enable expected 0 in DEAD, got %b", tx_enable); fail_cnt=fail_cnt+1;
        end

        // ---- Test 8: state_change fires on transitions ----
        $display("\n--- Test 8: state_change fires on IDLE->NORMAL and NORMAL->DEAD ---");
        do_reset;
        @(posedge clk); #1; active_edge = 1;
        @(posedge clk); #1; active_edge = 0;
        // state_change should be 1 the clock after active_edge latches
        repeat(1) @(posedge clk);
        if (state_change === 1'b1) begin
            $display("[PASS] state_change=1 on IDLE->NORMAL"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] state_change expected 1 on IDLE->NORMAL"); fail_cnt=fail_cnt+1;
        end
        send_halt_cmd;
        repeat(1) @(posedge clk);
        if (state_change === 1'b1) begin
            $display("[PASS] state_change=1 on NORMAL->DEAD"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] state_change expected 1 on NORMAL->DEAD"); fail_cnt=fail_cnt+1;
        end

        $display("\n========================================");
        $display("[DONE] fault_fsm: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        $display("========================================");
        $finish;
    end

endmodule
