// tdma_slave_sys: 보드 전용 top — tx_data_gen + tdma_slave_top
// enable/soft_rst/irq_clr 는 내부 고정; bus_b는 비전송 시 0 구동 (tri-state 없음)
module tdma_slave_sys #(
    parameter [9:0]  DIV           = 10'd4,
    parameter [9:0]  GUARD_TICKS   = 10'd256,
    parameter [2:0]  SLAVE_ADDR    = 3'd0,
    parameter [7:0]  FAULT_TH      = 8'd30,
    parameter [7:0]  LINE_FAULT_TH = 8'd30,
    parameter [4:0]  IRQ_MASK      = 5'b00001
) (
    input  wire        clk,
    input  wire        rst_n,    // 액티브-로우, Y18 PUSH_G0 (누르면 리셋)
    input  wire        bus_a,    // Bus A: 마스터 브로드캐스트 수신 (E16)
    output wire        bus_b     // Bus B: 슬레이브 송신, 비전송 시 0 (F16)
);
    wire [31:0] tx_data;

    tx_data_gen u_gen (
        .clk(clk), .rst_n(rst_n),
        .tx_data(tx_data)
    );

    tdma_slave_top #(
        .DIV          (DIV),
        .GUARD_TICKS  (GUARD_TICKS),
        .SLAVE_ADDR   (SLAVE_ADDR),
        .FAULT_TH     (FAULT_TH),
        .LINE_FAULT_TH(LINE_FAULT_TH),
        .IRQ_MASK     (IRQ_MASK)
    ) u_slave (
        .clk       (clk),
        .rst_n     (rst_n),
        .enable    (1'b1),      // 상시 활성 (외부 핀 불필요)
        .soft_rst  (1'b0),
        .tx_data   (tx_data),
        .irq_clr   (5'b0),
        .irq_status(),          // 미사용 (LED 연결 시 포트 추가)
        .fsm_state (),
        .bus_a     (bus_a),
        .bus_b     (bus_b),
        .irq       ()
    );


endmodule
