`timescale 1ns / 1ps

module tb_slave_tx_path;

    reg         clk;
    reg         resetn;

    reg  [2:0]  slot_id;
    reg  [31:0] cfg_data_out0;
    reg  [31:0] cfg_data_out1;
    reg  [31:0] cfg_data_out2;
    reg  [31:0] cfg_data_out3;
    reg  [31:0] cfg_data_out4;
    reg  [31:0] cfg_data_out5;
    reg  [31:0] pl_payload6;
    reg         pl_payload6_valid;
    reg  [31:0] pl_payload7;
    reg         pl_payload7_valid;
    wire [2:0]  selected_payload_slot_id;
    wire [31:0] selected_payload;
    wire        selected_payload_valid;

    reg         frame_cmd_valid;
    reg         frame_ready;
    wire        frame_cmd_ready;
    wire        frame_cmd_accept;
    wire        frame_cmd_skip;
    wire [49:0] frame_out;
    wire        frame_valid;

    reg  [49:0] ser_frame;
    reg         ser_valid;
    reg  [31:0] ser_reload;
    wire        ser_ready;
    wire        ser_serial;
    wire        ser_oe;
    wire        ser_active;
    wire        ser_done;

    reg         seq_cfg_enable;
    reg         seq_sync_pulse;
    reg  [7:0]  seq_active_slot;
    reg  [7:0]  seq_halt_mask;
    reg  [7:0]  seq_slot_match;
    reg         seq_cmd_ready;
    reg         seq_cmd_accept;
    reg         seq_cmd_skip;
    reg         seq_tx_done;
    wire        seq_cmd_valid;
    wire [2:0]  seq_cmd_slot_id;
    wire        seq_skip_invalid_payload;
    wire        seq_slot_cycle_done;
    wire [2:0]  seq_current_slot;
    wire        seq_slot_valid;
    wire        seq_fault_tx_overlap;

    reg  [34:0] expected_encoder_data;
    wire [41:0] expected_codeword;
    reg  [49:0] expected_frame;
    integer     error_count;
    integer     mask_index;
    integer     accept_count;

    slave_payload_table u_slave_payload_table (
        .i_SLOT_ID(slot_id),
        .i_CFG_DATA_OUT0(cfg_data_out0),
        .i_CFG_DATA_OUT1(cfg_data_out1),
        .i_CFG_DATA_OUT2(cfg_data_out2),
        .i_CFG_DATA_OUT3(cfg_data_out3),
        .i_CFG_DATA_OUT4(cfg_data_out4),
        .i_CFG_DATA_OUT5(cfg_data_out5),
        .i_PL_PAYLOAD6(pl_payload6),
        .i_PL_PAYLOAD6_VALID(pl_payload6_valid),
        .i_PL_PAYLOAD7(pl_payload7),
        .i_PL_PAYLOAD7_VALID(pl_payload7_valid),
        .o_SELECTED_PAYLOAD_SLOT_ID(selected_payload_slot_id),
        .o_SELECTED_PAYLOAD(selected_payload),
        .o_SELECTED_PAYLOAD_VALID(selected_payload_valid)
    );

    slave_frame_builder u_slave_frame_builder (
        .i_TX_CMD_VALID(frame_cmd_valid),
        .i_TX_CMD_SLOT_ID(slot_id),
        .i_SELECTED_PAYLOAD(selected_payload),
        .i_SELECTED_PAYLOAD_VALID(selected_payload_valid),
        .i_TX_FRAME_READY(frame_ready),
        .o_TX_CMD_READY(frame_cmd_ready),
        .o_TX_CMD_ACCEPT(frame_cmd_accept),
        .o_TX_CMD_SKIP(frame_cmd_skip),
        .o_TX_FRAME(frame_out),
        .o_TX_FRAME_VALID(frame_valid)
    );

    slave_tx_serializer u_slave_tx_serializer (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_TX_FRAME(ser_frame),
        .i_TX_FRAME_VALID(ser_valid),
        .i_CFG_BIT_PERIOD_RELOAD(ser_reload),
        .o_TX_FRAME_READY(ser_ready),
        .o_SLAVE_SERIAL(ser_serial),
        .o_SLAVE_OE(ser_oe),
        .o_TX_ACTIVE(ser_active),
        .o_TX_DONE(ser_done)
    );

    slave_slot_sequencer u_slave_slot_sequencer (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_CFG_ENABLE(seq_cfg_enable),
        .i_SYNC_PULSE(seq_sync_pulse),
        .i_CFG_ACTIVE_SLOT(seq_active_slot),
        .i_HALT_MASK_SNAPSHOT(seq_halt_mask),
        .i_SLOT_TIME_MATCH(seq_slot_match),
        .i_TX_CMD_READY(seq_cmd_ready),
        .i_TX_CMD_ACCEPT(seq_cmd_accept),
        .i_TX_CMD_SKIP(seq_cmd_skip),
        .i_TX_DONE(seq_tx_done),
        .o_TX_CMD_VALID(seq_cmd_valid),
        .o_TX_CMD_SLOT_ID(seq_cmd_slot_id),
        .o_TX_SKIP_INVALID_PAYLOAD(seq_skip_invalid_payload),
        .o_SLOT_CYCLE_DONE(seq_slot_cycle_done),
        .o_STS_CURRENT_SLOT(seq_current_slot),
        .o_STS_SLOT_VALID(seq_slot_valid),
        .o_FAULT_TX_OVERLAP(seq_fault_tx_overlap)
    );

    slave_hamming_enc u_expected_hamming_enc (
        .i_DATA(expected_encoder_data),
        .o_CODEWORD(expected_codeword)
    );

    always begin
        clk = 1'b0;
        #5;
        clk = 1'b1;
        #5;
    end

    function integer popcount8;
        input [7:0] value;
        integer i;
        begin
            popcount8 = 0;
            for (i = 0; i < 8; i = i + 1) begin
                if (value[i] == 1'b1) begin
                    popcount8 = popcount8 + 1;
                end
            end
        end
    endfunction

    task check_equal_32;
        input [31:0] actual;
        input [31:0] expected;
        input [255:0] label_text;
        begin
            if (actual !== expected) begin
                $display("FAIL %0s actual=%h expected=%h time=%0t", label_text, actual, expected, $time);
                error_count = error_count + 1;
            end
        end
    endtask

    task check_equal_50;
        input [49:0] actual;
        input [49:0] expected;
        input [255:0] label_text;
        begin
            if (actual !== expected) begin
                $display("FAIL %0s actual=%h expected=%h time=%0t", label_text, actual, expected, $time);
                error_count = error_count + 1;
            end
        end
    endtask

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

    task reset_dut;
        begin
            resetn = 1'b0;
            slot_id = 3'd0;
            cfg_data_out0 = 32'h1000_0000;
            cfg_data_out1 = 32'h1000_0001;
            cfg_data_out2 = 32'h1000_0002;
            cfg_data_out3 = 32'h1000_0003;
            cfg_data_out4 = 32'h1000_0004;
            cfg_data_out5 = 32'h1000_0005;
            pl_payload6 = 32'h6000_0006;
            pl_payload6_valid = 1'b1;
            pl_payload7 = 32'h7000_0007;
            pl_payload7_valid = 1'b1;
            frame_cmd_valid = 1'b0;
            frame_ready = 1'b1;
            ser_frame = 50'd0;
            ser_valid = 1'b0;
            ser_reload = 32'd0;
            seq_cfg_enable = 1'b0;
            seq_sync_pulse = 1'b0;
            seq_active_slot = 8'd0;
            seq_halt_mask = 8'd0;
            seq_slot_match = 8'd0;
            seq_cmd_ready = 1'b1;
            seq_cmd_accept = 1'b0;
            seq_cmd_skip = 1'b0;
            seq_tx_done = 1'b0;
            expected_encoder_data = 35'd0;
            expected_frame = 50'd0;
            repeat (4) @(posedge clk);
            resetn = 1'b1;
            repeat (2) @(posedge clk);
        end
    endtask

    task test_payload_and_frame_builder;
        integer i;
        reg [31:0] expected_payload;
        begin
            $display("TEST payload table and frame builder");
            for (i = 0; i < 8; i = i + 1) begin
                slot_id = i[2:0];
                #1;
                case (i[2:0])
                    3'd0: expected_payload = cfg_data_out0;
                    3'd1: expected_payload = cfg_data_out1;
                    3'd2: expected_payload = cfg_data_out2;
                    3'd3: expected_payload = cfg_data_out3;
                    3'd4: expected_payload = cfg_data_out4;
                    3'd5: expected_payload = cfg_data_out5;
                    3'd6: expected_payload = pl_payload6;
                    3'd7: expected_payload = pl_payload7;
                    default: expected_payload = 32'd0;
                endcase
                check_equal_32(selected_payload, expected_payload, "payload select");
                check_bit(selected_payload_valid, 1'b1, "payload valid");

                expected_encoder_data = {i[2:0], expected_payload};
                #1;
                expected_frame = {8'hAA, expected_codeword};
                frame_cmd_valid = 1'b1;
                #1;
                check_bit(frame_cmd_accept, 1'b1, "frame accept");
                check_bit(frame_valid, 1'b1, "frame valid");
                check_equal_50(frame_out, expected_frame, "frame value");
                frame_cmd_valid = 1'b0;
                #1;
            end

            slot_id = 3'd6;
            pl_payload6_valid = 1'b0;
            #1;
            frame_cmd_valid = 1'b1;
            #1;
            check_bit(frame_cmd_skip, 1'b1, "invalid payload skip");
            check_bit(frame_valid, 1'b0, "invalid payload no frame");
            frame_cmd_valid = 1'b0;
            pl_payload6_valid = 1'b1;
        end
    endtask

    task test_serializer;
        input [49:0] test_frame;
        input [31:0] reload_value;
        integer bit_index;
        integer hold_index;
        begin
            $display("TEST serializer reload=%0d", reload_value);
            ser_frame = test_frame;
            ser_reload = reload_value;
            ser_valid = 1'b1;
            @(posedge clk);
            #1;
            ser_valid = 1'b0;
            check_bit(ser_active, 1'b1, "serializer active after accept");

            for (bit_index = 0; bit_index < 50; bit_index = bit_index + 1) begin
                for (hold_index = 0; hold_index <= reload_value; hold_index = hold_index + 1) begin
                    @(negedge clk);
                    check_bit(ser_serial, test_frame[49 - bit_index], "serializer serial bit");
                    check_bit(ser_oe, 1'b1, "serializer oe");
                    @(posedge clk);
                    #1;
                end
            end

            check_bit(ser_done, 1'b1, "serializer done pulse");
            @(posedge clk);
            #1;
            check_bit(ser_active, 1'b0, "serializer idle after done");
            check_bit(ser_serial, 1'b0, "serializer idle serial");
        end
    endtask

    task pulse_seq_sync;
        begin
            seq_sync_pulse = 1'b1;
            @(posedge clk);
            #1;
            seq_sync_pulse = 1'b0;
        end
    endtask

    task run_seq_mask;
        input [7:0] mask_value;
        integer slot_loop;
        begin
            seq_active_slot = mask_value;
            seq_halt_mask = 8'd0;
            seq_cfg_enable = 1'b1;
            seq_cmd_ready = 1'b1;
            accept_count = 0;
            pulse_seq_sync();

            for (slot_loop = 0; slot_loop < 8; slot_loop = slot_loop + 1) begin
                seq_slot_match = (8'b0000_0001 << slot_loop);
                @(posedge clk);
                #1;
                seq_slot_match = 8'd0;

                if (mask_value[slot_loop] == 1'b1) begin
                    check_bit(seq_cmd_valid, 1'b1, "sequencer cmd valid");
                    if (seq_cmd_slot_id !== slot_loop[2:0]) begin
                        $display("FAIL sequencer slot actual=%0d expected=%0d time=%0t",
                                 seq_cmd_slot_id, slot_loop, $time);
                        error_count = error_count + 1;
                    end
                    seq_cmd_accept = 1'b1;
                    @(posedge clk);
                    #1;
                    seq_cmd_accept = 1'b0;
                    accept_count = accept_count + 1;
                    seq_tx_done = 1'b1;
                    @(posedge clk);
                    #1;
                    seq_tx_done = 1'b0;
                    @(posedge clk);
                    #1;
                end else begin
                    check_bit(seq_cmd_valid, 1'b0, "inactive slot no cmd");
                    @(posedge clk);
                    #1;
                end
            end

            repeat (3) @(posedge clk);
            #1;
            if (accept_count != popcount8(mask_value)) begin
                $display("FAIL sequencer count mask=%h actual=%0d expected=%0d time=%0t",
                         mask_value, accept_count, popcount8(mask_value), $time);
                error_count = error_count + 1;
            end
        end
    endtask

    task test_slot_sequencer_full_masks;
        begin
            $display("TEST slot sequencer active-slot full masks");
            for (mask_index = 0; mask_index < 256; mask_index = mask_index + 1) begin
                run_seq_mask(mask_index[7:0]);
            end
        end
    endtask

    task test_slot_sequencer_skip_and_overlap;
        integer skip_slot_index;
        begin
            $display("TEST slot sequencer skip and overlap");
            seq_active_slot = 8'b0100_0000;
            seq_halt_mask = 8'd0;
            seq_cfg_enable = 1'b1;
            seq_cmd_ready = 1'b1;
            pulse_seq_sync();

            for (skip_slot_index = 0; skip_slot_index < 6; skip_slot_index = skip_slot_index + 1) begin
                seq_slot_match = (8'b0000_0001 << skip_slot_index);
                @(posedge clk);
                #1;
                seq_slot_match = 8'd0;
                check_bit(seq_cmd_valid, 1'b0, "skip setup inactive slot no cmd");
                @(posedge clk);
                #1;
            end

            seq_slot_match = 8'b0100_0000;
            @(posedge clk);
            #1;
            seq_slot_match = 8'd0;
            check_bit(seq_cmd_valid, 1'b1, "sequencer skip cmd valid");
            seq_cmd_skip = 1'b1;
            @(posedge clk);
            #1;
            seq_cmd_skip = 1'b0;
            check_bit(seq_skip_invalid_payload, 1'b1, "sequencer skip pulse");

            reset_dut();
            seq_active_slot = 8'b0000_0001;
            seq_cfg_enable = 1'b1;
            seq_cmd_ready = 1'b0;
            pulse_seq_sync();
            seq_slot_match = 8'b0000_0001;
            @(posedge clk);
            #1;
            seq_slot_match = 8'd0;
            repeat (2) @(posedge clk);
            #1;
            check_bit(seq_fault_tx_overlap, 1'b1, "sequencer blocked fault");
            seq_cmd_ready = 1'b1;
            seq_cmd_accept = 1'b1;
            @(posedge clk);
            #1;
            seq_cmd_accept = 1'b0;
            seq_tx_done = 1'b1;
            @(posedge clk);
            #1;
            seq_tx_done = 1'b0;
        end
    endtask

    initial begin
        error_count = 0;
        reset_dut();

        test_payload_and_frame_builder();
        test_serializer(50'b1010_1010_1100_0011_0101_0110_1111_0000_0001_0010_0011_0101_01, 32'd0);
        test_serializer(50'b0101_0101_0011_1100_1010_1001_0000_1111_1110_1101_1100_1010_10, 32'd2);
        test_slot_sequencer_full_masks();
        reset_dut();
        test_slot_sequencer_skip_and_overlap();

        if (error_count == 0) begin
            $display("PASS tb_slave_tx_path");
        end else begin
            $display("FAIL tb_slave_tx_path error_count=%0d", error_count);
        end
        $finish;
    end

endmodule
