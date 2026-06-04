`timescale 1ns / 1ps

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
endmodule