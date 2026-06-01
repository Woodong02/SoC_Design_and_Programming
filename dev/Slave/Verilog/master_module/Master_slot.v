module Master_slot (
    input wire resetn,
    input wire clk,
    input wire [9:0] DIV,     
    input wire [9:0] GUARD_TICKS,
    input wire [3:0] NODE_CNT,   // 4비트: NODE_CNT_p1 최대 8(N=7 슬레이브) 수용

    output reg  [3:0] slot,      // 4비트: 슬롯 0~8 표현 가능
    output reg        slot_change,
    output reg        slot_pre_change,
    output reg  [15:0] clk_cnt,
    output wire [1:0] rx_stat,
    output reg  [63:0] cycle_cnt
);

  wire [15:0] data_len_tick = 16'd50 * DIV;
  wire [15:0] total_tick = data_len_tick + {6'b0, GUARD_TICKS};

  always @(posedge clk or negedge resetn) begin
      if (!resetn) begin
          clk_cnt <= 16'd0;
          slot <= 4'd0;
          slot_change <= 1'b1;
          cycle_cnt <= 64'b0;
      end
      else begin
          if((clk_cnt == (total_tick - 16'd1))) begin
            clk_cnt <= 16'd0;
            if(slot==NODE_CNT) begin
              slot <= 4'd0;
              cycle_cnt <= cycle_cnt + 64'b1;
            end
            else
              slot <= slot + 4'd1;
            slot_change <= 1'b1;
          end
          else begin
            clk_cnt <= clk_cnt + 16'd1;
            slot <= slot;
            slot_change <= 1'b0;
          end
      end
  end

  always @(posedge clk or negedge resetn) begin
      if (!resetn) begin
          slot_pre_change <= 1'b0;
      end
      else begin
          if(clk_cnt == (total_tick - 16'd2)) begin
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