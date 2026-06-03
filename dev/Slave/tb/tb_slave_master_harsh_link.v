`timescale 1ns / 1ps

module tb_slave_master_harsh_link;

    reg master_clk;
    reg slave_clk;
    reg resetn;

    reg         master_tx_trigger;
    reg  [7:0]  master_halt_cmd;
    reg  [9:0]  master_guard_ticks;
    reg  [9:0]  master_div;
    reg  [31:0] slave_payload;
    reg         master_rx_slot_pre_change;

    wire master_to_slave_raw;
    reg  master_to_slave_line;
    wire slave_to_master_raw;
    reg  slave_to_master_line;

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

    reg [31:0] last_master_payload;
    reg [2:0]  last_master_node_id;
    reg        last_master_2bit_err;
    reg        last_master_preamble_err;

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
        .GPIO_in(slave_to_master_line),
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
        if ((m2s_transition_count % 3) == 0)
            selected_delay_ns = m2s_base_delay_ns + m2s_jitter_ns;
        else if ((m2s_transition_count % 3) == 1)
            selected_delay_ns = m2s_base_delay_ns - m2s_jitter_ns;
        if (selected_delay_ns < 0.0)
            selected_delay_ns = 0.0;
        master_to_slave_line <= #(selected_delay_ns) master_to_slave_raw;
    end

    always @(slave_to_master_raw) begin
        s2m_transition_count = s2m_transition_count + 1;
        selected_delay_ns = s2m_base_delay_ns;
        if ((s2m_transition_count % 4) == 0)
            selected_delay_ns = s2m_base_delay_ns + s2m_jitter_ns;
        else if ((s2m_transition_count % 4) == 1)
            selected_delay_ns = s2m_base_delay_ns - s2m_jitter_ns;
        if (selected_delay_ns < 0.0)
            selected_delay_ns = 0.0;
        slave_to_master_line <= #(selected_delay_ns) slave_to_master_raw;
    end

    always @(posedge master_clk) begin
        if (master_rx_valid) begin
            master_valid_count = master_valid_count + 1;
            last_master_payload = master_decoded_data[31:0];
            last_master_node_id = master_decoded_data[34:32];
            last_master_2bit_err = master_ham_2bit_err;
            last_master_preamble_err = master_rx_preamble_err;
            $display("[WAVE] Master_rx valid node=%0d payload=0x%08x 1bit=%0b 2bit=%0b time=%0t",
                     master_decoded_data[34:32], master_decoded_data[31:0],
                     master_ham_1bit_err, master_ham_2bit_err, $time);
        end
    end

    task pulse_master_broadcast;
        input [7:0] halt_cmd;
        input [9:0] guard_ticks;
        begin
            master_halt_cmd = halt_cmd;
            master_guard_ticks = guard_ticks;
            @(negedge master_clk);
            master_tx_trigger = 1'b1;
            @(negedge master_clk);
            master_tx_trigger = 1'b0;
        end
    endtask

    task reset_link;
        begin
            resetn = 1'b0;
            master_tx_trigger = 1'b0;
            master_halt_cmd = 8'd0;
            master_guard_ticks = TB_GUARD_TICKS;
            master_div = TB_BIT_DIV;
            master_rx_slot_pre_change = 1'b0;
            master_to_slave_line = 1'b0;
            slave_to_master_line = 1'b0;
            m2s_transition_count = 0;
            s2m_transition_count = 0;
            master_valid_count = 0;
            last_master_payload = 32'd0;
            last_master_node_id = 3'd0;
            last_master_2bit_err = 1'b0;
            last_master_preamble_err = 1'b0;
            repeat (12) @(posedge master_clk);
            resetn = 1'b1;
            repeat (8) @(posedge master_clk);
        end
    endtask

    task run_scenario;
        input [511:0] scenario_name;
        input real master_period_ns;
        input real slave_period_ns;
        input real m2s_delay_ns;
        input real s2m_delay_ns;
        input real m2s_jitter_in_ns;
        input real s2m_jitter_in_ns;
        input [31:0] expected_payload;
        input must_pass;
        reg scenario_ok;
        reg response_ok;
        begin
            scenario_count = scenario_count + 1;
            master_half_ns = master_period_ns / 2.0;
            slave_half_ns = slave_period_ns / 2.0;
            m2s_base_delay_ns = m2s_delay_ns;
            s2m_base_delay_ns = s2m_delay_ns;
            m2s_jitter_ns = m2s_jitter_in_ns;
            s2m_jitter_ns = s2m_jitter_in_ns;
            slave_payload = expected_payload;

            $display("");
            $display("============================================================");
            $display("[SCENARIO %0d] %0s", scenario_count, scenario_name);
            $display(" master_period=%0.3f ns slave_period=%0.3f ns m2s_delay=%0.3f ns s2m_delay=%0.3f ns m2s_jitter=%0.3f ns s2m_jitter=%0.3f ns",
                     master_period_ns, slave_period_ns, m2s_delay_ns, s2m_delay_ns,
                     m2s_jitter_in_ns, s2m_jitter_in_ns);
            $display("============================================================");

            reset_link();
            pulse_master_broadcast(8'h00, 10'd77);

            wait_count = 0;
            while ((slave_latched_guard_ticks !== 10'd77) && (wait_count < 12000)) begin
                wait_count = wait_count + 1;
                @(posedge master_clk);
            end

            scenario_ok = 1'b1;
            if (slave_latched_guard_ticks !== 10'd77) begin
                $display("[OBSERVE] slave did not latch broadcast guard within timeout");
                scenario_ok = 1'b0;
            end else begin
                $display("[PASS] slave latched broadcast guard");
            end

            wait_count = 0;
            while ((master_valid_count == 0) && (wait_count < 20000)) begin
                wait_count = wait_count + 1;
                @(posedge master_clk);
            end

            response_ok = (master_valid_count != 0) &&
                          (last_master_node_id == TB_NODE_ID) &&
                          (last_master_payload == expected_payload) &&
                          (last_master_2bit_err == 1'b0) &&
                          (last_master_preamble_err == 1'b0);

            if (response_ok) begin
                $display("[PASS] response decoded correctly under scenario");
            end else begin
                $display("[OBSERVE] response not cleanly decoded: valid_count=%0d node=%0d payload=0x%08x 2bit=%0b preamble_err=%0b",
                         master_valid_count, last_master_node_id, last_master_payload,
                         last_master_2bit_err, last_master_preamble_err);
                scenario_ok = 1'b0;
            end

            if (must_pass && !scenario_ok) begin
                $display("[FAIL] must-pass harsh scenario failed: %0s", scenario_name);
                fail_count = fail_count + 1;
                must_pass_fail_count = must_pass_fail_count + 1;
            end else if (!must_pass && !scenario_ok) begin
                $display("[INFO] exploratory harsh scenario exposed limit: %0s", scenario_name);
            end else begin
                $display("[PASS] scenario accepted: %0s", scenario_name);
            end
        end
    endtask

    initial begin
        fail_count = 0;
        must_pass_fail_count = 0;
        scenario_count = 0;
        resetn = 1'b0;
        master_tx_trigger = 1'b0;
        master_halt_cmd = 8'd0;
        master_guard_ticks = TB_GUARD_TICKS;
        master_div = TB_BIT_DIV;
        slave_payload = 32'd0;
        master_rx_slot_pre_change = 1'b0;
        master_to_slave_line = 1'b0;
        slave_to_master_line = 1'b0;
        m2s_base_delay_ns = 0.0;
        s2m_base_delay_ns = 0.0;
        m2s_jitter_ns = 0.0;
        s2m_jitter_ns = 0.0;
        m2s_transition_count = 0;
        s2m_transition_count = 0;
        master_valid_count = 0;
        last_master_payload = 32'd0;
        last_master_node_id = 3'd0;
        last_master_2bit_err = 1'b0;
        last_master_preamble_err = 1'b0;

        $display("[INFO] tb_slave_master_harsh_link start");

        run_scenario("nominal separate clocks, no delay",
                     10.000, 10.000, 0.000, 0.000, 0.000, 0.000,
                     32'h01020304, 1'b1);

        run_scenario("slave clock +0.25 percent fast",
                     10.000, 9.975, 0.000, 0.000, 0.000, 0.000,
                     32'h11223344, 1'b1);

        run_scenario("slave clock -0.25 percent slow",
                     10.000, 10.025, 0.000, 0.000, 0.000, 0.000,
                     32'h55667788, 1'b1);

        run_scenario("quarter-bit propagation delay with transition jitter",
                     10.000, 10.000, 40.000, 40.000, 8.000, 8.000,
                     32'h89abcdef, 1'b1);

        run_scenario("combined mild drift and delayed noisy line",
                     10.000, 9.985, 30.000, 55.000, 6.000, 10.000,
                     32'h0badc0de, 1'b1);

        run_scenario("exploratory extreme slave +2 percent fast",
                     10.000, 9.800, 0.000, 0.000, 0.000, 0.000,
                     32'hdeadbeef, 1'b0);

        if (fail_count == 0)
            $display("PASS: tb_slave_master_harsh_link must-pass scenarios survived, total_scenarios=%0d", scenario_count);
        else
            $display("FAIL: tb_slave_master_harsh_link fail_count=%0d must_pass_fail_count=%0d", fail_count, must_pass_fail_count);

        $finish;
    end

endmodule

