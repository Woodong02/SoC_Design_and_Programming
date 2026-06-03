`timescale 1ns / 1ps

module tb_slave_control;

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

    slave_control dut (
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

    function [34:0] make_broadcast;
        input [7:0] halt_cmd;
        input [9:0] guard_ticks;
        begin
            make_broadcast = {halt_cmd, guard_ticks, 17'd0};
        end
    endfunction

    task check_bit;
        input [639:0] check_name;
        input actual_value;
        input expected_value;
        begin
            tb_check_count = tb_check_count + 1;
            if (actual_value !== expected_value) begin
                tb_fail_count = tb_fail_count + 1;
                $display("FAIL: %0s actual=%b expected=%b time=%0t",
                         check_name, actual_value, expected_value, $time);
            end else begin
                $display("PASS: %0s value=%b time=%0t",
                         check_name, actual_value, $time);
            end
        end
    endtask

    task check_10;
        input [639:0] check_name;
        input [9:0] actual_value;
        input [9:0] expected_value;
        begin
            tb_check_count = tb_check_count + 1;
            if (actual_value !== expected_value) begin
                tb_fail_count = tb_fail_count + 1;
                $display("FAIL: %0s actual=%0d expected=%0d time=%0t",
                         check_name, actual_value, expected_value, $time);
            end else begin
                $display("PASS: %0s value=%0d time=%0t",
                         check_name, actual_value, $time);
            end
        end
    endtask

    task check_32;
        input [639:0] check_name;
        input [31:0] actual_value;
        input [31:0] expected_value;
        begin
            tb_check_count = tb_check_count + 1;
            if (actual_value !== expected_value) begin
                tb_fail_count = tb_fail_count + 1;
                $display("FAIL: %0s actual=0x%08h expected=0x%08h time=%0t",
                         check_name, actual_value, expected_value, $time);
            end else begin
                $display("PASS: %0s value=0x%08h time=%0t",
                         check_name, actual_value, $time);
            end
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
        input       two_bit_err;
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

    initial begin
        tb_clk = 1'b0;
        forever #5 tb_clk = ~tb_clk;
    end

    initial begin
        tb_fail_count = 0;
        tb_check_count = 0;
        tb_node_id = 3'd2;
        tb_payload_in = 32'h1234_abcd;
        tb_resetn = 1'b1;
        tb_broadcast_data = 35'd0;
        tb_broadcast_valid = 1'b0;
        tb_broadcast_2bit_err = 1'b0;

        $display("INFO: tb_slave_control start");

        apply_reset();
        check_bit("reset tx disabled", tb_tx_enable, 1'b0);
        check_bit("reset not halted", tb_halted, 1'b0);
        check_10("reset guard clear", tb_latched_guard_ticks, 10'd0);
        check_32("payload pass-through after reset", tb_payload, 32'h1234_abcd);

        send_broadcast(8'b0000_0000, 10'd123, 1'b0);
        check_bit("active entry tx enabled", tb_tx_enable, 1'b1);
        check_bit("active entry halted clear", tb_halted, 1'b0);
        check_10("guard latch active", tb_latched_guard_ticks, 10'd123);

        tb_payload_in = 32'hfeed_cafe;
        #1;
        check_32("payload pass-through active", tb_payload, 32'hfeed_cafe);

        send_broadcast(8'b0000_0100, 10'd456, 1'b0);
        check_bit("halt set disables tx", tb_tx_enable, 1'b0);
        check_bit("halt set halted", tb_halted, 1'b1);
        check_10("guard latch halt set", tb_latched_guard_ticks, 10'd456);

        send_broadcast(8'b0000_0000, 10'd789, 1'b0);
        check_bit("halt clear re-enables tx", tb_tx_enable, 1'b1);
        check_bit("halt clear exits halted", tb_halted, 1'b0);
        check_10("guard latch halt clear", tb_latched_guard_ticks, 10'd789);

        send_broadcast(8'b0000_0100, 10'd321, 1'b1);
        check_bit("2bit error keeps tx enabled", tb_tx_enable, 1'b1);
        check_bit("2bit error keeps halted clear", tb_halted, 1'b0);
        check_10("2bit error keeps guard", tb_latched_guard_ticks, 10'd789);

        send_broadcast(8'b0000_0100, 10'd654, 1'b0);
        check_bit("clean halt after ignored frame disables tx", tb_tx_enable, 1'b0);
        check_bit("clean halt after ignored frame halted", tb_halted, 1'b1);
        check_10("clean halt after ignored frame latches guard", tb_latched_guard_ticks, 10'd654);

        tb_node_id = 3'd5;
        send_broadcast(8'b0010_0000, 10'd77, 1'b0);
        check_bit("node5 halt bit indexing disables tx", tb_tx_enable, 1'b0);
        check_bit("node5 halt bit indexing halted", tb_halted, 1'b1);
        check_10("node5 halt bit indexing guard", tb_latched_guard_ticks, 10'd77);

        send_broadcast(8'b0000_0100, 10'd88, 1'b0);
        check_bit("node5 ignores node2 halt bit", tb_tx_enable, 1'b1);
        check_bit("node5 clear exits halted", tb_halted, 1'b0);
        check_10("node5 clear latch guard", tb_latched_guard_ticks, 10'd88);

        tb_node_id = 3'd0;
        send_broadcast(8'b0000_0001, 10'd99, 1'b0);
        check_bit("node0 halt bit indexing disables tx", tb_tx_enable, 1'b0);
        check_bit("node0 halt bit indexing halted", tb_halted, 1'b1);

        if (tb_fail_count == 0) begin
            $display("PASS: tb_slave_control completed checks=%0d", tb_check_count);
        end else begin
            $display("FAIL: tb_slave_control failures=%0d checks=%0d",
                     tb_fail_count, tb_check_count);
        end

        $finish;
    end

endmodule
