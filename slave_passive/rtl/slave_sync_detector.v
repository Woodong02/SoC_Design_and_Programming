`timescale 1ns / 1ps

// ---------------------------------------------------------------------------
// slave_sync_detector
// ---------------------------------------------------------------------------
// master serial 입력을 2단 FF로 동기화하고, idle 상태에서 관측된 유효 상승
// 에지만 sync pulse로 변환한다. TX/RX active 동안에는 프레임 내부 데이터
// 비트가 재동기로 해석되지 않도록 sync 감지를 막는다.
// ---------------------------------------------------------------------------
module slave_sync_detector (
    input  wire i_CLK,
    input  wire i_RESETN,
    input  wire i_SERIAL_IN,
    input  wire i_CFG_ENABLE,
    input  wire i_TX_ACTIVE,
    input  wire i_RX_ACTIVE,
    output wire o_SYNC_PULSE,
    output wire o_SERIAL_SYNC_FF
);

    // -----------------------------------------------------------------------
    // 내부 신호 선언
    // -----------------------------------------------------------------------

    wire clk;
    wire resetn;
    wire serial_in;
    wire cfg_enable;
    wire tx_active;
    wire rx_active;
    wire sync_edge_detected;
    wire sync_pulse;
    wire serial_sync_ff;

    reg serial_meta_ff;
    reg serial_sync_ff_reg;
    reg sync_pulse_ff;

    // -----------------------------------------------------------------------
    // 포트 버퍼링
    // -----------------------------------------------------------------------

    assign clk = i_CLK;
    assign resetn = i_RESETN;
    assign serial_in = i_SERIAL_IN;
    assign cfg_enable = i_CFG_ENABLE;
    assign tx_active = i_TX_ACTIVE;
    assign rx_active = i_RX_ACTIVE;

    // -----------------------------------------------------------------------
    // 조합 논리
    // -----------------------------------------------------------------------
    // serial_meta_ff는 현재 샘플, serial_sync_ff_reg는 직전 안정 샘플이다.
    // 둘의 0->1 전이를 보되, 코어가 송수신 중이면 무시한다.

    assign sync_edge_detected = cfg_enable & ~tx_active & ~rx_active &
                                ~serial_sync_ff_reg & serial_meta_ff;

    // -----------------------------------------------------------------------
    // 순차 레지스터
    // -----------------------------------------------------------------------
    // 비동기 입력 안정화용 2단 FF와 1-cycle sync pulse FF를 분리해 둔다.

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            serial_meta_ff <= 1'b0;
        end else begin
            serial_meta_ff <= serial_in;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            serial_sync_ff_reg <= 1'b0;
        end else begin
            serial_sync_ff_reg <= serial_meta_ff;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            sync_pulse_ff <= 1'b0;
        end else begin
            sync_pulse_ff <= sync_edge_detected;
        end
    end

    // -----------------------------------------------------------------------
    // 출력 버퍼링
    // -----------------------------------------------------------------------

    assign sync_pulse = sync_pulse_ff;
    assign serial_sync_ff = serial_sync_ff_reg;

    assign o_SYNC_PULSE = sync_pulse;
    assign o_SERIAL_SYNC_FF = serial_sync_ff;

endmodule
