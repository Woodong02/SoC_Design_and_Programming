module master_top (
    input wire clk,
    input wire resetn,
    input wire [9:0] DIV,
    input wire [9:0] GUARD_TICKS,
    input wire [2:0] NODE_CNT,
    input wire GPIO_in,

    output wire GPIO_out,
    output wire [31:0] err_cnt0,
    output wire [31:0] err_cnt1,
    output wire [31:0] err_cnt2,
    output wire [31:0] err_cnt3,
    output wire [31:0] err_cnt4,
    output wire [31:0] err_cnt5,
    output wire [31:0] err_cnt6,
    output wire [31:0] err_cnt7,
    output wire [31:0] slot_out0,
    output wire [31:0] slot_out1,
    output wire [31:0] slot_out2,
    output wire [31:0] slot_out3,
    output wire [31:0] slot_out4,
    output wire [31:0] slot_out5,
    output wire [31:0] slot_out6,
    output wire [31:0] slot_out7
);

    wire last_slot;
    wire slot;
    wire clk_cnt;
    wire slot_change;
    wire tx_trigger = (slot_change && slot==last_slot)? 1'b1 : 1'b0;
    wire [7:0] halt_cmd;
    wire data_bus;
    wire sig_bus;
    wire preamble_err;

    assign halt_cmd[0] = ((err_cnt0[31:24]+err_cnt0[23:16]+err_cnt0[15:8]+err_cnt0[7:0]) > 200) ? 1'b1 : 1'b0;
    assign halt_cmd[1] = ((err_cnt0[31:24]+err_cnt0[23:16]+err_cnt0[15:8]+err_cnt0[7:0]) > 200) ? 1'b1 : 1'b0;
    assign halt_cmd[2] = ((err_cnt0[31:24]+err_cnt0[23:16]+err_cnt0[15:8]+err_cnt0[7:0]) > 200) ? 1'b1 : 1'b0;
    assign halt_cmd[3] = ((err_cnt0[31:24]+err_cnt0[23:16]+err_cnt0[15:8]+err_cnt0[7:0]) > 200) ? 1'b1 : 1'b0;
    assign halt_cmd[4] = ((err_cnt0[31:24]+err_cnt0[23:16]+err_cnt0[15:8]+err_cnt0[7:0]) > 200) ? 1'b1 : 1'b0;
    assign halt_cmd[5] = ((err_cnt0[31:24]+err_cnt0[23:16]+err_cnt0[15:8]+err_cnt0[7:0]) > 200) ? 1'b1 : 1'b0;
    assign halt_cmd[6] = ((err_cnt0[31:24]+err_cnt0[23:16]+err_cnt0[15:8]+err_cnt0[7:0]) > 200) ? 1'b1 : 1'b0;
    assign halt_cmd[7] = ((err_cnt0[31:24]+err_cnt0[23:16]+err_cnt0[15:8]+err_cnt0[7:0]) > 200) ? 1'b1 : 1'b0;

    master_slot s0(.resetn(resetn), .clk(clk), .DIV(DIV), .GUARD_TICKS(GUARD_TICKS), .NODE_CNT(NODE_CNT),
                   .last_slot(last_slot), .slot_change(slot_change), .clk_cnt(clk_cnt));

    master_tx t0(.clk(clk), .resetn(resetn), .DIV(DIV), .tx_trigger(tx_trigger), .halt_cmd(halt_cmd),
                 .GPIO_out(GPIO_out));

    Master_rx r0(.clk(clk), .DIV(DIV), .GPIO_in(GPIO_in), .resetn(resetn), .slot_change(slot_change),
                 .data_out(data_bus), .out_sig(sig_bus), .preamble_err(preamble_err));

    Master_dec_ham dh0(.resetn(resetn), .clk(clk), .in_sig(sig_bus), .GUARD_TICKS(GUARD_TICKS), .data_in(data_bus),
                       .slot(slot), .clk_cnt(clk_cnt), .preamble_err(preamble_err), .slot_change(slot_change), .last_slot(last_slot),
                       .slot_out0(slot_out0), .slot_out1(slot_out1), .slot_out2(slot_out2), .slot_out3(slot_out3), 
                       .slot_out4(slot_out4), .slot_out5(slot_out5), .slot_out6(slot_out6), .slot_out7(slot_out7),
                       .err_cnt0(err_cnt0), .err_cnt1(err_cnt1), .err_cnt2(err_cnt2), .err_cnt3(err_cnt3), 
                       .err_cnt4(err_cnt4), .err_cnt5(err_cnt5), .err_cnt6(err_cnt6), .err_cnt7(err_cnt7));

    


endmodule
