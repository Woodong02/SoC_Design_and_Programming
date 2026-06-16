`timescale 1ns / 1ps
// rgb.v  -  8-channel TDMA oscilloscope display
//
// 화면: 480x272, opclk=12.5MHz (clk의 절반)
// 그리드: 3열x3행, 각 셀 160x90px → 슬롯 0~7 + 우하단(box=8) 미사용
//
// 캡처 방식:
//   clk(25MHz) 도메인에서 슬롯별로 독립 샘플링.
//   슬롯 시작(clk_cnt==0 엣지) 시 해당 슬롯의 pixel_cnt/smp_cnt 리셋.
//   이후 매 safe_interval 클럭마다 GPIO_in 1샘플 → wave_buf[slot][pixel_cnt].
//   pixel_cnt 0~159가 채워지면 정지, 다음 슬롯 시작 시 다시 리셋.
//   → 슬롯마다 이전 파형을 지우고 새 파형으로 갱신 (롤링 오실로스코프).
//
// 파형 표시:
//   셀 높이 90px. Hi(1) → 위 30px 초록, Lo(0) → 아래 30px 초록.
//   중간 30px(30~59)는 배경색. 중간선(44~45px) 약한 회색선.
//   커서(빨강): 현재 캡처 중인 pixel_cnt 열.
//
// CDC (clock domain crossing):
//   wave_buf, pixel_cnt는 clk 도메인에서 write.
//   opclk 도메인에서 read 시 2단 FF 동기화 (* ASYNC_REG = "TRUE" *).
//   opclk = clk/2이므로 메타스테이빌리티 위험 최소.

module rgb (
    input  wire        clk,         // 25MHz  (TDMA 캡처 도메인)
    input  wire        opclk,       // 12.5MHz (LCD 픽셀 출력 도메인)
    input  wire        rstn,

    // LCD 타이밍 (horizontal.v, vertical.v 출력)
    input  wire [9:0]  HsyncCount,  // 0~524  (hDE: 43~522 → 480px)
    input  wire [9:0]  VsyncCount,  // 0~285  (vDE: 12~283 → 272px)
    input  wire        DE,

    // TDMA 신호
    input  wire [2:0]  slot,        // 현재 활성 슬롯 (0~7)
    input  wire [37:0] clk_cnt,     // 슬롯 내 클럭 카운터 (슬롯 시작 시 0)
    input  wire [31:0] DIV,         // 비트당 클럭 수
    input  wire        GPIO_in,     // 수신 GPIO 신호

    output reg  [4:0]  R,
    output reg  [5:0]  G,
    output reg  [4:0]  B
);

// =========================================================
// 파라미터
// =========================================================
// 슬롯당 총 클럭 수 ? 50 * DIV (가드 타임 제외).
// 이를 160 픽셀에 균등 배분 → 픽셀당 클럭 = 50*DIV / 160 = 5*DIV/16.
// 정수 근사: safe_interval = (50 * DIV) >> 4 / 10
//           = 50*DIV >> 4 (÷16 → 약 3.125*DIV, 160칸 × 3.125*DIV = 500*DIV/160 = 50*DIV/16 부족)
// 가장 단순하고 안전한 방법:
//   sample_interval = DIV >> 1  (비트당 클럭의 절반)
//   → 160샘플 = 80*DIV 클럭, 슬롯(50*DIV)보다 많으므로 실제로는 50비트 구간에서 멈춤
//   → 대신 pixel_cnt < 50일 때만 샘플링하면 정확히 50샘플 (1픽셀=1비트)
//
// 최종 결정: DIV>>1 간격으로 샘플링, pixel_cnt 0~49로 제한 (비트 1:1 대응)
// 화면에서 50픽셀만 사용하고 나머지 110픽셀은 배경 → 좌측 정렬 표시

// =========================================================
// 1. 파형 캡처 (clk 도메인)
// =========================================================
reg [7:0]   pixel_cnt [0:7];   // 슬롯별 현재 픽셀 카운터 (0~49)
reg [31:0]  smp_cnt   [0:7];   // 슬롯별 샘플 타이머
reg [49:0]  wave_buf  [0:7];   // 슬롯별 파형 (50비트, 1비트=1샘플)

// 슬롯 시작 엣지 감지: clk_cnt가 0이 되는 순간
reg [37:0] clk_cnt_r;
always @(posedge clk or negedge rstn)
    if (!rstn) clk_cnt_r <= 38'd1;
    else       clk_cnt_r <= clk_cnt;

wire slot_start = (clk_cnt == 38'd0) && (clk_cnt_r != 38'd0);

// 샘플 간격: DIV>>1 (비트 중앙 샘플링과 동일 간격)
// DIV==0 방지
wire [31:0] half_div      = (DIV == 32'd0) ? 32'd1 : (DIV >> 1);
wire [31:0] safe_interval = (half_div == 32'd0) ? 32'd1 : half_div;

integer idx;
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        for (idx = 0; idx < 8; idx = idx + 1) begin
            pixel_cnt[idx] <= 8'd0;
            smp_cnt[idx]   <= 32'd0;
            wave_buf[idx]  <= 50'd0;
        end
    end else begin
        if (slot_start) begin
            // 슬롯 시작: 해당 슬롯 카운터 리셋, 버퍼 클리어
            pixel_cnt[slot] <= 8'd0;
            smp_cnt[slot]   <= 32'd0;
            wave_buf[slot]  <= 50'd0;   // 새 파형 시작 전 지움
        end else begin
            // 50샘플 미만일 때만 샘플링
            if (pixel_cnt[slot] < 8'd50) begin
                if (smp_cnt[slot] >= safe_interval - 32'd1) begin
                    smp_cnt[slot]  <= 32'd0;
                    wave_buf[slot][pixel_cnt[slot]] <= GPIO_in;
                    pixel_cnt[slot] <= pixel_cnt[slot] + 8'd1;
                end else begin
                    smp_cnt[slot] <= smp_cnt[slot] + 32'd1;
                end
            end
            // pixel_cnt == 50이면 슬롯 종료까지 대기
        end
    end
end

// =========================================================
// 2. CDC: clk → opclk 2단 FF 동기화
// =========================================================
(* ASYNC_REG = "TRUE" *) reg [49:0] wave_s1 [0:7];
(* ASYNC_REG = "TRUE" *) reg [49:0] wave_s2 [0:7];

(* ASYNC_REG = "TRUE" *) reg [7:0]  pcnt_s1 [0:7];
(* ASYNC_REG = "TRUE" *) reg [7:0]  pcnt_s2 [0:7];

always @(posedge opclk or negedge rstn) begin
    if (!rstn) begin
        for (idx = 0; idx < 8; idx = idx + 1) begin
            wave_s1[idx] <= 50'd0;  wave_s2[idx] <= 50'd0;
            pcnt_s1[idx] <= 8'd0;   pcnt_s2[idx] <= 8'd0;
        end
    end else begin
        for (idx = 0; idx < 8; idx = idx + 1) begin
            wave_s1[idx] <= wave_buf[idx];
            wave_s2[idx] <= wave_s1[idx];
            pcnt_s1[idx] <= pixel_cnt[idx];
            pcnt_s2[idx] <= pcnt_s1[idx];
        end
    end
end

// =========================================================
// 3. 픽셀 좌표 계산 (opclk 도메인, 조합 논리)
// =========================================================
// x_pos: 0~479, y_pos: 0~271
wire [9:0] x_pos = (HsyncCount > 10'd42) ? (HsyncCount - 10'd43) : 10'd0;
wire [8:0] y_pos = (VsyncCount > 9'd11)  ? (VsyncCount[8:0] - 9'd12) : 9'd0;

// 열/행 인덱스
wire [1:0] col = (x_pos < 10'd160) ? 2'd0 :
                 (x_pos < 10'd320) ? 2'd1 : 2'd2;
wire [1:0] row = (y_pos < 9'd90)   ? 2'd0 :
                 (y_pos < 9'd180)  ? 2'd1 : 2'd2;

// box 번호 (0~8)
wire [3:0] box = ({2'd0, row} * 4'd3) + {2'd0, col};

// 유효한 슬롯 셀인지 (box<8, y<270)
wire valid_box = (box <= 4'd7) && (y_pos < 9'd270);

// 셀 내 로컬 x 좌표 (0~159), 곱셈 없이 mux로 계산
wire [9:0] col_base = (col == 2'd1) ? 10'd160 :
                      (col == 2'd2) ? 10'd320 : 10'd0;
wire [7:0] local_x = x_pos[7:0] - col_base[7:0];  // 0~159

// 셀 내 로컬 y 좌표 (0~89)
wire [8:0] row_base = (row == 2'd1) ? 9'd90 :
                      (row == 2'd2) ? 9'd180 : 9'd0;
wire [6:0] local_y = y_pos[6:0] - row_base[6:0];  // 0~89

// =========================================================
// 4. 파형 픽셀 판정 (opclk 도메인, 조합 논리)
// =========================================================
// local_x 0~49 → 파형 비트 인덱스 (1:1)
// local_x 50~159 → 배경 (파형 없음)
wire in_wave_area = (local_x < 8'd50);
wire [5:0] bit_idx = local_x[5:0];   // 0~49

wire pixel_val  = (valid_box && in_wave_area) ?
                  wave_s2[box[2:0]][bit_idx] : 1'b0;

// 커서: 현재 캡처 중인 열
wire [7:0] cursor_pos = pcnt_s2[box[2:0]];
wire is_cursor = valid_box && in_wave_area &&
                 (bit_idx == cursor_pos[5:0]) &&
                 (cursor_pos < 8'd50);

// 파형 영역 판정
// 셀 90px 분할: Hi영역 y 0~29, 전환영역 y 30~59, Lo영역 y 60~89
wire sig_hi_row = (local_y < 7'd30);
wire sig_lo_row = (local_y >= 7'd60);
wire signal_px  = in_wave_area && (
                    (pixel_val  && sig_hi_row) ||   // 1 → 위쪽
                    (!pixel_val && sig_lo_row)       // 0 → 아래쪽
                  );

// 셀 테두리 (1픽셀)
wire is_border = (local_x == 8'd0)   || (local_x == 8'd159) ||
                 (local_y == 7'd0)   || (local_y == 7'd89);

// 중간선 (y=44~45, Hi/Lo 경계 시각화)
wire is_midline = (local_y == 7'd44) || (local_y == 7'd45);

// 파형 영역 오른쪽 경계선 (x=50)
wire is_wave_edge = (local_x == 8'd50);

// =========================================================
// 5. RGB 출력 (opclk 도메인, 레지스터)
// =========================================================
always @(posedge opclk or negedge rstn) begin
    if (!rstn) begin
        R <= 5'd0; G <= 6'd0; B <= 5'd0;
    end else if (!DE || !valid_box) begin
        // 블랭킹 또는 미사용 영역
        R <= 5'd0; G <= 6'd0; B <= 5'd0;
    end else if (is_cursor) begin
        // 커서: 빨강
        R <= 5'b11111; G <= 6'b000000; B <= 5'b00000;
    end else if (is_border) begin
        // 셀 테두리: 밝은 회색
        R <= 5'b01000; G <= 6'b010000; B <= 5'b01000;
    end else if (is_wave_edge) begin
        // 파형 영역 우측 경계: 어두운 회색
        R <= 5'b00100; G <= 6'b001000; B <= 5'b00100;
    end else if (signal_px) begin
        // 파형: 밝은 초록
        R <= 5'b00000; G <= 6'b111111; B <= 5'b00000;
    end else if (is_midline) begin
        // 중간 기준선: 어두운 회색
        R <= 5'b00011; G <= 6'b000110; B <= 5'b00011;
    end else begin
        // 배경: 아주 어두운 청록 (오실로스코프 배경)
        R <= 5'b00001; G <= 6'b000011; B <= 5'b00010;
    end
end

endmodule


/*`timescale 1ns / 1ps

