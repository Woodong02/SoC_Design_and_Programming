`timescale 1ns / 1ps

module tb_fault_fsm;

    reg       clk, rst_n;
    reg [7:0] fault_th, line_fault_th;
    reg       active_edge, bc_valid, bc_preamble_ok;
    reg       bc_hamming_err, bc_preamble_err;
    reg       no_broadcast, halt_cmd;

    wire      tx_enable, state_change;
    wire [2:0] fsm_state;

    localparam IDLE=3'd0, NORMAL=3'd1, DATA_RECOVERY=3'd2, FAULT_ST=3'd3, DEAD=3'd4;

    fault_fsm uut (
        .clk(clk), .rst_n(rst_n),
        .fault_th(fault_th), .line_fault_th(line_fault_th),
        .active_edge(active_edge), .bc_valid(bc_valid),
        .bc_preamble_ok(bc_preamble_ok), .bc_hamming_err(bc_hamming_err),
        .bc_preamble_err(bc_preamble_err), .no_broadcast(no_broadcast),
        .halt_cmd(halt_cmd),
        .tx_enable(tx_enable), .state_change(state_change),
        .fsm_state(fsm_state)
    );

    always #5 clk = ~clk;

    integer pass_cnt, fail_cnt;

    task pulse;
        input reg sig;  // not quite right, use signal inline
        begin end
    endtask

    task check_state;
        input [2:0] exp;
        input [63:0] label;
        begin
            repeat(2) @(posedge clk);
            if (fsm_state === exp) begin
                $display("[PASS] state=%0d (%s)", fsm_state, label);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("[FAIL] state=%0d, expected %0d (%s)", fsm_state, exp, label);
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
        $display("\n--- Test 1: IDLE -> NORMAL ---");
        if (fsm_state !== IDLE) begin
            $display("[FAIL] Initial state not IDLE"); fail_cnt=fail_cnt+1;
        end else begin
            $display("[PASS] Initial state = IDLE"); pass_cnt=pass_cnt+1;
        end
        send_active_edge;
        repeat(2) @(posedge clk);
        if (fsm_state === NORMAL) begin
            $display("[PASS] IDLE->NORMAL on active_edge"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] Expected NORMAL, got %0d", fsm_state); fail_cnt=fail_cnt+1;
        end

        // ---- Test 2: NORMAL → DATA_RECOVERY (fault_cnt > 0) ----
        $display("\n--- Test 2: NORMAL -> DATA_RECOVERY on hamming_err ---");
        // Send one hamming_err: fault_cnt += 10 → 10 > 0
        send_hamming_err;
        repeat(3) @(posedge clk);
        if (fsm_state === DATA_RECOVERY) begin
            $display("[PASS] NORMAL->DATA_RECOVERY"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] Expected DATA_RECOVERY, got %0d", fsm_state); fail_cnt=fail_cnt+1;
        end

        // ---- Test 3: DATA_RECOVERY → NORMAL (fault_cnt → 0) ----
        $display("\n--- Test 3: DATA_RECOVERY -> NORMAL (fault_cnt decrement) ---");
        // fault_cnt=10, need 10 bc_valid pulses to reach 0
        repeat(10) begin send_bc_valid; end
        repeat(3) @(posedge clk);
        if (fsm_state === NORMAL) begin
            $display("[PASS] DATA_RECOVERY->NORMAL"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] Expected NORMAL, got %0d", fsm_state); fail_cnt=fail_cnt+1;
        end

        // ---- Test 4: NORMAL → FAULT (fault_cnt >= fault_th=20) ----
        $display("\n--- Test 4: NORMAL -> FAULT (2x hamming_err) ---");
        // 2 hamming_err: fault_cnt = 10+10 = 20 = fault_th
        send_hamming_err; send_hamming_err;
        repeat(3) @(posedge clk);
        if (fsm_state === FAULT_ST) begin
            $display("[PASS] NORMAL->FAULT"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] Expected FAULT, got %0d", fsm_state); fail_cnt=fail_cnt+1;
        end

        // ---- Test 5: FAULT → DATA_RECOVERY (fault_cnt < fault_th) ----
        $display("\n--- Test 5: FAULT -> DATA_RECOVERY (bc_valid decrements) ---");
        // fault_cnt=20=fault_th. Need 1 bc_valid to drop to 19 < 20
        send_bc_valid;
        repeat(3) @(posedge clk);
        if (fsm_state === DATA_RECOVERY) begin
            $display("[PASS] FAULT->DATA_RECOVERY"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] Expected DATA_RECOVERY, got %0d", fsm_state); fail_cnt=fail_cnt+1;
        end

        // Drain fault_cnt back to 0 and return to NORMAL
        repeat(19) begin send_bc_valid; end
        repeat(5) @(posedge clk);

        // ---- Test 6: halt_cmd → FAULT immediately ----
        $display("\n--- Test 6: halt_cmd -> FAULT ---");
        // First make sure we're in NORMAL
        if (fsm_state !== NORMAL) begin
            $display("[SKIP] Not in NORMAL for test 6 (state=%0d)", fsm_state);
        end else begin
            send_halt_cmd;
            repeat(3) @(posedge clk);
            if (fsm_state === FAULT_ST) begin
                $display("[PASS] halt_cmd->FAULT"); pass_cnt=pass_cnt+1;
            end else begin
                $display("[FAIL] Expected FAULT, got %0d", fsm_state); fail_cnt=fail_cnt+1;
            end
        end

        // Recover from FAULT
        repeat(21) begin send_bc_valid; end
        repeat(5) @(posedge clk);

        // ---- Test 7: NORMAL → DEAD (line_cnt >= line_fault_th) ----
        $display("\n--- Test 7: NORMAL -> DEAD (line_cnt saturates) ---");
        // Need 2 no_broadcast events: line_cnt=10, 20=line_fault_th
        if (fsm_state !== NORMAL) begin
            $display("[SKIP] Not in NORMAL for test 7 (state=%0d)", fsm_state);
        end else begin
            send_no_broadcast; send_no_broadcast;
            repeat(3) @(posedge clk);
            if (fsm_state === DEAD) begin
                $display("[PASS] NORMAL->DEAD"); pass_cnt=pass_cnt+1;
            end else begin
                $display("[FAIL] Expected DEAD, got %0d", fsm_state); fail_cnt=fail_cnt+1;
            end
        end

        // ---- Test 8: DEAD → IDLE (line_cnt → 0) ----
        $display("\n--- Test 8: DEAD -> IDLE (line_cnt decrement) ---");
        // line_cnt=20, need 20 bc_preamble_ok pulses
        if (fsm_state !== DEAD) begin
            $display("[SKIP] Not in DEAD for test 8");
        end else begin
            repeat(20) begin send_preamble_ok; end
            repeat(3) @(posedge clk);
            if (fsm_state === IDLE) begin
                $display("[PASS] DEAD->IDLE"); pass_cnt=pass_cnt+1;
            end else begin
                $display("[FAIL] Expected IDLE, got %0d", fsm_state); fail_cnt=fail_cnt+1;
            end
        end

        // ---- Test 9: tx_enable follows NORMAL/DATA_RECOVERY ----
        $display("\n--- Test 9: tx_enable=1 in NORMAL/DATA_RECOVERY ---");
        send_active_edge;
        repeat(2) @(posedge clk);
        if (tx_enable === 1'b1) begin
            $display("[PASS] tx_enable=1 in NORMAL"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] tx_enable expected 1 in NORMAL, got %b", tx_enable);
            fail_cnt=fail_cnt+1;
        end

        $display("\n[DONE] fault_fsm: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        $finish;
    end

endmodule
