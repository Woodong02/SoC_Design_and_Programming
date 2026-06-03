`timescale 1ns / 1ps

module tb_slave21_rx;

    reg         i_CLK;
    reg         i_RESETN;
    reg         i_SERIAL_IN;
    reg  [15:0] i_BIT_PERIOD;
    wire [41:0] o_CODEWORD;
    wire        o_CODEWORD_VALID;
    wire        o_FRAME_DONE;
    wire        o_PREAMBLE_OK;
    wire        o_PREAMBLE_ERR;
    wire        o_RX_ACTIVE;

    integer fail_count;
    integer bit_index;
    integer frame_done_count;
    integer valid_count;
    integer preamble_ok_count;
    integer preamble_err_count;

    reg [49:0] frame_bits;
    reg [41:0] expected_codeword;

    slave21_rx dut (
        .i_CLK(i_CLK),
        .i_RESETN(i_RESETN),
        .i_SERIAL_IN(i_SERIAL_IN),
        .i_BIT_PERIOD(i_BIT_PERIOD),
        .o_CODEWORD(o_CODEWORD),
        .o_CODEWORD_VALID(o_CODEWORD_VALID),
        .o_FRAME_DONE(o_FRAME_DONE),
        .o_PREAMBLE_OK(o_PREAMBLE_OK),
        .o_PREAMBLE_ERR(o_PREAMBLE_ERR),
        .o_RX_ACTIVE(o_RX_ACTIVE)
    );

    initial begin
        i_CLK = 1'b0;
        forever #5 i_CLK = ~i_CLK;
    end

    always @(posedge i_CLK) begin
        #1;
        if (o_FRAME_DONE == 1'b1) begin
            frame_done_count = frame_done_count + 1;
        end
        if (o_CODEWORD_VALID == 1'b1) begin
            valid_count = valid_count + 1;
        end
        if (o_PREAMBLE_OK == 1'b1) begin
            preamble_ok_count = preamble_ok_count + 1;
        end
        if (o_PREAMBLE_ERR == 1'b1) begin
            preamble_err_count = preamble_err_count + 1;
        end
    end

    task check_1;
        input actual_value;
        input expected_value;
        input [255:0] label;
        begin
            if (actual_value !== expected_value) begin
                fail_count = fail_count + 1;
                $display("FAIL: %0s actual=%0b expected=%0b time=%0t", label, actual_value, expected_value, $time);
            end else begin
                $display("PASS: %0s value=%0b time=%0t", label, actual_value, $time);
            end
        end
    endtask

    task check_42;
        input [41:0] actual_value;
        input [41:0] expected_value;
        input [255:0] label;
        begin
            if (actual_value !== expected_value) begin
                fail_count = fail_count + 1;
                $display("FAIL: %0s actual=0x%011h expected=0x%011h time=%0t", label, actual_value, expected_value, $time);
            end else begin
                $display("PASS: %0s value=0x%011h time=%0t", label, actual_value, $time);
            end
        end
    endtask

    task check_int;
        input integer actual_value;
        input integer expected_value;
        input [255:0] label;
        begin
            if (actual_value != expected_value) begin
                fail_count = fail_count + 1;
                $display("FAIL: %0s actual=%0d expected=%0d time=%0t", label, actual_value, expected_value, $time);
            end else begin
                $display("PASS: %0s value=%0d time=%0t", label, actual_value, $time);
            end
        end
    endtask

    task wait_cycles;
        input integer cycle_count;
        integer cycle_idx;
        begin
            for (cycle_idx = 0; cycle_idx < cycle_count; cycle_idx = cycle_idx + 1) begin
                @(posedge i_CLK);
            end
            #1;
        end
    endtask

    task apply_reset;
        begin
            @(negedge i_CLK);
            i_RESETN = 1'b0;
            i_SERIAL_IN = 1'b0;
            i_BIT_PERIOD = 16'd8;
            wait_cycles(4);
            check_1(o_CODEWORD_VALID, 1'b0, "reset clears codeword valid");
            check_1(o_FRAME_DONE, 1'b0, "reset clears frame done");
            check_1(o_PREAMBLE_OK, 1'b0, "reset clears preamble ok");
            check_1(o_PREAMBLE_ERR, 1'b0, "reset clears preamble err");
            check_1(o_RX_ACTIVE, 1'b0, "reset clears rx active");
            @(negedge i_CLK);
            i_RESETN = 1'b1;
            wait_cycles(2);
        end
    endtask

    task drive_serial_bit;
        input bit_value;
        input integer period_value;
        integer hold_idx;
        begin
            @(negedge i_CLK);
            i_SERIAL_IN = bit_value;
            for (hold_idx = 0; hold_idx < period_value; hold_idx = hold_idx + 1) begin
                @(posedge i_CLK);
            end
            #1;
        end
    endtask

    task send_frame;
        input [7:0] preamble_value;
        input [41:0] codeword_value;
        input integer period_value;
        integer send_idx;
        begin
            frame_bits = {preamble_value, codeword_value};
            @(negedge i_CLK);
            i_SERIAL_IN = 1'b0;
            wait_cycles(2);
            for (send_idx = 49; send_idx >= 0; send_idx = send_idx - 1) begin
                drive_serial_bit(frame_bits[send_idx], period_value);
            end
            @(negedge i_CLK);
            i_SERIAL_IN = 1'b0;
            wait_cycles(2);
        end
    endtask

    task send_frame_with_period_change;
        input [41:0] codeword_value;
        input integer period_value;
        input [15:0] changed_period;
        integer send_idx;
        begin
            frame_bits = {8'hAA, codeword_value};
            @(negedge i_CLK);
            i_SERIAL_IN = 1'b0;
            wait_cycles(2);
            for (send_idx = 49; send_idx >= 0; send_idx = send_idx - 1) begin
                if (send_idx == 30) begin
                    @(negedge i_CLK);
                    i_BIT_PERIOD = changed_period;
                end
                drive_serial_bit(frame_bits[send_idx], period_value);
            end
            @(negedge i_CLK);
            i_SERIAL_IN = 1'b0;
            wait_cycles(2);
        end
    endtask

    initial begin
        fail_count = 0;
        frame_done_count = 0;
        valid_count = 0;
        preamble_ok_count = 0;
        preamble_err_count = 0;
        i_RESETN = 1'b0;
        i_SERIAL_IN = 1'b0;
        i_BIT_PERIOD = 16'd8;

        $display("tb_slave21_rx: start");

        apply_reset;
        check_1(o_RX_ACTIVE, 1'b0, "idle after reset");

        $display("tb_slave21_rx: idle-low");
        i_SERIAL_IN = 1'b0;
        wait_cycles(20);
        check_int(frame_done_count, 0, "idle-low no frame done");
        check_int(valid_count, 0, "idle-low no valid");
        check_int(preamble_err_count, 0, "idle-low no preamble error");

        $display("tb_slave21_rx: valid frame");
        expected_codeword = 42'h2A5_1234_5678;
        i_BIT_PERIOD = 16'd8;
        send_frame(8'hAA, expected_codeword, 8);
        check_int(frame_done_count, 1, "valid frame done count");
        check_int(valid_count, 1, "valid frame valid count");
        check_int(preamble_ok_count, 1, "valid frame preamble ok count");
        check_int(preamble_err_count, 0, "valid frame no preamble error");
        check_42(o_CODEWORD, expected_codeword, "valid frame codeword");
        check_1(o_CODEWORD_VALID, 1'b0, "valid pulse returned low");
        check_1(o_FRAME_DONE, 1'b0, "frame done pulse returned low");

        $display("tb_slave21_rx: wrong preamble discard");
        expected_codeword = o_CODEWORD;
        i_BIT_PERIOD = 16'd8;
        send_frame(8'hA8, 42'h155_0BAD_CAFE, 8);
        check_int(frame_done_count, 2, "wrong preamble frame done count");
        check_int(valid_count, 1, "wrong preamble blocks valid");
        check_int(preamble_ok_count, 1, "wrong preamble no ok");
        check_int(preamble_err_count, 1, "wrong preamble error count");
        check_42(o_CODEWORD, expected_codeword, "wrong preamble preserves last codeword");
        check_1(o_PREAMBLE_ERR, 1'b0, "preamble error pulse returned low");

        $display("tb_slave21_rx: mid-frame period change ignored");
        expected_codeword = 42'h001_ABCDEFA;
        i_BIT_PERIOD = 16'd8;
        send_frame_with_period_change(expected_codeword, 8, 16'd3);
        check_int(frame_done_count, 3, "period-change frame done count");
        check_int(valid_count, 2, "period-change valid count");
        check_int(preamble_ok_count, 2, "period-change preamble ok count");
        check_int(preamble_err_count, 1, "period-change no new error");
        check_42(o_CODEWORD, expected_codeword, "period-change codeword");
        check_1(o_CODEWORD_VALID, 1'b0, "period-change valid pulse one cycle");
        check_1(o_FRAME_DONE, 1'b0, "period-change frame done one cycle");

        $display("tb_slave21_rx: small bit period boundary");
        expected_codeword = 42'h3AA_5555_0001;
        i_BIT_PERIOD = 16'd1;
        send_frame(8'hAA, expected_codeword, 1);
        check_int(frame_done_count, 4, "small-period frame done count");
        check_int(valid_count, 3, "small-period valid count");
        check_int(preamble_ok_count, 3, "small-period preamble ok count");
        check_int(preamble_err_count, 1, "small-period no new error");
        check_42(o_CODEWORD, expected_codeword, "small-period codeword");
        check_1(o_RX_ACTIVE, 1'b0, "small-period returns idle");

        if (fail_count == 0) begin
            $display("PASS: tb_slave21_rx");
        end else begin
            $display("FAIL: tb_slave21_rx fail_count=%0d", fail_count);
        end

        $finish;
    end

endmodule
