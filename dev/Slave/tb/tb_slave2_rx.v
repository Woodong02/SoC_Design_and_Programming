`timescale 1ns / 1ps

module tb_slave2_rx;

    reg         i_CLK;
    reg         i_RESETN;
    reg         i_SERIAL_IN;
    reg         i_SAMPLE_TICK;
    reg         i_SAMPLE_EARLY_TICK;
    reg         i_SAMPLE_LATE_TICK;
    wire [41:0] o_CODEWORD;
    wire        o_CODEWORD_VALID;
    wire        o_SYNC_PULSE;
    wire        o_RX_ACTIVE;
    wire        o_PREAMBLE_ERR;

    integer error_count;
    integer sync_count;
    integer valid_count;
    integer err_count;
    integer bit_index;

    reg [49:0] frame_bits;
    reg [41:0] expected_codeword;

    slave2_rx dut (
        .i_CLK(i_CLK),
        .i_RESETN(i_RESETN),
        .i_SERIAL_IN(i_SERIAL_IN),
        .i_SAMPLE_TICK(i_SAMPLE_TICK),
        .i_SAMPLE_EARLY_TICK(i_SAMPLE_EARLY_TICK),
        .i_SAMPLE_LATE_TICK(i_SAMPLE_LATE_TICK),
        .o_CODEWORD(o_CODEWORD),
        .o_CODEWORD_VALID(o_CODEWORD_VALID),
        .o_SYNC_PULSE(o_SYNC_PULSE),
        .o_RX_ACTIVE(o_RX_ACTIVE),
        .o_PREAMBLE_ERR(o_PREAMBLE_ERR)
    );

    initial begin
        i_CLK = 1'b0;
        forever #5 i_CLK = ~i_CLK;
    end

    always @(posedge i_CLK) begin
        #1;
        if (o_SYNC_PULSE)
            sync_count = sync_count + 1;
        if (o_CODEWORD_VALID)
            valid_count = valid_count + 1;
        if (o_PREAMBLE_ERR)
            err_count = err_count + 1;
    end

    task clear_ticks;
        begin
            i_SAMPLE_EARLY_TICK = 1'b0;
            i_SAMPLE_TICK = 1'b0;
            i_SAMPLE_LATE_TICK = 1'b0;
        end
    endtask

    task idle_cycle;
        begin
            @(negedge i_CLK);
            clear_ticks;
            @(posedge i_CLK);
            #1;
        end
    endtask

    task pulse_early;
        input sample_value;
        begin
            @(negedge i_CLK);
            i_SERIAL_IN = sample_value;
            i_SAMPLE_EARLY_TICK = 1'b1;
            @(negedge i_CLK);
            i_SAMPLE_EARLY_TICK = 1'b0;
        end
    endtask

    task pulse_center;
        input sample_value;
        begin
            @(negedge i_CLK);
            i_SERIAL_IN = sample_value;
            i_SAMPLE_TICK = 1'b1;
            @(negedge i_CLK);
            i_SAMPLE_TICK = 1'b0;
        end
    endtask

    task pulse_late;
        input sample_value;
        begin
            @(negedge i_CLK);
            i_SERIAL_IN = sample_value;
            i_SAMPLE_LATE_TICK = 1'b1;
            @(posedge i_CLK);
            #2;
            i_SAMPLE_LATE_TICK = 1'b0;
        end
    endtask

    task send_bit_majority;
        input bit_value;
        begin
            pulse_early(bit_value);
            pulse_center(bit_value);
            pulse_late(bit_value);
        end
    endtask

    task send_bit_center_glitch;
        input bit_value;
        begin
            pulse_early(bit_value);
            pulse_center(~bit_value);
            pulse_late(bit_value);
        end
    endtask

    task send_frame_nominal;
        input [41:0] codeword_value;
        begin
            frame_bits = {8'hAA, codeword_value};
            for (bit_index = 49; bit_index >= 0; bit_index = bit_index - 1)
                send_bit_majority(frame_bits[bit_index]);
        end
    endtask

    task send_frame_with_center_glitch;
        input [41:0] codeword_value;
        begin
            frame_bits = {8'hAA, codeword_value};
            for (bit_index = 49; bit_index >= 0; bit_index = bit_index - 1) begin
                if (bit_index == 35)
                    send_bit_center_glitch(frame_bits[bit_index]);
                else
                    send_bit_majority(frame_bits[bit_index]);
            end
        end
    endtask

    task send_preamble;
        input [7:0] preamble_value;
        begin
            for (bit_index = 7; bit_index >= 0; bit_index = bit_index - 1)
                send_bit_majority(preamble_value[bit_index]);
        end
    endtask

    task check_equal_1;
        input actual_value;
        input expected_value;
        input [255:0] message;
        begin
            if (actual_value !== expected_value) begin
                $display("FAIL: %0s actual=%0b expected=%0b time=%0t", message, actual_value, expected_value, $time);
                error_count = error_count + 1;
            end
        end
    endtask

    task check_equal_42;
        input [41:0] actual_value;
        input [41:0] expected_value;
        input [255:0] message;
        begin
            if (actual_value !== expected_value) begin
                $display("FAIL: %0s actual=0x%011h expected=0x%011h time=%0t", message, actual_value, expected_value, $time);
                error_count = error_count + 1;
            end
        end
    endtask

    task check_equal_int;
        input integer actual_value;
        input integer expected_value;
        input [255:0] message;
        begin
            if (actual_value != expected_value) begin
                $display("FAIL: %0s actual=%0d expected=%0d time=%0t", message, actual_value, expected_value, $time);
                error_count = error_count + 1;
            end
        end
    endtask

    task apply_reset;
        begin
            i_RESETN = 1'b0;
            i_SERIAL_IN = 1'b0;
            clear_ticks;
            repeat (4) @(posedge i_CLK);
            #1;
            check_equal_1(o_CODEWORD_VALID, 1'b0, "reset clears codeword valid");
            check_equal_1(o_SYNC_PULSE, 1'b0, "reset clears sync pulse");
            check_equal_1(o_RX_ACTIVE, 1'b0, "reset clears active");
            check_equal_1(o_PREAMBLE_ERR, 1'b0, "reset clears preamble error");
            i_RESETN = 1'b1;
            repeat (2) @(posedge i_CLK);
            #1;
        end
    endtask

    initial begin
        error_count = 0;
        sync_count = 0;
        valid_count = 0;
        err_count = 0;
        i_RESETN = 1'b0;
        i_SERIAL_IN = 1'b0;
        clear_ticks;

        $display("tb_slave2_rx: start");

        apply_reset;
        check_equal_1(o_RX_ACTIVE, 1'b0, "idle after reset");

        $display("tb_slave2_rx: idle noise without ticks");
        i_SERIAL_IN = 1'b1;
        repeat (6) idle_cycle;
        check_equal_int(sync_count, 0, "idle noise does not create sync");
        check_equal_int(valid_count, 0, "idle noise does not create valid");
        check_equal_int(err_count, 0, "idle noise does not create error");
        i_SERIAL_IN = 1'b0;
        idle_cycle;

        $display("tb_slave2_rx: nominal frame");
        expected_codeword = 42'h2A5_1234_5678;
        send_frame_nominal(expected_codeword);
        check_equal_1(o_CODEWORD_VALID, 1'b1, "nominal valid pulse asserted");
        check_equal_42(o_CODEWORD, expected_codeword, "nominal codeword");
        check_equal_int(sync_count, 1, "nominal sync count");
        check_equal_int(valid_count, 1, "nominal valid count");
        check_equal_int(err_count, 0, "nominal error count");
        idle_cycle;
        check_equal_1(o_CODEWORD_VALID, 1'b0, "valid pulse is one cycle");
        check_equal_1(o_SYNC_PULSE, 1'b0, "sync pulse returned low");

        $display("tb_slave2_rx: preamble error");
        send_preamble(8'hA8);
        check_equal_1(o_PREAMBLE_ERR, 1'b1, "wrong preamble error pulse");
        check_equal_int(sync_count, 1, "wrong preamble blocks sync");
        check_equal_int(valid_count, 1, "wrong preamble blocks valid");
        check_equal_int(err_count, 1, "wrong preamble error count");
        idle_cycle;
        check_equal_1(o_PREAMBLE_ERR, 1'b0, "error pulse is one cycle");

        $display("tb_slave2_rx: majority sampling with center glitch");
        expected_codeword = 42'h155_0F0F_00AA;
        send_frame_with_center_glitch(expected_codeword);
        check_equal_1(o_CODEWORD_VALID, 1'b1, "majority valid pulse asserted");
        check_equal_42(o_CODEWORD, expected_codeword, "majority codeword");
        check_equal_int(sync_count, 2, "majority sync count");
        check_equal_int(valid_count, 2, "majority valid count");
        check_equal_int(err_count, 1, "majority no new error");
        idle_cycle;

        $display("tb_slave2_rx: back-to-back frames");
        expected_codeword = 42'h001_ABCDEFA;
        send_frame_nominal(expected_codeword);
        check_equal_1(o_CODEWORD_VALID, 1'b1, "back-to-back first valid");
        check_equal_42(o_CODEWORD, expected_codeword, "back-to-back first codeword");
        idle_cycle;
        expected_codeword = 42'h3AA_5555_0001;
        send_frame_nominal(expected_codeword);
        check_equal_1(o_CODEWORD_VALID, 1'b1, "back-to-back second valid");
        check_equal_42(o_CODEWORD, expected_codeword, "back-to-back second codeword");
        check_equal_int(sync_count, 4, "back-to-back sync count");
        check_equal_int(valid_count, 4, "back-to-back valid count");
        check_equal_int(err_count, 1, "back-to-back no new error");
        idle_cycle;

        if (error_count == 0)
            $display("PASS: tb_slave2_rx");
        else
            $display("FAIL: tb_slave2_rx error_count=%0d", error_count);

        $finish;
    end

endmodule
