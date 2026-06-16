`timescale 1ns / 1ps


module TFTLCDctrl (
    input wire clk,  
    input wire rstn,
    
    input wire [2:0] slot,      
    input wire [37:0] clk_cnt, 
    input wire [31:0] DIV,    
    input wire GPIO_in,  

    output wire opclk,      
    output wire Hsync,         
    output wire Vsync,    
    output wire [4:0] R,     
    output wire [5:0] G,    
    output wire [4:0] B,    
    output wire TFTLCD_Tpower, 
    output wire TFTLCD_DE_out 
);
   
    wire [9:0] HsyncCount;
    wire [8:0] VsyncCount;
    wire hDE;
    wire vDE;
    wire DE;

    assign TFTLCD_DE_out = hDE & vDE;
    assign TFTLCD_Tpower = 1'b1;
    assign DE = hDE & vDE;

    g2m g2m_u0(
        .rstn(rstn),
        .clk(clk),
        .opclk(opclk)
    );

    horizontal horizontal_u0(
        .rstn(rstn),
        .clk(opclk),
        .HsyncCount(HsyncCount),
        .Hsync(Hsync),
        .hDE(hDE)
    );

    vertical vertical_u0(
        .rstn(rstn),
        .clk(opclk),
        .HsyncCount(HsyncCount),
        .VsyncCount(VsyncCount),
        .Vsync(Vsync),
        .vDE(vDE)
    );

    rgb rgb_u0(
        .clk(clk),      
        .opclk(opclk),  
        .rstn(rstn),
        .HsyncCount(HsyncCount),
        .VsyncCount(VsyncCount),
        .DE(DE),
        
        .slot(slot),
        .clk_cnt(clk_cnt),    
        .DIV(DIV),          
        .GPIO_in(GPIO_in),
        
        .R(R), 
        .G(G), 
        .B(B)
    );

endmodule