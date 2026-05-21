module clock_and_slot (
    input wire resetn,
    input wire clk,

    output reg  [3:0] slot,
    output reg  [9:0] rat_slot,
    output reg    sync
);
  reg [21:0] clk_cnt;  // for 0.1sec
  reg [11:0] clk_cnt2;  // for 0.0001sec = 0.1ms. 0.1sec의 0.1% 단위
  reg [ 9:0] sync_cnt;  // 10바퀴 돌면 싱크 신호

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      clk_cnt <= 0;
    end else begin
      if (clk_cnt == 22'd2499999) clk_cnt <= 22'd0;
      else clk_cnt <= clk_cnt + 22'd1;
    end
  end  // 클럭 카운트 0.1초마다 리셋

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      slot <= 4'd0;
    end else begin
      if (clk_cnt == 22'd2499999) begin
        if (slot == 4'd9) slot <= 4'd0;
        else slot <= slot + 4'd1;
      end
    end
  end  // 0.1초가 지나면 슬롯 변경

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      sync_cnt <= 10'd0;
      sync <= 1'b0;
    end else begin
      if (clk_cnt == 22'd2499999) begin
        if (sync_cnt == 10'd999) begin
          sync_cnt <= 10'd0;
          sync <= 1'b1;
        end else begin
          sync <= 1'b0;
          sync_cnt <= sync_cnt + 10'd1;
        end
      end else sync <= 1'b0;
    end
  end  // 100초마다 싱크 신호 보내기

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      clk_cnt2 <= 12'd0;
      rat_slot <= 10'd0;
    end else begin
      if (clk_cnt == 22'd2499999) begin
        clk_cnt2 <= 12'd0;
        rat_slot <= 10'd0;
      end else if (clk_cnt2 == 12'd2499) begin
        clk_cnt2 <= 12'd0;
        rat_slot <= rat_slot + 10'd1;
      end else clk_cnt2 <= clk_cnt2 + 12'd1;
    end
  end  // 1ms가 지날 때마다 rat_slot 1씩 상승 : 0.1% 해상도 (슬롯 변경시 초기화)

endmodule
