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

    // slot_ticks = 100*(div+1) + guard_ticks
    // For div=3, guard=0: slot_ticks=400
    // trig_cnt = slave_addr * slot_ticks
    // wdog_cnt = 9 * slot_ticks = 3600

    task pulse_active_edge;
        begin
            @(posedge clk); #1;
            active_edge = 1'b1;
            @(posedge clk); #1;
            active_edge = 1'b0;
        end
    endtask

    integer pass_cnt, fail_cnt;

    task check_trigger_delay;
        input [31:0] expected_delay; // clocks after active_edge deasserts
        reg trig_seen;
        integer cnt;
        begin
            trig_seen = 0;
            cnt = 0;
            // wait up to expected_delay+10 cycles
            repeat (expected_delay + 10) begin
                @(posedge clk);
                if (tx_trigger) begin
                    trig_seen = 1;
                    if (cnt == expected_delay) begin
                        $display("[PASS] tx_trigger at expected count=%0d", expected_delay);
                        pass_cnt = pass_cnt + 1;
                    end else begin
                        $display("[FAIL] tx_trigger at count=%0d, expected=%0d", cnt, expected_delay);
                        fail_cnt = fail_cnt + 1;
                    end
                end
                cnt = cnt + 1;
            end
            if (!trig_seen) begin
                $display("[FAIL] tx_trigger not seen within %0d cycles", expected_delay + 10);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    initial begin
        clk = 0; rst_n = 0;
        div = 10'd3; guard_ticks = 10'd0;
        slave_addr = 3'd0; active_edge = 0;
        pass_cnt = 0; fail_cnt = 0;
        #30; @(posedge clk); rst_n = 1;
        repeat(5) @(posedge clk);

        // ---- Test 1: slave_addr=0, tx_trigger fires 1 clock after active_edge ----
        // slot_ticks=400, trig_cnt=0*400=0 → fires at slot_cnt==0 (1 clock after ae)
        $display("\n--- Test 1: slave_addr=0, trig at slot_cnt=0 (1 clk after ae) ---");
        slave_addr = 3'd0;
        @(posedge clk); #1; active_edge = 1'b1;
        @(posedge clk); #1; active_edge = 1'b0;
        // slot_cnt=0 at next posedge → tx_trigger registered; visible 1 clock later
        @(posedge clk); // condition met (slot_cnt=0==trig_cnt), tx_trigger latches
        @(posedge clk); // tx_trigger visible here
        if (tx_trigger) begin
            $display("[PASS] slave_addr=0: tx_trigger fires 1 clock after active_edge");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("[FAIL] slave_addr=0: tx_trigger did not fire");
            fail_cnt = fail_cnt + 1;
        end
        repeat(10) @(posedge clk);

        // ---- Test 2: slave_addr=1, tx_trigger at slot_cnt=slot_ticks=400 ----
        $display("\n--- Test 2: slave_addr=1, trig at slot_cnt=400 ---");
        slave_addr = 3'd1;
        // Fire active_edge; count 400 clocks
        @(posedge clk); #1; active_edge = 1'b1;
        @(posedge clk); #1; active_edge = 1'b0;
        // slot_cnt is now 0 (reset to 0 registered at active_edge, so 0 at next clk)
        // tx_trigger fires when slot_cnt==400
        // expected_delay from ae-deassert to trigger: 400 clocks
        begin : test2
            integer cnt2;
            reg seen2;
            seen2 = 0;
            for (cnt2 = 0; cnt2 <= 410; cnt2 = cnt2 + 1) begin
                @(posedge clk);
                if (tx_trigger && !seen2) begin
                    seen2 = 1;
                    if (cnt2 == 401) begin
                        $display("[PASS] slave_addr=1: tx_trigger at slot_cnt=%0d", cnt2);
                        pass_cnt = pass_cnt + 1;
                    end else begin
                        $display("[FAIL] slave_addr=1: tx_trigger at slot_cnt=%0d, expected 401", cnt2);
                        fail_cnt = fail_cnt + 1;
                    end
                end
            end
            if (!seen2) begin
                $display("[FAIL] slave_addr=1: tx_trigger not seen");
                fail_cnt = fail_cnt + 1;
            end
        end
        repeat(10) @(posedge clk);

        // ---- Test 3: slave_addr=3, tx_trigger at slot_cnt=1200 ----
        $display("\n--- Test 3: slave_addr=3, trig at slot_cnt=1200 ---");
        slave_addr = 3'd3;
        @(posedge clk); #1; active_edge = 1'b1;
        @(posedge clk); #1; active_edge = 1'b0;
        begin : test3
            integer cnt3;
            reg seen3;
            seen3 = 0;
            for (cnt3 = 0; cnt3 <= 1210; cnt3 = cnt3 + 1) begin
                @(posedge clk);
                if (tx_trigger && !seen3) begin
                    seen3 = 1;
                    if (cnt3 == 1201) begin
                        $display("[PASS] slave_addr=3: tx_trigger at slot_cnt=%0d", cnt3);
                        pass_cnt = pass_cnt + 1;
                    end else begin
                        $display("[FAIL] slave_addr=3: tx_trigger at slot_cnt=%0d, expected 1201", cnt3);
                        fail_cnt = fail_cnt + 1;
                    end
                end
            end
            if (!seen3) begin
                $display("[FAIL] slave_addr=3: tx_trigger not seen");
                fail_cnt = fail_cnt + 1;
            end
        end
        repeat(10) @(posedge clk);

        // ---- Test 4: watchdog (no_broadcast) at 9*slot_ticks=3600 ----
        $display("\n--- Test 4: watchdog no_broadcast at slot_cnt=3600 ---");
        slave_addr = 3'd0;
        @(posedge clk); #1; active_edge = 1'b1;
        @(posedge clk); #1; active_edge = 1'b0;
        begin : test4
            integer cnt4;
            reg seen4;
            seen4 = 0;
            for (cnt4 = 0; cnt4 <= 3610; cnt4 = cnt4 + 1) begin
                @(posedge clk);
                if (no_broadcast && !seen4) begin
                    seen4 = 1;
                    if (cnt4 == 3601) begin
                        $display("[PASS] watchdog: no_broadcast at slot_cnt=%0d", cnt4);
                        pass_cnt = pass_cnt + 1;
                    end else begin
                        $display("[FAIL] watchdog: no_broadcast at slot_cnt=%0d, expected 3601", cnt4);
                        fail_cnt = fail_cnt + 1;
                    end
                end
            end
            if (!seen4) begin
                $display("[FAIL] watchdog: no_broadcast not seen");
                fail_cnt = fail_cnt + 1;
            end
        end

        // ---- Test 5: guard_ticks=10 → slot_ticks=410, trig at 410 for slave_addr=1 ----
        $display("\n--- Test 5: guard_ticks=10, slave_addr=1, trig at 410 ---");
        guard_ticks = 10'd10;
        slave_addr  = 3'd1;
        @(posedge clk); #1; active_edge = 1'b1;
        @(posedge clk); #1; active_edge = 1'b0;
        begin : test5
            integer cnt5;
            reg seen5;
            seen5 = 0;
            for (cnt5 = 0; cnt5 <= 420; cnt5 = cnt5 + 1) begin
                @(posedge clk);
                if (tx_trigger && !seen5) begin
                    seen5 = 1;
                    if (cnt5 == 411) begin
                        $display("[PASS] guard=10: tx_trigger at slot_cnt=%0d", cnt5);
                        pass_cnt = pass_cnt + 1;
                    end else begin
                        $display("[FAIL] guard=10: tx_trigger at slot_cnt=%0d, expected 411", cnt5);
                        fail_cnt = fail_cnt + 1;
                    end
                end
            end
            if (!seen5) begin
                $display("[FAIL] guard=10: tx_trigger not seen");
                fail_cnt = fail_cnt + 1;
            end
        end

        $display("\n[DONE] slot_timer: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        $finish;
    end

endmodule
