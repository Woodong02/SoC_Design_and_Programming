`timescale 1ns/1ps
// tb_tdma_slave_top: tdma_slave_top 통합 테스트 (Stage 2)
// 컴파일: vlog hamming_enc.v hamming_dec.v clk_div.v master_rx.v slot_timer.v
//              slave_tx.v fault_fsm.v irq_ctrl.v tdma_slave_top.v tb_tdma_slave_top.v
// 실행: vsim -c tb_tdma_slave_top -do "run -all; quit"
//
// DIV=8, GUARD=200, slot_ticks=600
//  Slot 0: slave0 (trig_cnt=100)
//  Slot 1: slave1 (trig_cnt=700)
//  Slot 2: slave2 (trig_cnt=1300)
//  Slot 3: 마스터 DATA 슬롯 (slave 없음)
//
// 검증 항목:
//  SC1: 마스터 SYNC 수신 후 FSM IDLE→NORMAL 전이
//  SC2: 각 슬레이브가 올바른 시점에 bus_b 전송
//  SC3: no_broadcast 후 FSM NORMAL→DEAD 전이 없음 (이 TB에선 계속 SYNC 공급)
//  SC4: FAULT_TH 이상 hamming 오류 시 FSM DEAD 전이
module tb_tdma_slave_top;

localparam CLK_HALF    = 5;       // 100 MHz
localparam [9:0] DIV   = 10'd8;
localparam [9:0] GT    = 10'd200;
localparam [7:0] HALT  = 8'h00;  // halt 없음
localparam [31:0] D0   = 32'hDEAD_0001;
localparam [31:0] D1   = 32'hBEEF_0002;

localparam SLOT_TICKS = 50*8+200;  // 600

reg clk = 0, resetn = 0;
always #CLK_HALF clk = ~clk;

// 마스터 SYNC 프레임 생성용 hamming_enc
wire [34:0] enc_d = {HALT, GT, 17'b0};
wire [41:0] enc_cw;
hamming_enc u_enc (.data(enc_d), .codeword(enc_cw));
wire [49:0] sync_frame = {8'hAA, enc_cw};

// bus_a: 마스터 브로드캐스트 구동 레지스터
reg bus_a;

// 슬레이브 0,1: 내결함성 (LINE_FAULT_TH=30, SC1-SC4)
wire bus_b0, bus_b1;
wire [4:0] irq_s0, irq_s1;
wire [2:0] fsm_s0, fsm_s1;

tdma_slave_top #(.DIV(DIV),.GUARD_TICKS(GT),.SLAVE_ADDR(3'd0),
                 .FAULT_TH(8'd30),.LINE_FAULT_TH(8'd30),.IRQ_MASK(5'b11111))
  s0 (.clk(clk),.rst_n(resetn),.enable(1'b1),.soft_rst(1'b0),
      .tx_data(D0),.irq_clr(5'b0),
      .irq_status(irq_s0),.fsm_state(fsm_s0),
      .bus_a(bus_a),.bus_b(bus_b0),.irq());

tdma_slave_top #(.DIV(DIV),.GUARD_TICKS(GT),.SLAVE_ADDR(3'd1),
                 .FAULT_TH(8'd30),.LINE_FAULT_TH(8'd30),.IRQ_MASK(5'b11111))
  s1 (.clk(clk),.rst_n(resetn),.enable(1'b1),.soft_rst(1'b0),
      .tx_data(D1),.irq_clr(5'b0),
      .irq_status(irq_s1),.fsm_state(fsm_s1),
      .bus_a(bus_a),.bus_b(bus_b1),.irq());

// 슬레이브 2: LINE_FAULT_TH=10 → no_broadcast 1회(+10)만으로 DEAD 전이 (SC5용)
wire [4:0] irq_sdead;
wire [2:0] fsm_sdead;
tdma_slave_top #(.DIV(DIV),.GUARD_TICKS(GT),.SLAVE_ADDR(3'd2),
                 .FAULT_TH(8'd30),.LINE_FAULT_TH(8'd10),.IRQ_MASK(5'b11111))
  s_dead (.clk(clk),.rst_n(resetn),.enable(1'b1),.soft_rst(1'b0),
          .tx_data(32'hCAFE_0003),.irq_clr(5'b0),
          .irq_status(irq_sdead),.fsm_state(fsm_sdead),
          .bus_a(bus_a),.bus_b(),.irq());

integer fail = 0, pass = 0;
task chk;
    input cond;
    input [255:0] msg;
    begin
        if (cond) begin $display("  PASS | %0s", msg); pass = pass + 1; end
        else      begin $display("  FAIL | %0s", msg); fail = fail + 1; end
    end
endtask

// NRZ 프레임 구동 (DIV 클럭/비트)
task drive_sync;
    integer b;
    begin
        for (b = 0; b < 50; b = b + 1) begin
            bus_a = sync_frame[49-b];
            repeat(DIV) @(posedge clk);
        end
        bus_a = 0;
    end
endtask

// 1 TDMA 주기 구동: SYNC를 slot 0 시작에 발사하고 나머지 빈 슬롯 대기
// 주기 = (NODE_CNT+2) × slot_ticks = 4 × 600 = 2400 클럭
// SYNC는 주기 시작 직전(마지막 슬롯 끝 2클럭 전)에 발사
task drive_one_cycle;
    // 마지막 슬롯(slot3) 구간에서 guard/2(100클럭) 대기 후 DATA TX 없음
    // (이 TB는 마스터 측 없으므로 그냥 시간만 소비)
    // SYNC는 주기 초기(400클럭 분량) 발사 후 idle
    integer wait_clk;
    begin
        // SYNC 프레임 발사
        drive_sync;
        // 남은 슬롯 구간 idle
        wait_clk = 4*SLOT_TICKS - 50*DIV;
        if (wait_clk > 0)
            repeat(wait_clk) @(posedge clk);
    end
endtask

reg b0_seen, b1_seen;
integer cnt;

initial begin
    $dumpfile("tb_tdma_slave_top.vcd");
    $dumpvars(0, tb_tdma_slave_top);

    bus_a  = 0;
    resetn = 0;
    repeat(20) @(posedge clk);
    resetn = 1;
    repeat(2)  @(posedge clk);

    // --- SC1: SYNC 수신 후 FSM NORMAL 전이 ---
    $display("[%0t] SC1: SYNC 수신 후 FSM NORMAL 전이 확인", $time);
    drive_sync;
    // bc_valid 후 FSM이 NORMAL 전이하는 데 몇 클럭 필요
    repeat(20) @(posedge clk);
    chk(fsm_s0 == 3'd1, "slave0 FSM = NORMAL after first SYNC");
    chk(fsm_s1 == 3'd1, "slave1 FSM = NORMAL after first SYNC");

    // --- SC2: 슬레이브 bus_b 전송 타이밍 확인 (5 주기) ---
    $display("[%0t] SC2: bus_b 전송 타이밍 확인 (5 주기)", $time);
    begin : cycle_loop
        integer cyc;
        integer b0_cnt, b1_cnt;
        b0_cnt = 0; b1_cnt = 0;
        for (cyc = 0; cyc < 5; cyc = cyc + 1) begin
            b0_seen = 0; b1_seen = 0;
            // SYNC 발사
            fork
                drive_sync;
                begin : monitor_b
                    integer m;
                    for (m = 0; m < 4*SLOT_TICKS; m = m + 1) begin
                        @(posedge clk);
                        if (bus_b0) b0_seen = 1;
                        if (bus_b1) b1_seen = 1;
                    end
                end
            join
            if (b0_seen) b0_cnt = b0_cnt + 1;
            if (b1_seen) b1_cnt = b1_cnt + 1;
        end
        $display("  slave0 tx in %0d/5 cycles, slave1 tx in %0d/5 cycles", b0_cnt, b1_cnt);
        chk(b0_cnt == 5, "slave0 transmitted every cycle");
        chk(b1_cnt == 5, "slave1 transmitted every cycle");
    end

    // --- SC3: FSM 유지 (지속 SYNC 후 NORMAL 유지) ---
    $display("[%0t] SC3: 10주기 후 FSM NORMAL 유지", $time);
    begin : keep_loop
        integer k;
        for (k = 0; k < 10; k = k + 1) begin
            drive_sync;
            repeat(4*SLOT_TICKS - 50*DIV) @(posedge clk);
        end
    end
    chk(fsm_s0 == 3'd1, "slave0 FSM still NORMAL");
    chk(fsm_s1 == 3'd1, "slave1 FSM still NORMAL");

    // --- SC4: no_broadcast 워치독 IRQ 확인 (LINE_FAULT_TH=30, DEAD 전이 없음) ---
    // no_broadcast 1회 +10, 10 < 30 → DEAD 아님. IRQ bit[1]만 확인
    $display("[%0t] SC4: no_broadcast IRQ 확인 (line_cnt+10, TH=30 → NORMAL 유지)", $time);
    repeat(9*SLOT_TICKS + 100) @(posedge clk);
    chk(irq_s0[1] == 1'b1, "slave0 irq_status[1]=1 (no_broadcast latched)");
    chk(fsm_s0 == 3'd1,    "slave0 FSM still NORMAL (line_cnt=10 < TH=30)");

    // --- SC5: LINE_FAULT_TH=10 슬레이브 → no_broadcast 1회로 DEAD 전이 ---
    $display("[%0t] SC5: LINE_FAULT_TH=10 슬레이브 no_broadcast → DEAD", $time);
    // s_dead는 SC4 대기 중 이미 no_broadcast 수신 → line_cnt=10 ≥ 10 → DEAD
    chk(fsm_sdead == 3'd2, "s_dead FSM = DEAD (line_cnt+10 >= LINE_FAULT_TH=10)");

    $display("");
    $display("=== Result: %0d PASS  %0d FAIL ===", pass, fail);
    $finish;
end

initial begin #50_000_000; $display("TIMEOUT"); $finish; end

endmodule
