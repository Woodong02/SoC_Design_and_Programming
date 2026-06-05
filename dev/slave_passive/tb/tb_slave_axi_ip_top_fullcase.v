`timescale 1ns / 1ps

module tb_slave_axi_ip_top_fullcase;

    localparam [5:0] ADDR_CTRL      = 6'h00;
    localparam [5:0] ADDR_DIV       = 6'h04;
    localparam [5:0] ADDR_DATA_OUT0 = 6'h08;
    localparam [5:0] ADDR_DATA_OUT1 = 6'h0C;
    localparam [5:0] ADDR_DATA_OUT2 = 6'h10;
    localparam [5:0] ADDR_DATA_OUT3 = 6'h14;
    localparam [5:0] ADDR_DATA_OUT4 = 6'h18;
    localparam [5:0] ADDR_DATA_OUT5 = 6'h1C;
    localparam [5:0] ADDR_EVENT     = 6'h24;
    localparam [5:0] ADDR_FAULT     = 6'h28;

    localparam [31:0] DIV_FAST      = 32'd0;
    localparam [9:0]  GUARD_FAST    = 10'd4;
    localparam integer BIT_TICKS    = 1;
    localparam integer FRAME_TICKS  = 50;
    localparam integer SLOT_TICKS   = 54;
    localparam integer GUARD_HALF   = 2;
    localparam integer TX_LAT_MIN   = 1;
    localparam integer TX_LAT_MAX   = 8;
    localparam integer MONITOR_TICKS = 540;
    localparam integer MAX_ERROR_PRINTS = 64;

    reg         clk;
    reg         resetn;
    reg  [5:0]  awaddr;
    reg         awvalid;
    wire        awready;
    reg  [31:0] wdata;
    reg  [3:0]  wstrb;
    reg         wvalid;
    wire        wready;
    wire [1:0]  bresp;
    wire        bvalid;
    reg         bready;
    reg  [5:0]  araddr;
    reg         arvalid;
    wire        arready;
    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rvalid;
    reg         rready;
    reg         master_serial;
    reg  [31:0] pl_payload6;
    reg         pl_payload6_valid;
    reg  [31:0] pl_payload7;
    reg         pl_payload7_valid;
    wire        slave_serial;
    wire        slave_oe;
    wire        irq;

    reg  [34:0] master_encoder_data;
    wire [41:0] master_codeword;
    reg  [34:0] expected_encoder_data;
    wire [41:0] expected_codeword;
    reg  [49:0] master_frame;
    reg  [49:0] expected_frame;

    reg  [31:0] payload0;
    reg  [31:0] payload1;
    reg  [31:0] payload2;
    reg  [31:0] payload3;
    reg  [31:0] payload4;
    reg  [31:0] payload5;
    reg  [49:0] captured_frame [0:15];
    reg  [7:0]  captured_slot_seen;
    reg         oe_seen [0:MONITOR_TICKS-1];
    integer     captured_start_tick [0:15];
    integer     captured_count;
    integer     errors;
    integer     active_mask_index;
    integer     slot_index;
    integer     bit_index;
    integer     monitor_tick;
    integer     frame_index;
    integer     expected_target_tick;
    integer     window_start_tick;
    integer     window_stop_tick;
    integer     detected_frame_index;
    integer     adjusted_start_tick;
    integer     expected_capture_count;
    integer     read_value;
    integer     error_prints;

    slave_axi_ip_top u_slave_axi_ip_top (
        .i_clk(clk),
        .i_resetn(resetn),
        .i_s_axi_awaddr(awaddr),
        .i_s_axi_awvalid(awvalid),
        .o_s_axi_awready(awready),
        .i_s_axi_wdata(wdata),
        .i_s_axi_wstrb(wstrb),
        .i_s_axi_wvalid(wvalid),
        .o_s_axi_wready(wready),
        .o_s_axi_bresp(bresp),
        .o_s_axi_bvalid(bvalid),
        .i_s_axi_bready(bready),
        .i_s_axi_araddr(araddr),
        .i_s_axi_arvalid(arvalid),
        .o_s_axi_arready(arready),
        .o_s_axi_rdata(rdata),
        .o_s_axi_rresp(rresp),
        .o_s_axi_rvalid(rvalid),
        .i_s_axi_rready(rready),
        .i_master_serial(master_serial),
        .i_pl_payload6(pl_payload6),
        .i_pl_payload6_valid(pl_payload6_valid),
        .i_pl_payload7(pl_payload7),
        .i_pl_payload7_valid(pl_payload7_valid),
        .o_slave_serial(slave_serial),
        .o_slave_oe(slave_oe),
        .o_irq(irq)
    );

    slave_hamming_enc u_master_hamming_enc (
        .i_DATA(master_encoder_data),
        .o_CODEWORD(master_codeword)
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

    function [31:0] expected_payload;
        input [2:0] slot_id;
        begin
            case (slot_id)
                3'd0: expected_payload = payload0;
                3'd1: expected_payload = payload1;
                3'd2: expected_payload = payload2;
                3'd3: expected_payload = payload3;
                3'd4: expected_payload = payload4;
                3'd5: expected_payload = payload5;
                3'd6: expected_payload = pl_payload6;
                3'd7: expected_payload = pl_payload7;
                default: expected_payload = 32'd0;
            endcase
        end
    endfunction

    function integer expected_target;
        input integer slot_id;
        begin
            expected_target = FRAME_TICKS + (slot_id * SLOT_TICKS) + GUARD_HALF;
        end
    endfunction

    task check32;
        input [255:0] label_text;
        input [31:0] actual;
        input [31:0] expected;
        begin
            if (actual !== expected) begin
                if (error_prints < MAX_ERROR_PRINTS) begin
                    $display("FAIL %0s actual=%h expected=%h time=%0t",
                             label_text, actual, expected, $time);
                end
                error_prints = error_prints + 1;
                errors = errors + 1;
            end
        end
    endtask

    task check50;
        input [255:0] label_text;
        input [49:0] actual;
        input [49:0] expected;
        input integer mask_value;
        input integer slot_id;
        begin
            if (actual !== expected) begin
                if (error_prints < MAX_ERROR_PRINTS) begin
                    $display("FAIL %0s mask=%02h slot=%0d actual=%h expected=%h time=%0t",
                             label_text, mask_value[7:0], slot_id, actual, expected, $time);
                end
                error_prints = error_prints + 1;
                errors = errors + 1;
            end
        end
    endtask

    task axi_write;
        input [5:0]  addr;
        input [31:0] data;
        begin
            @(negedge clk);
            awaddr = addr;
            wdata = data;
            wstrb = 4'hF;
            awvalid = 1'b1;
            wvalid = 1'b1;
            bready = 1'b1;
            wait (awready && wready);
            @(negedge clk);
            awvalid = 1'b0;
            wvalid = 1'b0;
            wait (bvalid);
            @(negedge clk);
            bready = 1'b0;
        end
    endtask

    task axi_read;
        input [5:0] addr;
        output [31:0] data;
        begin
            @(negedge clk);
            araddr = addr;
            arvalid = 1'b1;
            rready = 1'b1;
            wait (arready);
            @(negedge clk);
            arvalid = 1'b0;
            wait (rvalid);
            data = rdata;
            @(negedge clk);
            rready = 1'b0;
        end
    endtask

    task clear_event_fault;
        begin
            axi_write(ADDR_EVENT, 32'h0000_00FF);
            axi_write(ADDR_FAULT, 32'h0000_001F);
            repeat (2) @(posedge clk);
        end
    endtask

    task configure_slave;
        input [7:0] active_slot_mask;
        begin
            axi_write(ADDR_CTRL, 32'd0);
            repeat (8) @(posedge clk);
            axi_write(ADDR_DIV, DIV_FAST);
            axi_write(ADDR_DATA_OUT0, payload0);
            axi_write(ADDR_DATA_OUT1, payload1);
            axi_write(ADDR_DATA_OUT2, payload2);
            axi_write(ADDR_DATA_OUT3, payload3);
            axi_write(ADDR_DATA_OUT4, payload4);
            axi_write(ADDR_DATA_OUT5, payload5);
            axi_write(ADDR_CTRL, 32'd1 | ({22'd0, GUARD_FAST} << 1) |
                                 ({24'd0, active_slot_mask} << 11));
            repeat (10) @(posedge clk);
        end
    endtask

    task configure_slave_guard;
        input [7:0] active_slot_mask;
        input [9:0] guard_ticks;
        begin
            axi_write(ADDR_CTRL, 32'd0);
            repeat (8) @(posedge clk);
            axi_write(ADDR_DIV, DIV_FAST);
            axi_write(ADDR_DATA_OUT0, payload0);
            axi_write(ADDR_DATA_OUT1, payload1);
            axi_write(ADDR_DATA_OUT2, payload2);
            axi_write(ADDR_DATA_OUT3, payload3);
            axi_write(ADDR_DATA_OUT4, payload4);
            axi_write(ADDR_DATA_OUT5, payload5);
            axi_write(ADDR_CTRL, 32'd1 | ({22'd0, guard_ticks} << 1) |
                                 ({24'd0, active_slot_mask} << 11));
            repeat (10) @(posedge clk);
        end
    endtask

    task send_master_frame;
        input [49:0] frame_value;
        integer send_index;
        begin
            @(negedge clk);
            for (send_index = 0; send_index < 50; send_index = send_index + 1) begin
                master_serial = frame_value[49 - send_index];
                @(negedge clk);
            end
            master_serial = 1'b0;
        end
    endtask

    task init_monitor_storage;
        integer init_index;
        begin
            captured_count = 0;
            captured_slot_seen = 8'd0;
            for (init_index = 0; init_index < MONITOR_TICKS; init_index = init_index + 1) begin
                oe_seen[init_index] = 1'b0;
            end
            for (init_index = 0; init_index < 16; init_index = init_index + 1) begin
                captured_frame[init_index] = 50'd0;
                captured_start_tick[init_index] = -1;
            end
        end
    endtask

    task monitor_slave_cycle;
        integer wait_index;
        integer capture_index;
        integer capture_slot;
        reg [49:0] capture_shift;
        begin
            init_monitor_storage();
            wait_index = 0;
            while ((u_slave_axi_ip_top.u_slave_ip_top.sync_pulse !== 1'b1) && (wait_index < 80)) begin
                @(posedge clk);
                #1;
                wait_index = wait_index + 1;
            end

            if (u_slave_axi_ip_top.u_slave_ip_top.sync_pulse !== 1'b1) begin
                if (error_prints < MAX_ERROR_PRINTS) begin
                    $display("FAIL sync pulse timeout time=%0t", $time);
                end
                error_prints = error_prints + 1;
                errors = errors + 1;
            end

            monitor_tick = 0;
            while (monitor_tick < MONITOR_TICKS) begin
                @(posedge clk);
                #1;
                oe_seen[monitor_tick] = slave_oe;

                if ((slave_oe == 1'b1) && (captured_count < 16)) begin
                    captured_start_tick[captured_count] = monitor_tick;
                    capture_shift = 50'd0;
                    for (capture_index = 0; capture_index < 50; capture_index = capture_index + 1) begin
                        @(negedge clk);
                        capture_shift = {capture_shift[48:0], slave_serial};
                        @(posedge clk);
                        #1;
                        if ((monitor_tick + capture_index) < MONITOR_TICKS) begin
                            oe_seen[monitor_tick + capture_index] = slave_oe;
                        end
                    end
                    captured_frame[captured_count] = capture_shift;
                    capture_slot = ((captured_start_tick[captured_count] - FRAME_TICKS) +
                                    (SLOT_TICKS / 2)) / SLOT_TICKS;
                    if ((capture_slot >= 0) && (capture_slot < 8)) begin
                        captured_slot_seen[capture_slot] = 1'b1;
                    end
                    captured_count = captured_count + 1;
                    monitor_tick = monitor_tick + 50;
                end else begin
                    monitor_tick = monitor_tick + 1;
                end
            end
        end
    endtask

    task monitor_no_tx_window;
        begin
            init_monitor_storage();
            monitor_tick = 0;
            while (monitor_tick < MONITOR_TICKS) begin
                @(posedge clk);
                #1;
                oe_seen[monitor_tick] = slave_oe;
                if ((slave_oe == 1'b1) && (captured_count < 16)) begin
                    captured_start_tick[captured_count] = monitor_tick;
                    captured_count = captured_count + 1;
                end
                monitor_tick = monitor_tick + 1;
            end
        end
    endtask

    task build_master_frame;
        begin
            master_encoder_data = {8'h00, GUARD_FAST, 17'd0};
            #1;
            master_frame = {8'hAA, master_codeword};
        end
    endtask

    task build_expected_frame;
        input [2:0] slot_id;
        begin
            expected_encoder_data = {slot_id, expected_payload(slot_id)};
            #1;
            expected_frame = {8'hAA, expected_codeword};
        end
    endtask

    task check_slot_inactive_window;
        input integer mask_value;
        input integer slot_id;
        integer inactive_frame_index;
        begin
            build_expected_frame(slot_id[2:0]);
            for (inactive_frame_index = 0;
                 inactive_frame_index < captured_count;
                 inactive_frame_index = inactive_frame_index + 1) begin
                if (captured_frame[inactive_frame_index] === expected_frame) begin
                    if (error_prints < MAX_ERROR_PRINTS) begin
                        $display("FAIL inactive slot frame mask=%02h slot=%0d start=%0d frame=%h time=%0t",
                                 mask_value[7:0], slot_id,
                                 captured_start_tick[inactive_frame_index],
                                 captured_frame[inactive_frame_index], $time);
                    end
                    error_prints = error_prints + 1;
                    errors = errors + 1;
                    inactive_frame_index = captured_count;
                end
            end
        end
    endtask

    task check_slot_active_frame;
        input integer mask_value;
        input integer slot_id;
        begin
            expected_target_tick = expected_target(slot_id);
            window_start_tick = expected_target_tick + TX_LAT_MIN;
            window_stop_tick = expected_target_tick + TX_LAT_MAX;
            detected_frame_index = -1;
            build_expected_frame(slot_id[2:0]);

            for (frame_index = 0; frame_index < captured_count; frame_index = frame_index + 1) begin
                adjusted_start_tick = captured_start_tick[frame_index] + frame_index;
                if ((captured_frame[frame_index] === expected_frame) &&
                    (adjusted_start_tick >= window_start_tick) &&
                    (adjusted_start_tick <= window_stop_tick)) begin
                    detected_frame_index = frame_index;
                end
            end

            if (detected_frame_index < 0) begin
                if (error_prints < MAX_ERROR_PRINTS) begin
                    $display("FAIL active slot frame missing mask=%02h slot=%0d target=%0d window=%0d..%0d captures=%0d time=%0t",
                             mask_value[7:0], slot_id, expected_target_tick,
                             window_start_tick, window_stop_tick, captured_count, $time);
                end
                error_prints = error_prints + 1;
                errors = errors + 1;
            end else begin
                check50("active slot frame", captured_frame[detected_frame_index],
                        expected_frame, mask_value, slot_id);
            end
        end
    endtask

    task analyze_active_mask;
        input [7:0] active_slot_mask;
        begin
            expected_capture_count = 0;
            for (slot_index = 0; slot_index < 8; slot_index = slot_index + 1) begin
                if (active_slot_mask[slot_index] == 1'b1) begin
                    expected_capture_count = expected_capture_count + 1;
                    check_slot_active_frame(active_slot_mask, slot_index);
                end else begin
                    check_slot_inactive_window(active_slot_mask, slot_index);
                end
            end
            if (captured_count != expected_capture_count) begin
                if (error_prints < MAX_ERROR_PRINTS) begin
                    $display("FAIL capture count mask=%02h actual=%0d expected=%0d time=%0t",
                             active_slot_mask, captured_count,
                             expected_capture_count, $time);
                end
                error_prints = error_prints + 1;
                errors = errors + 1;
            end
        end
    endtask

    task run_active_mask_case;
        input [7:0] active_slot_mask;
        begin
            clear_event_fault();
            configure_slave(active_slot_mask);
            build_master_frame();
            fork
                send_master_frame(master_frame);
                monitor_slave_cycle();
            join
            analyze_active_mask(active_slot_mask);
            repeat (8) @(posedge clk);
        end
    endtask

    task run_pl_invalid_case;
        input [7:0] active_slot_mask;
        input       valid6;
        input       valid7;
        input [31:0] expected_fault_mask;
        begin
            clear_event_fault();
            pl_payload6_valid = valid6;
            pl_payload7_valid = valid7;
            configure_slave(active_slot_mask);
            build_master_frame();
            fork
                send_master_frame(master_frame);
                monitor_slave_cycle();
            join
            analyze_active_mask(active_slot_mask & {valid7, valid6, 6'b11_1111});
            repeat (8) @(posedge clk);
            axi_read(ADDR_FAULT, read_value);
            check32("PL invalid fault", read_value & expected_fault_mask, expected_fault_mask);
            axi_read(ADDR_EVENT, read_value);
            check32("PL invalid slot cycle done", read_value & 32'h0000_0008, 32'h0000_0008);
            pl_payload6_valid = 1'b1;
            pl_payload7_valid = 1'b1;
        end
    endtask

    task run_guard_invalid_case;
        begin
            clear_event_fault();
            configure_slave_guard(8'h01, 10'd0);
            build_master_frame();
            fork
                send_master_frame(master_frame);
                monitor_no_tx_window();
            join
            if (captured_count != 0) begin
                if (error_prints < MAX_ERROR_PRINTS) begin
                    $display("FAIL guard invalid produced TX captures=%0d time=%0t",
                             captured_count, $time);
                end
                error_prints = error_prints + 1;
                errors = errors + 1;
            end
            repeat (8) @(posedge clk);
            axi_read(ADDR_FAULT, read_value);
            check32("guard invalid fault", read_value & 32'h0000_0002, 32'h0000_0002);
        end
    endtask

    initial begin
        errors = 0;
        error_prints = 0;
        resetn = 1'b0;
        awaddr = 6'd0;
        awvalid = 1'b0;
        wdata = 32'd0;
        wstrb = 4'd0;
        wvalid = 1'b0;
        bready = 1'b0;
        araddr = 6'd0;
        arvalid = 1'b0;
        rready = 1'b0;
        master_serial = 1'b0;
        payload0 = 32'h1000_0000;
        payload1 = 32'h2111_0001;
        payload2 = 32'h3222_0002;
        payload3 = 32'h4333_0003;
        payload4 = 32'h5444_0004;
        payload5 = 32'h6555_0005;
        pl_payload6 = 32'h7666_0006;
        pl_payload6_valid = 1'b1;
        pl_payload7 = 32'h8777_0007;
        pl_payload7_valid = 1'b1;
        master_encoder_data = 35'd0;
        expected_encoder_data = 35'd0;
        master_frame = 50'd0;
        expected_frame = 50'd0;

        repeat (5) @(negedge clk);
        resetn = 1'b1;
        repeat (5) @(negedge clk);

        for (active_mask_index = 0; active_mask_index < 256; active_mask_index = active_mask_index + 1) begin
            run_active_mask_case(active_mask_index[7:0]);
        end

        run_pl_invalid_case(8'b0100_0000, 1'b0, 1'b1, 32'h0000_0004);
        run_pl_invalid_case(8'b1000_0000, 1'b1, 1'b0, 32'h0000_0008);
        run_pl_invalid_case(8'b1100_0000, 1'b0, 1'b0, 32'h0000_000C);
        run_guard_invalid_case();

        if (errors == 0) begin
            $display("PASS tb_slave_axi_ip_top_fullcase");
        end else begin
            $display("FAIL tb_slave_axi_ip_top_fullcase errors=%0d", errors);
        end
        $finish;
    end

endmodule
