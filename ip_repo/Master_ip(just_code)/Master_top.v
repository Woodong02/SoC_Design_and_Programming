module master_top (
    input wire clk,
    input wire resetn_bt,
    input wire [9:0] DIV,
    input wire [9:0] GUARD_TICKS,
    input wire [2:0] NODE_CNT,
    input wire GPIO_in,
    input wire [3:0] DIP_SW,
    input wire ENABLE,
    input wire [7:0] FAULT_TH,
    input wire [7:0] SILENT_TH,

    output wire [7:0] seg_en,
    output wire [7:0] seg_data,

    output wire GPIO_out,
    output wire intr,
    output reg [15:0] clk_cnt_out,
    output reg [2:0] slot_out,

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
    output wire [31:0] slot_out7,

    output wire [63:0] cycle_cnt
);
    wire slot_change;
    wire pre_slot_change;
    wire slot_pre_change;
    wire [2:0] slot;
    wire [2:0] NODE_CNT_p1 = NODE_CNT + 3'd1;
    wire [9:0] DIV_p1 = DIV + 10'd1;
    wire tx_trigger = (slot_pre_change && slot==NODE_CNT_p1)? 1'b1 : 1'b0;
    wire [7:0] halt_cmd;
    wire [41:0] data_bus;
    wire sig_bus;
    wire preamble_err;
    wire [1:0] rx_stat;
    wire [15:0] clk_cnt;
    assign intr = GPIO_in || tx_trigger;
    wire resetn = resetn_bt && ENABLE;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            slot_out    <= 3'd0;
            clk_cnt_out <= 16'd0;
        end
        else begin
            if (GPIO_in) begin 
                slot_out    <= slot;
                clk_cnt_out <= clk_cnt;
            end
        end
    end


    assign halt_cmd[0] = ((err_cnt0[31:24]+err_cnt0[23:16]+err_cnt0[15:8]) > FAULT_TH) ? 1'b1 : 1'b0;
    assign halt_cmd[1] = ((err_cnt1[31:24]+err_cnt1[23:16]+err_cnt1[15:8]) > FAULT_TH) ? 1'b1 : 1'b0;
    assign halt_cmd[2] = ((err_cnt2[31:24]+err_cnt2[23:16]+err_cnt2[15:8]) > FAULT_TH) ? 1'b1 : 1'b0;
    assign halt_cmd[3] = ((err_cnt3[31:24]+err_cnt3[23:16]+err_cnt3[15:8]) > FAULT_TH) ? 1'b1 : 1'b0;
    assign halt_cmd[4] = ((err_cnt4[31:24]+err_cnt4[23:16]+err_cnt4[15:8]) > FAULT_TH) ? 1'b1 : 1'b0;
    assign halt_cmd[5] = ((err_cnt5[31:24]+err_cnt5[23:16]+err_cnt5[15:8]) > FAULT_TH) ? 1'b1 : 1'b0;
    assign halt_cmd[6] = ((err_cnt6[31:24]+err_cnt6[23:16]+err_cnt6[15:8]) > FAULT_TH) ? 1'b1 : 1'b0;
    assign halt_cmd[7] = ((err_cnt7[31:24]+err_cnt7[23:16]+err_cnt7[15:8]) > FAULT_TH) ? 1'b1 : 1'b0; //except silent_cnt!!

    Master_slot s0(.resetn(resetn), .clk(clk), .DIV(DIV_p1), .GUARD_TICKS(GUARD_TICKS), .NODE_CNT(NODE_CNT_p1),
                   .slot(slot), .slot_change(slot_change), .slot_pre_change(slot_pre_change), .clk_cnt(clk_cnt), .rx_stat(rx_stat), .cycle_cnt(cycle_cnt));

    Master_tx t0(.clk(clk), .resetn(resetn), .DIV(DIV_p1), .tx_trigger(tx_trigger), .halt_cmd(halt_cmd), .GUARD_TICKS(GUARD_TICKS),
                 .GPIO_out(GPIO_out));


    Master_rx r0(.clk(clk), .DIV(DIV_p1), .GPIO_in(GPIO_in), .resetn(resetn), .slot_pre_change(slot_pre_change),
                 .data_out(data_bus), .out_sig(sig_bus), .preamble_err(preamble_err));

    Master_dec_ham dh0(.resetn(resetn), .clk(clk), .in_sig(sig_bus), .GUARD_TICKS(GUARD_TICKS), .data_in(data_bus), .SILENT_TH(SILENT_TH),
                       .slot(slot), .preamble_err(preamble_err), .slot_change(slot_change), .GPIO_in(GPIO_in), .rx_stat(rx_stat), .halt_cmd(halt_cmd),
                       .slot_out0(slot_out0), .slot_out1(slot_out1), .slot_out2(slot_out2), .slot_out3(slot_out3), 
                       .slot_out4(slot_out4), .slot_out5(slot_out5), .slot_out6(slot_out6), .slot_out7(slot_out7),
                       .err_cnt0(err_cnt0), .err_cnt1(err_cnt1), .err_cnt2(err_cnt2), .err_cnt3(err_cnt3), 
                       .err_cnt4(err_cnt4), .err_cnt5(err_cnt5), .err_cnt6(err_cnt6), .err_cnt7(err_cnt7));


    wire [31:0] seg_slot_out = (DIP_SW[3:1]==3'd0) ? slot_out0 :
                           (DIP_SW[3:1]==3'd1) ? slot_out1 :
                           (DIP_SW[3:1]==3'd2) ? slot_out2 :
                           (DIP_SW[3:1]==3'd3) ? slot_out3 :
                           (DIP_SW[3:1]==3'd4) ? slot_out4 :
                           (DIP_SW[3:1]==3'd5) ? slot_out5 :
                           (DIP_SW[3:1]==3'd6) ? slot_out6 : slot_out7;
                           
    wire [31:0] seg_err_out;

    assign seg_err_out[31:28] = err_cnt0[7:0] > 200 ? 1'd1 : halt_cmd[0] ? 4'd2 : 4'd0;
    assign seg_err_out[27:24] = NODE_CNT_p1 < 3'd1 ? 4'd9 : err_cnt1[7:0] > 200 ? 4'd1 : halt_cmd[1] ? 4'd2 : 4'd0;
    assign seg_err_out[23:20] = NODE_CNT_p1 < 3'd2 ? 4'd9 : err_cnt1[7:0] > 200 ? 4'd1 : halt_cmd[2] ? 4'd2 : 4'd0;
    assign seg_err_out[19:16] = NODE_CNT_p1 < 3'd3 ? 4'd9 : err_cnt1[7:0] > 200 ? 4'd1 : halt_cmd[3] ? 4'd2 : 4'd0;
    assign seg_err_out[15:12] = NODE_CNT_p1 < 3'd4 ? 4'd9 : err_cnt1[7:0] > 200 ? 4'd1 : halt_cmd[4] ? 4'd2 : 4'd0;
    assign seg_err_out[11:8] = NODE_CNT_p1 < 3'd5 ? 4'd9 : err_cnt1[7:0] > 200 ? 4'd1 : halt_cmd[5] ? 4'd2 : 4'd0;
    assign seg_err_out[7:4] = NODE_CNT_p1 < 3'd6 ? 4'd9 : err_cnt1[7:0] > 200 ? 4'd1 : halt_cmd[6] ? 4'd2 : 4'd0;
    assign seg_err_out[3:0] = NODE_CNT_p1 < 3'd7 ? 4'd9 : err_cnt1[7:0] > 200 ? 4'd1 : halt_cmd[7] ? 4'd2 : 4'd0; 

    wire [31:0] seg_in = DIP_SW[0] ? seg_slot_out : seg_err_out;

    /*if slave is smaller than NODE_CNT : 9
     else if slave is silent : 1
     else if slave is err node and shutdowned : 2
     else slave is normal : 0. they are showed by 7-segment*/




    seven_seg seg0(.resetn(resetn), .clk(clk), .data(seg_in), .seg_en(seg_en), .seg_data(seg_data));


endmodule
