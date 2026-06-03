`timescale 1ns / 1ps

module tb_slave2_line_sync;

    reg  i_CLK;
    reg  i_RESETN;
    reg  i_SERIAL_ASYNC;
    wire o_SERIAL_SYNC;

    integer fail_count;
    integer saw_00;
    integer saw_10;
    integer saw_11;
    integer saw_01;

    slave2_line_sync dut (
        .i_CLK(i_CLK),
        .i_RESETN(i_RESETN),
        .i_SERIAL_ASYNC(i_SERIAL_ASYNC),
        .o_SERIAL_SYNC(o_SERIAL_SYNC)
    );

    initial begin
        i_CLK = 1'b0;
        forever #5 i_CLK = ~i_CLK;
    end

    always @(posedge i_CLK or negedge i_RESETN) begin
        if (!i_RESETN) begin
            saw_00 <= 1;
        end else begin
            if ({dut.ff_sync_stage1, dut.ff_sync_stage2} == 2'b00)
                saw_00 <= 1;
            if ({dut.ff_sync_stage1, dut.ff_sync_stage2} == 2'b10)
                saw_10 <= 1;
            if ({dut.ff_sync_stage1, dut.ff_sync_stage2} == 2'b11)
                saw_11 <= 1;
            if ({dut.ff_sync_stage1, dut.ff_sync_stage2} == 2'b01)
                saw_01 <= 1;
        end
    end

    task expect_bit;
        input [255:0] name;
        input         got;
        input         exp;
        begin
            if (got !== exp) begin
                $display("[FAIL] %0s got=%0b exp=%0b time=%0t", name, got, exp, $time);
                fail_count = fail_count + 1;
            end else begin
                $display("[PASS] %0s got=%0b time=%0t", name, got, $time);
            end
        end
    endtask

    task expect_stage;
        input [255:0] name;
        input [1:0]   exp;
        begin
            if ({dut.ff_sync_stage1, dut.ff_sync_stage2} !== exp) begin
                $display("[FAIL] %0s stage=%0b exp=%0b time=%0t",
                         name, {dut.ff_sync_stage1, dut.ff_sync_stage2}, exp, $time);
                fail_count = fail_count + 1;
            end else begin
                $display("[PASS] %0s stage=%0b time=%0t",
                         name, {dut.ff_sync_stage1, dut.ff_sync_stage2}, $time);
            end
        end
    endtask

    task reset_with_async;
        input async_value;
        begin
            @(negedge i_CLK);
            i_SERIAL_ASYNC = async_value;
            i_RESETN = 1'b0;
            repeat (3) @(posedge i_CLK);
            expect_bit("reset output low", o_SERIAL_SYNC, 1'b0);
            expect_stage("reset clears stages", 2'b00);
            @(negedge i_CLK);
            i_RESETN = 1'b1;
        end
    endtask

    initial begin
        fail_count = 0;
        saw_00 = 0;
        saw_10 = 0;
        saw_11 = 0;
        saw_01 = 0;

        i_RESETN = 1'b0;
        i_SERIAL_ASYNC = 1'b0;

        $display("[INFO] tb_slave2_line_sync start");

        reset_with_async(1'b1);

        @(posedge i_CLK);
        #1;
        expect_stage("stable high after first edge", 2'b10);
        expect_bit("stable high output first edge latency", o_SERIAL_SYNC, 1'b0);

        @(posedge i_CLK);
        #1;
        expect_stage("stable high after second edge", 2'b11);
        expect_bit("stable high output after two edges", o_SERIAL_SYNC, 1'b1);

        @(negedge i_CLK);
        i_SERIAL_ASYNC = 1'b0;

        @(posedge i_CLK);
        #1;
        expect_stage("stable low after first edge", 2'b01);
        expect_bit("stable low output first edge latency", o_SERIAL_SYNC, 1'b1);

        @(posedge i_CLK);
        #1;
        expect_stage("stable low after second edge", 2'b00);
        expect_bit("stable low output after two edges", o_SERIAL_SYNC, 1'b0);

        $display("[INFO] one-clock pulse latency test");
        @(negedge i_CLK);
        i_SERIAL_ASYNC = 1'b1;
        @(posedge i_CLK);
        #1;
        expect_stage("pulse captured in stage1", 2'b10);
        expect_bit("pulse output still low", o_SERIAL_SYNC, 1'b0);

        @(negedge i_CLK);
        i_SERIAL_ASYNC = 1'b0;
        @(posedge i_CLK);
        #1;
        expect_stage("pulse moved to stage2", 2'b01);
        expect_bit("pulse output high after latency", o_SERIAL_SYNC, 1'b1);

        @(posedge i_CLK);
        #1;
        expect_stage("pulse drained", 2'b00);
        expect_bit("pulse output returns low", o_SERIAL_SYNC, 1'b0);

        $display("[INFO] reset while async high");
        reset_with_async(1'b1);
        expect_bit("reset masks async high output", o_SERIAL_SYNC, 1'b0);
        expect_stage("reset masks async high stages", 2'b00);

        @(posedge i_CLK);
        #1;
        @(posedge i_CLK);
        #1;

        expect_bit("reachable stage 00 seen", saw_00[0], 1'b1);
        expect_bit("reachable stage 10 seen", saw_10[0], 1'b1);
        expect_bit("reachable stage 11 seen", saw_11[0], 1'b1);
        expect_bit("reachable stage 01 seen", saw_01[0], 1'b1);

        if (fail_count == 0)
            $display("PASS: tb_slave2_line_sync");
        else
            $display("FAIL: tb_slave2_line_sync fail_count=%0d", fail_count);

        $finish;
    end

endmodule
