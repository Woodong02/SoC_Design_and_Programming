`timescale 1ns / 1ps

module tb_slave21_tx;

    reg         i_CLK;
    reg         i_RESETN;
    reg  [2:0]  i_NODE_ID;
    reg  [31:0] i_PAYLOAD;
    reg  [15:0] i_BIT_PERIOD;
    reg         i_TX_TRIGGER;
    reg         i_TX_ENABLE;
    wire        o_SERIAL_OUT;
    wire        o_TX_ACTIVE;
    wire        o_TX_DONE;

    integer fail_count;
    integer bit_index;
    integer hold_index;

    reg [49:0] expected_frame;

    slave21_tx dut (
        .i_CLK(i_CLK),
        .i_RESETN(i_RESETN),
        .i_NODE_ID(i_NODE_ID),
        .i_PAYLOAD(i_PAYLOAD),
        .i_BIT_PERIOD(i_BIT_PERIOD),
        .i_TX_TRIGGER(i_TX_TRIGGER),
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

    task check_bit;
        input [255:0] label_text;
        input expected_value;
        input actual_value;
        begin
            if (actual_value !== expected_value) begin
                fail_count = fail_count + 1;
                $display("[FAIL] %0s expected=%0b actual=%0b time=%0t", label_text, expected_value, actual_value, $time);
            end
        end
    endtask

    task wait_clock;
        begin
            @(posedge i_CLK);
            #1;
        end
    endtask

    task apply_reset;
        begin
            $display("PHASE: reset and idle");
            i_RESETN = 1'b0;
            i_NODE_ID = 3'd0;
            i_PAYLOAD = 32'd0;
            i_BIT_PERIOD = 16'd4;
            i_TX_TRIGGER = 1'b0;
            i_TX_ENABLE = 1'b0;
            repeat (3) wait_clock;
            check_bit("reset serial low", 1'b0, o_SERIAL_OUT);
            check_bit("reset active low", 1'b0, o_TX_ACTIVE);
            check_bit("reset done low", 1'b0, o_TX_DONE);
            @(negedge i_CLK);
            i_RESETN = 1'b1;
            wait_clock;
            check_bit("idle serial low after reset", 1'b0, o_SERIAL_OUT);
            check_bit("idle active low after reset", 1'b0, o_TX_ACTIVE);
            check_bit("idle done low after reset", 1'b0, o_TX_DONE);
        end
    endtask

    task check_idle_cycles;
        input integer cycle_count;
        input [255:0] label_text;
        integer idle_index;
        begin
            $display("PHASE: %0s", label_text);
            for (idle_index = 0; idle_index < cycle_count; idle_index = idle_index + 1) begin
                wait_clock;
                check_bit("idle serial low", 1'b0, o_SERIAL_OUT);
                check_bit("idle active low", 1'b0, o_TX_ACTIVE);
                check_bit("idle done low", 1'b0, o_TX_DONE);
            end
        end
    endtask

    task start_frame;
        input [2:0] node_id_value;
        input [31:0] payload_value;
        input [15:0] period_value;
        input enable_value;
        begin
            @(negedge i_CLK);
            i_NODE_ID = node_id_value;
            i_PAYLOAD = payload_value;
            i_BIT_PERIOD = period_value;
            i_TX_ENABLE = enable_value;
            i_TX_TRIGGER = 1'b1;
            @(posedge i_CLK);
            #1;
            i_TX_TRIGGER = 1'b0;
        end
    endtask

    task check_done_and_idle;
        begin
            check_bit("done pulse asserted", 1'b1, o_TX_DONE);
            check_bit("active low during done", 1'b0, o_TX_ACTIVE);
            check_bit("serial idle during done", 1'b0, o_SERIAL_OUT);
            wait_clock;
            check_bit("done pulse one cycle", 1'b0, o_TX_DONE);
            check_bit("active remains idle", 1'b0, o_TX_ACTIVE);
            check_bit("serial remains idle", 1'b0, o_SERIAL_OUT);
        end
    endtask

    task check_frame_with_period;
        input [49:0] frame_value;
        input [15:0] expected_period;
        input change_period_mid_frame;
        input retrigger_mid_frame;
        integer period_cycle;
        begin
            for (bit_index = 0; bit_index < 50; bit_index = bit_index + 1) begin
                for (period_cycle = 0; period_cycle < expected_period; period_cycle = period_cycle + 1) begin
                    check_bit("frame serial bit", frame_value[49 - bit_index], o_SERIAL_OUT);
                    check_bit("frame active high", 1'b1, o_TX_ACTIVE);
                    check_bit("done low during frame", 1'b0, o_TX_DONE);

                    if ((change_period_mid_frame == 1'b1) && (bit_index == 3) && (period_cycle == 1)) begin
                        @(negedge i_CLK);
                        i_BIT_PERIOD = 16'd1;
                    end

                    if ((retrigger_mid_frame == 1'b1) && (bit_index == 5) && (period_cycle == 1)) begin
                        @(negedge i_CLK);
                        i_NODE_ID = 3'd7;
                        i_PAYLOAD = 32'hFFFFFFFF;
                        i_BIT_PERIOD = 16'd1;
                        i_TX_TRIGGER = 1'b1;
                        @(posedge i_CLK);
                        #1;
                        i_TX_TRIGGER = 1'b0;
                    end else begin
                        wait_clock;
                    end
                end
            end
            check_done_and_idle;
        end
    endtask

    task check_first_bit_full_width;
        input [49:0] frame_value;
        input [15:0] expected_period;
        begin
            $display("PHASE: first bit immediate and full-width");
            check_bit("first bit immediate", frame_value[49], o_SERIAL_OUT);
            check_bit("active immediate", 1'b1, o_TX_ACTIVE);
            for (hold_index = 0; hold_index < expected_period; hold_index = hold_index + 1) begin
                check_bit("first bit held full width", frame_value[49], o_SERIAL_OUT);
                if (hold_index != (expected_period - 1)) begin
                    wait_clock;
                end
            end
            wait_clock;
            check_bit("second bit after full width", frame_value[48], o_SERIAL_OUT);
        end
    endtask

    initial begin
        fail_count = 0;
        i_RESETN = 1'b0;
        i_NODE_ID = 3'd0;
        i_PAYLOAD = 32'd0;
        i_BIT_PERIOD = 16'd4;
        i_TX_TRIGGER = 1'b0;
        i_TX_ENABLE = 1'b0;

        $display("TB_START: tb_slave21_tx");

        apply_reset;
        check_idle_cycles(4, "idle without trigger");

        $display("PHASE: disabled trigger ignored");
        start_frame(3'd2, 32'h12345678, 16'd4, 1'b0);
        check_idle_cycles(6, "post disabled trigger idle");

        expected_frame = {8'hAA, reference_codeword({3'd5, 32'hA5C33C5A})};
        $display("PHASE: normal frame expected=%050b", expected_frame);
        start_frame(3'd5, 32'hA5C33C5A, 16'd4, 1'b1);
        check_frame_with_period(expected_frame, 16'd4, 1'b0, 1'b0);

        expected_frame = {8'hAA, reference_codeword({3'd1, 32'h0F0F55AA})};
        start_frame(3'd1, 32'h0F0F55AA, 16'd5, 1'b1);
        check_first_bit_full_width(expected_frame, 16'd5);
        for (bit_index = 1; bit_index < 50; bit_index = bit_index + 1) begin
            for (hold_index = 0; hold_index < 5; hold_index = hold_index + 1) begin
                check_bit("remaining frame after first width test", expected_frame[49 - bit_index], o_SERIAL_OUT);
                wait_clock;
            end
        end
        check_done_and_idle;

        expected_frame = {8'hAA, reference_codeword({3'd3, 32'h13572468})};
        $display("PHASE: active retrigger ignored");
        start_frame(3'd3, 32'h13572468, 16'd3, 1'b1);
        check_frame_with_period(expected_frame, 16'd3, 1'b0, 1'b1);

        expected_frame = {8'hAA, reference_codeword({3'd6, 32'h24681357})};
        $display("PHASE: mid-frame period snapshot");
        start_frame(3'd6, 32'h24681357, 16'd4, 1'b1);
        check_frame_with_period(expected_frame, 16'd4, 1'b1, 1'b0);

        check_idle_cycles(4, "final idle");

        if (fail_count == 0) begin
            $display("PASS: tb_slave21_tx");
        end else begin
            $display("FAIL: tb_slave21_tx fail_count=%0d", fail_count);
        end

        $finish;
    end

endmodule
