module clock_and_slot_Master (
    input wire resetn,
    input wire clk_in,
    input wire [9:0] guard_ticks,
    input wire [2:0] node_cnt,

    output reg  [3:0] slot,
    output reg  [10:0] clk_cnt
);


  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      clk_cnt <= 0;
    end
    else begin
      if (clk_cnt == 10'd49 + guard_ticks)
        clk_cnt <= 10'd0;
      else
        clk_cnt <= clk_cnt + 10'd1;
    end
  end  // clk_cnt reset at dataframe bit + guard time

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      slot <= 4'd0;
    end
    else begin
      if (clk_cnt == 10'd49 + guard_ticks) begin
        if (slot == node_cnt)
          slot <= 3'd0;
        else
          slot <= slot + 3'd1;
      end
    end
  end  //slot change at clk_reset, up to node_cnt


endmodule