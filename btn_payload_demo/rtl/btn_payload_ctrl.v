`timescale 1ns / 1ps

// ---------------------------------------------------------------------------
// btn_payload_ctrl
// ---------------------------------------------------------------------------
// 푸시 버튼(active-low) 입력을 20ms 주기로 샘플링하여 안누름→누름 전환
// (HIGH→LOW)을 한 번만 검출하고, 슬롯별 payload 레지스터를 증가시킨다.
//
// 슬롯별 증가 단위:
//   slot 0 : +1      slot 1 : +2      slot 2 : +4      slot 3 : +8
//   slot 4 : +16     slot 5 : +32     slot 6 : +64     slot 7 : +128
// ---------------------------------------------------------------------------
module btn_payload_ctrl #(
    parameter integer CLK_FREQ_HZ = 250_000_000,
    parameter integer SAMPLE_MS   = 20
)(
    input  wire        i_CLK,
    input  wire        i_RST_N,
    input  wire        i_BTN,       // active-low: 평소 1, 누르면 0
    output reg  [31:0] o_PAYLOAD0,
    output reg  [31:0] o_PAYLOAD1,
    output reg  [31:0] o_PAYLOAD2,
    output reg  [31:0] o_PAYLOAD3,
    output reg  [31:0] o_PAYLOAD4,
    output reg  [31:0] o_PAYLOAD5,
    output reg  [31:0] o_PAYLOAD6,
    output reg  [31:0] o_PAYLOAD7
);

    // 250MHz × 20ms = 5,000,000 카운트 → 23비트 카운터로 충분
    localparam integer SAMPLE_CNT = (CLK_FREQ_HZ / 1000) * SAMPLE_MS;

    reg [22:0] cnt;
    reg        sample_tick;
    reg        btn_q;   // 직전 샘플 값

    // -----------------------------------------------------------------------
    // 20ms 주기 tick 생성
    // -----------------------------------------------------------------------
    always @(posedge i_CLK or negedge i_RST_N) begin
        if (!i_RST_N) begin
            cnt         <= 23'd0;
            sample_tick <= 1'b0;
        end else begin
            if (cnt == SAMPLE_CNT - 1) begin
                cnt         <= 23'd0;
                sample_tick <= 1'b1;
            end else begin
                cnt         <= cnt + 1'b1;
                sample_tick <= 1'b0;
            end
        end
    end

    // -----------------------------------------------------------------------
    // 버튼 이전 샘플 저장
    // -----------------------------------------------------------------------
    always @(posedge i_CLK or negedge i_RST_N) begin
        if (!i_RST_N)
            btn_q <= 1'b1;          // idle = 1 (not pressed)
        else if (sample_tick)
            btn_q <= i_BTN;
    end

    // -----------------------------------------------------------------------
    // 안누름(1) → 누름(0) 전환 검출
    // sample_tick 시점에 btn_q(이전)=1, i_BTN(현재)=0 일 때만 pulse
    // -----------------------------------------------------------------------
    wire btn_pressed = sample_tick & (btn_q == 1'b1) & (i_BTN == 1'b0);

    // -----------------------------------------------------------------------
    // 슬롯별 payload 레지스터
    // -----------------------------------------------------------------------
    always @(posedge i_CLK or negedge i_RST_N) begin
        if (!i_RST_N) begin
            o_PAYLOAD0 <= 32'd0;
            o_PAYLOAD1 <= 32'd0;
            o_PAYLOAD2 <= 32'd0;
            o_PAYLOAD3 <= 32'd0;
            o_PAYLOAD4 <= 32'd0;
            o_PAYLOAD5 <= 32'd0;
            o_PAYLOAD6 <= 32'd0;
            o_PAYLOAD7 <= 32'd0;
        end else if (btn_pressed) begin
            o_PAYLOAD0 <= o_PAYLOAD0 + 32'd1;
            o_PAYLOAD1 <= o_PAYLOAD1 + 32'd2;
            o_PAYLOAD2 <= o_PAYLOAD2 + 32'd4;
            o_PAYLOAD3 <= o_PAYLOAD3 + 32'd8;
            o_PAYLOAD4 <= o_PAYLOAD4 + 32'd16;
            o_PAYLOAD5 <= o_PAYLOAD5 + 32'd32;
            o_PAYLOAD6 <= o_PAYLOAD6 + 32'd64;
            o_PAYLOAD7 <= o_PAYLOAD7 + 32'd128;
        end
    end

endmodule
