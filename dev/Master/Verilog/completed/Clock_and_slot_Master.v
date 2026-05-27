module clock_and_slot_Master (
    input wire resetn,
    input wire clk,
    input wire [9:0] DIV,     
    input wire [9:0] guard_ticks,
    input wire [2:0] node_cnt,

    output reg  [2:0] last_slot,
    output reg  [2:0] slot,
    output reg  [10:0] clk_cnt,
    output reg        slot_change
);

  reg [9:0] clk_cnt2;

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
      clk_cnt2    <= 10'b0;
      slot_change <= 1'b0;
    end
    else begin
      if (clk_cnt2 == DIV - 10'd1) begin
        clk_cnt2 <= 10'd0;
      end
      else begin
        clk_cnt2 <= clk_cnt2 + 10'd1;
      end

      if ((clk_cnt == 11'd49 + {1'b0, guard_ticks}) && (clk_cnt2 == DIV - 10'd1)) begin
        slot_change <= 1'b1;
      end
      else begin
        slot_change <= 1'b0;
      end
    end
  end

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      clk_cnt <= 11'd0;
    end
    else begin
      if (clk_cnt2 == DIV - 10'd1) begin
        if (clk_cnt == 11'd49 + {1'b0, guard_ticks}) begin
          clk_cnt <= 11'd0;
        end
        else begin
          clk_cnt <= clk_cnt + 11'd1;
        end
      end
    end
  end

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      slot <= 3'd0;
    end
    else begin
      if ((clk_cnt == 11'd49 + {1'b0, guard_ticks}) && (clk_cnt2 == DIV - 10'd1)) begin
        if (slot == node_cnt) begin
          slot <= 3'd0;
        end
        else begin
          slot <= slot + 3'd1;
        end
      end
    end
  end

endmodule