`timescale 1ns / 1ps


module rgb (
    input  wire        clk,         // 25MHz  (캡처 도메인)
    input  wire        opclk,       // 12.5MHz (LCD 출력 도메인)
    input  wire        rstn,

    // LCD 타이밍 (opclk 기준)
    input  wire [9:0]  HsyncCount,  // 0~524
    input  wire [8:0]  VsyncCount,  // 0~285
    input  wire        DE,

    // TDMA 신호 (clk 기준)
    input  wire [2:0]  slot,
    input  wire [37:0] clk_cnt,
    input  wire [31:0] DIV,
    input  wire        GPIO_in,

    output reg  [4:0]  R,
    output reg  [5:0]  G,
    output reg  [4:0]  B
);

// =========================================================
// 1. 파형 캡처 (negedge clk 도메인 - 원본과 동일)
// =========================================================
reg [49:0] wave_buf  [0:7];
reg [5:0]  pixel_cnt [0:7];
reg [31:0] smp_cnt   [0:7];

reg [37:0] clk_cnt_r;
always @(negedge clk or negedge rstn)
    if (!rstn) clk_cnt_r <= 38'd1;
    else       clk_cnt_r <= clk_cnt;

wire slot_start = (clk_cnt == 38'd0) && (clk_cnt_r != 38'd0);

wire [31:0] safe_div = (DIV < 32'd2) ? 32'd2 : DIV;

integer i;
always @(negedge clk or negedge rstn) begin
    if (!rstn) begin
        for (i = 0; i < 8; i = i + 1) begin
            wave_buf[i]  <= 50'd0;
            pixel_cnt[i] <= 6'd0;
            smp_cnt[i]   <= 32'd0;
        end
    end else begin
        if (slot_start) begin
            wave_buf[slot]  <= 50'd0;
            pixel_cnt[slot] <= 6'd0;
            smp_cnt[slot]   <= 32'd0;
        end else if (pixel_cnt[slot] < 6'd50) begin
            if (smp_cnt[slot] >= (safe_div >> 1) - 32'd1) begin
                wave_buf[slot][pixel_cnt[slot]] <= GPIO_in;
                pixel_cnt[slot] <= pixel_cnt[slot] + 6'd1;
                smp_cnt[slot]   <= 32'd0;
            end else begin
                smp_cnt[slot] <= smp_cnt[slot] + 32'd1;
            end
        end
    end
end

// =========================================================
// 2. CDC: clk → opclk 2단 FF 동기화
// =========================================================
(* ASYNC_REG = "TRUE" *) reg [49:0] wave_s1 [0:7];
(* ASYNC_REG = "TRUE" *) reg [49:0] wave_s2 [0:7];
(* ASYNC_REG = "TRUE" *) reg [5:0]  pcnt_s1 [0:7];
(* ASYNC_REG = "TRUE" *) reg [5:0]  pcnt_s2 [0:7];

always @(negedge opclk or negedge rstn) begin
    if (!rstn) begin
        for (i = 0; i < 8; i = i + 1) begin
            wave_s1[i] <= 50'd0; wave_s2[i] <= 50'd0;
            pcnt_s1[i] <= 6'd0;  pcnt_s2[i] <= 6'd0;
        end
    end else begin
        for (i = 0; i < 8; i = i + 1) begin
            wave_s1[i] <= wave_buf[i];
            wave_s2[i] <= wave_s1[i];
            pcnt_s1[i] <= pixel_cnt[i];
            pcnt_s2[i] <= pcnt_s1[i];
        end
    end
end

// =========================================================
// 3. 픽셀 판정 (조합 논리 - opclk 도메인)
// =========================================================
// 열: HsyncCount 43~202(col0), 203~362(col1), 363~522(col2)
// 행: VsyncCount 12~101(row0), 102~191(row1), 192~281(row2)
wire [1:0] col = (HsyncCount < 10'd203) ? 2'd0 :
                 (HsyncCount < 10'd363) ? 2'd1 : 2'd2;
wire [1:0] row = (VsyncCount < 9'd102)  ? 2'd0 :
                 (VsyncCount < 9'd192)  ? 2'd1 : 2'd2;

wire [3:0] box      = ({2'd0, row} * 4'd3) + {2'd0, col};
wire       valid_box = (DE == 1'b1) &&
                       (box <= 4'd7) &&
                       (VsyncCount < 9'd282);

// 셀 내 로컬 좌표
wire [9:0] col_base = (col == 2'd1) ? 10'd203 :
                      (col == 2'd2) ? 10'd363 : 10'd43;
wire [7:0] local_x  = HsyncCount[7:0] - col_base[7:0];  // 0~159

wire [8:0] row_base = (row == 2'd1) ? 9'd102 :
                      (row == 2'd2) ? 9'd192 : 9'd12;
wire [7:0] local_y  = VsyncCount[7:0] - row_base[7:0];  // 0~89

// 파형 영역 (local_x 0~49)
wire       in_wave  = (local_x < 8'd50);
wire [5:0] bit_idx  = local_x[5:0];

wire       pix_val  = (valid_box && in_wave) ?
                      wave_s2[box[2:0]][bit_idx] : 1'b0;

// 커서
wire [5:0] cur_pos   = pcnt_s2[box[2:0]];
wire       is_cursor = valid_box && in_wave &&
                       (bit_idx == cur_pos) && (cur_pos < 6'd50);

// 파형 픽셀 (Hi→위 30px, Lo→아래 30px)
wire sig_hi  =  pix_val && (local_y < 8'd30);
wire sig_lo  = !pix_val && (local_y >= 8'd60);
wire sig_px  = in_wave && (sig_hi || sig_lo);

// 테두리/선
wire is_border   = (local_x == 8'd0)  || (local_x == 8'd159) ||
                   (local_y == 8'd0)  || (local_y == 8'd89);
wire is_midline  = (local_y == 8'd44) || (local_y == 8'd45);
wire is_waveedge = (local_x == 8'd50);

// =========================================================
// 4. RGB 출력 (negedge opclk 순차 논리)
// =========================================================
always @(negedge opclk or negedge rstn) begin
    if (!rstn) begin
        R <= 5'd0; G <= 6'd0; B <= 5'd0;
    end else if (!DE || !valid_box) begin
        R <= 5'd0; G <= 6'd0; B <= 5'd0;
    end else if (is_cursor) begin
        R <= 5'b11111; G <= 6'b000000; B <= 5'b00000;  // 빨강
    end else if (is_border) begin
        R <= 5'b01000; G <= 6'b010000; B <= 5'b01000;  // 회색 테두리
    end else if (is_waveedge) begin
        R <= 5'b00100; G <= 6'b001000; B <= 5'b00100;  // 어두운 회색
    end else if (sig_px) begin
        R <= 5'b00000; G <= 6'b111111; B <= 5'b00000;  // 초록 파형
    end else if (is_midline) begin
        R <= 5'b00011; G <= 6'b000110; B <= 5'b00011;  // 기준선
    end else begin
        R <= 5'b00001; G <= 6'b000011; B <= 5'b00010;  // 배경
    end
end

endmodule
