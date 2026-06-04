`timescale 1ns / 1ps

//
// TFT-LCD Pure Hardware Oscilloscope Controller
// AXI BRAM 우회 및 TDMA 다이렉트 렌더링 매립 사양
//

module TFTLCDctrl (
    input wire clk,            // Zynq 시스템 클럭 (TDMA와 동일한 25MHz 인입)
    input wire rstn,
    
    // ==========================================
    // TDMA 혈관 직접 주입 포트 (대역폭 정합 완료)
    // ==========================================
    input wire [2:0] slot,       // 현재 통신 슬롯 (0~7)
    input wire [21:0] clk_cnt,   // 22비트 프레임 카운터
    input wire [15:0] DIV,       // 16비트 1비트당 클럭 수
    input wire GPIO_in,          // 현재 수신 중인 데이터
    // ==========================================

    output wire opclk,         // TFT-LCD Clock (12.5MHz 사출)
    output wire Hsync,         // TFT-LCD HSYNC
    output wire Vsync,         // TFT-LCD VSYNC
    output wire [4:0] R,       // TFT-LCD Red
    output wire [5:0] G,       // TFT-LCD Green
    output wire [4:0] B,       // TFT-LCD Blue
    output wire TFTLCD_Tpower, // TFT-LCD Backlight On signal
    output wire TFTLCD_DE_out  // TFT-LCD Data enable
);
   
    wire [9:0] HsyncCount;
    wire [8:0] VsyncCount;
    wire hDE;
    wire vDE;
    wire DE;

    // [필수 교정] LCD 즉사를 방지하는 정상 데이터 인에이블 배선
    assign TFTLCD_DE_out = hDE & vDE;
    assign TFTLCD_Tpower = 1'b1;
    assign DE = hDE & vDE;

    // 25MHz -> 12.5MHz 2분주 (사용자 검증 완료된 물리 블랙박스)
    g2m g2m_u0(
        .rstn(rstn),
        .clk(clk),
        .opclk(opclk)
    );

    // 수평 타이밍 카운터
    horizontal horizontal_u0(
        .rstn(rstn),
        .clk(opclk),
        .HsyncCount(HsyncCount),
        .Hsync(Hsync),
        .hDE(hDE)
    );

    // 수직 타이밍 카운터
    vertical vertical_u0(
        .rstn(rstn),
        .clk(opclk),
        .HsyncCount(HsyncCount),
        .VsyncCount(VsyncCount),
        .Vsync(Vsync),
        .vDE(vDE)
    );

    // 순수 PL 오실로스코프 렌더러 결착
    rgb rgb_u0(
        .clk(clk),       // TDMA 고속 클럭 (Write 도메인 - 현재 25MHz)
        .opclk(opclk),          // LCD 픽셀 클럭 (Read 도메인 - 12.5MHz)
        .rstn(rstn),
        .HsyncCount(HsyncCount),
        .VsyncCount(VsyncCount),
        .DE(DE),
        
        // 확장된 TDMA 포트 1:1 결착
        .slot(slot),
        .clk_cnt(clk_cnt),      // 22-bit
        .DIV(DIV),              // 16-bit
        .GPIO_in(GPIO_in),
        
        .R(R), 
        .G(G), 
        .B(B)
    );

endmodule