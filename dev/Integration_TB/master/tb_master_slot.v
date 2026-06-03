`timescale 1ns/1ps
// tb_master_slot: Master_slot 단위 테스트
// 컴파일: vlog Master_slot.v tb_master_slot.v
// 실행: vsim -c tb_master_slot -do "run -all; quit"
//
// 파라미터: DIV=4, GUARD=20, NODE_CNT=2
//   slot_ticks = 50*4+20 = 220
//   last_slot  = NODE_CNT+1 = 3
//   전체 주기  = 4 슬롯 × 220 = 880 클럭
module tb_master_slot;

localparam CLK_HALF  = 5;
localparam [9:0] DIV   = 10'd4;
localparam [9:0] GUARD = 10'd20;
localparam [2:0] NCNT  = 3'd2;          // NODE_CNT
localparam       SLOT_TICKS = 50*4+20;  // 220
localparam       LAST_SLOT  = NCNT+1;   // 3

reg clk = 0, resetn = 0;
always #CLK_HALF clk = ~clk;

wire [2:0]  slot;
wire        slot_change, slot_pre_change;
wire [15:0] clk_cnt;
wire [1:0]  rx_stat;
wire [63:0] cycle_cnt;

Master_slot dut (
    .resetn(resetn), .clk(clk),
    .DIV(DIV), .GUARD_TICKS(GUARD), .NODE_CNT(NCNT),
    .slot(slot), .slot_change(slot_change), .slot_pre_change(slot_pre_change),
    .clk_cnt(clk_cnt), .rx_stat(rx_stat), .cycle_cnt(cycle_cnt)
);

integer fail = 0, pass = 0;

task chk;
    input cond;
    input [127:0] msg;
    begin
        if (cond) begin $display("  PASS | %0s", msg); pass = pass + 1; end
        else      begin $display("  FAIL | %0s", msg); fail = fail + 1; end
    end
endtask

// 슬롯 시퀀스 기록
reg [2:0] slot_seq [0:7];
integer   seq_idx;
reg       change_latch;

integer i;

initial begin
    $dumpfile("tb_master_slot.vcd");
    $dumpvars(0, tb_master_slot);

    resetn = 0;
    repeat(4) @(posedge clk);
    resetn = 1;
    @(posedge clk); // slot_change=1 at reset release

    // --- SC1: 슬롯 시퀀스 확인 (2 전체 주기) ---
    $display("[%0t] SC1: 슬롯 시퀀스 검증", $time);
    seq_idx = 0;
    // slot_change=1 인 클럭을 포착하며 슬롯 번호 기록
    begin : seq_check
        integer cyc;
        for (cyc = 0; cyc < 2*4*SLOT_TICKS; cyc = cyc + 1) begin
            @(posedge clk);
            if (slot_change && seq_idx < 8)
                slot_seq[seq_idx] = slot;
            if (slot_change)
                seq_idx = seq_idx + 1;
        end
    end
    // 예상 시퀀스: 1,2,3,0,1,2,3,0 (slot_change 시점의 slot 값)
    chk(slot_seq[0]==3'd1, "seq[0]==1");
    chk(slot_seq[1]==3'd2, "seq[1]==2");
    chk(slot_seq[2]==3'd3, "seq[2]==3 (master_slot)");
    chk(slot_seq[3]==3'd0, "seq[3]==0 (wrap)");
    chk(slot_seq[4]==3'd1, "seq[4]==1 (2nd cycle)");
    chk(slot_seq[7]==3'd0, "seq[7]==0 (2nd wrap)");

    // --- SC2: cycle_cnt ---
    $display("[%0t] SC2: cycle_cnt 검증", $time);
    // 리셋 후 2 전체 주기 경과 = cycle_cnt >= 2
    chk(cycle_cnt >= 64'd2, "cycle_cnt >= 2 after 2 full cycles");

    // --- SC3: slot_pre_change 타이밍 ---
    // slot_pre_change는 slot_change 1클럭 전에 와야 함
    $display("[%0t] SC3: slot_pre_change 1클럭 전 검증", $time);
    begin : pre_chk
        integer w;
        reg pre_seen;
        pre_seen = 0;
        for (w = 0; w < SLOT_TICKS+10; w = w + 1) begin
            @(posedge clk);
            if (slot_pre_change) pre_seen = 1;
            if (slot_change) begin
                chk(pre_seen, "slot_pre_change came before slot_change");
                pre_seen = 0;
            end
        end
    end

    // --- SC4: rx_stat 윈도우 ---
    // clk_cnt < data_len_tick(200) → 2, 중간 guard 구간 → 0, edge → 1
    $display("[%0t] SC4: rx_stat 검증", $time);
    // clk_cnt=0: rx_stat=2
    // clk_cnt=205 (200+5=data+guard/4): rx_stat=0 window 시작
    // wait until next slot_change
    begin : wait_sc
        forever begin
            @(posedge clk);
            if (slot_change) disable wait_sc;
        end
    end
    @(posedge clk);
    chk(rx_stat==2'd2, "rx_stat=2 at clk_cnt=0");
    // wait for data period end
    repeat(200) @(posedge clk);
    // clk_cnt=200: guard 시작, rx_stat=1 (guard/4=5 아직 안됨)
    chk(rx_stat==2'd1, "rx_stat=1 at guard start");
    repeat(5) @(posedge clk);
    // clk_cnt=205: rx_stat=0 detection window
    chk(rx_stat==2'd0, "rx_stat=0 in detection window");

    $display("");
    $display("=== Result: %0d PASS  %0d FAIL ===", pass, fail);
    $finish;
end

initial begin
    #500_000;
    $display("TIMEOUT");
    $finish;
end

endmodule
