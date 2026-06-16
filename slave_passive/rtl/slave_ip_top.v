`timescale 1ns / 1ps

// ---------------------------------------------------------------------------
// slave_ip_top
// ---------------------------------------------------------------------------
// passive slave 통신 프로토콜 코어의 최상위 통합 모듈이다.
// AXI-Lite 인터페이스는 이 모듈 외부에서 담당한다. 이 모듈은 raw register
// 값을 입력으로 받고, sync 감지/수신/슬롯 스케줄링/송신 경로/상태 집계를
// 묶는다. 외부 register block 없이 직접 구동하거나, Vivado IP wrapper가
// slave_axi_lite_regs를 붙이는 방식 모두에 대응한다.
// ---------------------------------------------------------------------------
module slave_ip_top #(
    parameter [9:0] MIN_GUARD_TICKS = 10'd4
) (
    input  wire        i_clk,
    input  wire        i_resetn,

    // -----------------------------------------------------------------------
    // raw register 입력 (AXI register file 또는 다른 설정 소스에서 올 수 있음)
    // -----------------------------------------------------------------------
    input  wire        i_reg_enable,
    input  wire [9:0]  i_reg_guard_ticks,
    input  wire [7:0]  i_reg_active_slot,
    input  wire [31:0] i_reg_div,
    input  wire [31:0] i_reg_data_out0,
    input  wire [31:0] i_reg_data_out1,
    input  wire [31:0] i_reg_data_out2,
    input  wire [31:0] i_reg_data_out3,
    input  wire [31:0] i_reg_data_out4,
    input  wire [31:0] i_reg_data_out5,
    input  wire        i_reg_write_pulse,
    input  wire [31:0] i_event_clear_mask,
    input  wire [31:0] i_fault_clear_mask,

    // -----------------------------------------------------------------------
    // status 출력 (AXI register file 또는 다른 상태 readback 소스로 전달)
    // -----------------------------------------------------------------------
    output wire [31:0] o_status_reg_value,
    output wire [31:0] o_event_reg_value,
    output wire [31:0] o_fault_reg_value,

    // -----------------------------------------------------------------------
    // 통신 포트
    // -----------------------------------------------------------------------
    input  wire        i_master_serial,
    input  wire [31:0] i_pl_payload6,
    input  wire        i_pl_payload6_valid,
    input  wire [31:0] i_pl_payload7,
    input  wire        i_pl_payload7_valid,
    output wire        o_slave_serial,
    output wire        o_slave_oe,
    output wire        o_irq
);

    // -----------------------------------------------------------------------
    // 내부 신호 선언
    // -----------------------------------------------------------------------
    wire clk;
    wire resetn;
    wire master_serial;
    wire [31:0] pl_payload6;
    wire        pl_payload6_valid;
    wire [31:0] pl_payload7;
    wire        pl_payload7_valid;

    wire [31:0] status_reg_value;
    wire [31:0] event_reg_value;
    wire [31:0] fault_reg_value;

    wire        cfg_enable;
    wire [9:0]  cfg_guard_ticks;
    wire [7:0]  cfg_active_slot;
    wire [32:0] cfg_bit_period_ticks;
    wire [31:0] cfg_bit_period_reload;
    wire [31:0] cfg_data_out0;
    wire [31:0] cfg_data_out1;
    wire [31:0] cfg_data_out2;
    wire [31:0] cfg_data_out3;
    wire [31:0] cfg_data_out4;
    wire [31:0] cfg_data_out5;
    wire        cfg_commit_pulse;
    wire        cfg_pending;
    wire        cfg_freeze_pulse;
    wire        core_idle;
    wire        guard_timing_invalid;
    wire        core_timing_enable;

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

    wire        schedule_active;
    wire [63:0] sync_tick_counter;
    wire [63:0] frame_ticks;
    wire [63:0] slot_ticks;
    wire [63:0] guard_half_ticks;
    wire [7:0]  slot_time_match;
    wire [63:0] slot_target_tick0;
    wire [63:0] slot_target_tick1;
    wire [63:0] slot_target_tick2;
    wire [63:0] slot_target_tick3;
    wire [63:0] slot_target_tick4;
    wire [63:0] slot_target_tick5;
    wire [63:0] slot_target_tick6;
    wire [63:0] slot_target_tick7;

    wire        seq_tx_cmd_valid;
    wire [2:0]  seq_tx_cmd_slot_id;
    wire        seq_tx_skip_invalid_payload;
    wire        seq_slot_cycle_done;
    wire [2:0]  seq_current_slot;
    wire        seq_slot_valid;
    wire        seq_fault_tx_overlap;
    wire        frame_tx_cmd_ready;
    wire        frame_tx_cmd_accept;
    wire        frame_tx_cmd_skip;
    wire [2:0]  selected_payload_slot_id;
    wire [31:0] selected_payload;
    wire        selected_payload_valid;
    wire [49:0] tx_frame;
    wire        tx_frame_valid;
    wire        tx_frame_ready;
    wire        slave_serial;
    wire        slave_oe;
    wire        tx_active;
    wire        tx_done;
    wire        irq;

    reg [7:0] halt_mask_pending_ff;
    reg [7:0] halt_mask_applied_ff;

    // -----------------------------------------------------------------------
    // 포트 버퍼링
    // -----------------------------------------------------------------------
    assign clk              = i_clk;
    assign resetn           = i_resetn;
    assign master_serial    = i_master_serial;
    assign pl_payload6      = i_pl_payload6;
    assign pl_payload6_valid = i_pl_payload6_valid;
    assign pl_payload7      = i_pl_payload7;
    assign pl_payload7_valid = i_pl_payload7_valid;

    // -----------------------------------------------------------------------
    // 상위 제어 정책
    // -----------------------------------------------------------------------
    // GUARD_TICKS가 최소값보다 작으면 fault를 세우고 코어 전체를 막는다.

    assign guard_timing_invalid = cfg_enable & (cfg_guard_ticks < MIN_GUARD_TICKS);
    assign core_timing_enable   = cfg_enable & ~guard_timing_invalid;
    assign cfg_freeze_pulse     = core_timing_enable & sync_pulse;
    assign core_idle            = ~schedule_active & ~rx_active & ~tx_active & ~seq_slot_valid;

    // -----------------------------------------------------------------------
    // 안전 경계 설정 섀도우
    // -----------------------------------------------------------------------
    // raw register 값을 idle 또는 다음 안전 경계에서 shadow로 commit한다.

    slave_cfg_shadow u_slave_cfg_shadow (
        .i_clk(clk),
        .i_resetn(resetn),
        .i_reg_enable(i_reg_enable),
        .i_reg_guard_ticks(i_reg_guard_ticks),
        .i_reg_active_slot(i_reg_active_slot),
        .i_reg_div(i_reg_div),
        .i_reg_data_out0(i_reg_data_out0),
        .i_reg_data_out1(i_reg_data_out1),
        .i_reg_data_out2(i_reg_data_out2),
        .i_reg_data_out3(i_reg_data_out3),
        .i_reg_data_out4(i_reg_data_out4),
        .i_reg_data_out5(i_reg_data_out5),
        .i_reg_write_pulse(i_reg_write_pulse),
        .i_cfg_freeze_pulse(cfg_freeze_pulse),
        .i_core_idle(core_idle),
        .o_cfg_enable(cfg_enable),
        .o_cfg_guard_ticks(cfg_guard_ticks),
        .o_cfg_active_slot(cfg_active_slot),
        .o_cfg_bit_period_ticks(cfg_bit_period_ticks),
        .o_cfg_bit_period_reload(cfg_bit_period_reload),
        .o_cfg_data_out0(cfg_data_out0),
        .o_cfg_data_out1(cfg_data_out1),
        .o_cfg_data_out2(cfg_data_out2),
        .o_cfg_data_out3(cfg_data_out3),
        .o_cfg_data_out4(cfg_data_out4),
        .o_cfg_data_out5(cfg_data_out5),
        .o_cfg_commit_pulse(cfg_commit_pulse),
        .o_cfg_pending(cfg_pending)
    );

    // -----------------------------------------------------------------------
    // Master broadcast 동기 감지 및 수신
    // -----------------------------------------------------------------------
    // rx_active로 마스킹하여 수신 중의 데이터 비트를 재동기로 오인하지 않는다.

    slave_sync_detector u_slave_sync_detector (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_SERIAL_IN(master_serial),
        .i_CFG_ENABLE(core_timing_enable),
        .i_TX_ACTIVE(tx_active),
        .i_RX_ACTIVE(rx_active),
        .o_SYNC_PULSE(sync_pulse),
        .o_SERIAL_SYNC_FF(serial_sync_ff)
    );

    slave_broadcast_rx u_slave_broadcast_rx (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_SERIAL_IN(serial_sync_ff),
        .i_CFG_ENABLE(core_timing_enable),
        .i_CFG_BIT_PERIOD_RELOAD(cfg_bit_period_reload),
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

    // -----------------------------------------------------------------------
    // 슬롯 타이밍 스케줄러
    // -----------------------------------------------------------------------
    slave_timing_scheduler u_slave_timing_scheduler (
        .clk(clk),
        .resetn(resetn),
        .cfg_enable(core_timing_enable),
        .sync_pulse(sync_pulse),
        .cycle_done(seq_slot_cycle_done),
        .cfg_bit_period_ticks(cfg_bit_period_ticks),
        .cfg_guard_ticks(cfg_guard_ticks),
        .schedule_active(schedule_active),
        .sync_tick_counter(sync_tick_counter),
        .frame_ticks(frame_ticks),
        .slot_ticks(slot_ticks),
        .guard_half_ticks(guard_half_ticks),
        .slot_time_match(slot_time_match),
        .slot_target_tick0(slot_target_tick0),
        .slot_target_tick1(slot_target_tick1),
        .slot_target_tick2(slot_target_tick2),
        .slot_target_tick3(slot_target_tick3),
        .slot_target_tick4(slot_target_tick4),
        .slot_target_tick5(slot_target_tick5),
        .slot_target_tick6(slot_target_tick6),
        .slot_target_tick7(slot_target_tick7)
    );

    // -----------------------------------------------------------------------
    // 슬롯 순회 및 TX 명령 발행
    // -----------------------------------------------------------------------
    slave_slot_sequencer u_slave_slot_sequencer (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_CFG_ENABLE(core_timing_enable),
        .i_SYNC_PULSE(sync_pulse),
        .i_CFG_ACTIVE_SLOT(cfg_active_slot),
        .i_HALT_MASK_SNAPSHOT(halt_mask_pending_ff),
        .i_SLOT_TIME_MATCH(slot_time_match),
        .i_TX_CMD_READY(frame_tx_cmd_ready),
        .i_TX_CMD_ACCEPT(frame_tx_cmd_accept),
        .i_TX_CMD_SKIP(frame_tx_cmd_skip),
        .i_TX_DONE(tx_done),
        .o_TX_CMD_VALID(seq_tx_cmd_valid),
        .o_TX_CMD_SLOT_ID(seq_tx_cmd_slot_id),
        .o_TX_SKIP_INVALID_PAYLOAD(seq_tx_skip_invalid_payload),
        .o_SLOT_CYCLE_DONE(seq_slot_cycle_done),
        .o_STS_CURRENT_SLOT(seq_current_slot),
        .o_STS_SLOT_VALID(seq_slot_valid),
        .o_FAULT_TX_OVERLAP(seq_fault_tx_overlap)
    );

    // -----------------------------------------------------------------------
    // Payload 선택 및 응답 프레임 생성
    // -----------------------------------------------------------------------
    // slot 0..5는 PS 레지스터 payload를, slot 6..7은 PL 입력 payload를 사용한다.

    slave_payload_table u_slave_payload_table (
        .i_SLOT_ID(seq_tx_cmd_slot_id),
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
        .i_TX_CMD_VALID(seq_tx_cmd_valid),
        .i_TX_CMD_SLOT_ID(selected_payload_slot_id),
        .i_SELECTED_PAYLOAD(selected_payload),
        .i_SELECTED_PAYLOAD_VALID(selected_payload_valid),
        .i_TX_FRAME_READY(tx_frame_ready),
        .o_TX_CMD_READY(frame_tx_cmd_ready),
        .o_TX_CMD_ACCEPT(frame_tx_cmd_accept),
        .o_TX_CMD_SKIP(frame_tx_cmd_skip),
        .o_TX_FRAME(tx_frame),
        .o_TX_FRAME_VALID(tx_frame_valid)
    );

    // -----------------------------------------------------------------------
    // 직렬 송신기
    // -----------------------------------------------------------------------
    slave_tx_serializer u_slave_tx_serializer (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_TX_FRAME(tx_frame),
        .i_TX_FRAME_VALID(tx_frame_valid),
        .i_CFG_BIT_PERIOD_RELOAD(cfg_bit_period_reload),
        .o_TX_FRAME_READY(tx_frame_ready),
        .o_SLAVE_SERIAL(slave_serial),
        .o_SLAVE_OE(slave_oe),
        .o_TX_ACTIVE(tx_active),
        .o_TX_DONE(tx_done)
    );

    // -----------------------------------------------------------------------
    // STATUS/EVENT/FAULT/IRQ 집계
    // -----------------------------------------------------------------------
    slave_status_event u_slave_status_event (
        .i_clk(clk),
        .i_resetn(resetn),
        .i_sts_enabled(cfg_enable),
        .i_sts_synced(schedule_active),
        .i_sts_rx_active(rx_active),
        .i_sts_tx_active(tx_active),
        .i_sts_current_slot(seq_current_slot),
        .i_sts_slot_valid(seq_slot_valid),
        .i_sts_halt_mask(halt_mask_applied_ff),
        .i_sts_cfg_pending(cfg_pending),
        .i_sts_pl_payload6_valid(pl_payload6_valid),
        .i_sts_pl_payload7_valid(pl_payload7_valid),
        .i_evt_sync_detected(sync_pulse),
        .i_evt_rx_frame_done(rx_frame_done),
        .i_evt_tx_done(tx_done),
        .i_evt_slot_cycle_done(seq_slot_cycle_done),
        .i_evt_preamble_err(rx_preamble_err),
        .i_evt_ham_1bit_err(broadcast_1bit_err),
        .i_evt_ham_2bit_err(broadcast_2bit_err),
        .i_evt_cfg_commit(cfg_commit_pulse),
        .i_fault_tx_overlap(seq_fault_tx_overlap),
        .i_fault_slot_timing_invalid(guard_timing_invalid),
        .i_fault_pl_payload6_invalid(frame_tx_cmd_skip & (seq_tx_cmd_slot_id == 3'd6)),
        .i_fault_pl_payload7_invalid(frame_tx_cmd_skip & (seq_tx_cmd_slot_id == 3'd7)),
        .i_fault_rx_ham_2bit(broadcast_2bit_err),
        .i_event_clear_mask(i_event_clear_mask),
        .i_fault_clear_mask(i_fault_clear_mask),
        .o_status_reg_value(status_reg_value),
        .o_event_reg_value(event_reg_value),
        .o_fault_reg_value(fault_reg_value),
        .o_irq(irq)
    );

    // -----------------------------------------------------------------------
    // Broadcast halt mask snapshot
    // -----------------------------------------------------------------------
    // pending은 broadcast 수신 시 갱신, applied는 sync 경계에서 고정한다.

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            halt_mask_pending_ff <= 8'd0;
        end else if (broadcast_valid == 1'b1) begin
            halt_mask_pending_ff <= broadcast_halt_mask;
        end else begin
            halt_mask_pending_ff <= halt_mask_pending_ff;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            halt_mask_applied_ff <= 8'd0;
        end else if (cfg_freeze_pulse == 1'b1) begin
            halt_mask_applied_ff <= halt_mask_pending_ff;
        end else begin
            halt_mask_applied_ff <= halt_mask_applied_ff;
        end
    end

    // -----------------------------------------------------------------------
    // 출력 버퍼링
    // -----------------------------------------------------------------------
    assign o_status_reg_value = status_reg_value;
    assign o_event_reg_value  = event_reg_value;
    assign o_fault_reg_value  = fault_reg_value;
    assign o_slave_serial     = slave_serial;
    assign o_slave_oe         = slave_oe;
    assign o_irq              = irq;

endmodule
