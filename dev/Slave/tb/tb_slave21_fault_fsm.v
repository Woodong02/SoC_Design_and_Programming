`timescale 1ns / 1ps

module tb_slave21_fault_fsm;

    localparam [2:0] FLT21_RESET     = 3'd0;
    localparam [2:0] FLT21_ACQUIRE   = 3'd1;
    localparam [2:0] FLT21_SEEN_ONCE = 3'd2;
    localparam [2:0] FLT21_TRACKING  = 3'd3;
    localparam [2:0] FLT21_RECOVERY  = 3'd4;

    reg        i_CLK;
    reg        i_RESETN;
    reg        i_FRAME_DONE;
    reg        i_GOOD_BROADCAST;
    reg        i_HALT_FOR_ME;
    reg        i_RATE_ERR;
    wire       o_TX_ALLOWED;
    wire       o_GOOD_BROADCAST_COMMIT;
    wire [2:0] o_FAULT_STATE;

    integer fail_count;

    slave21_fault_fsm dut (
        .i_CLK(i_CLK),
        .i_RESETN(i_RESETN),
        .i_FRAME_DONE(i_FRAME_DONE),
        .i_GOOD_BROADCAST(i_GOOD_BROADCAST),
        .i_HALT_FOR_ME(i_HALT_FOR_ME),
        .i_RATE_ERR(i_RATE_ERR),
        .o_TX_ALLOWED(o_TX_ALLOWED),
        .o_GOOD_BROADCAST_COMMIT(o_GOOD_BROADCAST_COMMIT),
        .o_FAULT_STATE(o_FAULT_STATE)
    );

    initial begin
        i_CLK = 1'b0;
        forever #5 i_CLK = ~i_CLK;
    end

    task check_value;
        input [255:0] label;
        input integer got;
        input integer exp;
        begin
            if (got !== exp) begin
                fail_count = fail_count + 1;
                $display("[FAIL] %0s got=%0d exp=%0d time=%0t", label, got, exp, $time);
            end else begin
                $display("[PASS] %0s got=%0d time=%0t", label, got, $time);
            end
        end
    endtask

    task drive_frame;
        input good_frame;
        begin
            @(negedge i_CLK);
            i_GOOD_BROADCAST = good_frame;
            i_FRAME_DONE = 1'b1;
            #1;
            check_value("commit pulse during frame", o_GOOD_BROADCAST_COMMIT, good_frame);
            @(negedge i_CLK);
            i_FRAME_DONE = 1'b0;
            i_GOOD_BROADCAST = 1'b0;
            @(posedge i_CLK);
            #1;
        end
    endtask

    task pulse_rate_error;
        begin
            @(negedge i_CLK);
            i_RATE_ERR = 1'b1;
            @(negedge i_CLK);
            i_RATE_ERR = 1'b0;
            @(posedge i_CLK);
            #1;
        end
    endtask

    initial begin
        fail_count = 0;
        i_RESETN = 1'b0;
        i_FRAME_DONE = 1'b0;
        i_GOOD_BROADCAST = 1'b0;
        i_HALT_FOR_ME = 1'b0;
        i_RATE_ERR = 1'b0;

        repeat (3) @(posedge i_CLK);
        #1;
        check_value("reset state", o_FAULT_STATE, FLT21_RESET);
        check_value("reset tx blocked", o_TX_ALLOWED, 0);

        @(negedge i_CLK);
        i_RESETN = 1'b1;
        @(posedge i_CLK);
        #1;
        check_value("reset release enters acquire", o_FAULT_STATE, FLT21_ACQUIRE);
        check_value("acquire tx blocked", o_TX_ALLOWED, 0);

        drive_frame(1'b0);
        check_value("bad frame stays acquire", o_FAULT_STATE, FLT21_ACQUIRE);
        check_value("bad frame tx blocked", o_TX_ALLOWED, 0);

        drive_frame(1'b1);
        check_value("first good enters seen once", o_FAULT_STATE, FLT21_SEEN_ONCE);
        check_value("seen once tx blocked", o_TX_ALLOWED, 0);

        drive_frame(1'b0);
        check_value("bad after seen once returns acquire", o_FAULT_STATE, FLT21_ACQUIRE);
        check_value("acquire after bad tx blocked", o_TX_ALLOWED, 0);

        drive_frame(1'b1);
        check_value("re-first good enters seen once", o_FAULT_STATE, FLT21_SEEN_ONCE);
        drive_frame(1'b1);
        check_value("second good enters tracking", o_FAULT_STATE, FLT21_TRACKING);
        check_value("tracking tx allowed", o_TX_ALLOWED, 1);

        @(negedge i_CLK);
        i_HALT_FOR_ME = 1'b1;
        #1;
        check_value("halt gates tx in tracking", o_TX_ALLOWED, 0);
        @(negedge i_CLK);
        i_HALT_FOR_ME = 1'b0;
        #1;
        check_value("halt clear restores tx allowed", o_TX_ALLOWED, 1);

        drive_frame(1'b0);
        check_value("bad in tracking enters recovery", o_FAULT_STATE, FLT21_RECOVERY);
        check_value("recovery tx blocked", o_TX_ALLOWED, 0);

        drive_frame(1'b1);
        check_value("recovery first good enters seen once", o_FAULT_STATE, FLT21_SEEN_ONCE);
        drive_frame(1'b1);
        check_value("recovery second good enters tracking", o_FAULT_STATE, FLT21_TRACKING);
        check_value("tracking restored tx allowed", o_TX_ALLOWED, 1);

        pulse_rate_error();
        check_value("rate error enters recovery", o_FAULT_STATE, FLT21_RECOVERY);
        check_value("rate recovery tx blocked", o_TX_ALLOWED, 0);

        drive_frame(1'b0);
        check_value("bad in recovery stays recovery", o_FAULT_STATE, FLT21_RECOVERY);

        if (fail_count == 0) begin
            $display("PASS: tb_slave21_fault_fsm");
        end else begin
            $display("FAIL: tb_slave21_fault_fsm fail_count=%0d", fail_count);
        end

        $finish;
    end

endmodule
