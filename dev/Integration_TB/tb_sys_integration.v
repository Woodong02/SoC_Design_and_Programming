`timescale 1ns/1ps
// tb_sys_integration: master_top ↔ tdma_slave_top 전체 통합 테스트 (Stage 3)
//
// 신규 타이밍:
//   Slot 0..NODE_CNT: 슬레이브 슬롯 (slave_addr = slot 번호)
//   Slot NODE_CNT+1 (=master_slot): 마스터 DATA TX (guard/2 대기 → 전송 → guard/2)
//   주기 끝 (slot_pre_change && slot==master_slot): SYNC TX 발사
//
// DIV_USER=8, GUARD=200:
//   slot_ticks=600, master_slot=3 (NCNT=2이므로 3슬롯 슬레이브+1슬롯 마스터)
//   전체 주기 = 4×600 = 2400 클럭 = 24us
//
// Bus A: master.GPIO_out → slave.bus_a  (SYNC 브로드캐스트)
// Bus B: slave.bus_b OR  → master.GPIO_in (슬레이브 응답)
//
// 검증:
//  SC1: 20주기 후 모든 슬레이브 FSM = NORMAL
//  SC2: master가 슬레이브 데이터 올바르게 수신 (slot_out0,1,2)
//  SC3: 마스터 DATA TX (slot=master_slot, clk_cnt=guard/2) 실제 발생 확인
//  SC4: err_cnt 모두 0 (오류 없는 정상 동작)
module tb_sys_integration;

localparam CLK_HALF   = 5;           // 100 MHz
localparam [9:0] DIV_USER = 10'd8;   // 실제 비트 주기
localparam [9:0] DIV_M    = DIV_USER - 10'd1; // PS 레지스터 값 (master_top 내부에서 +1)
localparam [9:0] GT   = 10'd200;     // GUARD_TICKS
localparam [2:0] NCNT = 3'd2;        // NODE_CNT (slave 3개: addr 0,1,2)
                                      // master_slot = NCNT+1 = 3

localparam [31:0] D0 = 32'hDEAD_0001;
localparam [31:0] D1 = 32'hBEEF_0002;
localparam [31:0] D2 = 32'hCAFE_0003;

// 주기 = (NODE_CNT+2) × slot_ticks = 4 × 600 = 2400 클럭
localparam CYCLE_CLKS = (NCNT+2) * (50*DIV_USER + GT); // 2400

reg clk = 0, resetn = 0;
always #CLK_HALF clk = ~clk;

// ── 버스 ────────────────────────────────────────────────────────────────────
wire bus_a;                              // Bus A: 마스터→슬레이브 (SYNC)
wire bus_b0, bus_b1, bus_b2;
wire bus_b = bus_b0 | bus_b1 | bus_b2;  // Bus B: 슬레이브→마스터 (OR 합성)

// ── master_top ───────────────────────────────────────────────────────────────
wire [31:0] m_slot_out0, m_slot_out1, m_slot_out2;
wire [31:0] m_err_cnt0,  m_err_cnt1,  m_err_cnt2;
wire [2:0]  m_slot;
wire [63:0] m_cycle_cnt;
wire [7:0]  m_halt_cmd, m_silent;
wire [15:0] m_clk_cnt;

master_top dut_m (
    .clk        (clk),
    .resetn_bt  (resetn),
    .DIV        (DIV_M),
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
    .err_cnt0(m_err_cnt0),.err_cnt1(m_err_cnt1),.err_cnt2(m_err_cnt2),
    .err_cnt3(),.err_cnt4(),.err_cnt5(),.err_cnt6(),.err_cnt7(),
    .slot_out0(m_slot_out0),.slot_out1(m_slot_out1),.slot_out2(m_slot_out2),
    .slot_out3(),.slot_out4(),.slot_out5(),.slot_out6(),.slot_out7(),
    .cycle_cnt  (m_cycle_cnt),
    .Silent_node(m_silent),
    .halt_cmd   (m_halt_cmd)
);

// ── tdma_slave_top × 3 ──────────────────────────────────────────────────────
wire [4:0] irq_s0; wire [2:0] fsm_s0;
tdma_slave_top #(.DIV(DIV_USER),.GUARD_TICKS(GT),.SLAVE_ADDR(3'd0),
                 .FAULT_TH(8'd30),.LINE_FAULT_TH(8'd30),.IRQ_MASK(5'b11111))
  slave0 (.clk(clk),.rst_n(resetn),.enable(1'b1),.soft_rst(1'b0),
          .tx_data(D0),.irq_clr(5'b0),
          .irq_status(irq_s0),.fsm_state(fsm_s0),
          .bus_a(bus_a),.bus_b(bus_b0),.irq());

wire [4:0] irq_s1; wire [2:0] fsm_s1;
tdma_slave_top #(.DIV(DIV_USER),.GUARD_TICKS(GT),.SLAVE_ADDR(3'd1),
                 .FAULT_TH(8'd30),.LINE_FAULT_TH(8'd30),.IRQ_MASK(5'b11111))
  slave1 (.clk(clk),.rst_n(resetn),.enable(1'b1),.soft_rst(1'b0),
          .tx_data(D1),.irq_clr(5'b0),
          .irq_status(irq_s1),.fsm_state(fsm_s1),
          .bus_a(bus_a),.bus_b(bus_b1),.irq());

wire [4:0] irq_s2; wire [2:0] fsm_s2;
tdma_slave_top #(.DIV(DIV_USER),.GUARD_TICKS(GT),.SLAVE_ADDR(3'd2),
                 .FAULT_TH(8'd30),.LINE_FAULT_TH(8'd30),.IRQ_MASK(5'b11111))
  slave2 (.clk(clk),.rst_n(resetn),.enable(1'b1),.soft_rst(1'b0),
          .tx_data(D2),.irq_clr(5'b0),
          .irq_status(irq_s2),.fsm_state(fsm_s2),
          .bus_a(bus_a),.bus_b(bus_b2),.irq());

// ── 검증 ────────────────────────────────────────────────────────────────────
integer fail = 0, pass = 0;
task chk_fsm;
    input [2:0] got, exp;
    input [63:0] id;
    begin
        if (got === exp) begin
            $display("  PASS | slave%0d fsm=%0d (NORMAL)", id, got);
            pass = pass + 1;
        end else begin
            $display("  FAIL | slave%0d fsm=%0d  exp=%0d", id, got, exp);
            fail = fail + 1;
        end
    end
endtask

task chk_data;
    input [31:0] got, exp;
    input [63:0] id;
    begin
        if (got === exp) begin
            $display("  PASS | slot_out%0d = 0x%08x", id, got);
            pass = pass + 1;
        end else begin
            $display("  FAIL | slot_out%0d  got=0x%08x  exp=0x%08x", id, got, exp);
            fail = fail + 1;
        end
    end
endtask

task chk;
    input cond;
    input [255:0] msg;
    begin
        if (cond) begin $display("  PASS | %0s", msg); pass = pass + 1; end
        else      begin $display("  FAIL | %0s", msg); fail = fail + 1; end
    end
endtask

// master DATA TX 발생 감지 (slot==master_slot && bus_a 상승 중)
reg master_data_tx_seen;
reg [2:0] master_slot_exp;
always @(posedge clk) begin
    // master_slot = NCNT+1 = 3
    // DATA TX는 slot==3 구간에서 bus_a가 올라옴
    // SYNC TX는 주기 끝에도 bus_a가 올라오므로 clk_cnt로 구분
    // DATA TX: clk_cnt ≈ guard/2 = 100 (slot==3 내)
    // SYNC TX: clk_cnt ≈ total_tick-2 = 598 (slot==3 끝)
    if (m_slot == 3'd3 && bus_a == 1'b1 && m_clk_cnt < 16'd400)
        master_data_tx_seen <= 1'b1;
end

// ── 메인 시뮬 ───────────────────────────────────────────────────────────────
initial begin : stim
    master_data_tx_seen = 0;
    master_slot_exp     = NCNT + 3'd1;

    resetn = 0;
    repeat(20) @(posedge clk);
    resetn = 1;
    $display("[%0t ns] Reset released | DIV=%0d DIV_M=%0d GT=%0d NCNT=%0d master_slot=%0d",
             $time, DIV_USER, DIV_M, GT, NCNT, master_slot_exp);
    $display("         cycle=%0d clk = %0d us",
             CYCLE_CLKS, CYCLE_CLKS/100);

    // 20 TDMA 주기 대기 (각 2400 클럭 → 20×2400 = 48000 클럭)
    repeat(20 * CYCLE_CLKS) @(posedge clk);

    // ── SC1: 슬레이브 FSM ─────────────────────────────────────────────────
    $display("[%0t ns] === SC1: Slave FSM state ===", $time);
    chk_fsm(fsm_s0, 3'd1, 0);
    chk_fsm(fsm_s1, 3'd1, 1);
    chk_fsm(fsm_s2, 3'd1, 2);

    // ── SC2: 수신 데이터 ──────────────────────────────────────────────────
    $display("[%0t ns] === SC2: Master slot_out data ===", $time);
    chk_data(m_slot_out0, D0, 0);
    chk_data(m_slot_out1, D1, 1);
    chk_data(m_slot_out2, D2, 2);

    // ── SC3: 마스터 DATA TX 확인 ──────────────────────────────────────────
    $display("[%0t ns] === SC3: Master DATA TX in master_slot ===", $time);
    chk(master_data_tx_seen, "master DATA TX observed in slot==master_slot (clk_cnt<400)");

    // ── SC4: 오류 카운트 ──────────────────────────────────────────────────
    $display("[%0t ns] === SC4: Error counters ===", $time);
    chk(m_err_cnt0[23:16] == 8'd0, "err_cnt0: slot_timeout=0");
    chk(m_err_cnt1[23:16] == 8'd0, "err_cnt1: slot_timeout=0");
    chk(m_err_cnt2[23:16] == 8'd0, "err_cnt2: slot_timeout=0");

    // ── 정보 출력 ─────────────────────────────────────────────────────────
    $display("[%0t ns] cycle_cnt=%0d  halt_cmd=0x%02x  silent=0x%02x",
             $time, m_cycle_cnt, m_halt_cmd, m_silent);
    $display("[%0t ns] err0=0x%08x  err1=0x%08x  err2=0x%08x",
             $time, m_err_cnt0, m_err_cnt1, m_err_cnt2);
    $display("[%0t ns] irq_s0=%05b fsm=%0d  irq_s1=%05b fsm=%0d  irq_s2=%05b fsm=%0d",
             $time, irq_s0, fsm_s0, irq_s1, fsm_s1, irq_s2, fsm_s2);

    $display("");
    $display("=== Result: %0d / %0d PASS  Errors=%0d ===",
             pass, pass+fail, fail);
    $finish;
end

initial begin
    #2_000_000;
    $display("TIMEOUT: 2ms exceeded");
    $finish;
end

endmodule
