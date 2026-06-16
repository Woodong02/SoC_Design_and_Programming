`timescale 1ns / 1ps

// ---------------------------------------------------------------------------
// slave_payload_table
// ---------------------------------------------------------------------------
// virtual slot 번호에 맞는 32-bit payload를 선택한다. slot 0..5는 AXI
// 레지스터에 저장된 PS payload를 사용하고, slot 6..7은 외부 PL payload와
// valid 신호를 그대로 따른다.
// ---------------------------------------------------------------------------
module slave_payload_table (
    input  wire [2:0]  i_SLOT_ID,
    input  wire [31:0] i_CFG_DATA_OUT0,
    input  wire [31:0] i_CFG_DATA_OUT1,
    input  wire [31:0] i_CFG_DATA_OUT2,
    input  wire [31:0] i_CFG_DATA_OUT3,
    input  wire [31:0] i_CFG_DATA_OUT4,
    input  wire [31:0] i_CFG_DATA_OUT5,
    input  wire [31:0] i_PL_PAYLOAD6,
    input  wire        i_PL_PAYLOAD6_VALID,
    input  wire [31:0] i_PL_PAYLOAD7,
    input  wire        i_PL_PAYLOAD7_VALID,
    output wire [2:0]  o_SELECTED_PAYLOAD_SLOT_ID,
    output wire [31:0] o_SELECTED_PAYLOAD,
    output wire        o_SELECTED_PAYLOAD_VALID
);

    // -----------------------------------------------------------------------
    // 내부 신호 선언
    // -----------------------------------------------------------------------

    wire [2:0]  slot_id;
    wire [31:0] cfg_data_out0;
    wire [31:0] cfg_data_out1;
    wire [31:0] cfg_data_out2;
    wire [31:0] cfg_data_out3;
    wire [31:0] cfg_data_out4;
    wire [31:0] cfg_data_out5;
    wire [31:0] pl_payload6;
    wire        pl_payload6_valid;
    wire [31:0] pl_payload7;
    wire        pl_payload7_valid;

    reg [31:0] selected_payload_reg;
    reg        selected_payload_valid_reg;

    wire [2:0]  selected_payload_slot_id;
    wire [31:0] selected_payload;
    wire        selected_payload_valid;

    // -----------------------------------------------------------------------
    // 포트 버퍼링
    // -----------------------------------------------------------------------

    assign slot_id = i_SLOT_ID;
    assign cfg_data_out0 = i_CFG_DATA_OUT0;
    assign cfg_data_out1 = i_CFG_DATA_OUT1;
    assign cfg_data_out2 = i_CFG_DATA_OUT2;
    assign cfg_data_out3 = i_CFG_DATA_OUT3;
    assign cfg_data_out4 = i_CFG_DATA_OUT4;
    assign cfg_data_out5 = i_CFG_DATA_OUT5;
    assign pl_payload6 = i_PL_PAYLOAD6;
    assign pl_payload6_valid = i_PL_PAYLOAD6_VALID;
    assign pl_payload7 = i_PL_PAYLOAD7;
    assign pl_payload7_valid = i_PL_PAYLOAD7_VALID;

    // -----------------------------------------------------------------------
    // Payload LUT
    // -----------------------------------------------------------------------
    // full-case TB가 각 slot의 동작을 직접 확인할 수 있도록 8-entry table
    // 형태의 case 문으로 작성한다. 존재하지 않는 slot은 invalid로 둔다.

    always @(*) begin
        case (slot_id)
            3'd0: begin
                selected_payload_reg = cfg_data_out0;
                selected_payload_valid_reg = 1'b1;
            end
            3'd1: begin
                selected_payload_reg = cfg_data_out1;
                selected_payload_valid_reg = 1'b1;
            end
            3'd2: begin
                selected_payload_reg = cfg_data_out2;
                selected_payload_valid_reg = 1'b1;
            end
            3'd3: begin
                selected_payload_reg = cfg_data_out3;
                selected_payload_valid_reg = 1'b1;
            end
            3'd4: begin
                selected_payload_reg = cfg_data_out4;
                selected_payload_valid_reg = 1'b1;
            end
            3'd5: begin
                selected_payload_reg = cfg_data_out5;
                selected_payload_valid_reg = 1'b1;
            end
            3'd6: begin
                selected_payload_reg = pl_payload6;
                selected_payload_valid_reg = pl_payload6_valid;
            end
            3'd7: begin
                selected_payload_reg = pl_payload7;
                selected_payload_valid_reg = pl_payload7_valid;
            end
            default: begin
                selected_payload_reg = 32'd0;
                selected_payload_valid_reg = 1'b0;
            end
        endcase
    end

    // -----------------------------------------------------------------------
    // 출력 버퍼링
    // -----------------------------------------------------------------------

    assign selected_payload_slot_id = slot_id;
    assign selected_payload = selected_payload_reg;
    assign selected_payload_valid = selected_payload_valid_reg;

    assign o_SELECTED_PAYLOAD_SLOT_ID = selected_payload_slot_id;
    assign o_SELECTED_PAYLOAD = selected_payload;
    assign o_SELECTED_PAYLOAD_VALID = selected_payload_valid;

endmodule
