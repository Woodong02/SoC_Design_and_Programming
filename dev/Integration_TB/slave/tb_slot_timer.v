`timescale 1ns / 1ps

module tb_slot_timer;

    reg        clk;
    reg        rst_n;
    reg [9:0]  div;
    reg [9:0]  guard_ticks;
    reg [2:0]  slave_addr;
    reg        active_edge;

    wire       tx_trigger;
    wire       no_broadcast;

    slot_timer uut (
        .clk(clk), .rst_n(rst_n),
        .div(div), .guard_ticks(guard_ticks),
        .slave_addr(slave_addr),
        .active_edge(active_edge),
        .tx_trigger(tx_trigger),
        .no_broadcast(no_broadcast)
    );

    always #5 clk = ~clk;

    // slot_ticks = 50*div + guard_ticks
    // trig_cnt   = slave_addr * slot_ticks + (guard_ticks >> 1)
    // tx_trigger visible at loop count == trig_cnt + 1 (1-cycle register delay)

    integer pass_cnt, fail_cnt;

    task fire_ae;
        begin
            @(posedge clk); #1; active_edge = 1'b1;
            @(posedge clk); #1; active_edge = 1'b0;
        end
    endtask

    // After ae deasserts, watch for tx_trigger.
    // expected_cnt = trig_cnt value (tx_trigger visible at loop count == trig_cnt + 1)
    task check_trigger;
        input [31:0] expected_trig_cnt;
        input [79:0] label;
        integer cnt;
        reg     seen;
        begin
            // cnt increments after @posedge; condition latches at trig_cnt,
            // visible one clock later → seen at cnt == trig_cnt + 2
            seen = 0; cnt = 0;
            repeat (expected_trig_cnt + 12) begin
                @(posedge clk);
                cnt = cnt + 1;
                if (tx_trigger && !seen) begin
                    seen = 1;
                    if (cnt == expected_trig_cnt + 2) begin
                        $display("[PASS] %s: tx_trigger at cnt=%0d (expected %0d)",
                                 label, cnt, expected_trig_cnt + 2);
                        pass_cnt = pass_cnt + 1;
                    end else begin
                        $display("[FAIL] %s: tx_trigger at cnt=%0d, expected %0d",
                                 label, cnt, expected_trig_cnt + 2);
                        fail_cnt = fail_cnt + 1;
                    end
                end
            end
            if (!seen) begin
                $display("[FAIL] %s: tx_trigger not seen within %0d cycles",
                         label, expected_trig_cnt + 12);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    // Compute expected trig_cnt from parameters
    function [31:0] expected_trig;
        input [9:0] div_in, guard_in;
        input [2:0] addr_in;
        reg [31:0] slot_t;
        begin
            slot_t = 50 * div_in + guard_in;
            expected_trig = addr_in * slot_t + (guard_in >> 1);
        end
    endfunction

    initial begin
        clk = 0; rst_n = 0;
        div = 10'd8; guard_ticks = 10'd0;
        slave_addr = 3'd0; active_edge = 0;
        pass_cnt = 0; fail_cnt = 0;
        #30; @(posedge clk); rst_n = 1;
        repeat(5) @(posedge clk);

        // ---- Test 1: slave_addr=0, guard=0 → trig_cnt=0, visible at cnt=1 ----
        // slot_ticks=50*8+0=400, trig_cnt=0*400+0=0
        $display("\n--- Test 1: slave_addr=0, guard=0, trig_cnt=0 ---");
        div=10'd8; guard_ticks=10'd0; slave_addr=3'd0;
        @(posedge clk); #1; active_edge=1'b1;
        @(posedge clk); #1; active_edge=1'b0;
        // slot_cnt=0 at next clk; condition met, tx_trigger latches; visible 1 clk later
        @(posedge clk); // T+1: condition check (slot_cnt_old=0==trig_cnt=0) → tx_trigger<=1
        @(posedge clk); // T+2: tx_trigger visible
        if (tx_trigger) begin
            $display("[PASS] slave_addr=0,guard=0: tx_trigger fires (cnt=1)"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] slave_addr=0,guard=0: tx_trigger did not fire"); fail_cnt=fail_cnt+1;
        end
        repeat(10) @(posedge clk);

        // ---- Test 2: slave_addr=1, guard=0 → trig_cnt=400 ----
        $display("\n--- Test 2: slave_addr=1, guard=0, trig_cnt=400 ---");
        div=10'd8; guard_ticks=10'd0; slave_addr=3'd1;
        fire_ae;
        check_trigger(expected_trig(10'd8, 10'd0, 3'd1), "addr=1,guard=0");
        repeat(10) @(posedge clk);

        // ---- Test 3: slave_addr=3, guard=0 → trig_cnt=1200 ----
        $display("\n--- Test 3: slave_addr=3, guard=0, trig_cnt=1200 ---");
        div=10'd8; guard_ticks=10'd0; slave_addr=3'd3;
        fire_ae;
        check_trigger(expected_trig(10'd8, 10'd0, 3'd3), "addr=3,guard=0");
        repeat(10) @(posedge clk);

        // ---- Test 4: watchdog no_broadcast at 9*slot_ticks=3600 ----
        $display("\n--- Test 4: watchdog no_broadcast at 9*slot_ticks=3600 ---");
        div=10'd8; guard_ticks=10'd0; slave_addr=3'd0;
        fire_ae;
        begin : test4
            integer cnt4; reg seen4;
            seen4=0; cnt4=0;
            repeat(3610) begin
                @(posedge clk); cnt4=cnt4+1;
                if (no_broadcast && !seen4) begin
                    seen4=1;
                    if (cnt4==3602) begin
                        $display("[PASS] watchdog: no_broadcast at cnt=%0d", cnt4); pass_cnt=pass_cnt+1;
                    end else begin
                        $display("[FAIL] watchdog: no_broadcast at cnt=%0d, expected 3602", cnt4); fail_cnt=fail_cnt+1;
                    end
                end
            end
            if (!seen4) begin $display("[FAIL] watchdog: no_broadcast not seen"); fail_cnt=fail_cnt+1; end
        end

        // ---- Test 5: slave_addr=1, guard=10 → trig_cnt=410+5=415, visible at cnt=416 ----
        // slot_ticks=50*8+10=410; trig=1*410+(10>>1)=415
        $display("\n--- Test 5: slave_addr=1, guard=10, trig_cnt=415 ---");
        div=10'd8; guard_ticks=10'd10; slave_addr=3'd1;
        fire_ae;
        check_trigger(expected_trig(10'd8, 10'd10, 3'd1), "addr=1,guard=10");
        repeat(10) @(posedge clk);

        // ---- Test 6: slave_addr=0, guard=10 → trig_cnt=5, visible at cnt=6 ----
        // guard_ticks>>1 = 5; trig = 0*410+5 = 5
        $display("\n--- Test 6: slave_addr=0, guard=10, trig_cnt=5 ---");
        div=10'd8; guard_ticks=10'd10; slave_addr=3'd0;
        fire_ae;
        check_trigger(expected_trig(10'd8, 10'd10, 3'd0), "addr=0,guard=10");
        repeat(10) @(posedge clk);

        $display("\n========================================");
        $display("[DONE] slot_timer: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        $display("========================================");
        $finish;
    end

endmodule
