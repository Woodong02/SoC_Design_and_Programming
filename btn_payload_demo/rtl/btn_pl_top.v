`timescale 1ns / 1ps

// ---------------------------------------------------------------------------
// btn_pl_top
// ---------------------------------------------------------------------------
// 버튼 payload 데모 최상위 모듈.
// i_BTN 하나만으로 슬롯 0~7의 payload가 각기 다른 단위로 증가하는 것을
// 확인할 수 있다.
// ---------------------------------------------------------------------------
module btn_pl_top (
    input  wire        i_CLK,
    input  wire        i_RST_N,
    input  wire        i_BTN,
    output wire [31:0] o_PAYLOAD0,
    output wire [31:0] o_PAYLOAD1,
    output wire [31:0] o_PAYLOAD2,
    output wire [31:0] o_PAYLOAD3,
    output wire [31:0] o_PAYLOAD4,
    output wire [31:0] o_PAYLOAD5,
    output wire [31:0] o_PAYLOAD6,
    output wire [31:0] o_PAYLOAD7
);

    btn_payload_ctrl #(
        .CLK_FREQ_HZ (250_000_000),
        .SAMPLE_MS   (20)
    ) u_ctrl (
        .i_CLK      (i_CLK),
        .i_RST_N    (i_RST_N),
        .i_BTN      (i_BTN),
        .o_PAYLOAD0 (o_PAYLOAD0),
        .o_PAYLOAD1 (o_PAYLOAD1),
        .o_PAYLOAD2 (o_PAYLOAD2),
        .o_PAYLOAD3 (o_PAYLOAD3),
        .o_PAYLOAD4 (o_PAYLOAD4),
        .o_PAYLOAD5 (o_PAYLOAD5),
        .o_PAYLOAD6 (o_PAYLOAD6),
        .o_PAYLOAD7 (o_PAYLOAD7)
    );

endmodule
