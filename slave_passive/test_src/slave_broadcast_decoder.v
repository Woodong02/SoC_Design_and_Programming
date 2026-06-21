`timescale 1ns / 1ps

// ---------------------------------------------------------------------------
// slave_broadcast_decoder
// ---------------------------------------------------------------------------
// 수신된 42-bit Hamming codeword를 복호화하고 master broadcast field를
// 추출한다. 2-bit 오류가 아니면 broadcast_valid를 세우며, 1-bit/2-bit
// 오류 정보는 상태 집계 모듈에서 EVENT/FAULT로 사용한다.
// ---------------------------------------------------------------------------
module slave_broadcast_decoder (
    input  wire [41:0] i_RX_CODEWORD,
    input  wire        i_RX_CODEWORD_VALID,
    output wire        o_BROADCAST_VALID,
    output wire [7:0]  o_BROADCAST_HALT_MASK,
    output wire [9:0]  o_BROADCAST_GUARD_TICKS,
    output wire        o_BROADCAST_1BIT_ERR,
    output wire        o_BROADCAST_2BIT_ERR
);

    // -----------------------------------------------------------------------
    // 내부 신호 선언
    // -----------------------------------------------------------------------

    wire [41:0] rx_codeword;
    wire        rx_codeword_valid;
    wire [34:0] decoded_data;
    wire        ham_1bit_err;
    wire        ham_2bit_err;
    wire        broadcast_valid;
    wire [7:0]  broadcast_halt_mask;
    wire [9:0]  broadcast_guard_ticks;

    // -----------------------------------------------------------------------
    // 포트 버퍼링
    // -----------------------------------------------------------------------

    assign rx_codeword = i_RX_CODEWORD;
    assign rx_codeword_valid = i_RX_CODEWORD_VALID;

    // -----------------------------------------------------------------------
    // Hamming 복호화
    // -----------------------------------------------------------------------
    // master broadcast payload는 {halt_mask[7:0], guard_ticks[9:0], reserved[16:0]}
    // 구조로 인코딩된다.

    slave_hamming_dec u_slave_hamming_dec (
        .i_CODEWORD(rx_codeword),
        .o_DATA(decoded_data),
        .o_HAM_1BIT_ERR(ham_1bit_err),
        .o_HAM_2BIT_ERR(ham_2bit_err)
    );

    // -----------------------------------------------------------------------
    // Field 추출 및 출력 버퍼링
    // -----------------------------------------------------------------------

    assign broadcast_valid = rx_codeword_valid & ~ham_2bit_err;
    assign broadcast_halt_mask = decoded_data[34:27];
    assign broadcast_guard_ticks = decoded_data[26:17];

    assign o_BROADCAST_VALID = broadcast_valid;
    assign o_BROADCAST_HALT_MASK = broadcast_halt_mask;
    assign o_BROADCAST_GUARD_TICKS = broadcast_guard_ticks;
    assign o_BROADCAST_1BIT_ERR = rx_codeword_valid & ham_1bit_err;
    assign o_BROADCAST_2BIT_ERR = rx_codeword_valid & ham_2bit_err;

endmodule
