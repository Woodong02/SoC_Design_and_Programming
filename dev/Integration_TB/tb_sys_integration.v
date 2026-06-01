`timescale 1ns / 1ps
// tb_sys_integration: master_top ↔ tdma_slave_top 전체 시스템 통합 테스트
//
// ── 버스 연결 ─────────────────────────────────────────────────────────────────
// Bus A: master_top.GPIO_out → 모든 slave.tx_line (직결)
//        tdma_slave_top 내부에 2-FF sync 포함 → 추가 sync 불필요
//        Master_tx: idle 시 0 출력 (tristate 아님)
//
// Bus B: 모든 slave.rx_line (tristate, High-Z when idle)
//        Verilog wire 다중 드라이버 → 자동 tristate 해석 (wired bus)
//        → Z 판별 후 2-FF sync → master_top.GPIO_in
//
// ── 타이밍 근거 (DIV=8, GUARD=200) ──────────────────────────────────────────
// slot_ticks = 50*8+200 = 600 clk
// 마스터 사이클 = (NODE_CNT+2)*600 clk  (NODE_CNT_p1+1 슬롯)
// 슬레이브 N (SLAVE_ADDR=N): trig_cnt = N*600+100 (active_edge 후)
//   → 응답 시작: active_edge+101, 완료: active_edge+501
//   → 마스터 슬롯 N의 slot_pre_change: ~N*600+~100+598 → 완료 이전 ✓
// 최대 슬레이브 수: NODE_CNT=6 (NODE_CNT_p1=7, 8슬롯)
//   NODE_CNT=7 → NODE_CNT_p1 3비트 오버플로우(=0) → 미지원
//
// ── 테스트 케이스 ─────────────────────────────────────────────────────────────
// T1: N=1  기본 라운드트립 (IDLE→NORMAL, slot_out0 갱신, data_sent IRQ)
// T2: N=3  3슬레이브 동시 동작 (slot_out0/1/2 갱신)
// T3: N=6  최대 슬레이브 6개 전체 동작 (slot_out0~5 갱신)
// T4: N=2  5사이클 연속 안정성 (cycle_cnt 증가, 데이터 유지)
// T5: N=1  no_broadcast watchdog (ENABLE=0 후 irq_status[1] 세트)
// T6: N=6  비대칭 활성화 (slave 0/2/4만 활성, 나머지 IDLE 유지)
// T7: N=4  소프트 리셋 후 재동작 (soft_rst 펄스 → slave 재진입)

module tb_sys_integration;

    reg clk;
    reg rst_n;
    always #5 clk = ~clk;

    // ── 공유 파라미터 ─────────────────────────────────────────────────────────
    localparam [9:0] DIV        = 10'd8;
    localparam [9:0] GUARD      = 10'd200;  // slot_ticks = 600 clk
    localparam [7:0] FAULT_TH   = 8'd30;
    localparam [7:0] SILENT_TH  = 8'd200;
    localparam [7:0] LINE_TH    = 8'd30;

    // 슬레이브별 tx_data: 구별 가능한 고정 패턴
    localparam [31:0] SDATA0 = 32'hDEAD_0000;
    localparam [31:0] SDATA1 = 32'hCAFE_1111;
    localparam [31:0] SDATA2 = 32'hBEEF_2222;
    localparam [31:0] SDATA3 = 32'h1234_3333;
    localparam [31:0] SDATA4 = 32'h5678_4444;
    localparam [31:0] SDATA5 = 32'h9ABC_5555;

    // ── master_top 제어 ───────────────────────────────────────────────────────
    reg [2:0] node_cnt;     // 테스트별 설정 (1~6)
    reg       m_enable;     // master ENABLE (0이면 내부 resetn=0)

    // ── Bus B: tristate wired-OR ──────────────────────────────────────────────
    // 6개 slave rx_line이 동일 wire를 구동 (Verilog 다중 드라이버 해석)
    // idle 슬레이브는 Z를 유지하므로 동시에 1명만 구동 = 정상 해석
    wire bus_b;

    // Z 제거 후 2-FF sync → master_top.GPIO_in
    wire      bus_b_in    = (bus_b === 1'bz) ? 1'b0 : bus_b;
    reg       b_ff1, b_ff2;
    always @(posedge clk or negedge rst_n)
        if (!rst_n) {b_ff2, b_ff1} <= 2'b0;
        else        {b_ff2, b_ff1} <= {b_ff1, bus_b_in};
    wire gpio_in_sync = b_ff2;

    // ── master_top ────────────────────────────────────────────────────────────
    wire        gpio_out_a;         // Bus A
    wire [7:0]  m_seg_en, m_seg_data;
    wire        m_intr;
    wire [15:0] m_clk_cnt_out;
    wire [2:0]  m_slot_out;
    wire [63:0] m_cycle_cnt;
    wire [31:0] m_so0, m_so1, m_so2, m_so3, m_so4, m_so5, m_so6, m_so7;
    wire [31:0] m_ec0, m_ec1, m_ec2, m_ec3, m_ec4, m_ec5, m_ec6, m_ec7;

    master_top u_master (
        .clk(clk),           .resetn_bt(rst_n),
        .DIV(DIV),           .GUARD_TICKS(GUARD),  .NODE_CNT(node_cnt),
        .GPIO_in(gpio_in_sync),
        .DIP_SW(4'h0),       .ENABLE(m_enable),
        .FAULT_TH(FAULT_TH), .SILENT_TH(SILENT_TH),
        .seg_en(m_seg_en),   .seg_data(m_seg_data),
        .GPIO_out(gpio_out_a),
        .intr(m_intr),
        .clk_cnt_out(m_clk_cnt_out), .slot_out(m_slot_out),
        .err_cnt0(m_ec0), .err_cnt1(m_ec1), .err_cnt2(m_ec2), .err_cnt3(m_ec3),
        .err_cnt4(m_ec4), .err_cnt5(m_ec5), .err_cnt6(m_ec6), .err_cnt7(m_ec7),
        .slot_out0(m_so0), .slot_out1(m_so1), .slot_out2(m_so2), .slot_out3(m_so3),
        .slot_out4(m_so4), .slot_out5(m_so5), .slot_out6(m_so6), .slot_out7(m_so7),
        .cycle_cnt(m_cycle_cnt)
    );

    // ── 슬레이브 enable (비트별 독립 제어) ───────────────────────────────────
    reg [5:0] sl_en;
    reg [5:0] sl_srst;   // soft_rst 펄스용

    // ── 슬레이브 인스턴스 6개 (Bus B = 동일 wire) ────────────────────────────
    // [0] IRQ_MASK[4:0]: 모든 IRQ 활성화
    //   [0]=data_sent [1]=no_broadcast [2]=bc_hamming_err [3]=halt_cmd [4]=state_change

    wire [2:0]  s0_fsm,  s1_fsm,  s2_fsm,  s3_fsm,  s4_fsm,  s5_fsm;
    wire [4:0]  s0_irqst, s1_irqst, s2_irqst, s3_irqst, s4_irqst, s5_irqst;
    wire        s0_irq,  s1_irq,  s2_irq,  s3_irq,  s4_irq,  s5_irq;

    tdma_slave_top #(
        .DIV(DIV), .GUARD_TICKS(GUARD), .SLAVE_ADDR(3'd0),
        .FAULT_TH(FAULT_TH), .LINE_FAULT_TH(LINE_TH), .IRQ_MASK(5'b11111)
    ) u_slave0 (
        .clk(clk), .rst_n(rst_n), .enable(sl_en[0]), .soft_rst(sl_srst[0]),
        .tx_data(SDATA0), .irq_clr(5'b0),
        .irq_status(s0_irqst), .fsm_state(s0_fsm),
        .tx_line(gpio_out_a), .rx_line(bus_b), .irq(s0_irq)
    );

    tdma_slave_top #(
        .DIV(DIV), .GUARD_TICKS(GUARD), .SLAVE_ADDR(3'd1),
        .FAULT_TH(FAULT_TH), .LINE_FAULT_TH(LINE_TH), .IRQ_MASK(5'b11111)
    ) u_slave1 (
        .clk(clk), .rst_n(rst_n), .enable(sl_en[1]), .soft_rst(sl_srst[1]),
        .tx_data(SDATA1), .irq_clr(5'b0),
        .irq_status(s1_irqst), .fsm_state(s1_fsm),
        .tx_line(gpio_out_a), .rx_line(bus_b), .irq(s1_irq)
    );

    tdma_slave_top #(
        .DIV(DIV), .GUARD_TICKS(GUARD), .SLAVE_ADDR(3'd2),
        .FAULT_TH(FAULT_TH), .LINE_FAULT_TH(LINE_TH), .IRQ_MASK(5'b11111)
    ) u_slave2 (
        .clk(clk), .rst_n(rst_n), .enable(sl_en[2]), .soft_rst(sl_srst[2]),
        .tx_data(SDATA2), .irq_clr(5'b0),
        .irq_status(s2_irqst), .fsm_state(s2_fsm),
        .tx_line(gpio_out_a), .rx_line(bus_b), .irq(s2_irq)
    );

    tdma_slave_top #(
        .DIV(DIV), .GUARD_TICKS(GUARD), .SLAVE_ADDR(3'd3),
        .FAULT_TH(FAULT_TH), .LINE_FAULT_TH(LINE_TH), .IRQ_MASK(5'b11111)
    ) u_slave3 (
        .clk(clk), .rst_n(rst_n), .enable(sl_en[3]), .soft_rst(sl_srst[3]),
        .tx_data(SDATA3), .irq_clr(5'b0),
        .irq_status(s3_irqst), .fsm_state(s3_fsm),
        .tx_line(gpio_out_a), .rx_line(bus_b), .irq(s3_irq)
    );

    tdma_slave_top #(
        .DIV(DIV), .GUARD_TICKS(GUARD), .SLAVE_ADDR(3'd4),
        .FAULT_TH(FAULT_TH), .LINE_FAULT_TH(LINE_TH), .IRQ_MASK(5'b11111)
    ) u_slave4 (
        .clk(clk), .rst_n(rst_n), .enable(sl_en[4]), .soft_rst(sl_srst[4]),
        .tx_data(SDATA4), .irq_clr(5'b0),
        .irq_status(s4_irqst), .fsm_state(s4_fsm),
        .tx_line(gpio_out_a), .rx_line(bus_b), .irq(s4_irq)
    );

    tdma_slave_top #(
        .DIV(DIV), .GUARD_TICKS(GUARD), .SLAVE_ADDR(3'd5),
        .FAULT_TH(FAULT_TH), .LINE_FAULT_TH(LINE_TH), .IRQ_MASK(5'b11111)
    ) u_slave5 (
        .clk(clk), .rst_n(rst_n), .enable(sl_en[5]), .soft_rst(sl_srst[5]),
        .tx_data(SDATA5), .irq_clr(5'b0),
        .irq_status(s5_irqst), .fsm_state(s5_fsm),
        .tx_line(gpio_out_a), .rx_line(bus_b), .irq(s5_irq)
    );

    // ── 공통 유틸리티 ─────────────────────────────────────────────────────────
    integer pass_cnt, fail_cnt;

    task check;
        input        cond;
        input [255:0] tag;
        begin
            if (cond) begin $display("[PASS] %0s", tag); pass_cnt = pass_cnt + 1; end
            else       begin $display("[FAIL] %0s", tag); fail_cnt = fail_cnt + 1; end
        end
    endtask

    // 하드 리셋: master + 모든 slave 동시 리셋
    task do_reset;
        begin
            @(posedge clk); #1;
            rst_n    = 0;
            m_enable = 0;
            sl_en    = 6'b0;
            sl_srst  = 6'b0;
            repeat(12) @(posedge clk); #1;
            rst_n    = 1;
            m_enable = 1;
            repeat(3) @(posedge clk);
        end
    endtask

    // ── 메인 시뮬레이션 ───────────────────────────────────────────────────────
    initial begin
        clk=0; rst_n=0; m_enable=0;
        sl_en=6'b0; sl_srst=6'b0; node_cnt=3'd1;
        pass_cnt=0; fail_cnt=0;
        do_reset;

        // ==================================================================
        // T1: N=1 기본 라운드트립
        //   NODE_CNT=1 → NODE_CNT_p1=2, 슬롯 0/1/2, 사이클=1800 clk
        //   첫 tx_trigger ≈ 2*600+598+15 = 1813 clk (리셋 후)
        //   slave 0 active_edge ≈ 1815, trig_cnt=100, 응답 완료 ≈ 2316
        //   → 5000 clk 대기로 충분히 커버
        // ==================================================================
        $display("\n=== T1: N=1 기본 라운드트립 (slave 0) ===");
        node_cnt = 3'd1;
        sl_en    = 6'b000001;   // slave 0만 활성
        repeat(5000) @(posedge clk); #1;

        check(s0_fsm  === 3'd1,    "T1a: slave0 IDLE→NORMAL");
        check(m_so0   === SDATA0,  "T1b: master slot_out0 = SDATA0 (Bus A→B 라운드트립)");
        check(s0_irqst[0] === 1'b1,"T1c: slave0 data_sent IRQ 세트 (irq_status[0])");
        check(s0_irq  === 1'b1,    "T1d: slave0 irq 출력 HIGH");
        check(s1_fsm  === 3'd0,    "T1e: slave1 IDLE (비활성 확인)");

        // ==================================================================
        // T2: N=3 3슬레이브 동시 동작
        //   NODE_CNT=3 → NODE_CNT_p1=4, 슬롯 0~3, 사이클=2400 clk
        //   첫 tx_trigger ≈ 3*600+598+15 = 2413 clk
        //   slave 2 응답 완료 ≈ 2415+1300+400 = 4115 clk
        //   → 8000 clk 대기 (2사이클 여유)
        // ==================================================================
        $display("\n=== T2: N=3 3슬레이브 동시 동작 (slave 0/1/2) ===");
        do_reset;
        node_cnt = 3'd3;
        sl_en    = 6'b000111;   // slave 0/1/2 활성
        repeat(8000) @(posedge clk); #1;

        check(s0_fsm === 3'd1,   "T2a: slave0 NORMAL");
        check(s1_fsm === 3'd1,   "T2b: slave1 NORMAL");
        check(s2_fsm === 3'd1,   "T2c: slave2 NORMAL");
        check(m_so0  === SDATA0, "T2d: slot_out0 = SDATA0");
        check(m_so1  === SDATA1, "T2e: slot_out1 = SDATA1");
        check(m_so2  === SDATA2, "T2f: slot_out2 = SDATA2");
        check(s3_fsm === 3'd0,   "T2g: slave3 IDLE (비활성)");

        // ==================================================================
        // T3: N=6 최대 슬레이브 6개 전체 동작
        //   NODE_CNT=6 → NODE_CNT_p1=7, 슬롯 0~7, 사이클=4800 clk
        //   첫 tx_trigger ≈ 7*600+598+15 = 4813 clk
        //   slave 5 응답 완료 ≈ 4815+3100+400 = 8315 clk
        //   → 15000 clk 대기 (1.5사이클 여유)
        //   ★ NODE_CNT=7은 NODE_CNT_p1 3비트 오버플로(→0) → 미지원
        // ==================================================================
        $display("\n=== T3: N=6 최대 슬레이브 전체 동작 (slave 0~5) ===");
        do_reset;
        node_cnt = 3'd6;
        sl_en    = 6'b111111;   // slave 0~5 전체 활성
        repeat(15000) @(posedge clk); #1;

        check(s0_fsm === 3'd1,   "T3a: slave0 NORMAL");
        check(s1_fsm === 3'd1,   "T3b: slave1 NORMAL");
        check(s2_fsm === 3'd1,   "T3c: slave2 NORMAL");
        check(s3_fsm === 3'd1,   "T3d: slave3 NORMAL");
        check(s4_fsm === 3'd1,   "T3e: slave4 NORMAL");
        check(s5_fsm === 3'd1,   "T3f: slave5 NORMAL");
        check(m_so0  === SDATA0, "T3g: slot_out0 = SDATA0");
        check(m_so1  === SDATA1, "T3h: slot_out1 = SDATA1");
        check(m_so2  === SDATA2, "T3i: slot_out2 = SDATA2");
        check(m_so3  === SDATA3, "T3j: slot_out3 = SDATA3");
        check(m_so4  === SDATA4, "T3k: slot_out4 = SDATA4");
        check(m_so5  === SDATA5, "T3l: slot_out5 = SDATA5");

        // ==================================================================
        // T4: N=2 5사이클 연속 안정성
        //   NODE_CNT=2 → 사이클=3*600=1800 clk
        //   초기 안정화 후 cc0 캡처 → 5사이클(9000 clk) 대기 → cycle_cnt 증가 확인
        //   slot_out이 리셋 없이 올바른 값으로 유지되는지 확인
        // ==================================================================
        $display("\n=== T4: N=2 5사이클 연속 안정성 ===");
        do_reset;
        node_cnt = 3'd2;
        sl_en    = 6'b000011;   // slave 0/1 활성
        begin : t4
            reg [63:0] cc0;
            repeat(4000) @(posedge clk); #1;    // 첫 응답 완료 대기
            cc0 = m_cycle_cnt;
            $display("  [INFO] cc0=%0d (cycle_cnt at t=4000)", cc0);
            repeat(12000) @(posedge clk); #1;   // 5사이클(9000) + 여유
            $display("  [INFO] cycle_cnt=%0d after +12000 clk", m_cycle_cnt);
            check(m_cycle_cnt >= cc0 + 5,  "T4a: cycle_cnt 5사이클 이상 증가");
            check(m_so0 === SDATA0,        "T4b: slot_out0 안정 유지");
            check(m_so1 === SDATA1,        "T4c: slot_out1 안정 유지");
            check(s0_fsm === 3'd1,         "T4d: slave0 NORMAL 유지");
            check(s1_fsm === 3'd1,         "T4e: slave1 NORMAL 유지");
        end

        // ==================================================================
        // T5: no_broadcast watchdog
        //   N=1: slave 0이 NORMAL 진입 후 m_enable=0 (master 정지)
        //   watchdog: 9*slot_ticks = 9*600 = 5400 clk 후 no_broadcast 펄스
        //   irq_ctrl: irq_status[1] = no_broadcast (IRQ_MASK[1]=1)
        //   → 5000(초기) + 6500(watchdog 여유) = 11500 clk 총 대기
        // ==================================================================
        $display("\n=== T5: no_broadcast watchdog (master 정지) ===");
        do_reset;
        node_cnt = 3'd1;
        sl_en    = 6'b000001;
        repeat(5000) @(posedge clk); #1;
        check(s0_fsm === 3'd1, "T5a: (조건) slave0 NORMAL 진입 확인");
        // 마스터 비활성화 → Bus A = 0 → 이후 active_edge 없음
        m_enable = 0;
        // 9*600=5400 clk 경과 후 no_broadcast 발생 → 6500 clk 대기
        repeat(6500) @(posedge clk); #1;
        check(s0_irqst[1] === 1'b1, "T5b: slave0 irq_status[1] = no_broadcast 세트");
        check(s0_irq      === 1'b1, "T5c: slave0 irq HIGH (IRQ_MASK[1] 활성)");
        m_enable = 1;   // 복원

        // ==================================================================
        // T6: 비대칭 활성화 (N=6, slave 0/2/4만 활성)
        //   비활성 slave(1/3/5)는 IDLE 유지, Bus B 비간섭 확인
        //   master: node_cnt=6 → 슬롯 0~6 수신 시도
        //           비활성 슬롯 silent_cnt 증가 (FAULT_TH=30이므로 halt_cmd 미발생)
        //   15000 clk 후: 활성 slave 3개 → NORMAL + slot_out 갱신
        //                 비활성 slave 3개 → IDLE + 해당 slot_out = 0 유지
        // ==================================================================
        $display("\n=== T6: N=6 비대칭 활성화 (slave 0/2/4 활성, 1/3/5 비활성) ===");
        do_reset;
        node_cnt = 3'd6;
        sl_en    = 6'b010101;   // slave 0(bit0), slave 2(bit2), slave 4(bit4)
        repeat(15000) @(posedge clk); #1;

        // 활성 슬레이브: NORMAL + slot_out 갱신
        check(s0_fsm === 3'd1,   "T6a: slave0 NORMAL (활성)");
        check(s2_fsm === 3'd1,   "T6b: slave2 NORMAL (활성)");
        check(s4_fsm === 3'd1,   "T6c: slave4 NORMAL (활성)");
        check(m_so0  === SDATA0, "T6d: slot_out0 = SDATA0");
        check(m_so2  === SDATA2, "T6e: slot_out2 = SDATA2");
        check(m_so4  === SDATA4, "T6f: slot_out4 = SDATA4");
        // 비활성 슬레이브: IDLE + 미응답
        check(s1_fsm === 3'd0,   "T6g: slave1 IDLE (비활성)");
        check(s3_fsm === 3'd0,   "T6h: slave3 IDLE (비활성)");
        check(s5_fsm === 3'd0,   "T6i: slave5 IDLE (비활성)");
        check(m_so1  === 32'h0,  "T6j: slot_out1 = 0 (slave1 미응답)");
        check(m_so3  === 32'h0,  "T6k: slot_out3 = 0 (slave3 미응답)");
        check(m_so5  === 32'h0,  "T6l: slot_out5 = 0 (slave5 미응답)");

        // ==================================================================
        // T7: soft_rst 후 재동작 (N=4)
        //   slave 0~3이 NORMAL 진입 후 soft_rst 1클럭 펄스 → 내부 리셋
        //   slot_timer 재동기화 → 이후 정상 응답 재개
        //   soft_rst 후 추가 2사이클 대기(≈10000 clk) → NORMAL 재진입 + slot_out 재갱신
        // ==================================================================
        $display("\n=== T7: N=4 soft_rst 후 재동작 ===");
        do_reset;
        node_cnt = 3'd4;
        sl_en    = 6'b001111;   // slave 0~3 활성
        repeat(8000) @(posedge clk); #1;   // 초기 NORMAL 진입 대기
        check(s0_fsm === 3'd1,   "T7a: (조건) soft_rst 전 slave0 NORMAL");
        check(s3_fsm === 3'd1,   "T7b: (조건) soft_rst 전 slave3 NORMAL");

        // slave 0~3 동시 soft_rst 펄스 (1클럭)
        @(posedge clk); #1;
        sl_srst = 6'b001111;
        @(posedge clk); #1;
        sl_srst = 6'b0;
        // soft_rst 후 FSM 재초기화: rst_int_n = rst_n & ~soft_rst → 내부 리셋
        // master는 계속 브로드캐스트 중 → 다음 active_edge에서 IDLE→NORMAL 재진입
        // N=4 사이클=5*600=3000 clk × 3사이클 = 9000 clk 대기
        repeat(10000) @(posedge clk); #1;

        check(s0_fsm === 3'd1,   "T7c: slave0 soft_rst 후 NORMAL 재진입");
        check(s1_fsm === 3'd1,   "T7d: slave1 soft_rst 후 NORMAL 재진입");
        check(s2_fsm === 3'd1,   "T7e: slave2 soft_rst 후 NORMAL 재진입");
        check(s3_fsm === 3'd1,   "T7f: slave3 soft_rst 후 NORMAL 재진입");
        check(m_so0  === SDATA0, "T7g: slot_out0 soft_rst 후 재갱신");
        check(m_so3  === SDATA3, "T7h: slot_out3 soft_rst 후 재갱신");

        // ==================================================================
        $display("\n========================================");
        $display("[DONE] sys_integration: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        $display("========================================");
        $finish;
    end

endmodule
