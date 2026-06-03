module tb_slave_tx;

    reg         i_CLK;
    reg         i_RESETN;
    reg  [9:0]  i_BIT_DIV;
    reg  [2:0]  i_NODE_ID;
    reg  [31:0] i_PAYLOAD;
    reg         i_TX_TRIGGER;
    reg         i_TX_ENABLE;
    wire        o_SERIAL_OUT;
    wire        o_TX_ACTIVE;
    wire        o_TX_DONE;

    integer error_count;
    integer bit_index;
    integer tick_index;
    integer done_seen_count;

    reg [49:0] expected_frame;

    slave_tx u_dut (
        .i_CLK(i_CLK),
        .i_RESETN(i_RESETN),
        .i_BIT_DIV(i_BIT_DIV),
        .i_NODE_ID(i_NODE_ID),
        .i_PAYLOAD(i_PAYLOAD),
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

    task apply_reset;
        begin
            $display("PHASE: apply reset");
            i_RESETN = 1'b0;
            i_TX_TRIGGER = 1'b0;
            i_TX_ENABLE = 1'b0;
            i_NODE_ID = 3'd0;
            i_PAYLOAD = 32'd0;
            i_BIT_DIV = 10'd4;
            #2;
            check_signal(1'b0, o_SERIAL_OUT, "reset serial idle");
            check_signal(1'b0, o_TX_ACTIVE, "reset active low");
            check_signal(1'b0, o_TX_DONE, "reset done low");
            repeat (3) wait_clock;
            i_RESETN = 1'b1;
            wait_clock;
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

    task check_frame_no_retrigger;
        input [49:0] frame_value;
        begin
            $display("PHASE: normal 50-bit frame check");
            check_signal(1'b1, o_TX_ACTIVE, "active asserted at frame start");
            check_signal(1'b1, o_SERIAL_OUT, "first bit is preamble MSB");

            for (bit_index = 0; bit_index < 50; bit_index = bit_index + 1) begin
                for (tick_index = 0; tick_index < i_BIT_DIV; tick_index = tick_index + 1) begin
                    check_signal(frame_value[49 - bit_index], o_SERIAL_OUT, "frame bit value and bit period");
                    check_signal(1'b1, o_TX_ACTIVE, "active remains high during frame");
                    check_signal(1'b0, o_TX_DONE, "done low during frame");
                    wait_clock;
                end
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
                for (tick_index = 0; tick_index < i_BIT_DIV; tick_index = tick_index + 1) begin
                    check_signal(frame_value[49 - bit_index], o_SERIAL_OUT, "frame preserved while retriggering");
                    check_signal(1'b1, o_TX_ACTIVE, "active high while retriggering");
                    check_signal(1'b0, o_TX_DONE, "done low while retriggering");

                    if ((bit_index == 5) && (tick_index == 0)) begin
                        $display("INFO: issue ignored retrigger while active");
                        i_NODE_ID = retrigger_node_id;
                        i_PAYLOAD = retrigger_payload;
                        i_TX_TRIGGER = 1'b1;
                    end else if ((bit_index == 5) && (tick_index == 1)) begin
                        i_TX_TRIGGER = 1'b0;
                    end

                    wait_clock;
                end
            end

            i_TX_TRIGGER = 1'b0;
            check_done_pulse_and_idle;
        end
    endtask

    task check_reset_interrupt;
        begin
            $display("PHASE: reset interrupts active frame");
            pulse_trigger(3'd2, 32'h13572468, 1'b1);
            check_signal(1'b1, o_TX_ACTIVE, "active before reset interrupt");
            repeat (5) wait_clock;
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
        done_seen_count = 0;
        i_RESETN = 1'b0;
        i_BIT_DIV = 10'd4;
        i_NODE_ID = 3'd0;
        i_PAYLOAD = 32'd0;
        i_TX_TRIGGER = 1'b0;
        i_TX_ENABLE = 1'b0;

        $display("TB_START: tb_slave_tx");

        apply_reset;

        check_idle_cycles(5, "idle without trigger");

        $display("PHASE: disabled trigger ignored");
        pulse_trigger(3'd3, 32'h12345678, 1'b0);
        check_idle_cycles(8, "post disabled trigger idle");

        expected_frame = {8'hAA, reference_codeword({3'd5, 32'hA5C33C5A})};
        $display("PHASE: start normal frame expected=%050b", expected_frame);
        pulse_trigger(3'd5, 32'hA5C33C5A, 1'b1);
        check_frame_no_retrigger(expected_frame);

        check_reset_interrupt;

        expected_frame = {8'hAA, reference_codeword({3'd1, 32'h0F0F55AA})};
        $display("PHASE: start frame for retrigger expected=%050b", expected_frame);
        pulse_trigger(3'd1, 32'h0F0F55AA, 1'b1);
        check_frame_with_retrigger(expected_frame, 3'd7, 32'hFFFFFFFF);

        check_idle_cycles(4, "final idle");

        if (error_count == 0) begin
            $display("PASS: tb_slave_tx completed with no errors");
        end else begin
            $display("FAIL: tb_slave_tx completed with %0d errors", error_count);
        end

        $finish;
    end

endmodule
