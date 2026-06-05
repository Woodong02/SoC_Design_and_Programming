`timescale 1ns / 1ps

module tb_slave_timing_scheduler;

    reg         clk;
    reg         resetn;
    reg         cfg_enable;
    reg         sync_pulse;
    reg         cycle_done;
    reg  [32:0] cfg_bit_period_ticks;
    reg  [9:0]  cfg_guard_ticks;

    wire        schedule_active;
    wire [63:0] sync_tick_counter;
    wire [63:0] frame_ticks;
    wire [63:0] slot_ticks;
    wire [63:0] guard_half_ticks;
    wire [7:0]  slot_time_match;
    wire [63:0] slot_target_tick0;
    wire [63:0] slot_target_tick1;
    wire [63:0] slot_target_tick2;
    wire [63:0] slot_target_tick3;
    wire [63:0] slot_target_tick4;
    wire [63:0] slot_target_tick5;
    wire [63:0] slot_target_tick6;
    wire [63:0] slot_target_tick7;

    integer error_count;

    slave_timing_scheduler dut (
        .clk(clk),
        .resetn(resetn),
        .cfg_enable(cfg_enable),
        .sync_pulse(sync_pulse),
        .cycle_done(cycle_done),
        .cfg_bit_period_ticks(cfg_bit_period_ticks),
        .cfg_guard_ticks(cfg_guard_ticks),
        .schedule_active(schedule_active),
        .sync_tick_counter(sync_tick_counter),
        .frame_ticks(frame_ticks),
        .slot_ticks(slot_ticks),
        .guard_half_ticks(guard_half_ticks),
        .slot_time_match(slot_time_match),
        .slot_target_tick0(slot_target_tick0),
        .slot_target_tick1(slot_target_tick1),
        .slot_target_tick2(slot_target_tick2),
        .slot_target_tick3(slot_target_tick3),
        .slot_target_tick4(slot_target_tick4),
        .slot_target_tick5(slot_target_tick5),
        .slot_target_tick6(slot_target_tick6),
        .slot_target_tick7(slot_target_tick7)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    function [63:0] expected_frame_ticks;
        input [32:0] bit_period_ticks;
        begin
            expected_frame_ticks = {31'd0, bit_period_ticks} * 64'd50;
        end
    endfunction

    function [63:0] expected_slot_ticks;
        input [32:0] bit_period_ticks;
        input [9:0]  guard_ticks;
        begin
            expected_slot_ticks = expected_frame_ticks(bit_period_ticks) +
                                  {54'd0, guard_ticks};
        end
    endfunction

    function [63:0] expected_guard_half_ticks;
        input [9:0] guard_ticks;
        begin
            expected_guard_half_ticks = {55'd0, guard_ticks[9:1]};
        end
    endfunction

    function [63:0] expected_target_tick;
        input [32:0] bit_period_ticks;
        input [9:0]  guard_ticks;
        input integer slot_index;
        begin
            expected_target_tick =
                expected_frame_ticks(bit_period_ticks) +
                ({32'd0, slot_index[31:0]} *
                 expected_slot_ticks(bit_period_ticks, guard_ticks)) +
                expected_guard_half_ticks(guard_ticks);
        end
    endfunction

    task check_equal64;
        input [1023:0] label_text;
        input [63:0]   actual_value;
        input [63:0]   expected_value;
        begin
            if (actual_value !== expected_value) begin
                $display("ERROR: %0s actual=%0d expected=%0d time=%0t",
                         label_text, actual_value, expected_value, $time);
                error_count = error_count + 1;
            end
        end
    endtask

    task check_equal8;
        input [1023:0] label_text;
        input [7:0]    actual_value;
        input [7:0]    expected_value;
        begin
            if (actual_value !== expected_value) begin
                $display("ERROR: %0s actual=0x%0h expected=0x%0h time=%0t",
                         label_text, actual_value, expected_value, $time);
                error_count = error_count + 1;
            end
        end
    endtask

    task pulse_sync;
        begin
            @(negedge clk);
            sync_pulse = 1'b1;
            @(posedge clk);
            #1;
            sync_pulse = 1'b0;
        end
    endtask

    task wait_cycles;
        input integer cycle_count;
        integer wait_index;
        begin
            for (wait_index = 0; wait_index < cycle_count; wait_index = wait_index + 1) begin
                @(posedge clk);
                #1;
            end
        end
    endtask

    task check_snapshot;
        input [32:0] bit_period_ticks;
        input [9:0]  guard_ticks;
        begin
            check_equal64("frame_ticks", frame_ticks,
                          expected_frame_ticks(bit_period_ticks));
            check_equal64("slot_ticks", slot_ticks,
                          expected_slot_ticks(bit_period_ticks, guard_ticks));
            check_equal64("guard_half_ticks", guard_half_ticks,
                          expected_guard_half_ticks(guard_ticks));
            check_equal64("slot_target_tick0", slot_target_tick0,
                          expected_target_tick(bit_period_ticks, guard_ticks, 0));
            check_equal64("slot_target_tick1", slot_target_tick1,
                          expected_target_tick(bit_period_ticks, guard_ticks, 1));
            check_equal64("slot_target_tick2", slot_target_tick2,
                          expected_target_tick(bit_period_ticks, guard_ticks, 2));
            check_equal64("slot_target_tick3", slot_target_tick3,
                          expected_target_tick(bit_period_ticks, guard_ticks, 3));
            check_equal64("slot_target_tick4", slot_target_tick4,
                          expected_target_tick(bit_period_ticks, guard_ticks, 4));
            check_equal64("slot_target_tick5", slot_target_tick5,
                          expected_target_tick(bit_period_ticks, guard_ticks, 5));
            check_equal64("slot_target_tick6", slot_target_tick6,
                          expected_target_tick(bit_period_ticks, guard_ticks, 6));
            check_equal64("slot_target_tick7", slot_target_tick7,
                          expected_target_tick(bit_period_ticks, guard_ticks, 7));
        end
    endtask

    task run_timing_case;
        input [32:0] bit_period_ticks;
        input [9:0]  guard_ticks;
        input [1023:0] case_name;
        integer slot_index;
        reg [63:0] expected_tick;
        begin
            $display("CASE: %0s", case_name);
            cfg_bit_period_ticks = bit_period_ticks;
            cfg_guard_ticks = guard_ticks;
            cfg_enable = 1'b1;

            pulse_sync();

            if (schedule_active !== 1'b1) begin
                $display("ERROR: schedule_active not set time=%0t", $time);
                error_count = error_count + 1;
            end
            check_equal64("sync_tick_counter after sync", sync_tick_counter, 64'd0);
            check_snapshot(bit_period_ticks, guard_ticks);

            for (slot_index = 0; slot_index < 8; slot_index = slot_index + 1) begin
                expected_tick = expected_target_tick(bit_period_ticks, guard_ticks, slot_index);
                while (sync_tick_counter < expected_tick) begin
                    @(posedge clk);
                    #1;
                    if (slot_time_match != 8'd0 &&
                        sync_tick_counter != expected_tick) begin
                        $display("ERROR: early slot_time_match=0x%0h counter=%0d slot=%0d time=%0t",
                                 slot_time_match, sync_tick_counter, slot_index, $time);
                        error_count = error_count + 1;
                    end
                end

                check_equal64("match counter", sync_tick_counter, expected_tick);
                check_equal8("slot_time_match", slot_time_match, (8'h01 << slot_index));

                @(posedge clk);
                #1;
                check_equal8("slot_time_match pulse width", slot_time_match, 8'd0);
            end
        end
    endtask

    task run_snapshot_hold_case;
        begin
            $display("CASE: snapshot holds until next sync");
            cfg_enable = 1'b1;
            cfg_bit_period_ticks = 33'd2;
            cfg_guard_ticks = 10'd2;
            pulse_sync();
            check_snapshot(33'd2, 10'd2);

            cfg_bit_period_ticks = 33'd5;
            cfg_guard_ticks = 10'd9;
            wait_cycles(7);
            check_snapshot(33'd2, 10'd2);

            pulse_sync();
            check_equal64("counter restart", sync_tick_counter, 64'd0);
            check_snapshot(33'd5, 10'd9);
        end
    endtask

    task run_cycle_done_case;
        begin
            $display("CASE: cycle done clears schedule");
            cfg_enable = 1'b1;
            cfg_bit_period_ticks = 33'd2;
            cfg_guard_ticks = 10'd4;
            pulse_sync();
            wait_cycles(5);

            @(negedge clk);
            cycle_done = 1'b1;
            @(posedge clk);
            #1;
            cycle_done = 1'b0;

            if (schedule_active !== 1'b0) begin
                $display("ERROR: schedule_active did not clear on cycle_done time=%0t", $time);
                error_count = error_count + 1;
            end
            check_equal64("cycle_done counter clear", sync_tick_counter, 64'd0);
            check_equal8("cycle_done match clear", slot_time_match, 8'd0);
        end
    endtask

    task run_disable_case;
        begin
            $display("CASE: disable behavior");
            cfg_enable = 1'b1;
            cfg_bit_period_ticks = 33'd1;
            cfg_guard_ticks = 10'd0;
            pulse_sync();
            wait_cycles(10);

            @(negedge clk);
            cfg_enable = 1'b0;
            wait_cycles(2);
            check_equal64("disabled counter clear", sync_tick_counter, 64'd0);
            if (schedule_active !== 1'b0) begin
                $display("ERROR: schedule_active stayed high while disabled time=%0t", $time);
                error_count = error_count + 1;
            end
            check_equal8("disabled match clear", slot_time_match, 8'd0);

            pulse_sync();
            wait_cycles(2);
            if (schedule_active !== 1'b0) begin
                $display("ERROR: disabled sync started scheduler time=%0t", $time);
                error_count = error_count + 1;
            end
        end
    endtask

    initial begin
        error_count = 0;
        resetn = 1'b0;
        cfg_enable = 1'b0;
        sync_pulse = 1'b0;
        cycle_done = 1'b0;
        cfg_bit_period_ticks = 33'd1;
        cfg_guard_ticks = 10'd0;

        wait_cycles(3);
        @(negedge clk);
        resetn = 1'b1;
        wait_cycles(2);

        check_equal64("reset frame_ticks", frame_ticks, 64'd0);
        check_equal64("reset slot_ticks", slot_ticks, 64'd0);
        check_equal64("reset sync_tick_counter", sync_tick_counter, 64'd0);
        check_equal8("reset slot_time_match", slot_time_match, 8'd0);

        run_timing_case(33'd1, 10'd0, "bit_period=1 guard=0");
        run_timing_case(33'd2, 10'd1, "bit_period=2 guard=1 odd");
        run_timing_case(33'd3, 10'd2, "bit_period=3 guard=2 even");
        run_timing_case(33'd4, 10'd3, "bit_period=4 guard=3 odd");
        run_timing_case(33'd7, 10'd10, "bit_period=7 guard=10 representative");
        run_snapshot_hold_case();
        run_cycle_done_case();
        run_disable_case();

        if (error_count == 0) begin
            $display("PASS: tb_slave_timing_scheduler");
        end else begin
            $display("FAIL: tb_slave_timing_scheduler errors=%0d", error_count);
        end
        $finish;
    end

endmodule
