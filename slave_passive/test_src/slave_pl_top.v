`timescale 1ns / 1ps

// ---------------------------------------------------------------------------
// slave_pl_top
// ---------------------------------------------------------------------------
// slave_ip_top을 PL 단독으로 구동하기 위한 parameter 기반 래퍼이다.
// PS/AXI 없이 합성할 때 이 모듈을 top으로 사용한다.
//
// [설정값 변경 위치]
//   아래 parameter 선언부를 수정한다.
//   - NODE_ID      : 응답할 슬롯 번호 (0~7)
//   - DIV_REG      : bit_period_ticks - 1  (bit_period_ticks = DIV_REG + 1)
//   - GUARD_TICKS  : 슬롯 간 guard 클럭 수 (최소 4)
//   - DATA_OUT0~5  : 슬롯 0~5 payload 값
// ---------------------------------------------------------------------------
module slave_pl_top #(
    // ------------------------------------------------------------------
    // ★ 설정값 변경 위치
    // ------------------------------------------------------------------
    parameter [7:0]  ACTIVE_SLOT = 8'b0000_1111,   // 슬롯 0~3 활성화
    parameter [31:0] DIV_REG     = 32'd2500000,      // 2^18 - 1 → bit_period = 2^18 클럭
    parameter [9:0]  GUARD_TICKS = 10'd8,        // 슬롯 간 guard
    parameter [31:0] DATA_OUT0   = 32'h1111_1111,   // 슬롯 0 번호
    parameter [31:0] DATA_OUT1   = 32'h2222_2222,   // 슬롯 1 번호
    parameter [31:0] DATA_OUT2   = 32'h3333_3333,   // 슬롯 2 번호
    parameter [31:0] DATA_OUT3   = 32'h4444_4444,   // 슬롯 3 번호
    parameter [31:0] DATA_OUT4   = 32'h5555_5555,
    parameter [31:0] DATA_OUT5   = 32'h6666_6666
    // ------------------------------------------------------------------
) (
    input  wire i_clk,
    input  wire i_resetn,

    input  wire i_master_serial,
    output wire o_slave_serial,

    // LED: [0] = 수신선 상태, [1] = 송신선 상태
    output wire [1:0] o_led
);

    wire slave_serial;
    wire slave_oe;
    wire irq;

    assign o_slave_serial = slave_serial;
    assign o_led[0]       = i_master_serial;
    assign o_led[1]       = slave_serial;

    slave_ip_top u_slave_ip_top (
        .i_clk                  (i_clk),
        .i_resetn               (i_resetn),

        // 설정값: parameter 상수로 고정
        .i_reg_enable           (1'b1),
        .i_reg_guard_ticks      (GUARD_TICKS),
        .i_reg_active_slot      (ACTIVE_SLOT),
        .i_reg_div              (DIV_REG),
        .i_reg_data_out0        (DATA_OUT0),
        .i_reg_data_out1        (DATA_OUT1),
        .i_reg_data_out2        (DATA_OUT2),
        .i_reg_data_out3        (DATA_OUT3),
        .i_reg_data_out4        (DATA_OUT4),
        .i_reg_data_out5        (DATA_OUT5),
        .i_reg_write_pulse      (1'b1),
        .i_event_clear_mask     (32'b0),
        .i_fault_clear_mask     (32'b0),

        // status 출력: PL 단독이므로 미연결
        .o_status_reg_value     (),
        .o_event_reg_value      (),
        .o_fault_reg_value      (),

        // 통신 포트
        .i_master_serial        (i_master_serial),
        .i_pl_payload6          (32'b0),
        .i_pl_payload6_valid    (1'b0),
        .i_pl_payload7          (32'b0),
        .i_pl_payload7_valid    (1'b0),
        .o_slave_serial         (slave_serial),
        .o_slave_oe             (slave_oe),
        .o_irq                  (irq)
    );

endmodule