module rgb(
    input wire clk,              
    input wire opclk,            
    input wire rstn,
    input wire [9:0] HsyncCount, 
    input wire [9:0] VsyncCount, 
    input wire DE,

    // 38-bit / 32-bit 확장 TDMA 혈관 정합 유지
    input wire [2:0] slot,       
    input wire [37:0] clk_cnt,   
    input wire [31:0] DIV,       
    input wire GPIO_in,          

    output reg [4:0] R, 
    output reg [5:0] G,
    output reg [4:0] B
);

    // 1. PL 초경량 레지스터 버퍼 (400 Bits)
    reg [49:0] wave_buffer [0:7];

    // 2. 통신 기록 로직 (clk 도메인)
    reg [5:0] bit_idx;
    reg [31:0] local_clk_cnt;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            bit_idx <= 6'd0;
            local_clk_cnt <= 32'd0;
        end else begin
            if (clk_cnt == 38'd0) begin
                bit_idx <= 6'd0;
                local_clk_cnt <= 32'd0;
            end else begin
                local_clk_cnt <= local_clk_cnt + 32'd1;
                if (local_clk_cnt >= (DIV - 32'd1)) begin
                    local_clk_cnt <= 32'd0;
                    if (bit_idx < 6'd50) bit_idx <= bit_idx + 6'd1;
                end
            end

            // [교정 완료] 상수 오버플로우 방어 (slot <= 3'd7)
            if (slot <= 3'd7 && bit_idx < 6'd50) begin
                wave_buffer[slot][bit_idx] <= GPIO_in;
                if (bit_idx < 6'd49) 
                    wave_buffer[slot][bit_idx + 1] <= 1'b0; // 앞길 클리어 (스위핑)
            end
        end
    end

    // 3. 디스플레이 렌더링 로직 (opclk 도메인)
    wire [9:0] x_pos = (HsyncCount >= 10'd43) ? (HsyncCount - 10'd43) : 10'd0;
    wire [9:0] y_pos = (VsyncCount >= 10'd11) ? (VsyncCount - 10'd11) : 10'd0;

    wire [1:0] grid_x = (x_pos < 10'd160) ? 2'd0 : (x_pos < 10'd320) ? 2'd1 : 2'd2;
    wire [1:0] grid_y = (y_pos < 10'd90)  ? 2'd0 : (y_pos < 10'd180) ? 2'd1 : 2'd2;
    
    wire [3:0] current_box = (grid_y * 3) + grid_x; 
    wire [7:0] local_x = x_pos - (grid_x * 10'd160);    

    wire [5:0] read_bit_idx = (local_x * 3'd5) >> 4; 

    // current_box는 4비트(wire [3:0])이므로 4'd8 비교가 안전하게 작동함
    wire pixel_val = (current_box < 4'd8 && read_bit_idx < 6'd50) ? wave_buffer[current_box][read_bit_idx] : 1'b0;
    wire is_cursor = (current_box == slot) && (read_bit_idx == bit_idx);

    always @(posedge opclk) begin
        if (!rstn) begin
            R <= 0; G <= 0; B <= 0;
        end else if (DE) begin
            if (current_box < 4'd8) begin
                if (is_cursor) begin
                    R <= 5'b11111; G <= 6'b000000; B <= 5'b00000; // 스위핑 바늘
                end else if (pixel_val) begin
                    R <= 5'b00000; G <= 6'b111111; B <= 5'b00000; // 데이터 궤적
                end else begin
                    // 3x3 그리드 테두리선
                    if (local_x == 0 || local_x == 159 || (y_pos % 90) == 0 || (y_pos % 90) == 89) begin
                        R <= 5'b01111; G <= 6'b011111; B <= 5'b01111; 
                    end else begin
                        R <= 5'b00100; G <= 6'b001000; B <= 5'b01000; 
                    end
                end
            end else begin
                R <= 0; G <= 0; B <= 0;
            end
        end else begin
            R <= 0; G <= 0; B <= 0;
        end
    end
endmodule*/