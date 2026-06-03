`timescale 1ns / 1ps

module tb_slave2_reuse_compat;

    reg  [34:0] tb_data;
    wire [41:0] tb_codeword;
    reg  [41:0] tb_decode_codeword;
    wire [34:0] tb_dec_data;
    wire        tb_dec_1bit_err;
    wire        tb_dec_2bit_err;

    reg         tb_clk;
    reg         tb_resetn;
    reg  [2:0]  tb_node_id;
    reg  [34:0] tb_broadcast_data;
    reg         tb_broadcast_valid;
    reg         tb_broadcast_2bit_err;
    reg  [31:0] tb_payload_in;
    wire        tb_tx_enable;
    wire [9:0]  tb_latched_guard_ticks;
    wire [31:0] tb_payload;
    wire        tb_halted;

    integer tb_fail_count;
    integer tb_check_count;
    integer tb_index;

    slave_hamming_enc u_enc (
        .i_DATA(tb_data),
        .o_CODEWORD(tb_codeword)
    );

    slave_hamming_dec u_dec (
        .i_CODEWORD(tb_decode_codeword),
        .o_DATA(tb_dec_data),
        .o_HAM_1BIT_ERR(tb_dec_1bit_err),
        .o_HAM_2BIT_ERR(tb_dec_2bit_err)
    );

    slave_control u_control (
        .i_CLK(tb_clk),
        .i_RESETN(tb_resetn),
        .i_NODE_ID(tb_node_id),
        .i_BROADCAST_DATA(tb_broadcast_data),
        .i_BROADCAST_VALID(tb_broadcast_valid),
        .i_BROADCAST_2BIT_ERR(tb_broadcast_2bit_err),
        .i_PAYLOAD_IN(tb_payload_in),
        .o_TX_ENABLE(tb_tx_enable),
        .o_LATCHED_GUARD_TICKS(tb_latched_guard_ticks),
        .o_PAYLOAD(tb_payload),
        .o_HALTED(tb_halted)
    );

    function is_master_skip_syndrome;
        input integer data_index;
        begin
            if ((data_index == 0)  || (data_index == 1)  ||
                (data_index == 3)  || (data_index == 7)  ||
                (data_index == 15) || (data_index == 31)) begin
                is_master_skip_syndrome = 1'b1;
            end else begin
                is_master_skip_syndrome = 1'b0;
            end
        end
    endfunction

    function [34:0] make_broadcast;
        input [7:0] halt_cmd;
        input [9:0] guard_ticks;
        begin
            make_broadcast = {halt_cmd, guard_ticks, 17'd0};
        end
    endfunction

    task report_fail;
        input [8*80-1:0] check_name;
        begin
            tb_fail_count = tb_fail_count + 1;
            $display("FAIL: %0s time=%0t", check_name, $time);
        end
    endtask

    task check_bit;
        input [8*80-1:0] check_name;
        input actual_value;
        input expected_value;
        begin
            tb_check_count = tb_check_count + 1;
            if (actual_value !== expected_value) begin
                report_fail(check_name);
                $display("      actual=%b expected=%b", actual_value, expected_value);
            end else begin
                $display("PASS: %0s value=%b", check_name, actual_value);
            end
        end
    endtask

    task check_10;
        input [8*80-1:0] check_name;
        input [9:0] actual_value;
        input [9:0] expected_value;
        begin
            tb_check_count = tb_check_count + 1;
            if (actual_value !== expected_value) begin
                report_fail(check_name);
                $display("      actual=%0d expected=%0d", actual_value, expected_value);
            end else begin
                $display("PASS: %0s value=%0d", check_name, actual_value);
            end
        end
    endtask

    task check_32;
        input [8*80-1:0] check_name;
        input [31:0] actual_value;
        input [31:0] expected_value;
        begin
            tb_check_count = tb_check_count + 1;
            if (actual_value !== expected_value) begin
                report_fail(check_name);
                $display("      actual=0x%08h expected=0x%08h", actual_value, expected_value);
            end else begin
                $display("PASS: %0s value=0x%08h", check_name, actual_value);
            end
        end
    endtask

    task check_35;
        input [8*80-1:0] check_name;
        input [34:0] actual_value;
        input [34:0] expected_value;
        begin
            tb_check_count = tb_check_count + 1;
            if (actual_value !== expected_value) begin
                report_fail(check_name);
                $display("      actual=0x%09h expected=0x%09h", actual_value, expected_value);
            end else begin
                $display("PASS: %0s value=0x%09h", check_name, actual_value);
            end
        end
    endtask

    task load_encoded;
        input [34:0] data_value;
        begin
            tb_data = data_value;
            #1;
            tb_decode_codeword = tb_codeword;
            #1;
        end
    endtask

    task check_roundtrip;
        input [34:0] data_value;
        begin
            load_encoded(data_value);
            check_35("roundtrip data", tb_dec_data, data_value);
            check_bit("roundtrip 1bit flag clear", tb_dec_1bit_err, 1'b0);
            check_bit("roundtrip 2bit flag clear", tb_dec_2bit_err, 1'b0);
            check_35("encoder systematic data field", tb_codeword[41:7], data_value);
        end
    endtask

    task check_single_data_error;
        input [34:0] data_value;
        input integer data_index;
        reg [34:0] expected_data;
        begin
            load_encoded(data_value);
            tb_decode_codeword[data_index + 7] = ~tb_decode_codeword[data_index + 7];
            #1;
            if (is_master_skip_syndrome(data_index) == 1'b1) begin
                expected_data = data_value ^ (35'd1 << data_index);
            end else begin
                expected_data = data_value;
            end
            check_35("single data bit policy", tb_dec_data, expected_data);
            check_bit("single data bit 1bit flag", tb_dec_1bit_err, 1'b1);
            check_bit("single data bit 2bit flag", tb_dec_2bit_err, 1'b0);
        end
    endtask

    task check_parity_error;
        input [34:0] data_value;
        input integer codeword_index;
        begin
            load_encoded(data_value);
            tb_decode_codeword[codeword_index] = ~tb_decode_codeword[codeword_index];
            #1;
            check_35("single parity bit keeps data", tb_dec_data, data_value);
            check_bit("single parity bit 1bit flag", tb_dec_1bit_err, 1'b1);
            check_bit("single parity bit 2bit flag", tb_dec_2bit_err, 1'b0);
        end
    endtask

    task check_overall_parity_error;
        input [34:0] data_value;
        begin
            load_encoded(data_value);
            tb_decode_codeword[0] = ~tb_decode_codeword[0];
            #1;
            check_35("overall parity bit keeps data", tb_dec_data, data_value);
            check_bit("overall parity source policy 1bit clear", tb_dec_1bit_err, 1'b0);
            check_bit("overall parity source policy 2bit clear", tb_dec_2bit_err, 1'b0);
        end
    endtask

    task check_double_error;
        input [34:0] data_value;
        input integer bit_a;
        input integer bit_b;
        begin
            load_encoded(data_value);
            tb_decode_codeword[bit_a] = ~tb_decode_codeword[bit_a];
            tb_decode_codeword[bit_b] = ~tb_decode_codeword[bit_b];
            #1;
            check_bit("double bit 1bit flag clear", tb_dec_1bit_err, 1'b0);
            check_bit("double bit 2bit flag set", tb_dec_2bit_err, 1'b1);
        end
    endtask

    task apply_reset;
        begin
            tb_resetn = 1'b0;
            tb_broadcast_valid = 1'b0;
            tb_broadcast_2bit_err = 1'b0;
            tb_broadcast_data = 35'd0;
            @(posedge tb_clk);
            @(posedge tb_clk);
            #1;
            tb_resetn = 1'b1;
            @(posedge tb_clk);
            #1;
        end
    endtask

    task send_broadcast;
        input [7:0] halt_cmd;
        input [9:0] guard_ticks;
        input two_bit_err;
        begin
            tb_broadcast_data = make_broadcast(halt_cmd, guard_ticks);
            tb_broadcast_2bit_err = two_bit_err;
            tb_broadcast_valid = 1'b1;
            @(posedge tb_clk);
            #1;
            tb_broadcast_valid = 1'b0;
            tb_broadcast_2bit_err = 1'b0;
            tb_broadcast_data = 35'd0;
        end
    endtask

    task run_hamming_checks;
        begin
            $display("");
            $display("PHASE: hamming encoder/decoder roundtrip");
            check_roundtrip(35'd0);
            check_roundtrip(35'h7ffffffff);
            check_roundtrip(35'h012345678);
            check_roundtrip(35'h155555555);
            check_roundtrip(35'h0a5a5a5a5);

            $display("");
            $display("PHASE: hamming single-bit data error policy");
            for (tb_index = 0; tb_index < 35; tb_index = tb_index + 1) begin
                check_single_data_error(35'h012345678, tb_index);
            end

            $display("");
            $display("PHASE: hamming parity and double-bit errors");
            check_parity_error(35'h012345678, 1);
            check_parity_error(35'h012345678, 2);
            check_parity_error(35'h012345678, 3);
            check_parity_error(35'h012345678, 4);
            check_parity_error(35'h012345678, 5);
            check_parity_error(35'h012345678, 6);
            check_overall_parity_error(35'h012345678);
            check_double_error(35'h012345678, 9, 10);
            check_double_error(35'h155555555, 12, 28);
        end
    endtask

    task run_control_checks;
        begin
            $display("");
            $display("PHASE: slave_control reset/active/halt/guard/payload");

            tb_node_id = 3'd2;
            tb_payload_in = 32'h1234abcd;
            apply_reset();
            check_bit("control reset tx disabled", tb_tx_enable, 1'b0);
            check_bit("control reset halted clear", tb_halted, 1'b0);
            check_10("control reset guard clear", tb_latched_guard_ticks, 10'd0);
            check_32("control reset payload pass-through", tb_payload, 32'h1234abcd);

            send_broadcast(8'b00000000, 10'd123, 1'b0);
            check_bit("control active tx enabled", tb_tx_enable, 1'b1);
            check_bit("control active halted clear", tb_halted, 1'b0);
            check_10("control active guard latch", tb_latched_guard_ticks, 10'd123);

            tb_payload_in = 32'hfeedcafe;
            #1;
            check_32("control active payload pass-through", tb_payload, 32'hfeedcafe);

            send_broadcast(8'b00000100, 10'd456, 1'b0);
            check_bit("control halt tx disabled", tb_tx_enable, 1'b0);
            check_bit("control halt asserted", tb_halted, 1'b1);
            check_10("control halt guard latch", tb_latched_guard_ticks, 10'd456);

            send_broadcast(8'b00000000, 10'd789, 1'b0);
            check_bit("control halt clear tx enabled", tb_tx_enable, 1'b1);
            check_bit("control halt clear halted clear", tb_halted, 1'b0);
            check_10("control halt clear guard latch", tb_latched_guard_ticks, 10'd789);

            send_broadcast(8'b00000100, 10'd321, 1'b1);
            check_bit("control 2bit ignore keeps tx", tb_tx_enable, 1'b1);
            check_bit("control 2bit ignore keeps halted clear", tb_halted, 1'b0);
            check_10("control 2bit ignore keeps guard", tb_latched_guard_ticks, 10'd789);

            send_broadcast(8'b00000100, 10'd654, 1'b0);
            check_bit("control clean halt after ignore tx disabled", tb_tx_enable, 1'b0);
            check_bit("control clean halt after ignore halted", tb_halted, 1'b1);
            check_10("control clean halt after ignore guard", tb_latched_guard_ticks, 10'd654);

            tb_node_id = 3'd5;
            send_broadcast(8'b00100000, 10'd77, 1'b0);
            check_bit("control node5 halt tx disabled", tb_tx_enable, 1'b0);
            check_bit("control node5 halt asserted", tb_halted, 1'b1);
            check_10("control node5 guard latch", tb_latched_guard_ticks, 10'd77);

            send_broadcast(8'b00000100, 10'd88, 1'b0);
            check_bit("control node5 ignores node2 halt", tb_tx_enable, 1'b1);
            check_bit("control node5 exits halt", tb_halted, 1'b0);
            check_10("control node5 clear guard", tb_latched_guard_ticks, 10'd88);
        end
    endtask

    initial begin
        tb_clk = 1'b0;
        forever #5 tb_clk = ~tb_clk;
    end

    initial begin
        tb_fail_count = 0;
        tb_check_count = 0;
        tb_index = 0;
        tb_data = 35'd0;
        tb_decode_codeword = 42'd0;
        tb_resetn = 1'b1;
        tb_node_id = 3'd0;
        tb_broadcast_data = 35'd0;
        tb_broadcast_valid = 1'b0;
        tb_broadcast_2bit_err = 1'b0;
        tb_payload_in = 32'd0;

        $display("============================================================");
        $display("tb_slave2_reuse_compat start");
        $display("Slave 2.0 direct-reuse leaf compatibility self-check");
        $display("============================================================");

        run_hamming_checks();
        run_control_checks();

        $display("");
        $display("============================================================");
        if (tb_fail_count == 0) begin
            $display("PASS: tb_slave2_reuse_compat completed %0d checks with no failures", tb_check_count);
        end else begin
            $display("FAIL: tb_slave2_reuse_compat completed %0d checks with %0d failures", tb_check_count, tb_fail_count);
        end
        $display("============================================================");
        $finish;
    end

endmodule

