`timescale 1ns / 1ps

module tb_slave_slot_timer;

    reg         i_CLK;
    reg         i_RESETN;
    reg  [2:0]  i_NODE_ID;
    reg  [2:0]  i_NODE_CNT;
    reg  [9:0]  i_BIT_DIV;
    reg  [9:0]  i_GUARD_TICKS;
    reg         i_SYNC_PULSE;
    reg  [15:0] i_SYNC_CLK_CNT;
    wire        o_SYNCED;
    wire [2:0]  o_SLOT;
    wire [15:0] o_CLK_CNT;
    wire        o_TX_TRIGGER;

    integer fail_count;
    integer trigger_count;

    slave_slot_timer dut (
        .i_CLK(i_CLK),
        .i_RESETN(i_RESETN),
        .i_NODE_ID(i_NODE_ID),
        .i_NODE_CNT(i_NODE_CNT),
        .i_BIT_DIV(i_BIT_DIV),
        .i_GUARD_TICKS(i_GUARD_TICKS),
        .i_SYNC_PULSE(i_SYNC_PULSE),
        .i_SYNC_CLK_CNT(i_SYNC_CLK_CNT),
        .o_SYNCED(o_SYNCED),
        .o_SLOT(o_SLOT),
        .o_CLK_CNT(o_CLK_CNT),
        .o_TX_TRIGGER(o_TX_TRIGGER)
    );

    initial begin
        i_CLK = 1'b0;
        forever #5 i_CLK = ~i_CLK;
    end

    task expect_value;
        input [255:0] name;
        input [31:0]  got;
        input [31:0]  exp;
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
            i_SYNC_CLK_CNT = 16'd0;
            repeat (3) @(posedge i_CLK);
            i_RESETN = 1'b1;
            @(posedge i_CLK);
        end
    endtask

    task pulse_sync;
        input [15:0] preload;
        begin
            @(negedge i_CLK);
            i_SYNC_CLK_CNT = preload;
            i_SYNC_PULSE = 1'b1;
            @(negedge i_CLK);
            i_SYNC_PULSE = 1'b0;
            i_SYNC_CLK_CNT = 16'd0;
            @(posedge i_CLK);
        end
    endtask

    always @(posedge i_CLK) begin
        if (o_TX_TRIGGER) begin
            trigger_count = trigger_count + 1;
            $display("[WAVE] TX trigger observed slot=%0d clk_cnt=%0d time=%0t", o_SLOT, o_CLK_CNT, $time);
        end
    end

    initial begin
        fail_count = 0;
        trigger_count = 0;

        i_NODE_ID = 3'd1;
        i_NODE_CNT = 3'd2;
        i_BIT_DIV = 10'd4;
        i_GUARD_TICKS = 10'd8;

        $display("[INFO] slave_slot_timer TB start");
        reset_dut();

        expect_value("reset synced", {31'd0, o_SYNCED}, 32'd0);
        expect_value("reset slot", {29'd0, o_SLOT}, 32'd0);
        expect_value("reset clk_cnt", {16'd0, o_CLK_CNT}, 32'd0);
        expect_value("reset tx_trigger", {31'd0, o_TX_TRIGGER}, 32'd0);

        $display("[INFO] sync with preload 8*BIT_DIV model value");
        pulse_sync(16'd3);
        expect_value("sync enters locked", {31'd0, o_SYNCED}, 32'd1);
        expect_value("sync slot zero", {29'd0, o_SLOT}, 32'd0);
        expect_value("sync preload clk_cnt", {16'd0, o_CLK_CNT}, 32'd3);
        expect_value("sync cycle trigger blocked", {31'd0, o_TX_TRIGGER}, 32'd0);

        @(posedge i_CLK);
        expect_value("locked counter increments", {16'd0, o_CLK_CNT}, 32'd4);

        $display("[INFO] wait for slot 1 trigger at GUARD_TICKS/2");
        while (!((o_SLOT == 3'd1) && (o_CLK_CNT == 16'd5))) begin
            @(posedge i_CLK);
        end
        expect_value("trigger after registered tick", {31'd0, o_TX_TRIGGER}, 32'd1);

        $display("[INFO] wait for slot wrap 0 after slot 2");
        while (!((o_SLOT == 3'd0) && (o_CLK_CNT == 16'd0))) begin
            @(posedge i_CLK);
        end
        expect_value("cycle wrap slot", {29'd0, o_SLOT}, 32'd0);
        expect_value("cycle wrap cnt", {16'd0, o_CLK_CNT}, 32'd0);

        $display("[INFO] repeated sync should resync immediately");
        repeat (5) @(posedge i_CLK);
        pulse_sync(16'd11);
        expect_value("resync slot zero", {29'd0, o_SLOT}, 32'd0);
        expect_value("resync preload", {16'd0, o_CLK_CNT}, 32'd11);

        $display("[INFO] NODE_ID > NODE_CNT blocks trigger");
        i_NODE_ID = 3'd5;
        i_NODE_CNT = 3'd2;
        trigger_count = 0;
        pulse_sync(16'd0);
        repeat (170) @(posedge i_CLK);
        expect_value("invalid node trigger count", trigger_count[31:0], 32'd0);

        if (fail_count == 0)
            $display("PASS: tb_slave_slot_timer");
        else
            $display("FAIL: tb_slave_slot_timer fail_count=%0d", fail_count);

        $finish;
    end

endmodule

