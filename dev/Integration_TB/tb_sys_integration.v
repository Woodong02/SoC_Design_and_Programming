`timescale 1ns/1ps
// Master_top ↔ tdma_slave_top 3-slave full system integration testbench
// Bus A: master.GPIO_out → all slave.tx_line (broadcast, unidirectional)
// Bus B: slave.rx_line (tristate wired-OR) → master.GPIO_in (TDMA response)
//
// DIV_USER=8: 비트 주기 8클럭. PS는 N-1을 레지스터에 쓰므로 master_top에 DIV_USER-1=7 전달.
// master_top 내부: DIV_p1 = 7+1 = 8 → slave parameter DIV=8과 일치.
// GUARD_TICKS=200 → slot=50*8+200=600clk=6us, cycle=3*600=1800clk=18us
module tb_sys_integration;

// ─── 파라미터 ─────────────────────────────────────────────────────────────
localparam CLK_HALF    = 5;         // 100 MHz
localparam [9:0]  DIV_USER = 10'd8; // 실제 비트 주기 (slave parameter 값)
localparam [9:0]  DIV  = DIV_USER - 10'd1; // PS가 레지스터에 쓰는 값 → master_top 입력
localparam [9:0]  GT   = 10'd200;   // GUARD_TICKS
localparam [2:0]  NCNT = 3'd2;      // NODE_CNT (슬레이브 3개: addr 0,1,2)

localparam [31:0] D0   = 32'hDEAD_0001;
localparam [31:0] D1   = 32'hBEEF_0002;
localparam [31:0] D2   = 32'hCAFE_0003;

// ─── 클럭·리셋 ────────────────────────────────────────────────────────────
reg clk = 0, resetn = 0;
always #CLK_HALF clk = ~clk;

// ─── 버스 ─────────────────────────────────────────────────────────────────
wire bus_a;  // Bus A: 브로드캐스트 (Master→Slave)
wire bus_b;  // Bus B: 응답 (Slave→Master), 슬레이브 tri-state wired-OR

// ─── master_top ───────────────────────────────────────────────────────────
wire [31:0] m_slot_out0, m_slot_out1, m_slot_out2;
wire [31:0] m_err_cnt0,  m_err_cnt1,  m_err_cnt2;
wire [2:0]  m_slot;
wire [63:0] m_cycle_cnt;
wire [7:0]  m_halt_cmd, m_silent;
wire [15:0] m_clk_cnt;

master_top dut_m (
    .clk        (clk),
    .resetn_bt  (resetn),
    .DIV        (DIV),
    .GUARD_TICKS(GT),
    .NODE_CNT   (NCNT),
    .GPIO_in    (bus_b),
    .DIP_SW     (4'b0),
    .ENABLE     (1'b1),
    .FAULT_TH   (8'hFF),
    .SILENT_TH  (8'hFF),
    .seg_en     (),
    .seg_data   (),
    .GPIO_out   (bus_a),
    .clk_cnt    (m_clk_cnt),
    .slot       (m_slot),
    .err_cnt0   (m_err_cnt0), .err_cnt1(m_err_cnt1), .err_cnt2(m_err_cnt2),
    .err_cnt3   (), .err_cnt4(), .err_cnt5(), .err_cnt6(), .err_cnt7(),
    .slot_out0  (m_slot_out0), .slot_out1(m_slot_out1), .slot_out2(m_slot_out2),
    .slot_out3  (), .slot_out4(), .slot_out5(), .slot_out6(), .slot_out7(),
    .cycle_cnt  (m_cycle_cnt),
    .Silent_node(m_silent),
    .halt_cmd   (m_halt_cmd)
);

// ─── tdma_slave_top × 3 (Bus B 공유 tri-state) ───────────────────────────
wire [4:0] irq_s0; wire [2:0] fsm_s0; wire irq0;
tdma_slave_top #(.DIV(DIV),.GUARD_TICKS(GT),.SLAVE_ADDR(3'd0),
                 .FAULT_TH(8'd30),.LINE_FAULT_TH(8'd30),.IRQ_MASK(5'b11111))
  slave0 (.clk(clk),.rst_n(resetn),.enable(1'b1),.soft_rst(1'b0),
          .tx_data(D0),.irq_clr(5'b0),
          .irq_status(irq_s0),.fsm_state(fsm_s0),
          .tx_line(bus_a),.rx_line(bus_b),.irq(irq0));

wire [4:0] irq_s1; wire [2:0] fsm_s1; wire irq1;
tdma_slave_top #(.DIV(DIV),.GUARD_TICKS(GT),.SLAVE_ADDR(3'd1),
                 .FAULT_TH(8'd30),.LINE_FAULT_TH(8'd30),.IRQ_MASK(5'b11111))
  slave1 (.clk(clk),.rst_n(resetn),.enable(1'b1),.soft_rst(1'b0),
          .tx_data(D1),.irq_clr(5'b0),
          .irq_status(irq_s1),.fsm_state(fsm_s1),
          .tx_line(bus_a),.rx_line(bus_b),.irq(irq1));

wire [4:0] irq_s2; wire [2:0] fsm_s2; wire irq2;
tdma_slave_top #(.DIV(DIV),.GUARD_TICKS(GT),.SLAVE_ADDR(3'd2),
                 .FAULT_TH(8'd30),.LINE_FAULT_TH(8'd30),.IRQ_MASK(5'b11111))
  slave2 (.clk(clk),.rst_n(resetn),.enable(1'b1),.soft_rst(1'b0),
          .tx_data(D2),.irq_clr(5'b0),
          .irq_status(irq_s2),.fsm_state(fsm_s2),
          .tx_line(bus_a),.rx_line(bus_b),.irq(irq2));

// ─── 검증 루틴 ────────────────────────────────────────────────────────────
integer errs = 0, pass_cnt = 0;

task chk_fsm;
    input [2:0] got, exp;
    input [63:0] id;
    begin
        if (got === exp) begin
            $display("  PASS | slave%0d fsm=%0d (NORMAL)", id, got);
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  FAIL | slave%0d fsm=%0d  exp=%0d", id, got, exp);
            errs = errs + 1;
        end
    end
endtask

task chk_data;
    input [31:0] got, exp;
    input [63:0] id;
    begin
        if (got === exp) begin
            $display("  PASS | slot_out%0d = 0x%08x", id, got);
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  FAIL | slot_out%0d  got=0x%08x  exp=0x%08x", id, got, exp);
            errs = errs + 1;
        end
    end
endtask

// ─── 메인 시뮬레이션 ──────────────────────────────────────────────────────
initial begin : stim
    resetn = 0;
    repeat(20) @(posedge clk);
    resetn = 1;
    $display("[%0t ns] Reset released | DIV=%0d GT=%0d NODE_CNT=%0d",
             $time, DIV, GT, NCNT);

    // 20 TDMA 사이클 대기 (cycle=1800clk → 20×=36000clk=360us)
    repeat(36000) @(posedge clk);

    // ─ FSM 상태 확인 ──────────────────────────────────────────────────────
    $display("[%0t ns] === SC1: Slave FSM state ===", $time);
    chk_fsm(fsm_s0, 3'd1, 0);
    chk_fsm(fsm_s1, 3'd1, 1);
    chk_fsm(fsm_s2, 3'd1, 2);

    // ─ 수신 데이터 확인 ──────────────────────────────────────────────────
    $display("[%0t ns] === SC2: Master slot_out data ===", $time);
    chk_data(m_slot_out0, D0, 0);
    chk_data(m_slot_out1, D1, 1);
    chk_data(m_slot_out2, D2, 2);

    // ─ 정보 출력 ─────────────────────────────────────────────────────────
    $display("[%0t ns] cycle_cnt=%0d  halt_cmd=0x%02x  silent=0x%02x",
             $time, m_cycle_cnt, m_halt_cmd, m_silent);
    $display("[%0t ns] err0=0x%08x  err1=0x%08x  err2=0x%08x",
             $time, m_err_cnt0, m_err_cnt1, m_err_cnt2);
    $display("[%0t ns] irq_s0=%05b fsm=%0d  irq_s1=%05b fsm=%0d  irq_s2=%05b fsm=%0d",
             $time,
             irq_s0, fsm_s0,
             irq_s1, fsm_s1,
             irq_s2, fsm_s2);

    $display("");
    $display("=== Result: %0d / %0d scenarios PASS  Errors=%0d ===",
             pass_cnt, pass_cnt+errs, errs);
    $finish;
end

initial begin
    #600_000;
    $display("TIMEOUT: 600 us exceeded");
    $finish;
end

endmodule
