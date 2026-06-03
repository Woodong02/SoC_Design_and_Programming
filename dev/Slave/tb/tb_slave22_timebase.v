`timescale 1ns / 1ps

module tb_slave22_timebase;

    reg         i_CLK;
    reg         i_RESETN;
    reg  [2:0]  i_NODE_ID;
    reg  [2:0]  i_NODE_CNT;
    reg  [15:0] i_BIT_PERIOD_DEFAULT;
    reg  [9:0]  i_GUARD_TICKS;
    reg         i_GOOD_BROADCAST_COMMIT;
    reg         i_TX_ACTIVE;
    reg         i_TX_ALLOWED;
    wire [15:0] o_BIT_PERIOD;
    wire        o_PERIOD_VALID;
    wire [2:0]  o_SLOT;
    wire [15:0] o_SLOT_CLK_CNT;
    wire        o_TX_TRIGGER;
    wire        o_RATE_ERR;

    integer fail_count;
    integer trigger_count;
    integer expected_interval;

    slave22_timebase dut (
        .i_CLK(i_CLK),
        .i_RESETN(i_RESETN),
        .i_NODE_ID(i_NODE_ID),
        .i_NODE_CNT(i_NODE_CNT),
        .i_BIT_PERIOD_DEFAULT(i_BIT_PERIOD_DEFAULT),
        .i_GUARD_TICKS(i_GUARD_TICKS),
        .i_GOOD_BROADCAST_COMMIT(i_GOOD_BROADCAST_COMMIT),
        .i_TX_ACTIVE(i_TX_ACTIVE),
        .i_TX_ALLOWED(i_TX_ALLOWED),
        .o_BIT_PERIOD(o_BIT_PERIOD),
        .o_PERIOD_VALID(o_PERIOD_VALID),
        .o_SLOT(o_SLOT),
        .o_SLOT_CLK_CNT(o_SLOT_CLK_CNT),
        .o_TX_TRIGGER(o_TX_TRIGGER),
        .o_RATE_ERR(o_RATE_ERR)
    );

    initial begin
        i_CLK = 1'b0;
        forever #5 i_CLK = ~i_CLK;
    end

    always @(posedge i_CLK) begin
        if (o_TX_TRIGGER == 1'b1) begin
            trigger_count = trigger_count + 1;
            $display("[INFO] TX trigger slot=%0d slot_cnt=%0d time=%0t",
                     o_SLOT, o_SLOT_CLK_CNT, $time);
        end
    end

    task expect_value;
        input [511:0] name;
        input [31:0] got;
        input [31:0] exp;
        begin
            if (got !== exp) begin
                $display("[FAIL] %0s got=%0d exp=%0d time=%0t", name, got, exp, $time);
                fail_count = fail_count + 1;
            end else begin
                $display("[PASS] %0s got=%0d time=%0t", name, got, $time);
            end
        end
    endtask

    task reset_dut;
        begin
            i_RESETN = 1'b0;
            i_GOOD_BROADCAST_COMMIT = 1'b0;
            i_TX_ACTIVE = 1'b0;
            i_TX_ALLOWED = 1'b0;
            trigger_count = 0;
            repeat (4) @(posedge i_CLK);
            i_RESETN = 1'b1;
            repeat (2) @(posedge i_CLK);
            #1;
        end
    endtask

    task pulse_commit;
        begin
            @(negedge i_CLK);
            i_GOOD_BROADCAST_COMMIT = 1'b1;
            @(posedge i_CLK);
            #1;
            @(negedge i_CLK);
            i_GOOD_BROADCAST_COMMIT = 1'b0;
            #1;
        end
    endtask

    task wait_cycles;
        input integer cycle_count;
        integer index;
        begin
            for (index = 0; index < cycle_count; index = index + 1) begin
                @(posedge i_CLK);
                #1;
            end
        end
    endtask

    task wait_commit_interval;
        input integer interval_count;
        begin
            wait_cycles(interval_count - 1);
            pulse_commit();
        end
    endtask

    task expect_no_trigger_for;
        input [511:0] name;
        input integer cycle_count;
        integer start_count;
        begin
            start_count = trigger_count;
            wait_cycles(cycle_count);
            if (trigger_count != start_count) begin
                $display("[FAIL] %0s trigger_count changed %0d -> %0d time=%0t",
                         name, start_count, trigger_count, $time);
                fail_count = fail_count + 1;
            end else begin
                $display("[PASS] %0s trigger_count=%0d time=%0t", name, trigger_count, $time);
            end
        end
    endtask

    task expect_trigger_within;
        input [511:0] name;
        input integer cycle_count;
        integer start_count;
        begin
            start_count = trigger_count;
            wait_cycles(cycle_count);
            if (trigger_count == start_count) begin
                $display("[FAIL] %0s no trigger within %0d cycles time=%0t",
                         name, cycle_count, $time);
                fail_count = fail_count + 1;
            end else begin
                $display("[PASS] %0s observed=%0d time=%0t",
                         name, trigger_count - start_count, $time);
            end
        end
    endtask

    // Establish TRACKING (period_valid=1, period converged to 8).
    task establish_tracking;
        begin
            i_TX_ALLOWED = 1'b0;
            i_TX_ACTIVE = 1'b0;
            trigger_count = 0;
            reset_dut();
            pulse_commit();
            expected_interval = 3 * ((50 * 8) + 10);
            wait_commit_interval(expected_interval);
            expect_value("tracking setup valid", {31'd0, o_PERIOD_VALID}, 32'd1);
            expect_value("tracking setup period", {16'd0, o_BIT_PERIOD}, 32'd8);
            trigger_count = 0;
        end
    endtask

    initial begin
        fail_count = 0;
        trigger_count = 0;

        i_NODE_ID = 3'd1;
        i_NODE_CNT = 3'd2;
        i_BIT_PERIOD_DEFAULT = 16'd8;
        i_GUARD_TICKS = 10'd10;

        $display("[INFO] tb_slave22_timebase start");
        reset_dut();

        // ---- T1: reset init ----
        $display("[INFO] T1 reset init");
        expect_value("T1 reset/default period", {16'd0, o_BIT_PERIOD}, 32'd8);
        expect_value("T1 reset period invalid", {31'd0, o_PERIOD_VALID}, 32'd0);
        expect_value("T1 reset no rate error", {31'd0, o_RATE_ERR}, 32'd0);

        // ---- 2.1 regression: slot hold on commit ----
        $display("[INFO] slot hold regression check");
        pulse_commit();
        expect_value("reg hold commit slot zero", {29'd0, o_SLOT}, 32'd0);
        wait_cycles(1);
        expect_value("reg hold slot remains zero", {29'd0, o_SLOT}, 32'd0);
        reset_dut();

        // ---- T2: first good -> WAIT_SECOND, period_valid stays 0 ----
        $display("[INFO] T2 first good commit acquisition");
        pulse_commit();
        expect_value("T2 first commit keeps default period", {16'd0, o_BIT_PERIOD}, 32'd8);
        expect_value("T2 first commit period invalid", {31'd0, o_PERIOD_VALID}, 32'd0);
        expect_value("T2 first commit slot zero", {29'd0, o_SLOT}, 32'd0);
        expect_value("T2 first commit frame-done preload", {16'd0, o_SLOT_CLK_CNT}, 32'd400);

        // ---- T3: second good -> TRACKING, period_valid=1 ----
        $display("[INFO] T3 second good commit -> tracking");
        expected_interval = 3 * ((50 * 8) + 10);
        wait_commit_interval(expected_interval);
        expect_value("T3 second commit period valid", {31'd0, o_PERIOD_VALID}, 32'd1);
        expect_value("T3 expected interval keeps period", {16'd0, o_BIT_PERIOD}, 32'd8);
        expect_value("T3 expected interval no rate error", {31'd0, o_RATE_ERR}, 32'd0);

        // ---- T13: rate correction accuracy (fast / slow) ----
        $display("[INFO] T13 fast interval bounded correction");
        wait_commit_interval(expected_interval - 300);
        expect_value("T13 fast interval decreases period", {16'd0, o_BIT_PERIOD}, 32'd6);
        expect_value("T13 fast interval remains valid", {31'd0, o_PERIOD_VALID}, 32'd1);
        expect_value("T13 fast interval no rate error", {31'd0, o_RATE_ERR}, 32'd0);

        $display("[INFO] T13 slow interval bounded correction");
        expected_interval = 3 * ((50 * 6) + 10);
        wait_commit_interval(expected_interval + 300);
        expect_value("T13 slow interval increases period", {16'd0, o_BIT_PERIOD}, 32'd8);
        expect_value("T13 slow interval remains valid", {31'd0, o_PERIOD_VALID}, 32'd1);
        expect_value("T13 slow interval no rate error", {31'd0, o_RATE_ERR}, 32'd0);

        // ---- T12: tx allowed gating ----
        $display("[INFO] T12 tx allowed gating blocks trigger");
        i_NODE_ID = 3'd1;
        establish_tracking();
        i_TX_ALLOWED = 1'b0;
        expect_no_trigger_for("T12 tx not allowed blocks trigger", 520);

        // ---- valid allowed node triggers ----
        $display("[INFO] valid allowed node triggers");
        i_NODE_ID = 3'd1;
        establish_tracking();
        i_TX_ALLOWED = 1'b1;
        expect_trigger_within("tx allowed valid node trigger", 520);

        // ---- T10: invalid node blocks trigger ----
        $display("[INFO] T10 invalid node blocks trigger");
        i_NODE_ID = 3'd5;
        establish_tracking();
        i_TX_ALLOWED = 1'b1;
        expect_no_trigger_for("T10 invalid node blocks trigger", 520);
        i_NODE_ID = 3'd1;

        // ---- T11: active tx blocks trigger ----
        $display("[INFO] T11 active tx blocks trigger");
        i_NODE_ID = 3'd1;
        establish_tracking();
        i_TX_ACTIVE = 1'b1;
        i_TX_ALLOWED = 1'b1;
        expect_no_trigger_for("T11 active tx blocks trigger", 520);
        i_TX_ACTIVE = 1'b0;

        // ---- T4: TRACKING + rate_error -> HOLDOVER (period_valid & bit_period held) ----
        $display("[INFO] T4 tracking rate_error -> holdover");
        i_NODE_ID = 3'd1;
        establish_tracking();
        i_TX_ALLOWED = 1'b0;
        expected_interval = 3 * ((50 * 8) + 10);
        // big positive interval error -> rate error
        wait_commit_interval(expected_interval + 900);
        expect_value("T4 rate error asserted", {31'd0, o_RATE_ERR}, 32'd1);
        expect_value("T4 holdover keeps period valid", {31'd0, o_PERIOD_VALID}, 32'd1);
        expect_value("T4 holdover holds bit period", {16'd0, o_BIT_PERIOD}, 32'd8);
        wait_cycles(2);
        expect_value("T4 rate error pulse clears", {31'd0, o_RATE_ERR}, 32'd0);
        expect_value("T4 still period valid after pulse", {31'd0, o_PERIOD_VALID}, 32'd1);

        // ---- T5/T6: HOLDOVER -> good -> WAIT_SECOND -> good -> TRACKING (correction resumes) ----
        $display("[INFO] T5/T6 holdover recovery");
        // First good after holdover: re-anchors, starts re-measure (period_valid stays 1)
        pulse_commit();
        expect_value("T5 holdover first good keeps valid", {31'd0, o_PERIOD_VALID}, 32'd1);
        expect_value("T5 holdover first good keeps period", {16'd0, o_BIT_PERIOD}, 32'd8);
        // Second good (normal interval): TRACKING, correction resumes, miss cleared
        expected_interval = 3 * ((50 * 8) + 10);
        wait_commit_interval(expected_interval);
        expect_value("T6 holdover recovered valid", {31'd0, o_PERIOD_VALID}, 32'd1);
        expect_value("T6 holdover recovered period", {16'd0, o_BIT_PERIOD}, 32'd8);
        expect_value("T6 holdover recovered no rate err", {31'd0, o_RATE_ERR}, 32'd0);

        // ---- T7: Scenario 9 reproduction ----
        // rate_error + good same clock -> HOLDOVER (period_valid held). Next good -> tx_trigger.
        $display("[INFO] T7 Scenario 9 reproduction");
        i_NODE_ID = 3'd1;
        establish_tracking();
        i_TX_ALLOWED = 1'b0;
        i_TX_ACTIVE = 1'b0;
        // Induce rate_error coincident with good_broadcast_commit (interval far too long).
        expected_interval = 3 * ((50 * 8) + 10);
        wait_commit_interval(expected_interval + 900);
        expect_value("T7 rate error at recovery good", {31'd0, o_RATE_ERR}, 32'd1);
        expect_value("T7 holdover period valid held", {31'd0, o_PERIOD_VALID}, 32'd1);
        // fault_fsm would now allow TX. Enable allowed and present next good broadcast.
        i_TX_ALLOWED = 1'b1;
        trigger_count = 0;
        // Next good broadcast re-anchors slot; trigger must fire within a frame.
        pulse_commit();
        expect_trigger_within("T7 next good produces tx_trigger", 520);
        i_TX_ALLOWED = 1'b0;

        // ---- T8: miss_count accumulation beyond limit -> reset to default, WAIT_FIRST ----
        $display("[INFO] T8 miss_count accumulation -> reset");
        i_NODE_ID = 3'd1;
        establish_tracking();
        i_TX_ALLOWED = 1'b0;
        expected_interval = 3 * ((50 * 8) + 10);
        // Generate MISS_RESET_LIMIT+1 = 5 consecutive rate errors.
        // Each rate-error good is a commit with bad interval; interval_seen reset each time,
        // so we need a preceding good to set interval_seen before each bad-interval good.
        begin : t8_block
            integer m;
            for (m = 0; m < 6; m = m + 1) begin
                pulse_commit();                                  // sets interval_seen
                wait_commit_interval(expected_interval + 900);   // bad interval -> rate error / miss++
            end
        end
        // After exceeding limit: bit_period default, period_valid 0.
        expect_value("T8 miss exceeded resets period", {16'd0, o_BIT_PERIOD}, 32'd8);
        expect_value("T8 miss exceeded clears valid", {31'd0, o_PERIOD_VALID}, 32'd0);

        // ---- T9: normal interval clears miss_count (single later miss absorbed by holdover) ----
        $display("[INFO] T9 miss_count cleared by good interval");
        i_NODE_ID = 3'd1;
        establish_tracking();   // fully reacquires -> miss_count = 0 via good intervals
        i_TX_ALLOWED = 1'b0;
        // A single rate error now must NOT reset (proves miss_count was cleared): holdover.
        expected_interval = 3 * ((50 * 8) + 10);
        wait_commit_interval(expected_interval + 900);
        expect_value("T9 single miss stays valid (count cleared)", {31'd0, o_PERIOD_VALID}, 32'd1);
        expect_value("T9 single miss holds period", {16'd0, o_BIT_PERIOD}, 32'd8);

        if (fail_count == 0) begin
            $display("PASS: tb_slave22_timebase");
        end else begin
            $display("FAIL: tb_slave22_timebase fail_count=%0d", fail_count);
        end

        $finish;
    end

endmodule
