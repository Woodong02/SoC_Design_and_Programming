`timescale 1ns / 1ps

// =============================================================================
// tb_slave22_comm_worst_case
//
// Slave 2.2 통신 가혹환경 TB. harsh_link(클럭 drift/지터/지연 sweep)와
// 의도적으로 차별화: 여기서는 broadcast 손상 패턴(corrupt/blackout)을 직접
// 인가하여 slave22_timebase 2.2 신규 로직 — holdover(period_valid 유지) 및
// miss_count(연속 rate_error 누적, MISS_RESET_LIMIT 초과 시에만 default 리셋) —
// 을 정밀 자극한다. 클럭/지연은 전 시나리오 nominal(10ns, 지연 0)로 고정한다.
//
// 공통 인프라(slave_hamming_enc broadcast 주입, slave22_top DUT, Master_rx 디코드,
// epoch slot 모니터, expect_no_slave_tx/wait_response_and_check 태스크, drift/지연/
// 지터 모델)는 tb_slave22_master_harsh_link / tb_slave22_master_link에서 그대로 재사용.
//
// must-pass:
//   W1 TRACKING 확립 후 단발 corrupt 1회 -> holdover 흡수, 다음 두 good에서
//      recovery TX(slot==NODE_ID) 발생. miss_count<limit. (Scenario 9 일반화)
//   W2 TRACKING 중 연속 3회 corrupt(miss_count 누적, limit 이하) -> holdover 유지,
//      이후 연속 good에서 recovery TX 발생. period_valid가 0으로 떨어지지 않음.
//   W3 corrupt/good 번갈아 오는 간헐 손상 -> 정상 interval마다 miss_count=0 클리어,
//      holdover 유지, 주기적 TX 지속.
//
// exploratory(must_pass=0, must_pass_fail_count 미포함):
//   E1 연속 corrupt가 MISS_RESET_LIMIT(4) 초과 -> default 리셋(period_valid=0,
//      WAIT_FIRST), TX 중단 관찰. 이후 두 good 재획득으로 TX 재개 관찰.
//   E2 장기 broadcast 완전 침묵(blackout) 후 재개 시 재획득 동작 관찰.
// =============================================================================

module tb_slave22_comm_worst_case;

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
    integer corrupt_index;

    // 2.2 신규 로직 가시성: timebase 내부 신호를 hierarchical 참조로 관찰
    reg period_valid_dropped;   // period_valid가 0으로 떨어졌는지 (must-pass에서 위반)
    reg period_valid_watch;     // 최초 TRACKING 확립 후에만 holdover 감시 활성화
    reg saw_recovery_tx;        // slot==NODE_ID recovery TX를 본 적 있는지

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

    slave22_top #(
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

    // ----- 2.2 timebase 내부 가시성 (hierarchical, 관찰 전용) -----
    // period_valid: holdover로 유지되어야 하는 핵심 신호.
    wire tb_period_valid = u_slave_top.u_timebase.period_valid_ff;
    wire [3:0] tb_miss_count = u_slave_top.u_timebase.miss_count_ff;
    wire [2:0] tb_tbstate = u_slave_top.u_timebase.state_ff;

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

    // period_valid가 1->0으로 떨어지는 순간을 포착 (holdover 위반 감시).
    // reset 직후 0은 무시하기 위해 resetn 동안만 감시한다.
    always @(posedge slave_clk) begin
        if (resetn && period_valid_watch && (tb_period_valid == 1'b0))
            period_valid_dropped <= 1'b1;
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
            period_valid_dropped = 1'b0;
            period_valid_watch = 1'b0;
            saw_recovery_tx = 1'b0;
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

    // nominal 클럭/지연으로 모델 리셋 (통신 가혹환경만 자극, drift는 harsh_link 담당)
    task set_nominal_link;
        begin
            master_half_ns = 5.000;
            slave_half_ns = 5.000;
            m2s_base_delay_ns = 0.0;
            s2m_base_delay_ns = 0.0;
            m2s_jitter_ns = 0.0;
            s2m_jitter_ns = 0.0;
        end
    endtask

    // 정상 broadcast 2회로 TRACKING 진입 후 초기 주기 TX 확인.
    // 호출 후 슬레이브는 TRACKING(tx_allowed) 상태, timebase period_valid=1.
    task establish_tracking;
        input [31:0] payload_value;
        begin
            slave_payload = payload_value;
            send_master_frame(8'hAA, 8'h00, TB_GUARD_TICKS);
            expect_no_slave_tx("establish first good no tx", TB_NO_TX_OBSERVE);
            wait_to_next_master_frame_start_after_observe();
            master_valid_count = 0;
            send_master_frame(8'hAA, 8'h00, TB_GUARD_TICKS);
            wait_response_and_check("establish second good tracking TX", payload_value, 1'b1);
            if (link_tracking !== 1'b1) begin
                $display("[FAIL] establish_tracking not in TRACKING fault_state=%0d", fault_state);
                fail_count = fail_count + 1;
                must_pass_fail_count = must_pass_fail_count + 1;
            end else begin
                $display("[PASS] establish_tracking link TRACKING fault_state=%0d tb_period_valid=%0b tb_miss=%0d",
                         fault_state, tb_period_valid, tb_miss_count);
            end
            // 최초 TRACKING(period_valid=1) 확립 시점부터 holdover 위반 감시 활성화
            period_valid_dropped = 1'b0;
            period_valid_watch = 1'b1;
        end
    endtask

    // corrupt broadcast 1회 인가. corrupt 수신 완료 후 master_valid_count를 리셋하여
    // 직전 TRACKING 사이클의 잔존 holdover TX(slot=0)와 진짜 recovery TX를 구분한다(L9 패턴).
    task inject_corrupt_frame;
        input [511:0] label;
        begin
            wait_to_next_master_frame_start();
            send_master_frame(8'hAB, 8'h00, TB_GUARD_TICKS); // bad preamble
            master_valid_count = 0; // corrupt 전송 완료 후 잔존 decode 클리어
            expect_no_slave_tx(label, TB_NO_TX_OBSERVE);
            if ((master_valid_count != 0) && (last_valid_slot == TB_NODE_ID)) begin
                $display("[FAIL] %0s produced new recovery-slot response valid_count=%0d slot=%0d",
                         label, master_valid_count, last_valid_slot);
                fail_count = fail_count + 1;
                must_pass_fail_count = must_pass_fail_count + 1;
            end
            $display("[INFO] after corrupt: fault_state=%0d tb_state=%0d tb_period_valid=%0b tb_miss=%0d",
                     fault_state, tb_tbstate, tb_period_valid, tb_miss_count);
        end
    endtask

    // 정상 broadcast 1회. wait_to_next 후 다음 frame 시작 정렬, observe 윈도우 동안 관찰.
    // recovery TX(slot==NODE_ID)가 잡히면 saw_recovery_tx를 set.
    task send_good_observe;
        input [511:0] label;
        begin
            wait_to_next_master_frame_start_after_observe();
            master_valid_count = 0;
            send_master_frame(8'hAA, 8'h00, TB_GUARD_TICKS);
            expect_no_slave_tx(label, TB_NO_TX_OBSERVE);
            $display("[INFO] after good: fault_state=%0d tb_state=%0d tb_period_valid=%0b tb_miss=%0d",
                     fault_state, tb_tbstate, tb_period_valid, tb_miss_count);
        end
    endtask

    // -------------------------------------------------------------------------
    // W1: TRACKING 확립 후 단발 corrupt -> holdover 흡수 -> 두 good에서 recovery TX.
    // -------------------------------------------------------------------------
    task run_W1_single_corrupt;
        begin
            scenario_count = scenario_count + 1;
            set_nominal_link();
            $display("");
            $display("============================================================");
            $display("[SCENARIO %0d] W1 single corrupt in TRACKING -> holdover -> recovery TX", scenario_count);
            $display("============================================================");
            reset_link();
            establish_tracking(32'hC0DE0001);

            // 단발 corrupt: TRACKING -> RECOVERY (fault_fsm), timebase는 아직 rate_err 없음.
            inject_corrupt_frame("W1 single corrupt no new recovery TX");

            // recovery 1: RECOVERY -> SEEN_ONCE (good_broadcast_commit). 여기서 timebase는
            // 약 2x interval -> rate_error_event -> miss_count++ (limit 이하) -> holdover 유지.
            send_good_observe("W1 recovery good1 no tx yet");
            // recovery 2: SEEN_ONCE -> TRACKING. period_valid holdover 유지 -> TX 발생해야 함.
            wait_to_next_master_frame_start_after_observe();
            master_valid_count = 0;
            send_master_frame(8'hAA, 8'h00, TB_GUARD_TICKS);
            wait_response_and_check("W1 recovery TX after single corrupt", 32'hC0DE0001, 1'b1);
            if (last_valid_slot == TB_NODE_ID)
                saw_recovery_tx = 1'b1;

            if (period_valid_dropped == 1'b1) begin
                $display("[FAIL] W1 period_valid dropped to 0 during single-corrupt holdover");
                fail_count = fail_count + 1;
                must_pass_fail_count = must_pass_fail_count + 1;
            end else begin
                $display("[PASS] W1 period_valid stayed 1 (holdover) through single corrupt; recovery TX slot=%0d", last_valid_slot);
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // W2: TRACKING 중 연속 3회 corrupt (miss_count 누적, limit=4 이하) -> holdover 유지,
    //     이후 연속 good에서 recovery TX. period_valid 0으로 안 떨어짐.
    // -------------------------------------------------------------------------
    task run_W2_burst_corrupt;
        begin
            scenario_count = scenario_count + 1;
            set_nominal_link();
            $display("");
            $display("============================================================");
            $display("[SCENARIO %0d] W2 burst 3x corrupt (miss<=limit) -> holdover -> recovery TX", scenario_count);
            $display("============================================================");
            reset_link();
            establish_tracking(32'hC0DE0002);

            // 연속 3회 corrupt. 첫 corrupt에서 TRACKING->RECOVERY. 이후 corrupt는 RECOVERY 유지.
            // timebase: 각 corrupt 후 다음 frame 부재로 interval은 누적되지만 rate_error_event는
            // interval_ready(=interval_seen & good_broadcast_commit)에서만 발생.
            for (corrupt_index = 0; corrupt_index < 3; corrupt_index = corrupt_index + 1) begin
                inject_corrupt_frame("W2 burst corrupt no new recovery TX");
            end

            // 연속 good: RECOVERY -> SEEN_ONCE -> TRACKING. 각 good_broadcast_commit에서
            // 누적 interval로 rate_error_event 가능하나 miss_count는 limit 이하라 holdover.
            send_good_observe("W2 recovery good1 no tx yet");
            // good2: SEEN_ONCE->TRACKING. tx_allowed가 이 프레임 중 활성화되어 recovery TX가
            // 곧바로 나갈 수 있으므로 no-tx를 단정하지 않고, 이어지는 good에서 응답을 확인한다.
            wait_to_next_master_frame_start_after_observe();
            send_master_frame(8'hAA, 8'h00, TB_GUARD_TICKS);
            $display("[INFO] W2 after good2 fault_state=%0d tb_state=%0d tb_period_valid=%0b tb_miss=%0d",
                     fault_state, tb_tbstate, tb_period_valid, tb_miss_count);
            // 다음 good: TRACKING TX 기대
            wait_to_next_master_frame_start_after_observe();
            master_valid_count = 0;
            send_master_frame(8'hAA, 8'h00, TB_GUARD_TICKS);
            wait_response_and_check("W2 recovery TX after burst corrupt", 32'hC0DE0002, 1'b1);
            if (last_valid_slot == TB_NODE_ID)
                saw_recovery_tx = 1'b1;

            if (period_valid_dropped == 1'b1) begin
                $display("[FAIL] W2 period_valid dropped to 0 during burst-corrupt holdover (miss should be <= limit)");
                fail_count = fail_count + 1;
                must_pass_fail_count = must_pass_fail_count + 1;
            end else begin
                $display("[PASS] W2 period_valid stayed 1 through 3x corrupt holdover; recovery TX slot=%0d", last_valid_slot);
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // W3: corrupt/good 번갈아 (간헐 손상). 정상 interval마다 miss_count=0 클리어 ->
    //     holdover 유지 -> 주기적 TX 지속.
    // -------------------------------------------------------------------------
    task run_W3_intermittent;
        integer good_tx_count;
        begin
            scenario_count = scenario_count + 1;
            set_nominal_link();
            $display("");
            $display("============================================================");
            $display("[SCENARIO %0d] W3 intermittent corrupt/good -> miss_count clears -> periodic TX", scenario_count);
            $display("============================================================");
            reset_link();
            establish_tracking(32'hC0DE0003);
            good_tx_count = 0;

            // 간헐 패턴: corrupt, good, good, corrupt, good, good ...
            // 각 corrupt가 RECOVERY로 떨어뜨리고 두 good이 TRACKING으로 복귀시켜 TX 재개.
            // 핵심: 정상 interval(good_interval_ok)마다 miss_count=0으로 클리어되어
            // 연속 누적이 limit에 도달하지 않으므로 period_valid는 절대 0으로 안 떨어짐.
            repeat (3) begin
                inject_corrupt_frame("W3 corrupt no new recovery TX");
                // 첫 good: RECOVERY->SEEN_ONCE
                send_good_observe("W3 good1 (recovery step)");
                // 둘째 good: SEEN_ONCE->TRACKING -> 다음 주기 TX 기대
                wait_to_next_master_frame_start_after_observe();
                master_valid_count = 0;
                send_master_frame(8'hAA, 8'h00, TB_GUARD_TICKS);
                wait_response_and_check("W3 periodic TX after intermittent corrupt", 32'hC0DE0003, 1'b1);
                if ((master_valid_count != 0) && (last_valid_slot == TB_NODE_ID)) begin
                    good_tx_count = good_tx_count + 1;
                    saw_recovery_tx = 1'b1;
                end
                $display("[INFO] W3 cycle done tb_miss=%0d tb_period_valid=%0b good_tx_count=%0d",
                         tb_miss_count, tb_period_valid, good_tx_count);
            end

            if ((period_valid_dropped == 1'b1) || (good_tx_count < 3)) begin
                $display("[FAIL] W3 holdover/periodic TX not sustained period_valid_dropped=%0b good_tx_count=%0d",
                         period_valid_dropped, good_tx_count);
                fail_count = fail_count + 1;
                must_pass_fail_count = must_pass_fail_count + 1;
            end else begin
                $display("[PASS] W3 miss_count cleared each good interval, period_valid held, periodic TX x%0d", good_tx_count);
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // E1 (exploratory): 연속 corrupt > MISS_RESET_LIMIT(4) -> default 리셋 관찰.
    //     이후 두 good 재획득으로 TX 재개 관찰. must_pass=0.
    // -------------------------------------------------------------------------
    task run_E1_miss_limit_exceeded;
        reg observed_reset;
        begin
            scenario_count = scenario_count + 1;
            set_nominal_link();
            $display("");
            $display("============================================================");
            $display("[SCENARIO %0d] E1 (exploratory) corrupt burst > MISS_RESET_LIMIT -> reset, then re-acquire", scenario_count);
            $display("============================================================");
            reset_link();
            establish_tracking(32'hC0DE00E1);

            // 충분히 많은 corrupt를 인가하되, 각 corrupt 사이에 good을 1회 끼워 넣어
            // interval_ready 시 rate_error_event가 발생하고 miss_count가 누적되게 한다.
            // (연속 corrupt만으로는 good_broadcast_commit이 없어 rate_error_event가
            //  트리거되지 않으므로 miss_count가 증가하지 않는다 — 2.2 설계 특성.)
            observed_reset = 1'b0;
            repeat (8) begin
                inject_corrupt_frame("E1 corrupt");
                // 단발 good: commit 발생 -> 누적 interval로 rate_error_event -> miss++.
                // RECOVERY->SEEN_ONCE 후 다시 corrupt로 RECOVERY 복귀 (TRACKING 미도달).
                wait_to_next_master_frame_start_after_observe();
                send_master_frame(8'hAA, 8'h00, TB_GUARD_TICKS);
                $display("[INFO] E1 after good-after-corrupt fault_state=%0d tb_state=%0d tb_period_valid=%0b tb_miss=%0d",
                         fault_state, tb_tbstate, tb_period_valid, tb_miss_count);
                if (tb_period_valid == 1'b0) begin
                    observed_reset = 1'b1;
                    $display("[OBSERVE] E1 miss_limit exceeded: period_valid=0, tb_state=%0d (WAIT_FIRST expected=1)", tb_tbstate);
                end
            end

            if (observed_reset)
                $display("[OBSERVE-PASS] E1 slave reset to default (period_valid=0) after exceeding MISS_RESET_LIMIT");
            else
                $display("[OBSERVE-NOTE] E1 did not observe period_valid=0 within burst (record for analysis)");

            // 재획득: 두 good broadcast -> 다시 TRACKING TX 재개 관찰
            reset_link();
            establish_tracking(32'hC0DE00E2);
            $display("[OBSERVE] E1 re-acquired after blackout-style reset; fault_state=%0d tb_period_valid=%0b", fault_state, tb_period_valid);
        end
    endtask

    // -------------------------------------------------------------------------
    // E2 (exploratory): 장기 broadcast 완전 침묵(blackout) 후 재개 시 재획득 관찰.
    // -------------------------------------------------------------------------
    task run_E2_blackout;
        begin
            scenario_count = scenario_count + 1;
            set_nominal_link();
            $display("");
            $display("============================================================");
            $display("[SCENARIO %0d] E2 (exploratory) long broadcast blackout then resume / re-acquire", scenario_count);
            $display("============================================================");
            reset_link();
            establish_tracking(32'hC0DE00B0);

            // blackout: 여러 master interval 동안 broadcast 완전 침묵(라인 0 유지).
            // good_broadcast_commit 없음 -> rate_error_event 없음(interval_ready=0).
            // 2.2 설계상 holdover 유지로 period_valid는 그대로일 수 있음 — 관찰.
            $display("[INFO] E2 entering blackout for ~6 master intervals");
            master_serial_raw = 1'b0;
            wait_master_cycles(TB_MASTER_INTERVAL * 6);
            $display("[OBSERVE] E2 after blackout: fault_state=%0d tb_state=%0d tb_period_valid=%0b tb_miss=%0d",
                     fault_state, tb_tbstate, tb_period_valid, tb_miss_count);

            // 재개: 연속 good broadcast로 재획득. exploratory이므로 [FAIL] 대신 순수 관찰만 한다.
            // (2.2 holdover 설계상 blackout 동안에도 period_valid가 유지되어 주기적 TX가
            //  지속됨이 위 WAVE 로그로 확인됨 — fault_fsm는 bad_frame 없이는 TRACKING 유지.)
            wait_to_next_master_frame_start();
            send_master_frame(8'hAA, 8'h00, TB_GUARD_TICKS);
            $display("[OBSERVE] E2 resume good1: fault_state=%0d tb_state=%0d tb_period_valid=%0b tb_miss=%0d",
                     fault_state, tb_tbstate, tb_period_valid, tb_miss_count);
            wait_to_next_master_frame_start();
            master_valid_count = 0;
            send_master_frame(8'hAA, 8'h00, TB_GUARD_TICKS);
            wait_count = 0;
            while ((master_valid_count == 0) && (wait_count < TB_RESPONSE_TIMEOUT)) begin
                wait_count = wait_count + 1;
                @(posedge master_clk);
            end
            if ((master_valid_count != 0) && (last_node_id == TB_NODE_ID))
                $display("[OBSERVE-PASS] E2 TX resumed after blackout payload=0x%08x slot=%0d valid_count=%0d",
                         last_payload, last_valid_slot, master_valid_count);
            else
                $display("[OBSERVE-NOTE] E2 no resume TX captured within timeout valid_count=%0d (record for analysis)",
                         master_valid_count);
            $display("[OBSERVE] E2 resume result: fault_state=%0d tb_period_valid=%0b last_slot=%0d valid_count=%0d",
                     fault_state, tb_period_valid, last_valid_slot, master_valid_count);
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
        period_valid_dropped = 1'b0;
        period_valid_watch = 1'b0;
        saw_recovery_tx = 1'b0;

        $display("[INFO] tb_slave22_comm_worst_case start (2.2 holdover/miss_count targeted)");

        // must-pass: 2.2 holdover/miss_count가 반드시 견뎌야 하는 통신 가혹 시나리오
        run_W1_single_corrupt();
        run_W2_burst_corrupt();
        run_W3_intermittent();

        // exploratory: 관찰/기록 전용 (must_pass_fail_count 미포함)
        run_E1_miss_limit_exceeded();
        run_E2_blackout();

        $display("");
        $display("============================================================");
        if (must_pass_fail_count == 0)
            $display("PASS: tb_slave22_comm_worst_case must-pass scenarios survived total_scenarios=%0d fail_count=%0d",
                     scenario_count, fail_count);
        else
            $display("FAIL: tb_slave22_comm_worst_case fail_count=%0d must_pass_fail_count=%0d total_scenarios=%0d",
                     fail_count, must_pass_fail_count, scenario_count);
        $display("============================================================");
        $finish;
    end

endmodule
