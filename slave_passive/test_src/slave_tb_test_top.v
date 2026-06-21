`timescale 1ns / 1ps

// ---------------------------------------------------------------------------
// slave_tb_test_top
// ---------------------------------------------------------------------------
// 푸시버튼(active-low) 하나로 slot 0~7 전체 payload를 실시간으로 변경한다.
// 버튼을 누를 때마다 각 슬롯의 payload가 아래 단위로 증가한다.
//
//   slot 0 : +1      slot 1 : +2      slot 2 : +4      slot 3 : +8
//   slot 4 : +16     slot 5 : +32     slot 6 : +64     slot 7 : +128
//
// slot 0~5 : btn_payload_ctrl 출력 → i_reg_data_out0~5
// slot 6~7 : btn_payload_ctrl 출력 → i_pl_payload6/7  (valid=1 고정)
//
// 핀 연결 요약
//   i_clk          : 250MHz 시스템 클럭
//   i_resetn        : active-low 리셋
//   i_BTN          : 페이로드 변경 버튼 (평소 HIGH, 누르면 LOW, AA18)
//   i_master_serial : 마스터 직렬 입력
//   o_slave_serial  : 슬레이브 직렬 출력
//   o_led[0]       : 마스터 수신선 상태
//   o_led[1]       : 슬레이브 송신선 상태
// ---------------------------------------------------------------------------
module slave_tb_test_top #(
    parameter [7:0]  ACTIVE_SLOT = 8'b1111_1111,   // slot 0~7 전체 활성화
    parameter [31:0] DIV_REG     = 32'd2500000,
    parameter [9:0]  GUARD_TICKS = 10'd8
) (
    input  wire       i_clk,
    input  wire       i_resetn,

    input  wire       i_BTN,          // 페이로드 변경 버튼 (active-low)

    input  wire       i_master_serial,
    output wire       o_slave_serial,

    output wire [1:0] o_led
);

    // -----------------------------------------------------------------------
    // 버튼 → payload 변환 (slot 0~7 전체)
    // -----------------------------------------------------------------------
    wire [31:0] btn_payload0;
    wire [31:0] btn_payload1;
    wire [31:0] btn_payload2;
    wire [31:0] btn_payload3;
    wire [31:0] btn_payload4;
    wire [31:0] btn_payload5;
    wire [31:0] btn_payload6;
    wire [31:0] btn_payload7;

    btn_payload_ctrl #(
        .CLK_FREQ_HZ (250_000_000),
        .SAMPLE_MS   (20)
    ) u_btn_payload_ctrl (
        .i_CLK      (i_clk),
        .i_RST_N    (i_resetn),
        .i_BTN      (i_BTN),
        .o_PAYLOAD0 (btn_payload0),
        .o_PAYLOAD1 (btn_payload1),
        .o_PAYLOAD2 (btn_payload2),
        .o_PAYLOAD3 (btn_payload3),
        .o_PAYLOAD4 (btn_payload4),
        .o_PAYLOAD5 (btn_payload5),
        .o_PAYLOAD6 (btn_payload6),
        .o_PAYLOAD7 (btn_payload7)
    );

    // -----------------------------------------------------------------------
    // slave 코어
    // -----------------------------------------------------------------------
    wire slave_serial;
    wire slave_oe;
    wire irq;

    assign o_slave_serial = slave_serial;
    assign o_led[0]       = i_master_serial;
    assign o_led[1]       = slave_serial;

    slave_ip_top u_slave_ip_top (
        .i_clk                  (i_clk),
        .i_resetn               (i_resetn),

        .i_reg_enable           (1'b1),
        .i_reg_guard_ticks      (GUARD_TICKS),
        .i_reg_active_slot      (ACTIVE_SLOT),
        .i_reg_div              (DIV_REG),
        .i_reg_data_out0        (btn_payload0),
        .i_reg_data_out1        (btn_payload1),
        .i_reg_data_out2        (btn_payload2),
        .i_reg_data_out3        (btn_payload3),
        .i_reg_data_out4        (btn_payload4),
        .i_reg_data_out5        (btn_payload5),
        .i_reg_write_pulse      (1'b1),
        .i_event_clear_mask     (32'b0),
        .i_fault_clear_mask     (32'b0),

        .o_status_reg_value     (),
        .o_event_reg_value      (),
        .o_fault_reg_value      (),

        .i_master_serial        (i_master_serial),
        .i_pl_payload6          (btn_payload6),
        .i_pl_payload6_valid    (1'b1),
        .i_pl_payload7          (btn_payload7),
        .i_pl_payload7_valid    (1'b1),
        .o_slave_serial         (slave_serial),
        .o_slave_oe             (slave_oe),
        .o_irq                  (irq)
    );

endmodule
