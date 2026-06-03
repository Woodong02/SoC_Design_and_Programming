`timescale 1ns / 1ps

module tb_slave2_tx;

    reg         i_CLK;
    reg         i_RESETN;
    reg  [2:0]  i_NODE_ID;
    reg  [31:0] i_PAYLOAD;
    reg         i_TX_TRIGGER;
    reg         i_TX_BIT_TICK;
    reg         i_TX_ENABLE;
    wire        o_SERIAL_OUT;
    wire        o_TX_ACTIVE;
    wire        o_TX_DONE;

    integer error_count;
    integer bit_index;
    integer hold_index;

    reg [49:0] expected_frame;

    slave2_tx u_dut (
        .i_CLK(i_CLK),
        .i_RESETN(i_RESETN),
        .i_NODE_ID(i_NODE_ID),
        .i_PAYLOAD(i_PAYLOAD),
        .i_TX_TRIGGER(i_TX_TRIGGER),
        .i_TX_BIT_TICK(i_TX_BIT_TICK),
        .i_TX_ENABLE(i_TX_ENABLE),
        .o_SERIAL_OUT(o_SERIAL_OUT),
        .o_TX_ACTIVE(o_TX_ACTIVE),
        .o_TX_DONE(o_TX_DONE)
    );

    initial begin
        i_CLK = 1'b0;
        forever #5 i_CLK = ~i_CLK;
    end

    function [41:0] reference_codeword;
        input [34:0] data;
        reg parity_0;
        reg parity_1;
        reg parity_2;
        reg parity_3;
        reg parity_4;
        reg parity_5;
        reg parity_overall;
        begin
            parity_0 = data[0] ^ data[2] ^ data[4] ^ data[6] ^ data[8] ^ data[10] ^ data[12] ^ data[14]
                     ^ data[16] ^ data[18] ^ data[20] ^ data[22] ^ data[24] ^ data[26] ^ data[28] ^ data[30]
                     ^ data[32] ^ data[34];

            parity_1 = data[1] ^ data[2] ^ data[5] ^ data[6] ^ data[9] ^ data[10] ^ data[13] ^ data[14]
                     ^ data[17] ^ data[18] ^ data[21] ^ data[22] ^ data[25] ^ data[26] ^ data[29] ^ data[30]
                     ^ data[33] ^ data[34];

            parity_2 = data[3] ^ data[4] ^ data[5] ^ data[6] ^ data[11] ^ data[12] ^ data[13] ^ data[14]
                     ^ data[19] ^ data[20] ^ data[21] ^ data[22] ^ data[27] ^ data[28] ^ data[29] ^ data[30];

            parity_3 = data[7] ^ data[8] ^ data[9] ^ data[10] ^ data[11] ^ data[12] ^ data[13] ^ data[14]
                     ^ data[23] ^ data[24] ^ data[25] ^ data[26] ^ data[27] ^ data[28] ^ data[29] ^ data[30];

            parity_4 = data[15] ^ data[16] ^ data[17] ^ data[18] ^ data[19] ^ data[20] ^ data[21] ^ data[22]
                     ^ data[23] ^ data[24] ^ data[25] ^ data[26] ^ data[27] ^ data[28] ^ data[29] ^ data[30];

            parity_5 = data[31] ^ data[32] ^ data[33] ^ data[34];
            parity_overall = ^{data, parity_5, parity_4, parity_3, parity_2, parity_1, parity_0};
            reference_codeword = {data, parity_5, parity_4, parity_3, parity_2, parity_1, parity_0, parity_overall};
        end
    endfunction

    task check_signal;
        input expected_value;
        input actual_value;
        input [511:0] message;
        begin
            if (actual_value !== expected_value) begin
                $display("FAIL: %0s expected=%0b actual=%0b time=%0t", message, expected_value, actual_value, $time);
                error_count = error_count + 1;
            end
        end
    endtask

    task wait_clock;
        begin
            @(posedge i_CLK);
            #1;
        end
    endtask

    task pulse_trigger;
        input [2:0] node_id_value;
        input [31:0] payload_value;
        input enable_value;
        begin
            @(negedge i_CLK);
            i_NODE_ID = node_id_value;
            i_PAYLOAD = payload_value;
            i_TX_ENABLE = enable_value;
            i_TX_TRIGGER = 1'b1;
            @(posedge i_CLK);
            #1;
            i_TX_TRIGGER = 1'b0;
        end
    endtask

    task pulse_trigger_with_tick;
        input [2:0] node_id_value;
        input [31:0] payload_value;
        begin
            @(negedge i_CLK);
            i_NODE_ID = node_id_value;
            i_PAYLOAD = payload_value;
            i_TX_ENABLE = 1'b1;
            i_TX_TRIGGER = 1'b1;
            i_TX_BIT_TICK = 1'b1;
            @(posedge i_CLK);
            #1;
            i_TX_TRIGGER = 1'b0;
            i_TX_BIT_TICK = 1'b0;
        end
    endtask

    task pulse_tick;
        begin
            @(negedge i_CLK);
            i_TX_BIT_TICK = 1'b1;
            @(posedge i_CLK);
            #1;
            i_TX_BIT_TICK = 1'b0;
        end
    endtask

    task apply_reset;
        begin
            $display("PHASE: apply reset");
            i_RESETN = 1'b0;
            i_NODE_ID = 3'd0;
            i_PAYLOAD = 32'd0;
            i_TX_TRIGGER = 1'b0;
            i_TX_BIT_TICK = 1'b0;
            i_TX_ENABLE = 1'b0;
            #2;
            check_signal(1'b0, o_SERIAL_OUT, "reset serial idle");
            check_signal(1'b0, o_TX_ACTIVE, "reset active low");
            check_signal(1'b0, o_TX_DONE, "reset done low");
            repeat (3) wait_clock;
            i_RESETN = 1'b1;
            wait_clock;
        end
    endtask

    task check_idle_cycles;
        input integer cycles;
        input [255:0] label_text;
        integer idle_idx;
        begin
            $display("PHASE: %0s", label_text);
            for (idle_idx = 0; idle_idx < cycles; idle_idx = idle_idx + 1) begin
                wait_clock;
                check_signal(1'b0, o_SERIAL_OUT, "idle serial low");
                check_signal(1'b0, o_TX_ACTIVE, "idle active low");
                check_signal(1'b0, o_TX_DONE, "idle done low");
            end
        end
    endtask

    task check_hold_without_tick;
        input [49:0] frame_value;
        begin
            $display("PHASE: hold without tick");
            for (hold_index = 0; hold_index < 5; hold_index = hold_index + 1) begin
                check_signal(frame_value[49], o_SERIAL_OUT, "first bit held without tick");
                check_signal(1'b1, o_TX_ACTIVE, "active held without tick");
                check_signal(1'b0, o_TX_DONE, "done low without tick");
                wait_clock;
            end
        end
    endtask

    task check_done_pulse_and_idle;
        begin
            check_signal(1'b1, o_TX_DONE, "done pulse asserted");
            check_signal(1'b0, o_TX_ACTIVE, "active low when done pulse asserted");
            check_signal(1'b0, o_SERIAL_OUT, "serial idle during done pulse");
            wait_clock;
            check_signal(1'b0, o_TX_DONE, "done pulse deasserted after one cycle");
            check_signal(1'b0, o_TX_ACTIVE, "active remains low after done");
            check_signal(1'b0, o_SERIAL_OUT, "serial idle after done");
        end
    endtask

    task check_tick_driven_frame;
        input [49:0] frame_value;
        begin
            $display("PHASE: tick-driven 50-bit frame check");
            check_signal(1'b1, o_TX_ACTIVE, "active asserted at frame start");
            check_signal(frame_value[49], o_SERIAL_OUT, "first bit at frame start");

            for (bit_index = 0; bit_index < 50; bit_index = bit_index + 1) begin
                check_signal(frame_value[49 - bit_index], o_SERIAL_OUT, "frame bit before tick");
                check_signal(1'b1, o_TX_ACTIVE, "active before tick");
                check_signal(1'b0, o_TX_DONE, "done low before final tick");
                pulse_tick;
            end

            check_done_pulse_and_idle;
        end
    endtask

    task check_frame_with_retrigger;
        input [49:0] frame_value;
        input [2:0]  retrigger_node_id;
        input [31:0] retrigger_payload;
        begin
            $display("PHASE: active retrigger ignored check");
            check_signal(1'b1, o_TX_ACTIVE, "active asserted before retrigger test");

            for (bit_index = 0; bit_index < 50; bit_index = bit_index + 1) begin
                check_signal(frame_value[49 - bit_index], o_SERIAL_OUT, "frame preserved while retriggering");

                if (bit_index == 5) begin
                    @(negedge i_CLK);
                    i_NODE_ID = retrigger_node_id;
                    i_PAYLOAD = retrigger_payload;
                    i_TX_TRIGGER = 1'b1;
                    i_TX_BIT_TICK = 1'b1;
                    @(posedge i_CLK);
                    #1;
                    i_TX_TRIGGER = 1'b0;
                    i_TX_BIT_TICK = 1'b0;
                end else begin
                    pulse_tick;
                end
            end

            check_done_pulse_and_idle;
        end
    endtask

    task check_enable_abort;
        begin
            $display("PHASE: enable low aborts active frame");
            pulse_trigger(3'd2, 32'h13572468, 1'b1);
            check_signal(1'b1, o_TX_ACTIVE, "active before enable abort");
            repeat (4) pulse_tick;
            @(negedge i_CLK);
            i_TX_ENABLE = 1'b0;
            @(posedge i_CLK);
            #1;
            check_signal(1'b0, o_SERIAL_OUT, "serial low after enable abort");
            check_signal(1'b0, o_TX_ACTIVE, "active low after enable abort");
            check_signal(1'b0, o_TX_DONE, "done low after enable abort");
            check_idle_cycles(3, "idle after enable abort");
            i_TX_ENABLE = 1'b1;
        end
    endtask

    task check_reset_interrupt;
        begin
            $display("PHASE: reset interrupts active frame");
            pulse_trigger(3'd4, 32'h24681357, 1'b1);
            check_signal(1'b1, o_TX_ACTIVE, "active before reset interrupt");
            repeat (5) pulse_tick;
            i_RESETN = 1'b0;
            #2;
            check_signal(1'b0, o_SERIAL_OUT, "serial low after reset interrupt");
            check_signal(1'b0, o_TX_ACTIVE, "active low after reset interrupt");
            check_signal(1'b0, o_TX_DONE, "done low after reset interrupt");
            repeat (2) wait_clock;
            i_RESETN = 1'b1;
            wait_clock;
            check_signal(1'b0, o_SERIAL_OUT, "serial idle after reset release");
            check_signal(1'b0, o_TX_ACTIVE, "active low after reset release");
        end
    endtask

    initial begin
        error_count = 0;
        i_RESETN = 1'b0;
        i_NODE_ID = 3'd0;
        i_PAYLOAD = 32'd0;
        i_TX_TRIGGER = 1'b0;
        i_TX_BIT_TICK = 1'b0;
        i_TX_ENABLE = 1'b0;

        $display("TB_START: tb_slave2_tx");

        apply_reset;

        check_idle_cycles(5, "idle without trigger");

        $display("PHASE: disabled trigger ignored");
        pulse_trigger(3'd3, 32'h12345678, 1'b0);
        check_idle_cycles(8, "post disabled trigger idle");

        expected_frame = {8'hAA, reference_codeword({3'd6, 32'hA5C33C5A})};
        $display("PHASE: start with simultaneous trigger and tick expected=%050b", expected_frame);
        pulse_trigger_with_tick(3'd6, 32'hA5C33C5A);
        check_hold_without_tick(expected_frame);
        check_tick_driven_frame(expected_frame);

        check_enable_abort;
        check_reset_interrupt;

        expected_frame = {8'hAA, reference_codeword({3'd1, 32'h0F0F55AA})};
        $display("PHASE: start frame for retrigger expected=%050b", expected_frame);
        pulse_trigger(3'd1, 32'h0F0F55AA, 1'b1);
        check_frame_with_retrigger(expected_frame, 3'd7, 32'hFFFFFFFF);

        check_idle_cycles(4, "final idle");

        if (error_count == 0) begin
            $display("PASS: tb_slave2_tx completed with no errors");
        end else begin
            $display("FAIL: tb_slave2_tx completed with %0d errors", error_count);
        end

        $finish;
    end

endmodule
