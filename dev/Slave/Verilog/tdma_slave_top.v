// tdma_slave_top: PL-only top-level for TDMA slave IP
// Static config via module parameters; runtime control via input ports.
// 2-FF synchronizer on tx_line; soft_rst generates 1-cycle internal reset.
module tdma_slave_top #(
    // ── 정적 설정 (합성 시 고정) ──────────────────────────────────────────
    // 비트 주기 = DIV 클럭 사이클 (마스터와 동일 값 사용)
    parameter [9:0]  DIV           = 10'd8,
    // 슬롯 가드 타임 (클럭 단위, 초기값; 브로드캐스트 수신 시 동적 업데이트)
    parameter [9:0]  GUARD_TICKS   = 10'd0,
    // 이 슬레이브의 TDMA 주소 (0~7)
    parameter [2:0]  SLAVE_ADDR    = 3'd0,
    // 해밍 오류 누적 임계값 (FAULT_CNT >= FAULT_TH → DEAD)
    parameter [7:0]  FAULT_TH      = 8'd30,
    // 라인 오류 누적 임계값 (LINE_CNT >= LINE_FAULT_TH → DEAD)
    parameter [7:0]  LINE_FAULT_TH = 8'd30,
    // IRQ 출력 마스크 비트: [0]=data_sent [1]=no_broadcast [2]=hamming_err
    //                      [3]=halt_cmd  [4]=state_change
    parameter [4:0]  IRQ_MASK      = 5'b00001
) (
    input  wire        clk,
    input  wire        rst_n,       // 비동기 액티브-로우 리셋

    // ── 런타임 제어 ──────────────────────────────────────────────────────
    input  wire        enable,      // 1: 정상 동작, 0: master_rx IDLE 유지
    input  wire        soft_rst,    // 1-클럭 펄스: FSM/타이머 소프트 리셋
    input  wire [31:0] tx_data,     // Bus B로 송신할 32비트 페이로드
    input  wire [4:0]  irq_clr,     // W1C: 해당 irq_status 비트 클리어 (1클럭 펄스)

    // ── 상태 출력 ─────────────────────────────────────────────────────────
    output wire [4:0]  irq_status,  // IRQ 상태 비트
    output wire [2:0]  fsm_state,   // 0=IDLE 1=NORMAL 2=DEAD

    // ── TDMA 물리 인터페이스 ──────────────────────────────────────────────
    input  wire        tx_line,     // Bus A 입력 (마스터→슬레이브 브로드캐스트)
    output wire        rx_line,     // Bus B 출력 (슬레이브→마스터), 비전송 시 High-Z

    // ── 인터럽트 ──────────────────────────────────────────────────────────
    output wire        irq          // 액티브-하이, IRQ_MASK 적용 후 출력
);

    // ── 2-FF synchronizer for tx_line ──────────────────────────────────────
    reg tx_ff1, tx_ff2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) {tx_ff2, tx_ff1} <= 2'b0;
        else        {tx_ff2, tx_ff1} <= {tx_ff1, tx_line};
    end
    wire tx_line_sync = tx_ff2;

    // soft_rst: 1-clock 내부 리셋
    wire rst_int_n = rst_n & ~soft_rst;

    // ── clk_div ────────────────────────────────────────────────────────────
    wire clk_tick;
    clk_div u_clk_div (
        .clk(clk), .rst_n(rst_int_n), .div(DIV),
        .clk_tick(clk_tick)
    );

    // ── master_rx ──────────────────────────────────────────────────────────
    wire        active_edge, bc_valid, bc_preamble_ok, bc_hamming_err, bc_preamble_err;
    wire [7:0]  bc_halt_cmd;
    wire [9:0]  bc_guard_ticks;

    master_rx u_master_rx (
        .clk(clk), .rst_n(rst_int_n),
        .enable(enable), .div(DIV),
        .tx_line_sync(tx_line_sync),
        .active_edge(active_edge),
        .bc_valid(bc_valid),
        .bc_preamble_ok(bc_preamble_ok),
        .bc_halt_cmd(bc_halt_cmd),
        .bc_guard_ticks(bc_guard_ticks),
        .bc_hamming_err(bc_hamming_err),
        .bc_preamble_err(bc_preamble_err)
    );

    // guard_ticks: 파라미터로 초기화, bc_valid 시 브로드캐스트 값으로 동적 업데이트
    reg [9:0] guard_ticks_sync;
    always @(posedge clk or negedge rst_int_n) begin
        if (!rst_int_n) guard_ticks_sync <= GUARD_TICKS;
        else if (bc_valid) guard_ticks_sync <= bc_guard_ticks;
    end

    // ── slot_timer ─────────────────────────────────────────────────────────
    wire tx_trigger, no_broadcast;

    slot_timer u_slot_timer (
        .clk(clk), .rst_n(rst_int_n),
        .div(DIV), .guard_ticks(guard_ticks_sync),
        .slave_addr(SLAVE_ADDR),
        .active_edge(active_edge),
        .tx_trigger(tx_trigger),
        .no_broadcast(no_broadcast)
    );

    // ── fault_fsm ──────────────────────────────────────────────────────────
    wire        tx_enable, state_change;
    wire [7:0]  fault_cnt_out, line_cnt_out;
    wire        halt_cmd = bc_halt_cmd[SLAVE_ADDR];

    fault_fsm u_fault_fsm (
        .clk(clk), .rst_n(rst_int_n),
        .fault_th(FAULT_TH), .line_fault_th(LINE_FAULT_TH),
        .active_edge(active_edge),
        .bc_valid(bc_valid), .bc_preamble_ok(bc_preamble_ok),
        .bc_hamming_err(bc_hamming_err), .bc_preamble_err(bc_preamble_err),
        .no_broadcast(no_broadcast), .halt_cmd(halt_cmd),
        .tx_enable(tx_enable), .state_change(state_change),
        .fsm_state(fsm_state),
        .fault_cnt_out(fault_cnt_out), .line_cnt_out(line_cnt_out)
    );

    // ── slave_tx ───────────────────────────────────────────────────────────
    wire data_sent;

    slave_tx u_slave_tx (
        .clk(clk), .rst_n(rst_int_n),
        .div(DIV), .tx_trigger(tx_trigger), .tx_enable(tx_enable),
        .slave_addr(SLAVE_ADDR), .tx_data(tx_data),
        .rx_line(rx_line),
        .tx_active(), .data_sent(data_sent)
    );

    // ── irq_ctrl ───────────────────────────────────────────────────────────
    irq_ctrl u_irq_ctrl (
        .clk(clk), .rst_n(rst_int_n),
        .data_sent(data_sent), .no_broadcast(no_broadcast),
        .bc_hamming_err(bc_hamming_err), .halt_cmd(halt_cmd),
        .state_change(state_change),
        .irq_clr(irq_clr), .irq_mask(IRQ_MASK),
        .irq_status(irq_status), .irq(irq)
    );

endmodule
