 module FSM_data_rx_Master (

    input wire clk,
    input wire [9:0] DIV,
    input wire GPIO_in,
    input wire resetn,

    output reg [41:0] data_out,
    output reg out_sig,
    output reg preamble_err

);


  reg [9:0] clk_cnt; //count for each state
  reg [41:0] buffer; //for buffer. output will out once it finished
  reg [1:0] state; //neutral, preamble, others
  reg [5:0] bit_cnt; //bit counts for each state

    always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      clk_cnt <= 10'b0;
    end
    else begin
      case(state)
        2'd0: begin
          if(DIV!=10'd1 && GPIO_in==1'b1)
            clk_cnt <= 10'b1;
          else
            clk_cnt <= 10'b0;
        end
        2'd1: begin
          if(clk_cnt == DIV-1)
            clk_cnt <= 10'b0;
          else
            clk_cnt <= clk_cnt + 10'b1;
        end
        default: begin
          if(clk_cnt == DIV-1)
            clk_cnt <= 10'b0;
          else
            clk_cnt <= clk_cnt + 10'b1;
        end
      endcase
    end
  end  // clk_cnt reset when state changes preamble to data


  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      bit_cnt <= 6'b0;
    end
    else begin
      case(state)
        2'd0:
          if(GPIO_in==1 && DIV==10'd1)
            bit_cnt <= 10'd1;
          else
            bit_cnt <= 10'd0;
        2'd1: begin
          if(clk_cnt == DIV>>1) begin
            if(bit_cnt == 6'd8)
              bit_cnt <= 6'd0;
            else
              bit_cnt <= bit_cnt + 6'b1;
          end
          else
            bit_cnt <= bit_cnt;
        end
        2'd2: begin
          if(clk_cnt == DIV>>1) begin
            if(bit_cnt == 6'd41) // 1 bit for guard time-like
              bit_cnt <= 6'd0;
            else
              bit_cnt <= bit_cnt + 6'b1;
          end
          else
            bit_cnt <= bit_cnt;
        end
      endcase
    end
  end //bit counts at each state


  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      buffer <= 42'b0;
    end
    else begin
      if(state==2'd2 && bit_cnt==6'd41 && clk_cnt==DIV>>1)
        buffer <= 42'b0;
      else if(clk_cnt == DIV>>1)
        buffer <= {buffer[40:0], GPIO_in};
      else
        buffer <= buffer;
    end
  end // LSL buffer and buffer[0] will new bit

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      state <= 2'd0;
    end
    else begin
      case(state)
        2'd0: begin
          if(GPIO_in == 1'b1)
            state <= 2'd1;
          else
            state <= state;
        end // neutral state. detecting edge will shift state to preamble state
        2'd1: begin
          if(bit_cnt==6'd8 && clk_cnt==DIV>>1)
            state <= 2'd2;
          else
            state <= state;
        end // preamble state. shift when grab 8 bits
        2'd2: begin
          if(bit_cnt==6'd41 && clk_cnt==DIV>>1) // change state 1bit after rx, for guard-like time
            state <= 2'd0;
          else
            state <= state;
        end // addr + payload + hamming bits state. shift when grab 42 bits
        default:
          state <= 2'd0; // will never happen(reserved)
      endcase
    end
  end //state change


  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      data_out <= 42'b0;
    end
    else begin
      if(state==2'd2 && clk_cnt == DIV>>1 && bit_cnt == 6'd41)
        data_out <= buffer;
      else
        data_out <= data_out;
    end
  end //data out when the last bit have just been buffer


  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      out_sig <= 1'b0;
    end
    else begin
      case(state)
        2'd2: begin
          if(clk_cnt == DIV>>1 && bit_cnt == 6'd41)
            out_sig <= 1'b1;
          else
            out_sig <= 1'b0;
        end
        default:
          out_sig <= 1'b0;
      endcase
    end
  end //data out when the last bit have just been buffer




  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      preamble_err <= 1'b0;
    end
    else begin
      case(state)
        2'd1: begin
          if(clk_cnt == DIV>>1 && bit_cnt == 6'd8) begin
            if(buffer[7:0] == 8'hAA)
              preamble_err <= 1'b0;
            else
              preamble_err <= 1'b1;
          end
          else
            preamble_err <= 1'b0;
        end
        default :
          preamble_err <= 1'b0;
      endcase
    end
  end //detecting preamble err when data in buffer != 0x55





endmodule 