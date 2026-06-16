`timescale 1ns / 1ps

module tb_slave_broadcast_rx_decoder;

    reg         clk;
    reg         resetn;
    reg         serial_in;
    reg         cfg_enable;
    reg         tx_active;
    reg  [31:0] bit_period_reload;
    reg  [34:0] encoder_data;
    wire [41:0] encoder_codeword;
    reg  [49:0] tx_frame;

    wire        sync_pulse;
    wire        serial_sync_ff;
    wire [41:0] rx_codeword;
    wire        rx_codeword_valid;
    wire        rx_frame_done;
    wire        rx_preamble_ok;
    wire        rx_preamble_err;
    wire        rx_active;
    wire        broadcast_valid;
    wire [7:0]  broadcast_halt_mask;
    wire [9:0]  broadcast_guard_ticks;
    wire        broadcast_1bit_err;
    wire        broadcast_2bit_err;

    integer error_count;

    slave_sync_detector u_slave_sync_detector (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_SERIAL_IN(serial_in),
        .i_CFG_ENABLE(cfg_enable),
        .i_TX_ACTIVE(tx_active),
        .i_RX_ACTIVE(rx_active),
        .o_SYNC_PULSE(sync_pulse),
        .o_SERIAL_SYNC_FF(serial_sync_ff)
    );

    slave_broadcast_rx u_slave_broadcast_rx (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_SERIAL_IN(serial_sync_ff),
        .i_CFG_ENABLE(cfg_enable),
        .i_CFG_BIT_PERIOD_RELOAD(bit_period_reload),
        .i_SYNC_PULSE(sync_pulse),
        .o_RX_CODEWORD(rx_codeword),
        .o_RX_CODEWORD_VALID(rx_codeword_valid),
        .o_RX_FRAME_DONE(rx_frame_done),
        .o_RX_PREAMBLE_OK(rx_preamble_ok),
        .o_RX_PREAMBLE_ERR(rx_preamble_err),
        .o_RX_ACTIVE(rx_active)
    );

    slave_broadcast_decoder u_slave_broadcast_decoder (
        .i_RX_CODEWORD(rx_codeword),
        .i_RX_CODEWORD_VALID(rx_codeword_valid),
        .o_BROADCAST_VALID(broadcast_valid),
        .o_BROADCAST_HALT_MASK(broadcast_halt_mask),
        .o_BROADCAST_GUARD_TICKS(broadcast_guard_ticks),
        .o_BROADCAST_1BIT_ERR(broadcast_1bit_err),
        .o_BROADCAST_2BIT_ERR(broadcast_2bit_err)
    );

    slave_hamming_enc u_slave_hamming_enc (
        .i_DATA(encoder_data),
        .o_CODEWORD(encoder_codeword)
    );

    always begin
        clk = 1'b0;
        #5;
        clk = 1'b1;
        #5;
    end

    task check_bit;
        input actual;
        input expected;
        input [255:0] label_text;
        begin
            if (actual !== expected) begin
                $display("FAIL %0s actual=%b expected=%b time=%0t", label_text, actual, expected, $time);
                error_count = error_count + 1;
            end
        end
    endtask

    task check_equal_42;
        input [41:0] actual;
        input [41:0] expected;
        input [255:0] label_text;
        begin
            if (actual !== expected) begin
                $display("FAIL %0s actual=%h expected=%h time=%0t", label_text, actual, expected, $time);
                error_count = error_count + 1;
            end
        end
    endtask

    task check_equal_8;
        input [7:0] actual;
        input [7:0] expected;
        input [255:0] label_text;
        begin
            if (actual !== expected) begin
                $display("FAIL %0s actual=%h expected=%h time=%0t", label_text, actual, expected, $time);
                error_count = error_count + 1;
            end
        end
    endtask

    task check_equal_10;
        input [9:0] actual;
        input [9:0] expected;
        input [255:0] label_text;
        begin
            if (actual !== expected) begin
                $display("FAIL %0s actual=%h expected=%h time=%0t", label_text, actual, expected, $time);
                error_count = error_count + 1;
            end
        end
    endtask

    task reset_dut;
        begin
            resetn = 1'b0;
            serial_in = 1'b0;
            cfg_enable = 1'b1;
            tx_active = 1'b0;
            bit_period_reload = 32'd0;
            encoder_data = 35'd0;
            repeat (4) @(posedge clk);
            resetn = 1'b1;
            repeat (4) @(posedge clk);
        end
    endtask

    task send_frame;
        input [49:0] frame_value;
        input [31:0] reload_value;
        integer bit_index;
        integer hold_index;
        begin
            bit_period_reload = reload_value;
            @(negedge clk);
            for (bit_index = 0; bit_index < 50; bit_index = bit_index + 1) begin
                serial_in = frame_value[49 - bit_index];
                for (hold_index = 0; hold_index <= reload_value; hold_index = hold_index + 1) begin
                    @(negedge clk);
                end
            end
            serial_in = 1'b0;
        end
    endtask

    task wait_for_valid;
        integer wait_index;
        begin
            for (wait_index = 0; wait_index < 1000; wait_index = wait_index + 1) begin
                @(posedge clk);
                #1;
                if (rx_codeword_valid == 1'b1) begin
                    wait_index = 1000;
                end
            end
            check_bit(rx_codeword_valid, 1'b1, "rx valid timeout");
        end
    endtask

    task test_valid_frame;
        input [31:0] reload_value;
        input [7:0]  halt_mask;
        input [9:0]  guard_ticks;
        begin
            $display("TEST broadcast rx valid reload=%0d", reload_value);
            encoder_data = {halt_mask, guard_ticks, 17'd0};
            #1;
            tx_frame = {8'hAA, encoder_codeword};
            fork
                send_frame(tx_frame, reload_value);
                wait_for_valid();
            join
            check_equal_42(rx_codeword, encoder_codeword, "rx codeword");
            check_bit(broadcast_valid, 1'b1, "broadcast valid");
            check_equal_8(broadcast_halt_mask, halt_mask, "halt mask");
            check_equal_10(broadcast_guard_ticks, guard_ticks, "guard ticks");
            check_bit(broadcast_2bit_err, 1'b0, "no 2bit err");
            repeat (5) @(posedge clk);
        end
    endtask

    task test_disabled_ignores_edge;
        begin
            $display("TEST sync disabled");
            cfg_enable = 1'b0;
            serial_in = 1'b0;
            repeat (2) @(posedge clk);
            serial_in = 1'b1;
            repeat (5) @(posedge clk);
            check_bit(sync_pulse, 1'b0, "disabled sync pulse");
            check_bit(rx_active, 1'b0, "disabled rx inactive");
            serial_in = 1'b0;
            cfg_enable = 1'b1;
            repeat (5) @(posedge clk);
        end
    endtask

    task test_tx_active_ignores_edge;
        begin
            $display("TEST tx active masks sync");
            tx_active = 1'b1;
            serial_in = 1'b0;
            repeat (2) @(posedge clk);
            serial_in = 1'b1;
            repeat (5) @(posedge clk);
            check_bit(sync_pulse, 1'b0, "tx active sync pulse");
            serial_in = 1'b0;
            tx_active = 1'b0;
            repeat (5) @(posedge clk);
        end
    endtask

    task test_preamble_error;
        begin
            $display("TEST preamble error");
            encoder_data = {8'h11, 10'd3, 17'd0};
            #1;
            tx_frame = {8'hAB, encoder_codeword};
            fork
                send_frame(tx_frame, 32'd1);
                begin
                    repeat (80) @(posedge clk);
                end
            join
            check_bit(rx_preamble_err, 1'b0, "preamble err pulse returned low");
        end
    endtask

    initial begin
        error_count = 0;
        reset_dut();

        test_valid_frame(32'd0, 8'hA5, 10'd0);
        test_valid_frame(32'd2, 8'h3C, 10'd17);
        test_disabled_ignores_edge();
        test_tx_active_ignores_edge();
        test_preamble_error();

        if (error_count == 0) begin
            $display("PASS tb_slave_broadcast_rx_decoder");
        end else begin
            $display("FAIL tb_slave_broadcast_rx_decoder error_count=%0d", error_count);
        end
        $finish;
    end

endmodule
