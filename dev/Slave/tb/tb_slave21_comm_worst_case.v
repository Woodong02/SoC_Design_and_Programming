`timescale 1ns / 1ps

module tb_slave21_master_harsh_link;

    parameter [2:0]  TB_NODE_ID = 3'd1;
    parameter [2:0]  TB_NODE_CNT = 3'd1;
    parameter [15:0] TB_BIT_PERIOD = 16'd16;
    parameter [9:0]  TB_GUARD_TICKS = 10'd20;
    parameter [31:0] TB_FRAME_BITS = 32'd50;
    parameter [31:0] TB_FRAME_TICKS = TB_FRAME_BITS * {16'd0, TB_BIT_PERIOD};
    parameter [31:0] TB_SLOT_TICKS = TB_FRAME_TICKS + {22'd0, TB_GUARD_TICKS};
    parameter [31:0] TB_MASTER_INTERVAL = ({29'd0, TB_NODE_CNT} + 32'd1) * TB_SLOT_TICKS;
    parameter [31:0] TB_RESPONSE_TIMEOUT = 32'd20000;
    parameter [31:0] TB_NO_TX_OBSERVE = 32'd200;

    reg         master_clk;
    reg         slave_clk;
    reg         resetn;
    reg         master_serial_raw;
    reg         master_serial_line;
    reg  [31:0] slave_payload;

    wire        slave_serial_raw;
    reg         slave_serial_line;
    wire        link_tracking;
    wire        halted;
    wire        rate_err;
    wire [2:0]  fault_state;
    wire [9:0]  latched_guard_ticks;

    reg  [34:0] master_data;
    wire [41:0] master_codeword;
    wire [41:0] master_rx_codeword;
    wire        master_rx_valid;
    wire        master_rx_preamble_err;
    wire [34:0] master_decoded_data;
    wire        master_ham_1bit_err;
    wire        master_ham_2bit_err;

    reg        arm_epoch;
    reg        epoch_locked;
    reg [2:0]  monitor_slot;
    reg [15:0] monitor_clk_cnt;
    reg        master_rx_slot_pre_change;

    real master_half_ns;
    real slave_half_ns;
    real m2s_base_delay_ns;
    real s2m_base_delay_ns;
    real m2s_jitter_ns;
    real s2m_jitter_ns;
    real selected_delay_ns;

    integer m2s_transition_count;
    integer s2m_transition_count;
    integer fail_count;
    integer must_pass_fail_count;
    integer scenario_count;
    integer master_valid_count;
    integer wait_count;
    integer bit_index;
    integer cycle_index;
    integer saw_tx_high;

    reg [31:0] last_payload;
    reg [2:0]  last_node_id;
    reg        last_2bit_err;
    reg        last_preamble_err;
    reg [2:0]  last_valid_slot;
    reg [15:0] last_valid_clk_cnt;

    slave_hamming_enc u_master_enc (
        .i_DATA(master_data),
        .o_CODEWORD(master_codeword)
    );

    slave21_top #(
        .NODE_ID(TB_NODE_ID),
        .NODE_CNT(TB_NODE_CNT),
        .BIT_PERIOD_DEFAULT(TB_BIT_PERIOD),
        .GUARD_TICKS_DEFAULT(TB_GUARD_TICKS)
    ) u_slave_top (
        .i_CLK(slave_clk),
        .i_RESETN(resetn),
        .i_MASTER_SERIAL(master_serial_line),
        .i_PAYLOAD(slave_payload),
        .o_SLAVE_SERIAL(slave_serial_raw),
        .o_LINK_TRACKING(link_tracking),
        .o_HALTED(halted),
        .o_RATE_ERR(rate_err),
        .o_FAULT_STATE(fault_state),
        .o_LATCHED_GUARD_TICKS(latched_guard_ticks)
    );

    Master_rx u_master_rx (
        .clk(master_clk),
        .DIV(TB_BIT_PERIOD[9:0]),
        .GPIO_in(slave_serial_line),
        .resetn(resetn),
        .slot_pre_change(master_rx_slot_pre_change),
        .data_out(master_rx_codeword),
        .out_sig(master_rx_valid),
        .preamble_err(master_rx_preamble_err)
    );

    hamming_dec u_master_dec (
        .codeword(master_rx_codeword),
        .data(master_decoded_data),
        .ham_1bit_err(master_ham_1bit_err),
        .ham_2bit_err(master_ham_2bit_err)
    );

    initial begin
        master_clk = 1'b0;
        master_half_ns = 5.000;
        forever begin
            #(master_half_ns) master_clk = ~master_clk;
        end
    end

    initial begin
        slave_clk = 1'b0;
        slave_half_ns = 5.000;
        forever begin
            #(slave_half_ns) slave_clk = ~slave_clk;
        end
    end

    always @(master_serial_raw) begin
        m2s_transition_count = m2s_transition_count + 1;
        selected_delay_ns = m2s_base_delay_ns;
        if ((m2s_transition_count % 3) == 0)
            selected_delay_ns = m2s_base_delay_ns + m2s_jitter_ns;
        else if ((m2s_transition_count % 3) == 1)
            selected_delay_ns = m2s_base_delay_ns - m2s_jitter_ns;
        if (selected_delay_ns < 0.0)
            selected_delay_ns = 0.0;
        master_serial_line <= #(selected_delay_ns) master_serial_raw;
    end

    always @(slave_serial_raw) begin
        s2m_transition_count = s2m_transition_count + 1;
        selected_delay_ns = s2m_base_delay_ns;
        if ((s2m_transition_count % 4) == 0)
            selected_delay_ns = s2m_base_delay_ns + s2m_jitter_ns;
        else if ((s2m_transition_count % 4) == 1)
            selected_delay_ns = s2m_base_delay_ns - s2m_jitter_ns;
        if (selected_delay_ns < 0.0)
            selected_delay_ns = 0.0;
        slave_serial_line <= #(selected_delay_ns) slave_serial_raw;
    end

    always @(posedge master_clk or negedge resetn) begin
        if (!resetn) begin
            epoch_locked <= 1'b0;
            monitor_slot <= 3'd0;
            monitor_clk_cnt <= 16'd0;
            master_rx_slot_pre_change <= 1'b0;
        end else begin
            if (arm_epoch && (master_serial_raw == 1'b1)) begin
                epoch_locked <= 1'b1;
                monitor_slot <= 3'd0;
                monitor_clk_cnt <= 16'd0;
                master_rx_slot_pre_change <= 1'b0;
            end else if (epoch_locked) begin
                master_rx_slot_pre_change <= (monitor_clk_cnt == (TB_SLOT_TICKS[15:0] - 16'd2));
                if (monitor_clk_cnt == (TB_SLOT_TICKS[15:0] - 16'd1)) begin
                    monitor_clk_cnt <= 16'd0;
                    if (monitor_slot == TB_NODE_CNT)
                        monitor_slot <= 3'd0;
                    else
                        monitor_slot <= monitor_slot + 3'd1;
                end else begin
                    monitor_clk_cnt <= monitor_clk_cnt + 16'd1;
                end
            end else begin
                master_rx_slot_pre_change <= 1'b0;
            end
        end
    end

    always @(posedge master_clk) begin
        if (resetn && arm_epoch && (master_serial_raw == 1'b1))
            arm_epoch <= 1'b0;
    end

    always @(posedge master_clk) begin
        if (master_rx_valid) begin
            master_valid_count = master_valid_count + 1;
            last_payload = master_decoded_data[31:0];
            last_node_id = master_decoded_data[34:32];
            last_2bit_err = master_ham_2bit_err;
            last_preamble_err = master_rx_preamble_err;
            last_valid_slot = monitor_slot;
            last_valid_clk_cnt = monitor_clk_cnt;
            $display("[WAVE] Master_rx valid slot=%0d clk_cnt=%0d node=%0d payload=0x%08x 2bit=%0b preamble_err=%0b time=%0t",
                     monitor_slot, monitor_clk_cnt, master_decoded_data[34:32],
                     master_decoded_data[31:0], master_ham_2bit_err,
                     master_rx_preamble_err, $time);
        end
    end

    task wait_master_cycles;
        input [31:0] cycle_count;
        begin
            for (cycle_index = 0; cycle_index < cycle_count; cycle_index = cycle_index + 1)
                @(posedge master_clk);
        end
    endtask

    task drive_master_bit;
        input bit_value;
        begin
            master_serial_raw = bit_value;
            wait_master_cycles({16'd0, TB_BIT_PERIOD});
        end
    endtask

    task send_master_frame;
        input [7:0] preamble_value;
        input [7:0] halt_cmd;
        input [9:0] guard_ticks;
        begin
            master_data = {halt_cmd, guard_ticks, 17'd0};
            #1;
            arm_epoch = 1'b1;
            for (bit_index = 7; bit_index >= 0; bit_index = bit_index - 1)
                drive_master_bit(preamble_value[bit_index]);
            for (bit_index = 41; bit_index >= 0; bit_index = bit_index - 1)
                drive_master_bit(master_codeword[bit_index]);
            master_serial_raw = 1'b0;
        end
    endtask

    task wait_to_next_master_frame_start;
        begin
            if (TB_MASTER_INTERVAL > TB_FRAME_TICKS)
                wait_master_cycles(TB_MASTER_INTERVAL - TB_FRAME_TICKS);
        end
    endtask

    task wait_to_next_master_frame_start_after_observe;
        begin
            if (TB_MASTER_INTERVAL > (TB_FRAME_TICKS + TB_NO_TX_OBSERVE))
                wait_master_cycles(TB_MASTER_INTERVAL - TB_FRAME_TICKS - TB_NO_TX_OBSERVE);
        end
    endtask

    task reset_link;
        begin
            resetn = 1'b0;
            master_serial_raw = 1'b0;
            master_serial_line = 1'b0;
            slave_serial_line = 1'b0;
            slave_payload = 32'd0;
            master_data = 35'd0;
            arm_epoch = 1'b0;
            m2s_transition_count = 0;
            s2m_transition_count = 0;
            master_valid_count = 0;
            last_payload = 32'd0;
            last_node_id = 3'd0;
            last_2bit_err = 1'b0;
            last_preamble_err = 1'b0;
            last_valid_slot = 3'd0;
            last_valid_clk_cnt = 16'd0;
            repeat (16) @(posedge master_clk);
            resetn = 1'b1;
            repeat (8) @(posedge master_clk);
        end
    endtask

    task expect_no_slave_tx;
        input [511:0] label;
        input [31:0] observe_cycles;
        begin
            saw_tx_high = 0;
            for (wait_count = 0; wait_count < observe_cycles; wait_count = wait_count + 1) begin
                @(posedge master_clk);
                if (slave_serial_line == 1'b1)
                    saw_tx_high = 1;
            end
            if (saw_tx_high == 0)
                $display("[PASS] %0s", label);
            else begin
                $display("[FAIL] %0s observed slave serial high", label);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task wait_response_and_check;
        input [511:0] label;
        input [31:0] expected_payload;
        input must_pass;
        reg decoded_ok;
        begin
            wait_count = 0;
            while ((master_valid_count == 0) && (wait_count < TB_RESPONSE_TIMEOUT)) begin
                wait_count = wait_count + 1;
                @(posedge master_clk);
            end
            decoded_ok = (master_valid_count != 0) &&
                         (last_node_id == TB_NODE_ID) &&
                         (last_payload == expected_payload) &&
                         (last_2bit_err == 1'b0) &&
                         (last_preamble_err == 1'b0);
            if (decoded_ok) begin
                $display("[PASS] %0s response decoded payload=0x%08x slot=%0d clk_cnt=%0d",
                         label, last_payload, last_valid_slot, last_valid_clk_cnt);
            end else begin
                $display("[FAIL] %0s response invalid valid_count=%0d node=%0d payload=0x%08x 2bit=%0b preamble_err=%0b",
                         label, master_valid_count, last_node_id, last_payload,
                         last_2bit_err, last_preamble_err);
                fail_count = fail_count + 1;
                if (must_pass)
                    must_pass_fail_count = must_pass_fail_count + 1;
            end
        end
    endtask

    task run_two_good_scenario;
        input [511:0] scenario_name;
        input real master_period_ns;
        input real slave_period_ns;
        input real start_phase_ns;
        input real m2s_delay_ns;
        input real s2m_delay_ns;
        input real m2s_jitter_in_ns;
        input real s2m_jitter_in_ns;
        input [31:0] payload_value;
        input must_pass;
        begin
            scenario_count = scenario_count + 1;
            master_half_ns = master_period_ns / 2.0;
            slave_half_ns = slave_period_ns / 2.0;
            m2s_base_delay_ns = m2s_delay_ns;
            s2m_base_delay_ns = s2m_delay_ns;
            m2s_jitter_ns = m2s_jitter_in_ns;
            s2m_jitter_ns = s2m_jitter_in_ns;
            $display("");
            $display("============================================================");
            $display("[SCENARIO %0d] %0s", scenario_count, scenario_name);
            $display(" master_period=%0.4f slave_period=%0.4f start_phase=%0.3f m2s_delay=%0.3f s2m_delay=%0.3f m2s_jitter=%0.3f s2m_jitter=%0.3f",
                     master_period_ns, slave_period_ns, start_phase_ns,
                     m2s_delay_ns, s2m_delay_ns, m2s_jitter_in_ns, s2m_jitter_in_ns);
            $display("============================================================");
            reset_link();
            slave_payload = payload_value;
            #(start_phase_ns);
            send_master_frame(8'hAA, 8'h00, TB_GUARD_TICKS);
            expect_no_slave_tx("first good broadcast does not transmit", TB_NO_TX_OBSERVE);
            wait_to_next_master_frame_start_after_observe();
            master_valid_count = 0;
            send_master_frame(8'hAA, 8'h00, TB_GUARD_TICKS);
            wait_response_and_check("second good tracking", payload_value, must_pass);
        end
    endtask

    task run_corrupt_first_recovery;
        begin
            scenario_count = scenario_count + 1;
            master_half_ns = 5.000;
            slave_half_ns = 5.000;
            m2s_base_delay_ns = 0.0;
            s2m_base_delay_ns = 0.0;
            m2s_jitter_ns = 0.0;
            s2m_jitter_ns = 0.0;
            $display("");
            $display("============================================================");
            $display("[SCENARIO %0d] first frame corrupt, later recovery", scenario_count);
            $display("============================================================");
            reset_link();
            slave_payload = 32'h55aa1001;
            send_master_frame(8'hAB, 8'h00, TB_GUARD_TICKS);
            expect_no_slave_tx("corrupt first frame no tx", TB_NO_TX_OBSERVE);
            wait_to_next_master_frame_start_after_observe();
            send_master_frame(8'hAA, 8'h00, TB_GUARD_TICKS);
            expect_no_slave_tx("first recovery good still no tx", TB_NO_TX_OBSERVE);
            wait_to_next_master_frame_start_after_observe();
            master_valid_count = 0;
            send_master_frame(8'hAA, 8'h00, TB_GUARD_TICKS);
            wait_response_and_check("second recovery good response", 32'h55aa1001, 1'b1);
        end
    endtask

    task run_tracking_missed_frame_recovery;
        begin
            scenario_count = scenario_count + 1;
            master_half_ns = 5.000;
            slave_half_ns = 5.000;
            m2s_base_delay_ns = 0.0;
            s2m_base_delay_ns = 0.0;
            m2s_jitter_ns = 0.0;
            s2m_jitter_ns = 0.0;
            $display("");
            $display("============================================================");
            $display("[SCENARIO %0d] one missed/corrupt broadcast in tracking, recovery", scenario_count);
            $display("============================================================");
            reset_link();
            slave_payload = 32'h66bb2002;
            send_master_frame(8'hAA, 8'h00, TB_GUARD_TICKS);
            wait_to_next_master_frame_start();
            master_valid_count = 0;
            send_master_frame(8'hAA, 8'h00, TB_GUARD_TICKS);
            wait_response_and_check("initial tracking response", 32'h66bb2002, 1'b1);

            wait_to_next_master_frame_start();
            master_valid_count = 0;
            send_master_frame(8'h00, 8'h00, TB_GUARD_TICKS);
            if (master_valid_count != 0) begin
                $display("[FAIL] missed/corrupt tracking frame produced wrong-slot response valid_count=%0d last_slot=%0d last_clk_cnt=%0d",
                         master_valid_count, last_valid_slot, last_valid_clk_cnt);
                fail_count = fail_count + 1;
                must_pass_fail_count = must_pass_fail_count + 1;
            end else begin
                $display("[PASS] no response completed during missed/corrupt tracking frame");
            end
            expect_no_slave_tx("missed/corrupt tracking frame suppresses wrong-slot tx", TB_NO_TX_OBSERVE);

            wait_to_next_master_frame_start_after_observe();
            send_master_frame(8'hAA, 8'h00, TB_GUARD_TICKS);
            expect_no_slave_tx("recovery first good no tx", TB_NO_TX_OBSERVE);
            wait_to_next_master_frame_start_after_observe();
            master_valid_count = 0;
            send_master_frame(8'hAA, 8'h00, TB_GUARD_TICKS);
            wait_response_and_check("recovery second good response", 32'h66bb2002, 1'b1);
        end
    endtask

    initial begin
        fail_count = 0;
        must_pass_fail_count = 0;
        scenario_count = 0;
        master_serial_raw = 1'b0;
        master_serial_line = 1'b0;
        slave_serial_line = 1'b0;
        resetn = 1'b0;
        slave_payload = 32'd0;
        m2s_base_delay_ns = 0.0;
        s2m_base_delay_ns = 0.0;
        m2s_jitter_ns = 0.0;
        s2m_jitter_ns = 0.0;
        m2s_transition_count = 0;
        s2m_transition_count = 0;
        master_valid_count = 0;
        arm_epoch = 1'b0;
        epoch_locked = 1'b0;
        monitor_slot = 3'd0;
        monitor_clk_cnt = 16'd0;
        master_rx_slot_pre_change = 1'b0;

        $display("[INFO] tb_slave21_master_harsh_link start");

        run_two_good_scenario("nominal separate clocks",
                              10.0000, 10.0000, 0.000, 0.000, 0.000, 0.000, 0.000,
                              32'h21000001, 1'b1);
        run_two_good_scenario("arbitrary reset/start phase",
                              10.0000, 10.0000, 3.750, 0.000, 0.000, 0.000, 0.000,
                              32'h21000002, 1'b1);
        run_two_good_scenario("slave clock +0.25 percent fast",
                              10.0000, 9.9750, 1.250, 0.000, 0.000, 0.000, 0.000,
                              32'h21000003, 1'b1);
        run_two_good_scenario("slave clock -0.25 percent slow",
                              10.0000, 10.0250, 2.500, 0.000, 0.000, 0.000, 0.000,
                              32'h21000004, 1'b1);
        run_two_good_scenario("slave clock +0.50 percent fast",
                              10.0000, 9.9500, 3.125, 0.000, 0.000, 0.000, 0.000,
                              32'h21000005, 1'b1);
        run_two_good_scenario("slave clock -0.50 percent slow",
                              10.0000, 10.0500, 4.375, 0.000, 0.000, 0.000, 0.000,
                              32'h21000006, 1'b1);
        run_two_good_scenario("propagation delay plus deterministic jitter",
                              10.0000, 10.0000, 0.000, 28.000, 36.000, 5.000, 7.000,
                              32'h21000007, 1'b1);
        run_corrupt_first_recovery();
        run_tracking_missed_frame_recovery();

        run_two_good_scenario("exploratory slave clock +1.00 percent fast",
                              10.0000, 9.9000, 0.000, 0.000, 0.000, 0.000, 0.000,
                              32'h21e00001, 1'b0);
        run_two_good_scenario("exploratory slave clock -1.00 percent slow",
                              10.0000, 10.1000, 0.000, 0.000, 0.000, 0.000, 0.000,
                              32'h21e00002, 1'b0);
        run_two_good_scenario("exploratory near half-bit propagation delay",
                              10.0000, 10.0000, 0.000, 72.000, 72.000, 0.000, 0.000,
                              32'h21e00003, 1'b0);

        $display("");
        $display("============================================================");
        if (must_pass_fail_count == 0)
            $display("PASS: tb_slave21_master_harsh_link must-pass scenarios survived total_scenarios=%0d fail_count=%0d",
                     scenario_count, fail_count);
        else
            $display("FAIL: tb_slave21_master_harsh_link fail_count=%0d must_pass_fail_count=%0d total_scenarios=%0d",
                     fail_count, must_pass_fail_count, scenario_count);
        $display("============================================================");
        $finish;
    end

endmodule
