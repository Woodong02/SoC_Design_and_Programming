module Master_slot (
    input wire resetn,
    input wire clk,
    input wire [31:0] DIV,     
    input wire [9:0] GUARD_TICKS,
    input wire [2:0] NODE_CNT,

    output reg  [2:0] slot,
    output reg        slot_change,
    output reg        slot_pre_change,
    output reg  [37:0] clk_cnt,
    output wire [1:0] rx_stat,
    output reg  [31:0] cycle_cnt
);

  wire [37:0] data_len_tick = 38'd50 * DIV; //data lenth is 50bits * DIV
  wire [37:0] guard_len_tick = {28'b0, GUARD_TICKS} * DIV; // Guard ticks also * DIV
  wire [37:0] total_tick     = data_len_tick + guard_len_tick; //Total tick

  // Slot and Cycles Management
  always @(posedge clk or negedge resetn) begin
      if (!resetn) begin
          clk_cnt <= 38'd0;
          slot <= 3'd0;
          slot_change <= 1'b1;
          cycle_cnt <= 32'b0;
      end
      else begin
          if (clk_cnt >= (total_tick - 38'd1)) begin
              slot_change <= 1'b1;
              clk_cnt <= 38'd0;
              if (slot == NODE_CNT) begin
                  slot <= 3'd0;
                  cycle_cnt <= cycle_cnt + 32'b1;
              end
              else begin
                  slot <= slot + 3'd1;
                  cycle_cnt <= cycle_cnt;
              end
          end
          else begin
              clk_cnt <= clk_cnt + 38'd1;
              slot <= slot;
              slot_change <= 1'b0;
              cycle_cnt <= cycle_cnt;
          end
      end
  end

  //slot pre change signal for Master Tx
  always @(posedge clk or negedge resetn) begin
      if (!resetn) begin
          slot_pre_change <= 1'b1;
      end
      else begin
          if (clk_cnt == (total_tick - 38'd2)) 
              slot_pre_change <= 1'b1;
          else
              slot_pre_change <= 1'b0;
      end
  end

  // Rx_stat will detect each Slave's Tx data frames Transfer in time or not.
  wire [37:0] guard_quarter_tick = ({28'b0, GUARD_TICKS} >> 2) * {6'b0, DIV};
  assign rx_stat = (clk_cnt < data_len_tick) ? 2'd2 : //2 means severe time invasion to another node
                   ((data_len_tick + guard_quarter_tick <= clk_cnt) && 
                    (clk_cnt < total_tick - guard_quarter_tick)) ? 2'd0 : 2'd1; // 1 means a little misaligned time. it's ok but be careful. Fault cnt will added.
                    //0 means Good Tx/Rx.

endmodule