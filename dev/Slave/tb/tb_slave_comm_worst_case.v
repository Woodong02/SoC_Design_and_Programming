`timescale 1ns / 1ps

module tb_slave_comm_worst_case;

    reg master_clk;
    reg slave_clk;
    reg resetn;

    reg         master_tx_trigger;
    reg  [7:0]  master_halt_cmd;
    reg  [9:0]  master_guard_ticks;
    reg  [9:0]  master_div;
    reg  [31:0] slave_payload;

    wire        master_to_slave_raw;
    reg         master_to_slave_line;
    wire        slave_to_master_raw;
    reg         slave_to_master_line;
    reg         manual_master_rx_line;
    reg         manual_mode;
    wire        master_rx_input;

    wire [41:0] master_rx_codeword;
    wire        master_rx_valid;
    wire        master_rx_preamble_err;
    wire [34:0] master_decoded_data;
    wire        master_ham_1bit_err;
    wire        master_ham_2bit_err;

    wire        slave_synced;
    wire        slave_halted;
    wire [9:0]  slave_latched_guard_ticks;

    parameter [2:0] TB_NODE_ID = 3'd1;
    parameter [2:0] TB_NODE_CNT = 3'd2;
    parameter [9:0] TB_BIT_DIV = 10'd16;
    parameter [9:0] TB_GUARD_TICKS = 10'd128;

    parameter [15:0] TB_DATA_TICKS = 16'd50 * {6'b0, TB_BIT_DIV};
    parameter [15:0] TB_SLOT_TICKS = TB_DATA_TICKS + {6'b0, TB_GUARD_TICKS};
    parameter [15:0] TB_NORMAL_START = TB_DATA_TICKS + {8'b0, (TB_GUARD_TICKS >> 2)};
    parameter [15:0] TB_NORMAL_END_EXCL = TB_SLOT_TICKS - {8'b0, (TB_GUARD_TICKS >> 2)};

    real master_half_ns;
    real slave_half_ns;
    real m2s_base_delay_ns;
    real s2m_base_delay_ns;
    real m2s_jitter_ns;
    real s2m_jitter_ns;
    real selected_delay_ns;

    integer m2s_transition_count;
    integer s2m_transition_count;
    integer scenario_count;
    integer guard_case_count;
    integer observed_fail_count;
    integer expected_pass_fail_count;
    integer master_valid_count;
    integer wait_count;
    integer bit_index;
    integer sweep_index;

    reg arm_epoch;
    reg epoch_locked;
    reg [2:0]  monitor_slot;
    reg [15:0] monitor_clk_cnt;
    reg        master_rx_slot_pre_change;

    reg [31:0] last_payload;
    reg [2:0]  last_node_id;
    reg        last_1bit_err;
    reg        last_2bit_err;
    reg        last_preamble_err;
    reg [2:0]  last_valid_slot;
    reg [15:0] last_valid_clk_cnt;

    assign master_rx_input = manual_mode ? manual_master_rx_line : slave_to_master_line;

    Master_tx u_master_tx (
        .clk(master_clk),
        .resetn(resetn),
        .tx_trigger(master_tx_trigger),
        .halt_cmd(master_halt_cmd),
        .GUARD_TICKS(master_guard_ticks),
        .DIV(master_div),
        .GPIO_out(master_to_slave_raw)
    );

    slave_top #(
        .NODE_ID(TB_NODE_ID),
        .NODE_CNT(TB_NODE_CNT),
        .BIT_DIV(TB_BIT_DIV),
        .GUARD_TICKS_DEFAULT(TB_GUARD_TICKS)
    ) u_slave_top (
        .i_CLK(slave_clk),
        .i_RESETN(resetn),
        .i_MASTER_SERIAL(master_to_slave_line),
        .i_PAYLOAD(slave_payload),
        .o_SLAVE_SERIAL(slave_to_master_raw),
        .o_SYNCED(slave_synced),
        .o_HALTED(slave_halted),
        .o_LATCHED_GUARD_TICKS(slave_latched_guard_ticks)
    );

    Master_rx u_master_rx (
        .clk(master_clk),
        .DIV(master_div),
        .GPIO_in(master_rx_input),
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

    always @(master_to_slave_raw) begin
        m2s_transition_count = m2s_transition_count + 1;
        selected_delay_ns = m2s_base_delay_ns;
        if ((m2s_transition_count % 5) == 0)
            selected_delay_ns = m2s_base_delay_ns + m2s_jitter_ns;
        else if ((m2s_transition_count % 5) == 1)
            selected_delay_ns = m2s_base_delay_ns - m2s_jitter_ns;
        if (selected_delay_ns < 0.0)
            selected_delay_ns = 0.0;
        master_to_slave_line <= #(selected_delay_ns) master_to_slave_raw;
    end

    always @(slave_to_master_raw) begin
        s2m_transition_count = s2m_transition_count + 1;
        selected_delay_ns = s2m_base_delay_ns;
        if ((s2m_transition_count % 7) == 0)
            selected_delay_ns = s2m_base_delay_ns + s2m_jitter_ns;
        else if ((s2m_transition_count % 7) == 1)
            selected_delay_ns = s2m_base_delay_ns - s2m_jitter_ns;
        if (selected_delay_ns < 0.0)
            selected_delay_ns = 0.0;
        slave_to_master_line <= #(selected_delay_ns) slave_to_master_raw;
    end

    always @(posedge master_clk or negedge resetn) begin
        if (!resetn) begin
            epoch_locked <= 1'b0;
            monitor_slot <= 3'd0;
            monitor_clk_cnt <= 16'd0;
            master_rx_slot_pre_change <= 1'b0;
        end else begin
            if (arm_epoch && (master_to_slave_raw == 1'b1)) begin
                epoch_locked <= 1'b1;
                monitor_slot <= 3'd0;
                monitor_clk_cnt <= 16'd0;
                master_rx_slot_pre_change <= 1'b0;
            end else if (epoch_locked) begin
                master_rx_slot_pre_change <= (monitor_clk_cnt == (TB_SLOT_TICKS - 16'd2));
                if (monitor_clk_cnt == (TB_SLOT_TICKS - 16'd1)) begin
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
        if (resetn && arm_epoch && (master_to_slave_raw == 1'b1))
            arm_epoch <= 1'b0;
    end

    always @(posedge master_clk) begin
        if (master_rx_valid) begin
            master_valid_count = master_valid_count + 1;
            last_payload = master_decoded_data[31:0];
            last_node_id = master_decoded_data[34:32];
            last_1bit_err = master_ham_1bit_err;
            last_2bit_err = master_ham_2bit_err;
            last_preamble_err = master_rx_preamble_err;
            last_valid_slot = monitor_slot;
            last_valid_clk_cnt = monitor_clk_cnt;
            $display("[WAVE] Master_rx valid slot=%0d clk_cnt=%0d node=%0d payload=0x%08x 1bit=%0b 2bit=%0b preamble_err=%0b time=%0t",
                     monitor_slot, monitor_clk_cnt, master_decoded_data[34:32],
                     master_decoded_data[31:0], master_ham_1bit_err,
                     master_ham_2bit_err, master_rx_preamble_err, $time);
        end
    end

    function [41:0] reference_codeword;
        input [34:0] data;
        reg p0;
        reg p1;
        reg p2;
        reg p3;
        reg p4;
        reg p5;
        reg p_overall;
        begin
            p0 = data[0] ^ data[2] ^ data[4] ^ data[6] ^ data[8] ^ data[10] ^ data[12] ^ data[14]
               ^ data[16] ^ data[18] ^ data[20] ^ data[22] ^ data[24] ^ data[26] ^ data[28] ^ data[30]
               ^ data[32] ^ data[34];
            p1 = data[1] ^ data[2] ^ data[5] ^ data[6] ^ data[9] ^ data[10] ^ data[13] ^ data[14]
               ^ data[17] ^ data[18] ^ data[21] ^ data[22] ^ data[25] ^ data[26] ^ data[29] ^ data[30]
               ^ data[33] ^ data[34];
            p2 = data[3] ^ data[4] ^ data[5] ^ data[6] ^ data[11] ^ data[12] ^ data[13] ^ data[14]
               ^ data[19] ^ data[20] ^ data[21] ^ data[22] ^ data[27] ^ data[28] ^ data[29] ^ data[30];
            p3 = data[7] ^ data[8] ^ data[9] ^ data[10] ^ data[11] ^ data[12] ^ data[13] ^ data[14]
               ^ data[23] ^ data[24] ^ data[25] ^ data[26] ^ data[27] ^ data[28] ^ data[29] ^ data[30];
            p4 = data[15] ^ data[16] ^ data[17] ^ data[18] ^ data[19] ^ data[20] ^ data[21] ^ data[22]
               ^ data[23] ^ data[24] ^ data[25] ^ data[26] ^ data[27] ^ data[28] ^ data[29] ^ data[30];
            p5 = data[31] ^ data[32] ^ data[33] ^ data[34];
            p_overall = ^{data, p5, p4, p3, p2, p1, p0};
            reference_codeword = {data, p5, p4, p3, p2, p1, p0, p_overall};
        end
    endfunction

    task reset_common;
        begin
            resetn = 1'b0;
            master_tx_trigger = 1'b0;
            master_halt_cmd = 8'd0;
            master_guard_ticks = TB_GUARD_TICKS;
            master_div = TB_BIT_DIV;
            slave_payload = 32'd0;
            manual_mode = 1'b0;
            manual_master_rx_line = 1'b0;
            master_to_slave_line = 1'b0;
            slave_to_master_line = 1'b0;
            m2s_transition_count = 0;
            s2m_transition_count = 0;
            master_valid_count = 0;
            last_payload = 32'd0;
            last_node_id = 3'd0;
            last_1bit_err = 1'b0;
            last_2bit_err = 1'b0;
            last_preamble_err = 1'b0;
            last_valid_slot = 3'd0;
            last_valid_clk_cnt = 16'd0;
            arm_epoch = 1'b0;
            repeat (12) @(posedge master_clk);
            resetn = 1'b1;
            repeat (8) @(posedge master_clk);
        end
    endtask

    task pulse_master_broadcast;
        input [7:0] halt_cmd;
        begin
            master_halt_cmd = halt_cmd;
            master_guard_ticks = TB_GUARD_TICKS;
            arm_epoch = 1'b1;
            @(negedge master_clk);
            master_tx_trigger = 1'b1;
            @(negedge master_clk);
            master_tx_trigger = 1'b0;
        end
    endtask

    task run_link_case;
        input [511:0] case_name;
        input real master_period_ns;
        input real slave_period_ns;
        input real start_phase_ns;
        input real m2s_delay_ns;
        input real s2m_delay_ns;
        input real m2s_jitter_in_ns;
        input real s2m_jitter_in_ns;
        input [31:0] payload_value;
        input expected_to_pass;
        reg decoded_ok;
        reg timing_ok;
        reg case_ok;
        begin
            scenario_count = scenario_count + 1;
            master_half_ns = master_period_ns / 2.0;
            slave_half_ns = slave_period_ns / 2.0;
            m2s_base_delay_ns = m2s_delay_ns;
            s2m_base_delay_ns = s2m_delay_ns;
            m2s_jitter_ns = m2s_jitter_in_ns;
            s2m_jitter_ns = s2m_jitter_in_ns;
            slave_payload = payload_value;

            $display("");
            $display("============================================================");
            $display("[LINK CASE %0d] %0s", scenario_count, case_name);
            $display(" master_period=%0.4f slave_period=%0.4f start_phase=%0.3f m2s_delay=%0.3f s2m_delay=%0.3f m2s_jitter=%0.3f s2m_jitter=%0.3f",
                     master_period_ns, slave_period_ns, start_phase_ns,
                     m2s_delay_ns, s2m_delay_ns, m2s_jitter_in_ns, s2m_jitter_in_ns);
            $display("============================================================");

            reset_common();
            slave_payload = payload_value;
            #(start_phase_ns);
            pulse_master_broadcast(8'h00);

            wait_count = 0;
            while ((slave_latched_guard_ticks !== TB_GUARD_TICKS) && (wait_count < 20000)) begin
                wait_count = wait_count + 1;
                @(posedge master_clk);
            end

            wait_count = 0;
            while ((master_valid_count == 0) && (wait_count < 60000)) begin
                wait_count = wait_count + 1;
                @(posedge master_clk);
            end

            decoded_ok = (master_valid_count != 0) &&
                         (last_node_id == TB_NODE_ID) &&
                         (last_payload == payload_value) &&
                         (last_2bit_err == 1'b0) &&
                         (last_preamble_err == 1'b0);
            timing_ok = (last_valid_slot == TB_NODE_ID) &&
                        (last_valid_clk_cnt >= TB_NORMAL_START) &&
                        (last_valid_clk_cnt < TB_NORMAL_END_EXCL);
            case_ok = decoded_ok && timing_ok;

            if (case_ok) begin
                $display("[PASS] clean decode inside Master normal guard window");
            end else begin
                $display("[FAIL] observed link case failure decoded_ok=%0b timing_ok=%0b valid_count=%0d last_slot=%0d last_clk_cnt=%0d payload=0x%08x",
                         decoded_ok, timing_ok, master_valid_count,
                         last_valid_slot, last_valid_clk_cnt, last_payload);
                observed_fail_count = observed_fail_count + 1;
            end

            if (expected_to_pass && !case_ok)
                expected_pass_fail_count = expected_pass_fail_count + 1;
        end
    endtask

    task drive_manual_bit;
        input bit_value;
        integer hold_index;
        begin
            manual_master_rx_line = bit_value;
            for (hold_index = 0; hold_index < TB_BIT_DIV; hold_index = hold_index + 1)
                @(posedge master_clk);
        end
    endtask

    task send_manual_response_frame;
        input [31:0] payload_value;
        reg [41:0] codeword;
        reg [49:0] frame;
        begin
            codeword = reference_codeword({TB_NODE_ID, payload_value});
            frame = {8'hAA, codeword};
            for (bit_index = 49; bit_index >= 0; bit_index = bit_index - 1)
                drive_manual_bit(frame[bit_index]);
            manual_master_rx_line = 1'b0;
        end
    endtask

    task run_guard_start_case;
        input [15:0] response_start_cnt;
        input [31:0] payload_value;
        reg normal_window_observed;
        reg decoded_ok;
        begin
            guard_case_count = guard_case_count + 1;

            reset_common();
            manual_mode = 1'b1;
            epoch_locked = 1'b1;
            monitor_slot = TB_NODE_ID;
            monitor_clk_cnt = 16'd0;
            manual_master_rx_line = 1'b0;
            master_valid_count = 0;

            $display("");
            $display("------------------------------------------------------------");
            $display("[GUARD SWEEP %0d] response_start_cnt=%0d", guard_case_count, response_start_cnt);
            $display(" expected start normal range: %0d..%0d", (TB_GUARD_TICKS >> 2), (TB_GUARD_TICKS - (TB_GUARD_TICKS >> 2) - 1));
            $display("------------------------------------------------------------");

            while (monitor_clk_cnt < response_start_cnt)
                @(posedge master_clk);

            send_manual_response_frame(payload_value);

            wait_count = 0;
            while ((master_valid_count == 0) && (wait_count < 2000)) begin
                wait_count = wait_count + 1;
                @(posedge master_clk);
            end

            normal_window_observed = (last_valid_slot == TB_NODE_ID) &&
                                     (last_valid_clk_cnt >= TB_NORMAL_START) &&
                                     (last_valid_clk_cnt < TB_NORMAL_END_EXCL);
            decoded_ok = (master_valid_count != 0) &&
                         (last_node_id == TB_NODE_ID) &&
                         (last_payload == payload_value) &&
                         (last_2bit_err == 1'b0);

            if (normal_window_observed && decoded_ok) begin
                $display("[PASS] normal-window response decoded done_clk_cnt=%0d", last_valid_clk_cnt);
            end else if (normal_window_observed && !decoded_ok) begin
                $display("[FAIL] normal-window response did not decode done_clk_cnt=%0d valid_count=%0d payload=0x%08x 2bit=%0b",
                         last_valid_clk_cnt, master_valid_count, last_payload, last_2bit_err);
                observed_fail_count = observed_fail_count + 1;
                expected_pass_fail_count = expected_pass_fail_count + 1;
            end else begin
                $display("[OBSERVE] outside normal window or reset edge: decoded_ok=%0b done_slot=%0d done_clk_cnt=%0d valid_count=%0d",
                         decoded_ok, last_valid_slot, last_valid_clk_cnt, master_valid_count);
            end
        end
    endtask

    initial begin
        scenario_count = 0;
        guard_case_count = 0;
        observed_fail_count = 0;
        expected_pass_fail_count = 0;
        m2s_base_delay_ns = 0.0;
        s2m_base_delay_ns = 0.0;
        m2s_jitter_ns = 0.0;
        s2m_jitter_ns = 0.0;
        master_half_ns = 5.0;
        slave_half_ns = 5.0;
        resetn = 1'b0;
        master_tx_trigger = 1'b0;
        master_halt_cmd = 8'd0;
        master_guard_ticks = TB_GUARD_TICKS;
        master_div = TB_BIT_DIV;
        slave_payload = 32'd0;
        manual_mode = 1'b0;
        manual_master_rx_line = 1'b0;
        master_to_slave_line = 1'b0;
        slave_to_master_line = 1'b0;
        m2s_transition_count = 0;
        s2m_transition_count = 0;
        master_valid_count = 0;
        arm_epoch = 1'b0;
        epoch_locked = 1'b0;
        monitor_slot = 3'd0;
        monitor_clk_cnt = 16'd0;
        master_rx_slot_pre_change = 1'b0;

        $display("[INFO] tb_slave_comm_worst_case start");
        $display("[INFO] Master normal done window clk_cnt=%0d..%0d", TB_NORMAL_START, TB_NORMAL_END_EXCL - 16'd1);
        $display("[INFO] Equivalent response start window inside guard=%0d..%0d", (TB_GUARD_TICKS >> 2), (TB_GUARD_TICKS - (TB_GUARD_TICKS >> 2) - 1));

        run_link_case("nominal shared rate, arbitrary reset phase",
                      10.0000, 10.0000, 0.000, 0.000, 0.000, 0.000, 0.000,
                      32'h10000001, 1'b1);
        run_link_case("slave +0.10 percent fast",
                      10.0000, 9.9900, 1.500, 0.000, 0.000, 0.000, 0.000,
                      32'h10000002, 1'b1);
        run_link_case("slave -0.10 percent slow",
                      10.0000, 10.0100, 2.250, 0.000, 0.000, 0.000, 0.000,
                      32'h10000003, 1'b1);
        run_link_case("slave +0.25 percent fast",
                      10.0000, 9.9750, 3.000, 0.000, 0.000, 0.000, 0.000,
                      32'h10000004, 1'b1);
        run_link_case("slave -0.25 percent slow",
                      10.0000, 10.0250, 4.500, 0.000, 0.000, 0.000, 0.000,
                      32'h10000005, 1'b1);
        run_link_case("slave +0.50 percent fast",
                      10.0000, 9.9500, 6.750, 0.000, 0.000, 0.000, 0.000,
                      32'h10000006, 1'b1);
        run_link_case("slave -0.50 percent slow",
                      10.0000, 10.0500, 7.250, 0.000, 0.000, 0.000, 0.000,
                      32'h10000007, 1'b1);
        run_link_case("quarter-bit symmetric delay plus jitter",
                      10.0000, 10.0000, 0.000, 40.000, 40.000, 8.000, 8.000,
                      32'h10000008, 1'b1);
        run_link_case("asymmetric delay close to half-bit on return",
                      10.0000, 10.0000, 5.000, 12.000, 72.000, 4.000, 12.000,
                      32'h10000009, 1'b1);
        run_link_case("combined +0.25 percent fast and asymmetric delayed line",
                      10.0000, 9.9750, 8.000, 28.000, 56.000, 6.000, 10.000,
                      32'h1000000a, 1'b1);
        run_link_case("exploratory +1.00 percent fast",
                      10.0000, 9.9000, 0.000, 0.000, 0.000, 0.000, 0.000,
                      32'h1000000b, 1'b0);
        run_link_case("exploratory -1.00 percent slow",
                      10.0000, 10.1000, 0.000, 0.000, 0.000, 0.000, 0.000,
                      32'h1000000c, 1'b0);
        run_link_case("exploratory +2.00 percent fast",
                      10.0000, 9.8000, 0.000, 0.000, 0.000, 0.000, 0.000,
                      32'h1000000d, 1'b0);

        for (sweep_index = 24; sweep_index <= 104; sweep_index = sweep_index + 1)
            run_guard_start_case(sweep_index[15:0], 32'h20000000 + sweep_index[31:0]);
        run_guard_start_case(16'd0,   32'h20001000);
        run_guard_start_case(16'd1,   32'h20001001);
        run_guard_start_case(16'd127, 32'h2000107f);

        $display("");
        $display("============================================================");
        $display("SUMMARY: link_cases=%0d guard_cases=%0d observed_failures=%0d expected_pass_failures=%0d",
                 scenario_count, guard_case_count, observed_fail_count, expected_pass_fail_count);
        if (expected_pass_fail_count == 0)
            $display("PASS: tb_slave_comm_worst_case expected-pass cases survived");
        else
            $display("FAIL: tb_slave_comm_worst_case expected-pass failures observed");
        $display("============================================================");

        $finish;
    end

endmodule
