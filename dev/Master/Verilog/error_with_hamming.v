module error_and_hamming (
    input wire resetn,
    input wire clk,
    input wire in_sig,
    input wire [9:0]  guard_ticks,
    input wire [41:0] data_in,
    input wire [3:0]  slot,
    input wire [10:0] clk_cnt,
    input wire preamble_err,
    
    output reg [31:0] slot_out0,
    output reg [7:0]  preamble_err_cnt0,
    output reg [7:0]  slot_timeout_cnt0,
    output reg [7:0]  hamming_err_cnt0,
    output reg [7:0]  silent_cnt0,
    output reg [31:0] slot_out1,
    output reg [7:0]  preamble_err_cnt1,
    output reg [7:0]  slot_timeout_cnt1,
    output reg [7:0]  hamming_err_cnt1,
    output reg [7:0]  silent_cnt1,
    output reg [31:0] slot_out2,
    output reg [7:0]  preamble_err_cnt2,
    output reg [7:0]  slot_timeout_cnt2,
    output reg [7:0]  hamming_err_cnt2,
    output reg [7:0]  silent_cnt2,
    output reg [31:0] slot_out3,
    output reg [7:0]  preamble_err_cnt3,
    output reg [7:0]  slot_timeout_cnt3,
    output reg [7:0]  hamming_err_cnt3,
    output reg [7:0]  silent_cnt3,
    output reg [31:0] slot_out4,
    output reg [7:0]  preamble_err_cnt4,
    output reg [7:0]  slot_timeout_cnt4,
    output reg [7:0]  hamming_err_cnt4,
    output reg [7:0]  silent_cnt4,
    output reg [31:0] slot_out5,
    output reg [7:0]  preamble_err_cnt5,
    output reg [7:0]  slot_timeout_cnt5,
    output reg [7:0]  hamming_err_cnt5,
    output reg [7:0]  silent_cnt5,
    output reg [31:0] slot_out6 ,
    output reg [7:0]  preamble_err_cnt6,
    output reg [7:0]  slot_timeout_cnt6,
    output reg [7:0]  hamming_err_cnt6,
    output reg [7:0]  silent_cnt6,
    output reg [31:0] slot_out7,
    output reg [7:0]  preamble_err_cnt7,
    output reg [7:0]  slot_timeout_cnt7,
    output reg [7:0]  hamming_err_cnt7,
    output reg [7:0]  silent_cnt7
);

wire [6:0]  syndrome;

