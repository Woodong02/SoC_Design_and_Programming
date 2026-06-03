`timescale 1ns / 1ps

module slave2_line_sync (
    input  wire i_CLK,
    input  wire i_RESETN,
    input  wire i_SERIAL_ASYNC,
    output wire o_SERIAL_SYNC
);

    wire clk;
    wire resetn;
    wire serial_async;
    wire serial_sync;

    reg ff_sync_stage1;
    reg ff_sync_stage2;

    assign clk          = i_CLK;
    assign resetn       = i_RESETN;
    assign serial_async = i_SERIAL_ASYNC;

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            ff_sync_stage1 <= 1'b0;
        else
            ff_sync_stage1 <= serial_async;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            ff_sync_stage2 <= 1'b0;
        else
            ff_sync_stage2 <= ff_sync_stage1;
    end

    assign serial_sync = ff_sync_stage2;
    assign o_SERIAL_SYNC = serial_sync;

endmodule
