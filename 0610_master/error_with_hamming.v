module Master_dec_ham (
    input wire resetn,
    input wire clk,
    input wire in_sig,
    input wire [41:0] data_in,
    input wire [7:0] SILENT_TH,
    input wire [2:0]  slot,
    input wire preamble_err,
    input wire slot_change,
    input wire GPIO_in,
    input wire [1:0] rx_stat,
    input wire [7:0] halt_cmd,
    
    output reg [31:0] slot_out0,
    output reg [31:0] slot_out1,
    output reg [31:0] slot_out2,
    output reg [31:0] slot_out3,
    output reg [31:0] slot_out4,
    output reg [31:0] slot_out5,
    output reg [31:0] slot_out6,
    output reg [31:0] slot_out7,

    output wire [31:0] err_cnt0,
    output wire [31:0] err_cnt1,
    output wire [31:0] err_cnt2,
    output wire [31:0] err_cnt3,
    output wire [31:0] err_cnt4,
    output wire [31:0] err_cnt5,
    output wire [31:0] err_cnt6,
    output wire [31:0] err_cnt7
);



reg [7:0]  preamble_err_cnt0;
reg [7:0]  slot_timeout_cnt0;
reg [7:0]  hamming_err_cnt0;
reg [7:0]  silent_cnt0;
reg [7:0]  preamble_err_cnt1;
reg [7:0]  slot_timeout_cnt1;
reg [7:0]  hamming_err_cnt1;
reg [7:0]  silent_cnt1;
reg [7:0]  preamble_err_cnt2;
reg [7:0]  slot_timeout_cnt2;
reg [7:0]  hamming_err_cnt2;
reg [7:0]  silent_cnt2;
reg [7:0]  preamble_err_cnt3;
reg [7:0]  slot_timeout_cnt3;
reg [7:0]  hamming_err_cnt3;
reg [7:0]  silent_cnt3;
reg [7:0]  preamble_err_cnt4;
reg [7:0]  slot_timeout_cnt4;
reg [7:0]  hamming_err_cnt4;
reg [7:0]  silent_cnt4;
reg [7:0]  preamble_err_cnt5;
reg [7:0]  slot_timeout_cnt5;
reg [7:0]  hamming_err_cnt5;
reg [7:0]  silent_cnt5;
reg [7:0]  preamble_err_cnt6;
reg [7:0]  slot_timeout_cnt6;
reg [7:0]  hamming_err_cnt6;
reg [7:0]  silent_cnt6;
reg [7:0]  preamble_err_cnt7;
reg [7:0]  slot_timeout_cnt7;
reg [7:0]  hamming_err_cnt7;
reg [7:0]  silent_cnt7;

assign err_cnt0 = {preamble_err_cnt0, slot_timeout_cnt0, hamming_err_cnt0, silent_cnt0};
assign err_cnt1 = {preamble_err_cnt1, slot_timeout_cnt1, hamming_err_cnt1, silent_cnt1};
assign err_cnt2 = {preamble_err_cnt2, slot_timeout_cnt2, hamming_err_cnt2, silent_cnt2};
assign err_cnt3 = {preamble_err_cnt3, slot_timeout_cnt3, hamming_err_cnt3, silent_cnt3};
assign err_cnt4 = {preamble_err_cnt4, slot_timeout_cnt4, hamming_err_cnt4, silent_cnt4};
assign err_cnt5 = {preamble_err_cnt5, slot_timeout_cnt5, hamming_err_cnt5, silent_cnt5};
assign err_cnt6 = {preamble_err_cnt6, slot_timeout_cnt6, hamming_err_cnt6, silent_cnt6};
assign err_cnt7 = {preamble_err_cnt7, slot_timeout_cnt7, hamming_err_cnt7, silent_cnt7};

wire [34:0] fixed_data;
wire        ham_1bit_err;
wire        ham_2bit_err;

hamming_dec u_hamming_dec (
    .codeword    (data_in),
    .data        (fixed_data),
    .ham_1bit_err(ham_1bit_err),
    .ham_2bit_err(ham_2bit_err)
);


reg [7:0] received;

