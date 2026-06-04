module Master_slot (
    input wire resetn,
    input wire clk,
    input wire [15:0] DIV,     
    input wire [9:0] GUARD_TICKS,
    input wire [2:0] NODE_CNT,

    output reg  [2:0] slot,
    output reg        slot_change,
    output reg        slot_pre_change,
    output reg  [21:0] clk_cnt,
    output wire [1:0] rx_stat,
    output reg  [31:0] cycle_cnt
);

  wire [21:0] data_len_tick = 16'd50 * DIV;
  wire [21:0] total_tick = data_len_tick + {12'b0, GUARD_TICKS};

  always @(posedge clk or negedge resetn) begin
      if (!resetn) begin
          clk_cnt <= 22'd0;
          slot <= 3'd0;
          slot_change <= 1'b1;
          cycle_cnt <= 32'b0;
      end
      else begin
          if((clk_cnt == (total_tick - 22'd1))) begin
            slot_change <= 1'b1;
            clk_cnt <= 22'd0;
            if(slot==NODE_CNT) begin
              slot <= 3'd0;
              cycle_cnt <= cycle_cnt + 32'b1;
            end
            else
              slot <= slot + 3'd1;
              cycle_cnt <= cycle_cnt;
          end
          else begin
            clk_cnt <= clk_cnt + 22'd1;
            slot <= slot;
            slot_change <= 1'b0;
            cycle_cnt <= cycle_cnt;
          end
      end
  end

  always @(posedge clk or negedge resetn) begin
      if (!resetn) begin
          slot_pre_change <= 1'b0;
      end
      else begin
          if(clk_cnt == (total_tick - 22'd2)) begin
            slot_pre_change <= 1'b1;
          end
          else begin
            slot_pre_change <= 1'b0;
          end
      end
  end

  assign rx_stat = (clk_cnt < data_len_tick) ? 2'd2 :
                   ((data_len_tick + (GUARD_TICKS>>2) <= clk_cnt) && (clk_cnt < total_tick - (GUARD_TICKS>>2))) ? 2'd0 : 2'd1;

endmodule