`timescale 1ns / 1ps

module tb_slave21_timebase;

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

    slave21_timebase dut (
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

        $display("[INFO] tb_slave21_timebase start");
        reset_dut();

        expect_value("reset/default period", {16'd0, o_BIT_PERIOD}, 32'd8);
        expect_value("reset period invalid", {31'd0, o_PERIOD_VALID}, 32'd0);
        expect_value("reset no rate error", {31'd0, o_RATE_ERR}, 32'd0);

        $display("[INFO] slot hold regression check");
        pulse_commit();
        expect_value("hold check commit slot zero", {29'd0, o_SLOT}, 32'd0);
        wait_cycles(1);
        expect_value("hold check slot remains zero", {29'd0, o_SLOT}, 32'd0);
        reset_dut();

        $display("[INFO] first good commit acquisition");
        pulse_commit();
        expect_value("first commit keeps default period", {16'd0, o_BIT_PERIOD}, 32'd8);
        expect_value("first commit period invalid", {31'd0, o_PERIOD_VALID}, 32'd0);
        expect_value("first commit slot zero", {29'd0, o_SLOT}, 32'd0);
        expect_value("first commit frame-done preload", {16'd0, o_SLOT_CLK_CNT}, 32'd400);

        $display("[INFO] second good commit expected interval");
        expected_interval = 3 * ((50 * 8) + 10);
        wait_commit_interval(expected_interval);
        expect_value("second commit period valid", {31'd0, o_PERIOD_VALID}, 32'd1);
        expect_value("expected interval keeps period", {16'd0, o_BIT_PERIOD}, 32'd8);
        expect_value("expected interval no rate error", {31'd0, o_RATE_ERR}, 32'd0);

        $display("[INFO] fast interval bounded correction");
        wait_commit_interval(expected_interval - 300);
        expect_value("fast interval decreases period", {16'd0, o_BIT_PERIOD}, 32'd6);
        expect_value("fast interval remains valid", {31'd0, o_PERIOD_VALID}, 32'd1);
        expect_value("fast interval no rate error", {31'd0, o_RATE_ERR}, 32'd0);

        $display("[INFO] slow interval bounded correction");
        expected_interval = 3 * ((50 * 6) + 10);
        wait_commit_interval(expected_interval + 300);
        expect_value("slow interval increases period", {16'd0, o_BIT_PERIOD}, 32'd8);
        expect_value("slow interval remains valid", {31'd0, o_PERIOD_VALID}, 32'd1);
        expect_value("slow interval no rate error", {31'd0, o_RATE_ERR}, 32'd0);

        $display("[INFO] tx allowed gating blocks trigger");
        i_NODE_ID = 3'd1;
        establish_tracking();
        i_TX_ALLOWED = 1'b0;
        expect_no_trigger_for("tx not allowed blocks trigger", 520);

        $display("[INFO] valid allowed node triggers");
        i_NODE_ID = 3'd1;
        establish_tracking();
        i_TX_ALLOWED = 1'b1;
        expect_trigger_within("tx allowed valid node trigger", 520);

        $display("[INFO] invalid node blocks trigger");
        i_NODE_ID = 3'd5;
        establish_tracking();
        i_TX_ALLOWED = 1'b1;
        expect_no_trigger_for("invalid node blocks trigger", 520);

        $display("[INFO] active tx blocks trigger");
        i_NODE_ID = 3'd1;
        establish_tracking();
        i_TX_ACTIVE = 1'b1;
        i_TX_ALLOWED = 1'b1;
        expect_no_trigger_for("active tx blocks trigger", 520);
        i_TX_ACTIVE = 1'b0;

        $display("[INFO] large rate error clears tracking");
        i_NODE_ID = 3'd1;
        establish_tracking();
        i_TX_ALLOWED = 1'b0;
        expected_interval = 3 * ((50 * 8) + 10);
        wait_commit_interval(expected_interval + 900);
        expect_value("large error asserted", {31'd0, o_RATE_ERR}, 32'd1);
        expect_value("large error clears valid", {31'd0, o_PERIOD_VALID}, 32'd0);
        expect_value("large error resets default period", {16'd0, o_BIT_PERIOD}, 32'd8);

        wait_cycles(2);
        expect_value("rate error pulse clears", {31'd0, o_RATE_ERR}, 32'd0);

        if (fail_count == 0) begin
            $display("PASS: tb_slave21_timebase");
        end else begin
            $display("FAIL: tb_slave21_timebase fail_count=%0d", fail_count);
        end

        $finish;
    end

endmodule