reg out_sig;
assign syndrome[0] = ^(data_in & 42'h155_5555_5555); // P1  (1, 3, 5, 7 ...)
assign syndrome[1] = ^(data_in & 42'h266_6666_6666); // P2  (2, 3, 6, 7 ...)
assign syndrome[2] = ^(data_in & 42'h078_7878_7878); // P4  (4~7, 12~15 ...)
assign syndrome[3] = ^(data_in & 42'h380_7F80_7F80); // P8  (8~15, 24~31 ...)
assign syndrome[4] = ^(data_in & 42'h000_7FFF_8000); // P16 (16~31)
assign syndrome[5] = ^(data_in & 42'h3FF_8000_0000); // P32 (32~41)
assign syndrome[6] = ^(data_in);

wire [41:0] fixed_data = (syndrome[5:0] == 6'b0) ?  data_in : (data_in ^ (42'b1 << (syndrome[5:0] - 6'b1)));

wire ham_1bit_err = (syndrome[5:0] != 6'b0) && (syndrome[6] == 1'b1);
wire ham_over_1bit_err = (syndrome[5:0] != 6'b0) && (syndrome[6] == 1'b0);


reg [7:0] received;


    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
        silent_cnt0 <= 8'b0;
        silent_cnt1 <= 8'b0;
        silent_cnt2 <= 8'b0;
        silent_cnt3 <= 8'b0;
        silent_cnt4 <= 8'b0;
        silent_cnt5 <= 8'b0;
        silent_cnt6 <= 8'b0;
        silent_cnt7 <= 8'b0;
        received <= 8'b0;
        end
        else begin
            if(in_sig) begin 
                case(slot)
                    3'd0:
                            received[0] <= 1'b1;
                    3'd1:
                            received[1] <= 1'b1;
                    3'd2:
                            received[2] <= 1'b1;
                    3'd3:
                            received[3] <= 1'b1;
                    3'd4:
                            received[4] <= 1'b1;
                    3'd5:
                            received[5] <= 1'b1;
                    3'd6:
                            received[6] <= 1'b1;
                    default:
                            received[7] <= 1'b1;
                endcase
            end
            else if(slot==3'd0 && clk_cnt == 11'd1) begin
                case(slot)
                    3'd0: begin
                        if(!received[0]) 
                            silent_cnt0 <= silent_cnt0 + 8'b6;
                        else if(silent_cnt0)
                            silent_cnt0 <= silent_cnt0 - 8'b1;
                    end
                    3'd1: begin
                        if(!received[1]) 
                            silent_cnt1 <= silent_cnt1 + 8'b6;
                        else if(silent_cnt0)
                            silent_cnt1 <= silent_cnt1 - 8'b1;
                    end
                    3'd2: begin
                        if(!received[2]) 
                            silent_cnt2 <= silent_cnt2 + 8'b6;
                        else if(silent_cnt0)
                            silent_cnt2 <= silent_cnt2 - 8'b1;
                    end
                    3'd3: begin
                        if(!received[3]) 
                            silent_cnt3 <= silent_cnt3 + 8'b6;
                        else if(silent_cnt0)
                            silent_cnt3 <= silent_cnt3 - 8'b1;
                    end
                    3'd4: begin
                        if(!received[4]) 
                            silent_cnt4 <= silent_cnt4 + 8'b6;
                        else if(silent_cnt0)
                            silent_cnt4 <= silent_cnt4 - 8'b1;
                    end
                    3'd5: begin
                        if(!received[5]) 
                            silent_cnt5 <= silent_cnt5 + 8'b6;
                        else if(silent_cnt0)
                            silent_cnt5 <= silent_cnt5 - 8'b1;
                    end
                    3'd6: begin
                        if(!received[6]) 
                            silent_cnt6 <= silent_cnt6 + 8'b6;
                        else if(silent_cnt0)
                            silent_cnt6 <= silent_cnt6 - 8'b1;
                    end
                    default: begin
                        if(!received[7]) 
                            silent_cnt7 <= silent_cnt7 + 8'b6;   
                        else if(silent_cnt0)
                            silent_cnt7 <= silent_cnt7 - 8'b1;
                    end    
                endcase
                received <= 8'b0;
            end
        end
    end


  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      slot_timeout_cnt0 <= 8'b0;
      slot_timeout_cnt1 <= 8'b0;
      slot_timeout_cnt2 <= 8'b0;
      slot_timeout_cnt3 <= 8'b0;
      slot_timeout_cnt4 <= 8'b0;
      slot_timeout_cnt5 <= 8'b0;
      slot_timeout_cnt6 <= 8'b0;
      slot_timeout_cnt7 <= 8'b0;
    end
    else begin
        if(out_sig) begin
            case(fixed_data[40:38])
            3'd0: begin
                if((fixed_data[40:38] != slot) || (clk_cnt < 10'd50)) //out_sig is 1clock later when slave transfer last bit of frame
                    slot_timeout_cnt0 <= 8'b255;
                else if( (clk_cnt < (10'd50 - (guard_ticks>>2))) || (10'd50 + (guard_ticks>>2) + (guard_ticks>>1)) < clk_cnt)
                    slot_timeout_cnt0 <= slot_timeout_cnt0 + 8'b6;
                else if(slot_timeout_cnt0)
                    slot_timeout_cnt0 <= slot_timeout_cnt0 - 8'b1;
            end
            3'd1: begin
                if((fixed_data[40:38] != slot) || (clk_cnt < 10'd50)) //out_sig is 1clock later when slave transfer last bit of frame
                    slot_timeout_cnt1 <= 8'b255;
                else if( (clk_cnt < (10'd50 - (guard_ticks>>2))) || (10'd50 + (guard_ticks>>2) + (guard_ticks>>1)) < clk_cnt)
                    slot_timeout_cnt1 <= slot_timeout_cnt1 + 8'b6;
                else if(slot_timeout_cnt1)
                    slot_timeout_cnt1 <= slot_timeout_cnt1 - 8'b1;
            end
            3'd2: begin
                if((fixed_data[40:38] != slot) || (clk_cnt < 10'd50)) //out_sig is 1clock later when slave transfer last bit of frame
                    slot_timeout_cnt2 <= 8'b255;
                else if( (clk_cnt < (10'd50 - (guard_ticks>>2))) || (10'd50 + (guard_ticks>>2) + (guard_ticks>>1)) < clk_cnt)
                    slot_timeout_cnt2 <= slot_timeout_cnt2 + 8'b6;
                else if(slot_timeout_cnt2)
                    slot_timeout_cnt2 <= slot_timeout_cnt2 - 8'b1;
            end
            3'd3: begin
                if((fixed_data[40:38] != slot) || (clk_cnt < 10'd50)) //out_sig is 1clock later when slave transfer last bit of frame
                    slot_timeout_cnt3 <= 8'b255;
                else if( (clk_cnt < (10'd50 - (guard_ticks>>2))) || (10'd50 + (guard_ticks>>2) + (guard_ticks>>1)) < clk_cnt)
                    slot_timeout_cnt3 <= slot_timeout_cnt3 + 8'b6;
                else if(slot_timeout_cnt1)
                    slot_timeout_cnt3 <= slot_timeout_cnt3 - 8'b1;
            end
            3'd4: begin
                if((fixed_data[40:38] != slot) || (clk_cnt < 10'd50)) //out_sig is 1clock later when slave transfer last bit of frame
                    slot_timeout_cnt4 <= 8'b255;
                else if( (clk_cnt < (10'd50 - (guard_ticks>>2))) || (10'd50 + (guard_ticks>>2) + (guard_ticks>>1)) < clk_cnt)
                    slot_timeout_cnt4 <= slot_timeout_cnt4 + 8'b6;
                else if(slot_timeout_cnt1)
                    slot_timeout_cnt4 <= slot_timeout_cnt4 - 8'b1;
            end
            3'd5: begin
                if((fixed_data[40:38] != slot) || (clk_cnt < 10'd50)) //out_sig is 1clock later when slave transfer last bit of frame
                    slot_timeout_cnt5 <= 8'b255;
                else if( (clk_cnt < (10'd50 - (guard_ticks>>2))) || (10'd50 + (guard_ticks>>2) + (guard_ticks>>1)) < clk_cnt)
                    slot_timeout_cnt5 <= slot_timeout_cnt5 + 8'b6;
                else if(slot_timeout_cnt1)
                    slot_timeout_cnt5 <= slot_timeout_cnt5 - 8'b1;
            end
            3'd6: begin
                if((fixed_data[40:38] != slot) || (clk_cnt < 10'd50)) //out_sig is 1clock later when slave transfer last bit of frame
                    slot_timeout_cnt6 <= 8'b255;
                else if( (clk_cnt < (10'd50 - (guard_ticks>>2))) || (10'd50 + (guard_ticks>>2) + (guard_ticks>>1)) < clk_cnt)
                    slot_timeout_cnt6 <= slot_timeout_cnt6 + 8'b6;
                else if(slot_timeout_cnt1)
                    slot_timeout_cnt6 <= slot_timeout_cnt6 - 8'b1;
            end
            3'd7: begin
                if((fixed_data[40:38] != slot) || (clk_cnt < 10'd50)) //out_sig is 1clock later when slave transfer last bit of frame
                    slot_timeout_cnt7 <= 8'b255;
                else if( (clk_cnt < (10'd50 - (guard_ticks>>2))) || (10'd50 + (guard_ticks>>2) + (guard_ticks>>1)) < clk_cnt)
                    slot_timeout_cnt7 <= slot_timeout_cnt7 + 8'b6;
                else if(slot_timeout_cnt1)
                    slot_timeout_cnt7 <= slot_timeout_cnt7 - 8'b1;
            end

            endcase
        end
    end
  end

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      preamble_err_cnt0 <= 8'b0;
      preamble_err_cnt1 <= 8'b0;
      preamble_err_cnt2 <= 8'b0;
      preamble_err_cnt3 <= 8'b0;
      preamble_err_cnt4 <= 8'b0;
      preamble_err_cnt5 <= 8'b0;
      preamble_err_cnt6 <= 8'b0;
      preamble_err_cnt7 <= 8'b0;
    end
    else begin
        if(preamble_err) begin
            case(slot)
                3'd0:
                    preamble_err_cnt0 <= preamble_err_cnt0 + 8'b6;
                3'd1:
                    preamble_err_cnt1 <= preamble_err_cnt1 + 8'b6;
                3'd2:
                    preamble_err_cnt2 <= preamble_err_cnt2 + 8'b6;
                3'd3:
                    preamble_err_cnt3 <= preamble_err_cnt3 + 8'b6;
                3'd4:
                    preamble_err_cnt4 <= preamble_err_cnt4 + 8'b6;
                3'd5:
                    preamble_err_cnt5 <= preamble_err_cnt5 + 8'b6;
                3'd6:
                    preamble_err_cnt6 <= preamble_err_cnt6 + 8'b6;
                default:
                    preamble_err_cnt7 <= preamble_err_cnt7 + 8'b6;
            endcase
        end
        else if(slot==3'd0 && clk_cnt == 11'd1) begin
            if(preamble_err_cnt0)
                preamble_err_cnt0 <= preamble_err_cnt0 - 8'b1;
            if(preamble_err_cnt1)
                preamble_err_cnt1 <= preamble_err_cnt1 - 8'b1;
            if(preamble_err_cnt2)
                preamble_err_cnt2 <= preamble_err_cnt2 - 8'b1;
            if(preamble_err_cnt3)
                preamble_err_cnt3 <= preamble_err_cnt3 - 8'b1;
            if(preamble_err_cnt4)
                preamble_err_cnt4 <= preamble_err_cnt4 - 8'b1;
            if(preamble_err_cnt5)
                preamble_err_cnt5 <= preamble_err_cnt5 - 8'b1;
            if(preamble_err_cnt6)
                preamble_err_cnt6 <= preamble_err_cnt6 - 8'b1;
            if(preamble_err_cnt7)
                preamble_err_cnt7 <= preamble_err_cnt7 - 8'b1;
        end
    end
  end

    always @(posedge clk or negedge resetn) begin //hamming err cnt and data out
        if (!resetn) begin
            hamming_err_cnt0 <= 8'b0;
            hamming_err_cnt1 <= 8'b0;
            hamming_err_cnt2 <= 8'b0;
            hamming_err_cnt3 <= 8'b0;
            hamming_err_cnt4 <= 8'b0;
            hamming_err_cnt5 <= 8'b0;
            hamming_err_cnt6 <= 8'b0;
            hamming_err_cnt7 <= 8'b0;
            slot_out0 <= 32'b0;
            slot_out1 <= 32'b0;
            slot_out2 <= 32'b0;
            slot_out3 <= 32'b0;
            slot_out4 <= 32'b0;
            slot_out5 <= 32'b0;
            slot_out6 <= 32'b0;
            slot_out7 <= 32'b0;
            out_sig <= 1'b0;
        end 
        else begin
            if(slot==3'd0 && clk_cnt == 11'd1) begin
                    out_sig <= 1'b0;
                    if (hamming_err_cnt0)
                        hamming_err_cnt0 <= hamming_err_cnt0 - 1'b1;
                    if (hamming_err_cnt1)
                        hamming_err_cnt1 <= hamming_err_cnt1 - 1'b1;
                    if (hamming_err_cnt2)
                        hamming_err_cnt2 <= hamming_err_cnt2 - 1'b1;
                    if (hamming_err_cnt3)
                        hamming_err_cnt3 <= hamming_err_cnt3 - 1'b1;
                    if (hamming_err_cnt4)
                        hamming_err_cnt4 <= hamming_err_cnt4 - 1'b1;
                    if (hamming_err_cnt5)
                        hamming_err_cnt5 <= hamming_err_cnt5 - 1'b1;
                    if (hamming_err_cnt6)
                        hamming_err_cnt6 <= hamming_err_cnt6 - 1'b1;
                    if (hamming_err_cnt7)
                        hamming_err_cnt7 <= hamming_err_cnt7 - 1'b1;
                end
            if(in_sig) begin
                if (!ham_over_1bit_err) begin
                    case(fixed_data[40:38])
                        3'd0: begin
                            slot_out0 <= {fixed_data[37:32], fixed_data[30:16], fixed_data[14:8], fixed_data[6:4], fixed_data[2]};
                            hamming_err_cnt0 <= hamming_err_cnt0 + (ham_1bit_err<<2);
                        end
                        3'd1: begin
                            slot_out1 <= {fixed_data[37:32], fixed_data[30:16], fixed_data[14:8], fixed_data[6:4], fixed_data[2]};
                            hamming_err_cnt1 <= hamming_err_cnt1 + (ham_1bit_err<<2);
                        end
                        3'd2: begin
                            slot_out2 <= {fixed_data[37:32], fixed_data[30:16], fixed_data[14:8], fixed_data[6:4], fixed_data[2]};
                            hamming_err_cnt2 <= hamming_err_cnt2 + (ham_1bit_err<<2);
                        end
                        3'd3: begin
                            slot_out3 <= {fixed_data[37:32], fixed_data[30:16], fixed_data[14:8], fixed_data[6:4], fixed_data[2]};
                            hamming_err_cnt3 <= hamming_err_cnt3 + (ham_1bit_err<<2);
                        end
                        3'd4: begin
                            slot_out4 <= {fixed_data[37:32], fixed_data[30:16], fixed_data[14:8], fixed_data[6:4], fixed_data[2]};
                            hamming_err_cnt4 <= hamming_err_cnt4 + (ham_1bit_err<<2);
                        end
                        3'd5: begin
                            slot_out5 <= {fixed_data[37:32], fixed_data[30:16], fixed_data[14:8], fixed_data[6:4], fixed_data[2]};
                            hamming_err_cnt5 <= hamming_err_cnt5 + (ham_1bit_err<<2);
                        end
                        3'd6: begin
                            slot_out6 <= {fixed_data[37:32], fixed_data[30:16], fixed_data[14:8], fixed_data[6:4], fixed_data[2]};
                            hamming_err_cnt6 <= hamming_err_cnt6 + (ham_1bit_err<<2);
                        end
                        default: begin
                            slot_out7 <= {fixed_data[37:32], fixed_data[30:16], fixed_data[14:8], fixed_data[6:4], fixed_data[2]};
                            hamming_err_cnt7 <= hamming_err_cnt7 + (ham_1bit_err<<2);
                        end
                        endcase
                    out_sig <= 1'b1;
                end
                else begin
                    out_sig <= 1'b0;
                    case(fixed_data[40:38])
                        3'd0: begin
                            hamming_err_cnt0 <= hamming_err_cnt0 + (ham_over_1bit_err<<3);
                        end
                        3'd1: begin
                            hamming_err_cnt1 <= hamming_err_cnt1 + (ham_over_1bit_err<<3);
                        end
                        3'd2: begin
                            hamming_err_cnt2 <= hamming_err_cnt2 + (ham_over_1bit_err<<3);
                        end
                        3'd3: begin
                            hamming_err_cnt3 <= hamming_err_cnt3 + (ham_over_1bit_err<<3);
                        end
                        3'd4: begin
                            hamming_err_cnt4 <= hamming_err_cnt4 + (ham_over_1bit_err<<3);
                        end
                        3'd5: begin
                            hamming_err_cnt5 <= hamming_err_cnt5 + (ham_over_1bit_err<<3);
                        end
                        3'd6: begin
                            hamming_err_cnt6 <= hamming_err_cnt6 + (ham_over_1bit_err<<3);
                        end
                        default: begin
                            hamming_err_cnt7 <= hamming_err_cnt7 + (ham_over_1bit_err<<3);
                        end
                    endcase
                end
            end
            else
            out_sig <= 1'b0;
        end
    end
endmodule