//Silent Cnt for each node. will counted when 'GPIO_in == 1' never detected in each slot.
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
            if(slot_change && slot==3'd0) begin
                if(!received[0] && silent_cnt0 < SILENT_TH) 
                    silent_cnt0 <= silent_cnt0 + 8'd6;
                else if(silent_cnt0 && received[0])
                    silent_cnt0 <= silent_cnt0 - 8'b1;
                if(!received[1] && silent_cnt1 < SILENT_TH) 
                    silent_cnt1 <= silent_cnt1 + 8'd6;
                else if(silent_cnt1 && received[1])
                    silent_cnt1 <= silent_cnt1 - 8'b1;
                if(!received[2] && silent_cnt2 < SILENT_TH) 
                    silent_cnt2 <= silent_cnt2 + 8'd6;
                else if(silent_cnt2 && received[2])
                    silent_cnt2 <= silent_cnt2 - 8'b1;
                if(!received[3] && silent_cnt3 < SILENT_TH) 
                    silent_cnt3 <= silent_cnt3 + 8'd6;
                else if(silent_cnt3 && received[3])
                    silent_cnt3 <= silent_cnt3 - 8'b1;
                if(!received[4] && silent_cnt4 < SILENT_TH)
                    silent_cnt4 <= silent_cnt4 + 8'd6;
                else if(silent_cnt4 && received[4])
                    silent_cnt4 <= silent_cnt4 - 8'b1;
                if(!received[5] && silent_cnt5 < SILENT_TH) 
                    silent_cnt5 <= silent_cnt5 + 8'd6;
                else if(silent_cnt5 && received[5])
                    silent_cnt5 <= silent_cnt5 - 8'b1;
                if(!received[6] && silent_cnt6 < SILENT_TH) 
                    silent_cnt6 <= silent_cnt6 + 8'd6;
                else if(silent_cnt6 && received[6])
                    silent_cnt6 <= silent_cnt6 - 8'b1;
                if(!received[7] && silent_cnt7 < SILENT_TH) 
                    silent_cnt7 <= silent_cnt7 + 8'd6;   
                else if(silent_cnt7 && received[7])
                    silent_cnt7 <= silent_cnt7 - 8'b1;
                received <= 8'b0;
            end
            else if(GPIO_in) begin 
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
            else
                received <= received;
        end
    end

    wire severe_err = (rx_stat==2'd2) || (fixed_data[34:32] != slot);
    wire weak_err = rx_stat==2'd1; //for detect timing err. severe err will invade other node, immediately stop(255).

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
        if(in_sig) begin
            case(fixed_data[34:32])
            3'd0: begin
                if(severe_err) //when in_sig, the timing will exactly same with estimated last bit slave have given
                    slot_timeout_cnt0 <= 8'd255; //255 will halt node
                else if(weak_err && !halt_cmd[0])
                    slot_timeout_cnt0 <= slot_timeout_cnt0 + 8'd6;
                else if(slot_timeout_cnt0 && !halt_cmd[0])
                    slot_timeout_cnt0 <= slot_timeout_cnt0 - 8'b1;
            end
            3'd1: begin
                if(severe_err) //when in_sig, the timing will exactly same with estimated last bit slave have given
                    slot_timeout_cnt1 <= 8'd255;
                else if(weak_err && !halt_cmd[1])
                    slot_timeout_cnt1 <= slot_timeout_cnt1 + 8'd6;
                else if(slot_timeout_cnt1 && !halt_cmd[1])
                    slot_timeout_cnt1 <= slot_timeout_cnt1 - 8'b1;
            end
            3'd2: begin
                if(severe_err) //when in_sig, the timing will exactly same with estimated last bit slave have given
                    slot_timeout_cnt2 <= 8'd255;
                else if(weak_err && !halt_cmd[2])
                    slot_timeout_cnt2 <= slot_timeout_cnt2 + 8'd6;
                else if(slot_timeout_cnt2 && !halt_cmd[2])
                    slot_timeout_cnt2 <= slot_timeout_cnt2 - 8'b1;
            end
            3'd3: begin
                if(severe_err) //when in_sig, the timing will exactly same with estimated last bit slave have given
                    slot_timeout_cnt3 <= 8'd255;
                else if(weak_err && !halt_cmd[3])
                    slot_timeout_cnt3 <= slot_timeout_cnt3 + 8'd6;
                else if(slot_timeout_cnt3 && !halt_cmd[3])
                    slot_timeout_cnt3 <= slot_timeout_cnt3 - 8'b1;
            end
            3'd4: begin
                if(severe_err) //when in_sig, the timing will exactly same with estimated last bit slave have given
                    slot_timeout_cnt4 <= 8'd255;
                else if(weak_err && !halt_cmd[4])
                    slot_timeout_cnt4 <= slot_timeout_cnt4 + 8'd6;
                else if(slot_timeout_cnt4 && !halt_cmd[4])
                    slot_timeout_cnt4 <= slot_timeout_cnt4 - 8'b1;
            end
            3'd5: begin
                if(severe_err) //when in_sig, the timing will exactly same with estimated last bit slave have given
                    slot_timeout_cnt5 <= 8'd255;
                else if(weak_err && !halt_cmd[5])
                    slot_timeout_cnt5 <= slot_timeout_cnt5 + 8'd6;
                else if(slot_timeout_cnt5 && !halt_cmd[5])
                    slot_timeout_cnt5 <= slot_timeout_cnt5 - 8'b1;
            end
            3'd6: begin
                if(severe_err) //when in_sig, the timing will exactly same with estimated last bit slave have given
                    slot_timeout_cnt6 <= 8'd255;
                else if(weak_err && !halt_cmd[6])
                    slot_timeout_cnt6 <= slot_timeout_cnt6 + 8'd6;
                else if(slot_timeout_cnt6 && !halt_cmd[6])
                    slot_timeout_cnt6 <= slot_timeout_cnt6 - 8'b1;
            end
            3'd7: begin
                if(severe_err) //when in_sig, the timing will exactly same with estimated last bit slave have given
                    slot_timeout_cnt7 <= 8'd255;
                else if(weak_err && !halt_cmd[7])
                    slot_timeout_cnt7 <= slot_timeout_cnt7 + 8'd6;
                else if(slot_timeout_cnt7 && !halt_cmd[7])
                    slot_timeout_cnt7 <= slot_timeout_cnt7 - 8'b1;
            end

            endcase
        end
    end
  end

  // preamble err
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
                3'd0:if(!halt_cmd[0])
                    preamble_err_cnt0 <= preamble_err_cnt0 + 8'd2;
                3'd1:if(!halt_cmd[1])
                    preamble_err_cnt1 <= preamble_err_cnt1 + 8'd2;
                3'd2:if(!halt_cmd[2])
                    preamble_err_cnt2 <= preamble_err_cnt2 + 8'd2;
                3'd3:if(!halt_cmd[3])
                    preamble_err_cnt3 <= preamble_err_cnt3 + 8'd2;
                3'd4:if(!halt_cmd[4])
                    preamble_err_cnt4 <= preamble_err_cnt4 + 8'd2;
                3'd5:if(!halt_cmd[5])
                    preamble_err_cnt5 <= preamble_err_cnt5 + 8'd2;
                3'd6:if(!halt_cmd[6])
                    preamble_err_cnt6 <= preamble_err_cnt6 + 8'd2;
                default:if(!halt_cmd[7])
                    preamble_err_cnt7 <= preamble_err_cnt7 + 8'd2;
            endcase //add +2 because erroneous sampling will detect many preamble errs
        end
        else if(slot_change && slot==3'd0) begin
            if(preamble_err_cnt0 && !halt_cmd[0])
                preamble_err_cnt0 <= preamble_err_cnt0 - 8'b1;
            if(preamble_err_cnt1 && !halt_cmd[1])
                preamble_err_cnt1 <= preamble_err_cnt1 - 8'b1;
            if(preamble_err_cnt2 && !halt_cmd[2])
                preamble_err_cnt2 <= preamble_err_cnt2 - 8'b1;
            if(preamble_err_cnt3 && !halt_cmd[3])
                preamble_err_cnt3 <= preamble_err_cnt3 - 8'b1;
            if(preamble_err_cnt4 && !halt_cmd[4])
                preamble_err_cnt4 <= preamble_err_cnt4 - 8'b1;
            if(preamble_err_cnt5 && !halt_cmd[5])
                preamble_err_cnt5 <= preamble_err_cnt5 - 8'b1;
            if(preamble_err_cnt6 && !halt_cmd[6])
                preamble_err_cnt6 <= preamble_err_cnt6 - 8'b1;
            if(preamble_err_cnt7 && !halt_cmd[7])
                preamble_err_cnt7 <= preamble_err_cnt7 - 8'b1;
        end
    end
  end
  
    //final slot_out decision after hamming decode
    always @(posedge clk or negedge resetn) begin 
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
        end 
        else begin
            if(slot_change && slot==3'd0) begin
                if (hamming_err_cnt0 && !halt_cmd[0])
                    hamming_err_cnt0 <= hamming_err_cnt0 - 1'b1;
                if (hamming_err_cnt1 && !halt_cmd[1])
                    hamming_err_cnt1 <= hamming_err_cnt1 - 1'b1;
                if (hamming_err_cnt2 && !halt_cmd[2])
                    hamming_err_cnt2 <= hamming_err_cnt2 - 1'b1;
                if (hamming_err_cnt3 && !halt_cmd[3])
                    hamming_err_cnt3 <= hamming_err_cnt3 - 1'b1;
                if (hamming_err_cnt4 && !halt_cmd[4])
                    hamming_err_cnt4 <= hamming_err_cnt4 - 1'b1;
                if (hamming_err_cnt5 && !halt_cmd[5])
                    hamming_err_cnt5 <= hamming_err_cnt5 - 1'b1;
                if (hamming_err_cnt6 && !halt_cmd[6])
                    hamming_err_cnt6 <= hamming_err_cnt6 - 1'b1;
                if (hamming_err_cnt7 && !halt_cmd[7])
                    hamming_err_cnt7 <= hamming_err_cnt7 - 1'b1;
            end
            else if(in_sig) begin
                if (!ham_2bit_err) begin //0 or 1bit err. data is in normaly. but 1 bit err will add err count 4
                    case(fixed_data[34:32])
                        3'd0: begin
                            slot_out0 <= fixed_data[31:0];
                            if(!halt_cmd[0])
                                hamming_err_cnt0 <= hamming_err_cnt0 + (ham_1bit_err<<2);
                        end
                        3'd1: begin
                            slot_out1 <= fixed_data[31:0];
                            if(!halt_cmd[1])
                                hamming_err_cnt1 <= hamming_err_cnt1 + (ham_1bit_err<<2);
                        end
                        3'd2: begin
                            slot_out2 <= fixed_data[31:0];
                            if(!halt_cmd[2])
                                hamming_err_cnt2 <= hamming_err_cnt2 + (ham_1bit_err<<2);
                        end
                        3'd3: begin
                            slot_out3 <= fixed_data[31:0];
                            if(!halt_cmd[3])
                                hamming_err_cnt3 <= hamming_err_cnt3 + (ham_1bit_err<<2);
                        end
                        3'd4: begin
                            slot_out4 <= fixed_data[31:0];
                            if(!halt_cmd[4])
                                hamming_err_cnt4 <= hamming_err_cnt4 + (ham_1bit_err<<2);
                        end
                        3'd5: begin
                            slot_out5 <= fixed_data[31:0];
                            if(!halt_cmd[5])
                                hamming_err_cnt5 <= hamming_err_cnt5 + (ham_1bit_err<<2);
                        end
                        3'd6: begin
                            slot_out6 <= fixed_data[31:0];
                            if(!halt_cmd[6])
                                hamming_err_cnt6 <= hamming_err_cnt6 + (ham_1bit_err<<2);
                        end
                        default: begin
                            slot_out7 <= fixed_data[31:0];
                            if(!halt_cmd[7])
                                hamming_err_cnt7 <= hamming_err_cnt7 + (ham_1bit_err<<2);
                        end
                        endcase
                end
                else begin
                    case(fixed_data[34:32]) //2bit err? can't receive data. will add err count 8
                        3'd0: begin
                            if(!halt_cmd[0])
                                hamming_err_cnt0 <= hamming_err_cnt0 + (ham_2bit_err<<3);
                        end
                        3'd1: begin
                            if(!halt_cmd[1])
                            hamming_err_cnt1 <= hamming_err_cnt1 + (ham_2bit_err<<3);
                        end
                        3'd2: begin
                            if(!halt_cmd[2])
                            hamming_err_cnt2 <= hamming_err_cnt2 + (ham_2bit_err<<3);
                        end
                        3'd3: begin
                            if(!halt_cmd[3])
                            hamming_err_cnt3 <= hamming_err_cnt3 + (ham_2bit_err<<3);
                        end
                        3'd4: begin
                            if(!halt_cmd[4])
                            hamming_err_cnt4 <= hamming_err_cnt4 + (ham_2bit_err<<3);
                        end
                        3'd5: begin
                            if(!halt_cmd[5])
                            hamming_err_cnt5 <= hamming_err_cnt5 + (ham_2bit_err<<3);
                        end
                        3'd6: begin
                            if(!halt_cmd[6])
                            hamming_err_cnt6 <= hamming_err_cnt6 + (ham_2bit_err<<3);
                        end
                        default: begin
                            if(!halt_cmd[7])
                            hamming_err_cnt7 <= hamming_err_cnt7 + (ham_2bit_err<<3);
                        end
                    endcase
                end
            end
        end
    end

endmodule