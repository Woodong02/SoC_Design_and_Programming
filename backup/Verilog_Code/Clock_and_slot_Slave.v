module clock_and_slot_slave (
    input wire resetn,
    input wire clk,
    input wire sync,
    input wire sel_sig,
// F16 : sync, E16 : ready
    output reg ready
);
  reg [24:0] clk_cnt;
  reg        slot_sel;
  parameter slot_2 = 25'd2499999;  // 0.1초 시작
  parameter slot_6 = 25'd12499999;  // 0.5초 시작

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      clk_cnt <= 25'b0;
    end else begin
      if (sync) clk_cnt <= 25'b0;
      else begin
        if (clk_cnt == 25'd24999999) clk_cnt <= 25'd0;
        else clk_cnt <= clk_cnt + 25'd1;
      end
    end
  end  // 클럭 카운트 1초(한 주기)마다 리셋, 싱크와 리셋 신호로 클럭 초기화

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      ready <= 1'b0;
    end else begin
      if (slot_sel == 1'b0) begin
        if ((slot_2 + 25'd125000 < clk_cnt) && (clk_cnt < slot_2 + 25'd2500000 - 25'd125000))
          ready <= 1'b1;
        else ready <= 1'b0;
      end else begin
        if ((slot_6 + 25'd125000 < clk_cnt) && (clk_cnt < slot_6 + 25'd2500000 - 25'd125000))
          ready <= 1'b1;
        else ready <= 1'b0;
      end
    end
  end  // 2, 6번째 슬롯 5% ~ 95%때 활성화

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      slot_sel <= 0;
    end else begin
      if (clk_cnt == 25'd24999999) begin
        if (!sel_sig) slot_sel <= 1'b0;
        else slot_sel <= 1'b1;
      end
    end
  end  // 슬롯 스위치에 따라 사이클 시작(종료)시 슬레이브 슬롯 변경




endmodule
