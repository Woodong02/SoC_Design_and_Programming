`timescale 1ns / 1ps
// tbfix_n7: NODE_CNT=7 (최대 슬레이브 7개) 시스템 통합 검증
//
// ── 수정 이력 ─────────────────────────────────────────────────────────────────
// 버그: Master_slot.v / Master_top.v의 NODE_CNT_p1이 3비트 wire여서
//       NODE_CNT=7 → 7+1=8 → 3비트 오버플로우=0 → 슬롯 순환 불가
// 수정: Master_slot.slot [3:0], Master_slot.NODE_CNT [3:0]
//       Master_top.NODE_CNT_p1 [3:0], Master_top 내부 slot wire [3:0]
//       (외부 포트 master_top.NODE_CNT [2:0]는 변경 없음)
//
// ── 타이밍 근거 (DIV=8, GUARD=200) ──────────────────────────────────────────
// NODE_CNT=7 → NODE_CNT_p1=8 (4비트 수정 후 오버플로우 없음)
// Master_slot: 9슬롯 순환 (슬롯 0~8), 각 600clk
// 사이클 = 9*600 = 5400 clk
// 첫 tx_trigger: 슬롯 8, clk_cnt=598 → 약 8*600+598+리셋 = ~5413 clk
// 슬레이브 6 응답 완료: active_edge≈5402, trig=5402+3701=9103, 완료≈9503 clk
// → 15000 clk 대기로 커버
//
// ── 테스트 케이스 ─────────────────────────────────────────────────────────────
// T1: 7개 슬레이브 전체 NORMAL 진입 + slot_out0~6 갱신
// T2: 2사이클 추가 안정성 (cycle_cnt 증가, slot_out 유지)
// T3: 비대칭 7슬레이브 (홀수 활성: 0/2/4/6, 짝수 비활성: 1/3/5)

module tbfix_n7;

    reg clk;
    reg rst_n;
    always #5 clk = ~clk;

    // ── 파라미터 ──────────────────────────────────────────────────────────────
    localparam [9:0] DIV        = 10'd8;
    localparam [9:0] GUARD      = 10'd200;
    localparam [7:0] FAULT_TH   = 8'd30;
    localparam [7:0] SILENT_TH  = 8'd200;
    localparam [7:0] LINE_TH    = 8'd30;

    localparam [31:0] SDATA0 = 32'hDEAD_0000;
    localparam [31:0] SDATA1 = 32'hCAFE_1111;
    localparam [31:0] SDATA2 = 32'hBEEF_2222;
    localparam [31:0] SDATA3 = 32'h1234_3333;
    localparam [31:0] SDATA4 = 32'h5678_4444;
    localparam [31:0] SDATA5 = 32'h9ABC_5555;
    localparam [31:0] SDATA6 = 32'hF0F0_6666;   // 7번째 슬레이브 (SLAVE_ADDR=6)

    // ── master_top 제어 ───────────────────────────────────────────────────────
    // NODE_CNT=7: 3비트 포트에 7(3'b111) 그대로 전달 가능
    reg [2:0] node_cnt;
    reg       m_enable;

    // ── Bus B tristate wired-OR → 2-FF → master GPIO_in ──────────────────────
    wire bus_b;
    wire      bus_b_in    = (bus_b === 1'bz) ? 1'b0 : bus_b;
    reg       b_ff1, b_ff2;
    always @(posedge clk or negedge rst_n)
        if (!rst_n) {b_ff2, b_ff1} <= 2'b0;
        else        {b_ff2, b_ff1} <= {b_ff1, bus_b_in};
    wire gpio_in_sync = b_ff2;

    // ── master_top ────────────────────────────────────────────────────────────
    wire        gpio_out_a;
    wire [7:0]  m_seg_en, m_seg_data;
    wire        m_intr;
    wire [15:0] m_clk_cnt_out;
    wire [2:0]  m_slot_out;
    wire [63:0] m_cycle_cnt;
    wire [31:0] m_so0,m_so1,m_so2,m_so3,m_so4,m_so5,m_so6,m_so7;
    wire [31:0] m_ec0,m_ec1,m_ec2,m_ec3,m_ec4,m_ec5,m_ec6,m_ec7;

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
        .err_cnt0(m_ec0),.err_cnt1(m_ec1),.err_cnt2(m_ec2),.err_cnt3(m_ec3),
        .err_cnt4(m_ec4),.err_cnt5(m_ec5),.err_cnt6(m_ec6),.err_cnt7(m_ec7),
        .slot_out0(m_so0),.slot_out1(m_so1),.slot_out2(m_so2),.slot_out3(m_so3),
        .slot_out4(m_so4),.slot_out5(m_so5),.slot_out6(m_so6),.slot_out7(m_so7),
        .cycle_cnt(m_cycle_cnt)
    );

    // ── 슬레이브 enable ───────────────────────────────────────────────────────
    reg [6:0] sl_en;   // 7비트 (슬레이브 0~6)

    // ── 슬레이브 인스턴스 7개 (bus_b tristate wired-OR) ──────────────────────
    wire [2:0] s0_fsm,s1_fsm,s2_fsm,s3_fsm,s4_fsm,s5_fsm,s6_fsm;
    wire [4:0] s0_irqst,s1_irqst,s2_irqst,s3_irqst,s4_irqst,s5_irqst,s6_irqst;
    wire       s0_irq,s1_irq,s2_irq,s3_irq,s4_irq,s5_irq,s6_irq;

    tdma_slave_top #(.DIV(DIV),.GUARD_TICKS(GUARD),.SLAVE_ADDR(3'd0),
        .FAULT_TH(FAULT_TH),.LINE_FAULT_TH(LINE_TH),.IRQ_MASK(5'b11111))
    u_slave0(.clk(clk),.rst_n(rst_n),.enable(sl_en[0]),.soft_rst(1'b0),
        .tx_data(SDATA0),.irq_clr(5'b0),
        .irq_status(s0_irqst),.fsm_state(s0_fsm),
        .tx_line(gpio_out_a),.rx_line(bus_b),.irq(s0_irq));

    tdma_slave_top #(.DIV(DIV),.GUARD_TICKS(GUARD),.SLAVE_ADDR(3'd1),
        .FAULT_TH(FAULT_TH),.LINE_FAULT_TH(LINE_TH),.IRQ_MASK(5'b11111))
    u_slave1(.clk(clk),.rst_n(rst_n),.enable(sl_en[1]),.soft_rst(1'b0),
        .tx_data(SDATA1),.irq_clr(5'b0),
        .irq_status(s1_irqst),.fsm_state(s1_fsm),
        .tx_line(gpio_out_a),.rx_line(bus_b),.irq(s1_irq));

    tdma_slave_top #(.DIV(DIV),.GUARD_TICKS(GUARD),.SLAVE_ADDR(3'd2),
        .FAULT_TH(FAULT_TH),.LINE_FAULT_TH(LINE_TH),.IRQ_MASK(5'b11111))
    u_slave2(.clk(clk),.rst_n(rst_n),.enable(sl_en[2]),.soft_rst(1'b0),
        .tx_data(SDATA2),.irq_clr(5'b0),
        .irq_status(s2_irqst),.fsm_state(s2_fsm),
        .tx_line(gpio_out_a),.rx_line(bus_b),.irq(s2_irq));

    tdma_slave_top #(.DIV(DIV),.GUARD_TICKS(GUARD),.SLAVE_ADDR(3'd3),
        .FAULT_TH(FAULT_TH),.LINE_FAULT_TH(LINE_TH),.IRQ_MASK(5'b11111))
    u_slave3(.clk(clk),.rst_n(rst_n),.enable(sl_en[3]),.soft_rst(1'b0),
        .tx_data(SDATA3),.irq_clr(5'b0),
        .irq_status(s3_irqst),.fsm_state(s3_fsm),
        .tx_line(gpio_out_a),.rx_line(bus_b),.irq(s3_irq));

    tdma_slave_top #(.DIV(DIV),.GUARD_TICKS(GUARD),.SLAVE_ADDR(3'd4),
        .FAULT_TH(FAULT_TH),.LINE_FAULT_TH(LINE_TH),.IRQ_MASK(5'b11111))
    u_slave4(.clk(clk),.rst_n(rst_n),.enable(sl_en[4]),.soft_rst(1'b0),
        .tx_data(SDATA4),.irq_clr(5'b0),
        .irq_status(s4_irqst),.fsm_state(s4_fsm),
        .tx_line(gpio_out_a),.rx_line(bus_b),.irq(s4_irq));

    tdma_slave_top #(.DIV(DIV),.GUARD_TICKS(GUARD),.SLAVE_ADDR(3'd5),
        .FAULT_TH(FAULT_TH),.LINE_FAULT_TH(LINE_TH),.IRQ_MASK(5'b11111))
    u_slave5(.clk(clk),.rst_n(rst_n),.enable(sl_en[5]),.soft_rst(1'b0),
        .tx_data(SDATA5),.irq_clr(5'b0),
        .irq_status(s5_irqst),.fsm_state(s5_fsm),
        .tx_line(gpio_out_a),.rx_line(bus_b),.irq(s5_irq));

    tdma_slave_top #(.DIV(DIV),.GUARD_TICKS(GUARD),.SLAVE_ADDR(3'd6),
        .FAULT_TH(FAULT_TH),.LINE_FAULT_TH(LINE_TH),.IRQ_MASK(5'b11111))
    u_slave6(.clk(clk),.rst_n(rst_n),.enable(sl_en[6]),.soft_rst(1'b0),
        .tx_data(SDATA6),.irq_clr(5'b0),
        .irq_status(s6_irqst),.fsm_state(s6_fsm),
        .tx_line(gpio_out_a),.rx_line(bus_b),.irq(s6_irq));

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

    task do_reset;
        begin
            @(posedge clk); #1;
            rst_n    = 0;
            m_enable = 0;
            sl_en    = 7'b0;
            repeat(12) @(posedge clk); #1;
            rst_n    = 1;
            m_enable = 1;
            repeat(3) @(posedge clk);
        end
    endtask

    // ── 메인 시뮬레이션 ───────────────────────────────────────────────────────
    initial begin
        clk=0; rst_n=0; m_enable=0; sl_en=7'b0;
        node_cnt=3'd7;   // ★ NODE_CNT=7 (오버플로우 수정 후 동작 확인)
        pass_cnt=0; fail_cnt=0;
        do_reset;

        // ==================================================================
        // T1: N=7 전체 슬레이브 동작
        //   NODE_CNT=7 → NODE_CNT_p1=8 (4비트 fix 후 정상)
        //   9슬롯 사이클=5400clk, 첫 tx_trigger ≈ 8*600+598+15=5413 clk
        //   slave 6 trig_cnt=3700, 응답 완료 ≈ 5415+3701+400=9516 clk
        //   → 15000 clk 대기 (1.5사이클 여유)
        // ==================================================================
        $display("\n=== T1: N=7 (NODE_CNT_p1=8 fix) 전체 7슬레이브 동작 ===");
        node_cnt = 3'd7;
        sl_en    = 7'b1111111;   // slave 0~6 전체 활성
        repeat(15000) @(posedge clk); #1;

        check(s0_fsm === 3'd1,   "T1a: slave0 NORMAL");
        check(s1_fsm === 3'd1,   "T1b: slave1 NORMAL");
        check(s2_fsm === 3'd1,   "T1c: slave2 NORMAL");
        check(s3_fsm === 3'd1,   "T1d: slave3 NORMAL");
        check(s4_fsm === 3'd1,   "T1e: slave4 NORMAL");
        check(s5_fsm === 3'd1,   "T1f: slave5 NORMAL");
        check(s6_fsm === 3'd1,   "T1g: slave6 NORMAL (SLAVE_ADDR=6, SDATA6)");
        check(m_so0  === SDATA0, "T1h: slot_out0 = SDATA0");
        check(m_so1  === SDATA1, "T1i: slot_out1 = SDATA1");
        check(m_so2  === SDATA2, "T1j: slot_out2 = SDATA2");
        check(m_so3  === SDATA3, "T1k: slot_out3 = SDATA3");
        check(m_so4  === SDATA4, "T1l: slot_out4 = SDATA4");
        check(m_so5  === SDATA5, "T1m: slot_out5 = SDATA5");
        check(m_so6  === SDATA6, "T1n: slot_out6 = SDATA6");

        // ==================================================================
        // T2: N=7 연속 2사이클 안정성
        //   각 사이클=5400clk, 2사이클=10800clk → cycle_cnt 2 이상 증가
        //   slot_out0~6 데이터 유지 확인
        // ==================================================================
        $display("\n=== T2: N=7 2사이클 연속 안정성 ===");
        begin : t2
            reg [63:0] cc0;
            repeat(1000) @(posedge clk); #1;
            cc0 = m_cycle_cnt;
            $display("  [INFO] cc0=%0d", cc0);
            repeat(12000) @(posedge clk); #1;   // 2사이클(10800) + 여유
            $display("  [INFO] cycle_cnt=%0d after +12000 clk", m_cycle_cnt);
            check(m_cycle_cnt >= cc0 + 2, "T2a: cycle_cnt 2사이클 이상 증가");
            check(m_so0 === SDATA0,       "T2b: slot_out0 안정 유지");
            check(m_so6 === SDATA6,       "T2c: slot_out6 안정 유지");
            check(s6_fsm === 3'd1,        "T2d: slave6 NORMAL 유지");
        end

        // ==================================================================
        // T3: N=7 비대칭 활성화
        //   slave 0/2/4/6 활성 (홀수 비활성: 1/3/5)
        //   비활성 슬레이브 IDLE, 해당 slot_out = 0 유지
        // ==================================================================
        $display("\n=== T3: N=7 비대칭 활성화 (0/2/4/6 활성) ===");
        do_reset;
        node_cnt = 3'd7;
        sl_en    = 7'b1010101;   // bit 0,2,4,6 = slave 0,2,4,6 활성
        repeat(15000) @(posedge clk); #1;

        check(s0_fsm === 3'd1,   "T3a: slave0 NORMAL (활성)");
        check(s2_fsm === 3'd1,   "T3b: slave2 NORMAL (활성)");
        check(s4_fsm === 3'd1,   "T3c: slave4 NORMAL (활성)");
        check(s6_fsm === 3'd1,   "T3d: slave6 NORMAL (활성)");
        check(m_so0  === SDATA0, "T3e: slot_out0 = SDATA0");
        check(m_so2  === SDATA2, "T3f: slot_out2 = SDATA2");
        check(m_so4  === SDATA4, "T3g: slot_out4 = SDATA4");
        check(m_so6  === SDATA6, "T3h: slot_out6 = SDATA6");
        check(s1_fsm === 3'd0,   "T3i: slave1 IDLE (비활성)");
        check(s3_fsm === 3'd0,   "T3j: slave3 IDLE (비활성)");
        check(s5_fsm === 3'd0,   "T3k: slave5 IDLE (비활성)");
        check(m_so1  === 32'h0,  "T3l: slot_out1 = 0 (slave1 미응답)");
        check(m_so3  === 32'h0,  "T3m: slot_out3 = 0 (slave3 미응답)");
        check(m_so5  === 32'h0,  "T3n: slot_out5 = 0 (slave5 미응답)");

        // ==================================================================
        $display("\n========================================");
        $display("[DONE] tbfix_n7 (NODE_CNT=7): %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        $display("========================================");
        $finish;
    end

endmodule
