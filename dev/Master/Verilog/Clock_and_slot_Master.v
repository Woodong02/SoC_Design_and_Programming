module clock_and_slot_Master (
    input wire resetn,
    input wire clk,
    input wire div_clk, 
    input wire [9:0] DIV,     
    input wire [9:0] guard_ticks,
    input wire [2:0] node_cnt,

    output reg  [2:0] last_slot,
    output reg  [2:0] slot,
    output reg  [9:0] clk_cnt,
    output reg        slot_change
);

  reg [9:0] clk_cnt2;
  
  wire [9:0] target_ticks = 10'd49 + guard_ticks;

  wire is_last_clk_tick = (clk_cnt == target_ticks);
  wire is_last_div_tick = (clk_cnt2 == DIV - 10'd1);
  
  wire is_slot_boundary = is_last_clk_tick && is_last_div_tick;



  always @(posedge clk or negedge resetn) begin
      if (!resetn) begin
          last_slot <= 3'd0;
      end
      else begin
          last_slot <= slot;
      end
  end

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      clk_cnt2        <= 10'b0;
      slot_change <= 1'b0;
    end
    else begin
      if (is_last_div_tick) begin
        clk_cnt2 <= 10'd0;
      end
      else begin
        clk_cnt2 <= clk_cnt2 + 10'd1;
      end
      if (is_slot_boundary) begin
        slot_change <= 1'b1;
      end
      else begin
        slot_change <= 1'b0;
      end
    end
  end

  always @(posedge div_clk or negedge resetn) begin
    if (!resetn) begin
      clk_cnt <= 10'd0;
    end
    else begin
      if (clk_cnt == target_ticks)
        clk_cnt <= 10'd0;
      else
        clk_cnt <= clk_cnt + 10'd1;
    end
  end

  always @(posedge div_clk or negedge resetn) begin
    if (!resetn) begin
      slot <= 3'd0;
    end
    else begin
      if (clk_cnt == target_ticks) begin
        if (slot == node_cnt)
          slot <= 3'd0;
        else
          slot <= slot + 3'd1;
      end
    end
  end

endmodule