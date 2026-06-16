`timescale 1ns / 1ps

// ---------------------------------------------------------------------------
// slave_frame_builder
// ---------------------------------------------------------------------------
// sequencer의 slot TX 명령과 payload table의 payload를 master 호환 50-bit
// 응답 프레임으로 변환한다. payload가 invalid인 명령은 소비만 하고 송신하지
// 않아, sequencer가 해당 슬롯을 fault/skip으로 처리한 뒤 계속 진행할 수 있다.
// ---------------------------------------------------------------------------
module slave_frame_builder (
    input  wire        i_TX_CMD_VALID,
    input  wire [2:0]  i_TX_CMD_SLOT_ID,
    input  wire [31:0] i_SELECTED_PAYLOAD,
    input  wire        i_SELECTED_PAYLOAD_VALID,
    input  wire        i_TX_FRAME_READY,
    output wire        o_TX_CMD_READY,
    output wire        o_TX_CMD_ACCEPT,
    output wire        o_TX_CMD_SKIP,
    output wire [49:0] o_TX_FRAME,
    output wire        o_TX_FRAME_VALID
);

    // -----------------------------------------------------------------------
    // 내부 신호 선언
    // -----------------------------------------------------------------------

    wire        tx_cmd_valid;
    wire [2:0]  tx_cmd_slot_id;
    wire [31:0] selected_payload;
    wire        selected_payload_valid;
    wire        tx_frame_ready;

    wire [34:0] encoder_data;
    wire [41:0] encoder_codeword;
    wire [49:0] tx_frame;
    wire        tx_cmd_ready;
    wire        tx_cmd_accept;
    wire        tx_cmd_skip;
    wire        tx_frame_valid;

    // -----------------------------------------------------------------------
    // 포트 버퍼링
    // -----------------------------------------------------------------------

    assign tx_cmd_valid = i_TX_CMD_VALID;
    assign tx_cmd_slot_id = i_TX_CMD_SLOT_ID;
    assign selected_payload = i_SELECTED_PAYLOAD;
    assign selected_payload_valid = i_SELECTED_PAYLOAD_VALID;
    assign tx_frame_ready = i_TX_FRAME_READY;

    // -----------------------------------------------------------------------
    // 응답 프레임 생성
    // -----------------------------------------------------------------------
    // slave 응답 payload는 {slot_id[2:0], payload[31:0]}이고, Hamming 인코딩 후
    // 8'hAA preamble을 붙여 50-bit 직렬 프레임을 만든다.

    assign encoder_data = {tx_cmd_slot_id, selected_payload};

    slave_hamming_enc u_slave_hamming_enc (
        .i_DATA(encoder_data),
        .o_CODEWORD(encoder_codeword)
    );

    assign tx_frame = {8'hAA, encoder_codeword};

    // -----------------------------------------------------------------------
    // Handshake 및 skip 판정
    // -----------------------------------------------------------------------
    // invalid payload 명령은 ready를 즉시 반환하고 skip pulse를 만들어
    // downstream serializer를 점유하지 않는다.

    assign tx_cmd_ready = (selected_payload_valid == 1'b1) ? tx_frame_ready : 1'b1;
    assign tx_cmd_accept = tx_cmd_valid & selected_payload_valid & tx_frame_ready;
    assign tx_cmd_skip = tx_cmd_valid & ~selected_payload_valid;
    assign tx_frame_valid = tx_cmd_accept;

    // -----------------------------------------------------------------------
    // 출력 버퍼링
    // -----------------------------------------------------------------------

    assign o_TX_CMD_READY = tx_cmd_ready;
    assign o_TX_CMD_ACCEPT = tx_cmd_accept;
    assign o_TX_CMD_SKIP = tx_cmd_skip;
    assign o_TX_FRAME = tx_frame;
    assign o_TX_FRAME_VALID = tx_frame_valid;

endmodule
