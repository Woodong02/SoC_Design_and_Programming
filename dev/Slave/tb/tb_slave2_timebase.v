`timescale 1ns / 1ps

module tb_slave2_timebase;

    reg         i_CLK;
    reg         i_RESETN;
    reg  [2:0]  i_NODE_ID;
    reg  [2:0]  i_NODE_CNT;
    reg  [9:0]  i_BIT_DIV_DEFAULT;
    reg  [9:0]  i_GUARD_TICKS;
    reg         i_SYNC_PULSE;
    reg         i_RX_ACTIVE;
    reg         i_TX_ACTIVE;
    wire        o_LOCKED;
    wire [15:0] o_BIT_PERIOD_EST;
    wire [2:0]  o_SLOT;
    wire [15:0] o_SLOT_CLK_CNT;
    wire        o_SAMPLE_TICK;
    wire        o_SAMPLE_EARLY_TICK;
    wire        o_SAMPLE_LATE_TICK;
    wire        o_TX_BIT_TICK;
    wire        o_TX_TRIGGER;
    wire        o_RATE_ERR;

    integer fail_count;
    integer trigger_count;

    slave2_timebase dut (
        .i_CLK(i_CLK),
        .i_RESETN(i_RESETN),
        .i_NODE_ID(i_NODE_ID),
        .i_NODE_CNT(i_NODE_CNT),
        .i_BIT_DIV_DEFAULT(i_BIT_DIV_DEFAULT),
        .i_GUARD_TICKS(i_GUARD_TICKS),
        .i_SYNC_PULSE(i_SYNC_PULSE),
        .i_RX_ACTIVE(i_RX_ACTIVE),
        .i_TX_ACTIVE(i_TX_ACTIVE),
        .o_LOCKED(o_LOCKED),
        .o_BIT_PERIOD_EST(o_BIT_PERIOD_EST),
        .o_SLOT(o_SLOT),
        .o_SLOT_CLK_CNT(o_SLOT_CLK_CNT),
        .o_SAMPLE_TICK(o_SAMPLE_TICK),
        .o_SAMPLE_EARLY_TICK(o_SAMPLE_EARLY_TICK),
        .o_SAMPLE_LATE_TICK(o_SAMPLE_LATE_TICK),
        .o_TX_BIT_TICK(o_TX_BIT_TICK),
        .o_TX_TRIGGER(o_TX_TRIGGER),
        .o_RATE_ERR(o_RATE_ERR)
    );

    initial begin
        i_CLK = 1'b0;
        forever #5 i_CLK = ~i_CLK;
    end

    task expect_value;
        input [255:0] name;
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
            i_SYNC_PULSE = 1'b0;
            i_RX_ACTIVE = 1'b0;
            i_TX_ACTIVE = 1'b0;
            repeat (4) @(posedge i_CLK);
            i_RESETN = 1'b1;
            @(posedge i_CLK);
        end
    endtask

    task pulse_sync;
        begin
            @(negedge i_CLK);
            i_SYNC_PULSE = 1'b1;
            @(negedge i_CLK);
            i_SYNC_PULSE = 1'b0;
            @(posedge i_CLK);
        end
    endtask

    task wait_cycles;
        input integer cycle_count;
        integer index;
        begin
            for (index = 0; index < cycle_count; index = index + 1) begin
                @(posedge i_CLK);
            end
        end
    endtask

    always @(posedge i_CLK) begin
        if (o_TX_TRIGGER) begin
            trigger_count = trigger_count + 1;
            $display("[INFO] TX trigger slot=%0d cnt=%0d time=%0t", o_SLOT, o_SLOT_CLK_CNT, $time);
        end
    end

    initial begin
        fail_count = 0;
        trigger_count = 0;

        i_NODE_ID = 3'd1;
        i_NODE_CNT = 3'd2;
        i_BIT_DIV_DEFAULT = 10'd8;
        i_GUARD_TICKS = 10'd10;

        $display("[INFO] tb_slave2_timebase start");
        reset_dut();

        expect_value("reset locked", {31'd0, o_LOCKED}, 32'd0);
        expect_value("reset period default loaded", {16'd0, o_BIT_PERIOD_EST}, 32'd8);

        wait_cycles(2);
        expect_value("default period loaded", {16'd0, o_BIT_PERIOD_EST}, 32'd8);

        $display("[INFO] default ticks");
        while (o_SAMPLE_TICK == 1'b0) begin
            @(posedge i_CLK);
        end
        expect_value("sample tick observed", {31'd0, o_SAMPLE_TICK}, 32'd1);
        while (o_TX_BIT_TICK == 1'b0) begin
            @(posedge i_CLK);
        end
        expect_value("tx bit tick observed", {31'd0, o_TX_BIT_TICK}, 32'd1);

        $display("[INFO] first sync acquisition");
        pulse_sync();
        expect_value("first sync not locked", {31'd0, o_LOCKED}, 32'd0);
        expect_value("first sync slot zero", {29'd0, o_SLOT}, 32'd0);
        expect_value("first sync preload 8 bits", {16'd0, o_SLOT_CLK_CNT}, 32'd64);

        $display("[INFO] second sync expected interval enters tracking");
        wait_cycles(1230);
        pulse_sync();
        expect_value("second sync locked", {31'd0, o_LOCKED}, 32'd1);
        expect_value("expected interval keeps period", {16'd0, o_BIT_PERIOD_EST}, 32'd8);

        $display("[INFO] fast cycle decreases period");
        wait_cycles(900);
        pulse_sync();
        expect_value("fast interval bounded period decrease", {16'd0, o_BIT_PERIOD_EST}, 32'd6);

        $display("[INFO] slow cycle increases period");
        wait_cycles(1230);
        pulse_sync();
        expect_value("slow interval bounded period increase", {16'd0, o_BIT_PERIOD_EST}, 32'd8);

        $display("[INFO] active pending update");
        i_TX_ACTIVE = 1'b1;
        wait_cycles(900);
        pulse_sync();
        expect_value("active holds current period", {16'd0, o_BIT_PERIOD_EST}, 32'd8);
        i_TX_ACTIVE = 1'b0;
        wait_cycles(2);
        expect_value("pending applies at boundary", {16'd0, o_BIT_PERIOD_EST}, 32'd6);

        $display("[INFO] invalid node blocks trigger");
        i_NODE_ID = 3'd5;
        trigger_count = 0;
        wait_cycles(300);
        expect_value("invalid node trigger count", trigger_count[31:0], 32'd0);

        $display("[INFO] valid node trigger appears");
        i_NODE_ID = 3'd1;
        trigger_count = 0;
        pulse_sync();
        wait_cycles(330);
        if (trigger_count == 0) begin
            $display("[FAIL] valid node trigger missing time=%0t", $time);
            fail_count = fail_count + 1;
        end else begin
            $display("[PASS] valid node trigger count=%0d", trigger_count);
        end

        $display("[INFO] large error enters holdover/rate error");
        wait_cycles(9000);
        pulse_sync();
        expect_value("large error asserted", {31'd0, o_RATE_ERR}, 32'd1);
        expect_value("large error unlocks tracking", {31'd0, o_LOCKED}, 32'd0);

        if (fail_count == 0)
            $display("PASS: tb_slave2_timebase");
        else
            $display("FAIL: tb_slave2_timebase fail_count=%0d", fail_count);

        $finish;
    end

endmodule
