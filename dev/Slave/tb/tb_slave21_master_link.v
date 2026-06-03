`timescale 1ns / 1ps

module tb_slave21_master_link;

    localparam [2:0]  TB_NODE_ID = 3'd1;
    localparam [2:0]  TB_NODE_CNT = 3'd1;
    localparam [9:0]  TB_DIV = 10'd16;
    localparam [15:0] TB_BIT_PERIOD = 16'd16;
    localparam [9:0]  TB_GUARD_TICKS = 10'd20;
    localparam integer TB_FRAME_BITS = 50;
    localparam integer TB_FRAME_TICKS = 50 * 16;
    localparam integer TB_SLOT_TICKS = (50 * 16) + 20;
    localparam integer TB_CYCLE_TICKS = 2 * ((50 * 16) + 20);
    localparam integer TB_RESPONSE_TIMEOUT = 50000;

    reg         clk;
    reg         resetn;
    reg         master_tx_trigger;
    reg  [7:0]  master_halt_cmd;
    reg  [9:0]  master_guard_ticks;
    reg  [31:0] slave_payload;
    reg         corrupt_broadcast_active;
    reg         master_rx_slot_pre_change;

    wire        master_tx_serial_raw;
    wire        master_to_slave_serial;
    wire        slave_to_master_serial;
    wire        slave_link_tracking;
    wire        slave_halted;
    wire        slave_rate_err;
    wire [2:0]  slave_fault_state;
    wire [9:0]  slave_latched_guard_ticks;
    wire [41:0] master_rx_codeword;
    wire        master_rx_valid;
    wire        master_rx_preamble_err;
    wire [34:0] master_decoded_data;
    wire        master_ham_1bit_err;
    wire        master_ham_2bit_err;

    integer fail_count;
    integer wait_count;
    integer valid_count;
    integer bit_index;
    integer monitor_slot;
    integer monitor_slot_clk_cnt;
    integer monitor_rx_stat;
    integer last_valid_slot;
    integer last_valid_slot_clk_cnt;
    integer last_valid_rx_stat;
    integer cycle_count;
    integer last_broadcast_cycle;

    Master_tx u_master_tx (
        .clk(clk),
        .resetn(resetn),
        .tx_trigger(master_tx_trigger),
        .halt_cmd(master_halt_cmd),
        .GUARD_TICKS(master_guard_ticks),
        .DIV(TB_DIV),
        .GPIO_out(master_tx_serial_raw)
    );

    assign master_to_slave_serial = (corrupt_broadcast_active == 1'b1) ?
                                    ~master_tx_serial_raw : master_tx_serial_raw;

    slave21_top #(
        .NODE_ID(TB_NODE_ID),
        .NODE_CNT(TB_NODE_CNT),
        .BIT_PERIOD_DEFAULT(TB_BIT_PERIOD),
        .GUARD_TICKS_DEFAULT(TB_GUARD_TICKS)
    ) u_slave21_top (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_MASTER_SERIAL(master_to_slave_serial),
        .i_PAYLOAD(slave_payload),
        .o_SLAVE_SERIAL(slave_to_master_serial),
        .o_LINK_TRACKING(slave_link_tracking),
        .o_HALTED(slave_halted),
        .o_RATE_ERR(slave_rate_err),
        .o_FAULT_STATE(slave_fault_state),
        .o_LATCHED_GUARD_TICKS(slave_latched_guard_ticks)
    );

    Master_rx u_master_rx (
        .clk(clk),
        .DIV(TB_DIV),
        .GPIO_in(slave_to_master_serial),
        .resetn(resetn),
        .slot_pre_change(master_rx_slot_pre_change),
        .data_out(master_rx_codeword),
        .out_sig(master_rx_valid),
        .preamble_err(master_rx_preamble_err)
    );

    hamming_dec u_master_hamming_dec (
        .codeword(master_rx_codeword),
        .data(master_decoded_data),
        .ham_1bit_err(master_ham_1bit_err),
        .ham_2bit_err(master_ham_2bit_err)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            cycle_count <= 0;
        end else begin
            cycle_count <= cycle_count + 1;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            monitor_slot <= 0;
        end else if (master_tx_trigger == 1'b1) begin
            monitor_slot <= 0;
        end else if (monitor_slot_clk_cnt >= (TB_SLOT_TICKS - 1)) begin
            if (monitor_slot >= TB_NODE_CNT) begin
                monitor_slot <= 0;
            end else begin
                monitor_slot <= monitor_slot + 1;
            end
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            monitor_slot_clk_cnt <= 0;
        end else if (master_tx_trigger == 1'b1) begin
            monitor_slot_clk_cnt <= 0;
        end else if (monitor_slot_clk_cnt >= (TB_SLOT_TICKS - 1)) begin
            monitor_slot_clk_cnt <= 0;
        end else begin
            monitor_slot_clk_cnt <= monitor_slot_clk_cnt + 1;
        end
    end

    always @(*) begin
        if (monitor_slot_clk_cnt < TB_FRAME_TICKS) begin
            monitor_rx_stat = 2;
        end else if ((monitor_slot_clk_cnt >= (TB_FRAME_TICKS + (TB_GUARD_TICKS / 4))) &&
                     (monitor_slot_clk_cnt < (TB_SLOT_TICKS - (TB_GUARD_TICKS / 4)))) begin
            monitor_rx_stat = 0;
        end else begin
            monitor_rx_stat = 1;
        end
    end

    always @(*) begin
        master_rx_slot_pre_change = (monitor_slot_clk_cnt >= (TB_SLOT_TICKS - 1)) ? 1'b1 : 1'b0;
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            valid_count <= 0;
            last_valid_slot <= 0;
            last_valid_slot_clk_cnt <= 0;
            last_valid_rx_stat <= 0;
        end else if (master_rx_valid == 1'b1) begin
            valid_count <= valid_count + 1;
            last_valid_slot <= monitor_slot;
            last_valid_slot_clk_cnt <= monitor_slot_clk_cnt;
            last_valid_rx_stat <= monitor_rx_stat;
            $display("[INFO] Master_rx valid slot=%0d cnt=%0d rx_stat=%0d node=%0d payload=0x%08x time=%0t",
                     monitor_slot, monitor_slot_clk_cnt, monitor_rx_stat,
                     master_decoded_data[34:32], master_decoded_data[31:0], $time);
        end
    end

    task expect_value;
        input [511:0] label;
        input [31:0] got;
        input [31:0] exp;
        begin
            if (got !== exp) begin
                fail_count = fail_count + 1;
                $display("[FAIL] %0s got=0x%08x exp=0x%08x time=%0t", label, got, exp, $time);
            end else begin
                $display("[PASS] %0s got=0x%08x time=%0t", label, got, $time);
            end
        end
    endtask

    task wait_cycles;
        input integer cycle_count;
        begin
            for (bit_index = 0; bit_index < cycle_count; bit_index = bit_index + 1) begin
                @(posedge clk);
            end
        end
    endtask

    task pulse_master_broadcast;
        input [7:0] halt_cmd;
        input       corrupt_frame;
        begin
            master_halt_cmd = halt_cmd;
            master_guard_ticks = TB_GUARD_TICKS;
            @(negedge clk);
            last_broadcast_cycle = cycle_count;
            master_tx_trigger = 1'b1;
            corrupt_broadcast_active = corrupt_frame;
            @(negedge clk);
            master_tx_trigger = 1'b0;
            $display("[PHASE] Master_tx broadcast halt=0x%02x corrupt=%0d time=%0t",
                     halt_cmd, corrupt_frame, $time);
            wait_cycles(TB_FRAME_TICKS);
            corrupt_broadcast_active = 1'b0;
        end
    endtask

    task wait_to_next_broadcast_start;
        begin
            while ((cycle_count - last_broadcast_cycle) < TB_CYCLE_TICKS) begin
                @(posedge clk);
            end
        end
    endtask

    task finish_cycle_expect_no_response;
        input [511:0] label;
        input integer start_count;
        begin
            wait_to_next_broadcast_start();
            expect_value(label, valid_count[31:0], start_count[31:0]);
        end
    endtask

    task expect_no_master_response;
        input [511:0] label;
        input integer cycle_count;
        integer start_count;
        begin
            start_count = valid_count;
            wait_cycles(cycle_count);
            expect_value(label, valid_count[31:0], start_count[31:0]);
        end
    endtask

    task wait_for_master_response;
        input [511:0] label;
        input [31:0] expected_payload;
        integer start_count;
        begin
            start_count = valid_count;
            wait_count = 0;
            while ((valid_count == start_count) && (wait_count < TB_RESPONSE_TIMEOUT)) begin
                wait_count = wait_count + 1;
                @(posedge clk);
            end

            if (wait_count >= TB_RESPONSE_TIMEOUT) begin
                fail_count = fail_count + 1;
                $display("[FAIL] %0s timeout time=%0t", label, $time);
            end else begin
                #1;
                expect_value({label, " node id"}, {29'd0, master_decoded_data[34:32]}, {29'd0, TB_NODE_ID});
                expect_value({label, " payload"}, master_decoded_data[31:0], expected_payload);
                expect_value({label, " no 2bit hamming"}, {31'd0, master_ham_2bit_err}, 32'd0);
                expect_value({label, " no preamble error"}, {31'd0, master_rx_preamble_err}, 32'd0);
                expect_value({label, " monitor slot"}, last_valid_slot[31:0], {29'd0, TB_NODE_ID});
                expect_value({label, " normal rx_stat"}, last_valid_rx_stat[31:0], 32'd0);
            end
        end
    endtask

    initial begin
        fail_count = 0;
        wait_count = 0;
        cycle_count = 0;
        last_broadcast_cycle = 0;
        master_tx_trigger = 1'b0;
        master_halt_cmd = 8'd0;
        master_guard_ticks = TB_GUARD_TICKS;
        slave_payload = 32'h13572468;
        corrupt_broadcast_active = 1'b0;
        resetn = 1'b0;

        $display("[INFO] tb_slave21_master_link start");
        wait_cycles(10);
        resetn = 1'b1;
        wait_cycles(20);

        wait_count = valid_count;
        pulse_master_broadcast(8'h00, 1'b0);
        expect_value("first good no tracking", {31'd0, slave_link_tracking}, 32'd0);
        expect_value("first good guard latch", {22'd0, slave_latched_guard_ticks}, {22'd0, TB_GUARD_TICKS});
        finish_cycle_expect_no_response("first good slave stays silent", wait_count);

        slave_payload = 32'hcafef00d;
        pulse_master_broadcast(8'h00, 1'b0);
        expect_value("second good tracking", {31'd0, slave_link_tracking}, 32'd1);
        expect_value("second good not halted", {31'd0, slave_halted}, 32'd0);
        wait_for_master_response("second good response", 32'hcafef00d);
        wait_to_next_broadcast_start();

        wait_count = valid_count;
        pulse_master_broadcast(8'h02, 1'b0);
        expect_value("halt command latches halted", {31'd0, slave_halted}, 32'd1);
        finish_cycle_expect_no_response("halt command causes silence", wait_count);

        resetn = 1'b0;
        corrupt_broadcast_active = 1'b0;
        master_tx_trigger = 1'b0;
        wait_cycles(10);
        resetn = 1'b1;
        wait_cycles(20);

        slave_payload = 32'h0badcafe;
        wait_count = valid_count;
        pulse_master_broadcast(8'h00, 1'b1);
        finish_cycle_expect_no_response("bad first broadcast causes silence", wait_count);

        wait_count = valid_count;
        pulse_master_broadcast(8'h00, 1'b0);
        expect_value("recovery first good not tracking", {31'd0, slave_link_tracking}, 32'd0);
        finish_cycle_expect_no_response("recovery first good still silent", wait_count);

        pulse_master_broadcast(8'h00, 1'b0);
        expect_value("recovery second good tracking", {31'd0, slave_link_tracking}, 32'd1);
        wait_for_master_response("recovery second good response", 32'h0badcafe);
        wait_to_next_broadcast_start();

        if (fail_count == 0) begin
            $display("PASS: tb_slave21_master_link");
        end else begin
            $display("FAIL: tb_slave21_master_link fail_count=%0d", fail_count);
        end

        $finish;
    end

endmodule
