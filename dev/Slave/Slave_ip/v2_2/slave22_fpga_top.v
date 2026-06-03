`timescale 1ns / 1ps

// 보드 bring-up용 얇은 top wrapper.
// core RTL은 slave22_top이며, 여기서는 board 핀 footprint만 정리한다.
//  - i_PAYLOAD[31:0]는 보드 상수로 고정 (필요 시 DIP/레지스터로 교체)
//  - 디버그 출력(fault_state, latched_guard)은 내부에서 종단
//  - 상태는 2개 LED로 축약 (마스터 보드 LED 핀과 동일 위치 사용)
module slave22_fpga_top (
    input  wire i_CLK,
    input  wire i_RESETN,
    input  wire i_MASTER_SERIAL,
    output wire o_SLAVE_SERIAL,
    output wire o_LED_TRACKING,
    output wire o_LED_FAULT
);

    // NODE_ID / NODE_CNT는 Master PS(AXI)가 설정하는 NODE_CNT와 반드시 일치해야 한다.
    // 점대점 단일 슬레이브면 NODE_ID=0. 슬레이브가 여럿이면 보드마다 NODE_ID를 바꾼다.
    localparam [2:0]  SLAVE_NODE_ID            = 3'd0;
    localparam [2:0]  SLAVE_NODE_CNT           = 3'd4;
    localparam [15:0] SLAVE_BIT_PERIOD_DEFAULT = 16'd1024; // Master DIV와 일치
    localparam [9:0]  SLAVE_GUARD_TICKS_DEFAULT= 10'd256;  // Master GUARD_TICKS와 일치
    localparam [31:0] FIXED_PAYLOAD            = 32'h0000_0001;

    wire        clk;
    wire        resetn;
    wire        master_serial;

    wire        slave_serial;
    wire        link_tracking;
    wire        halted;
    wire        rate_err;
    wire [2:0]  fault_state_unused;
    wire [9:0]  latched_guard_unused;

    wire        led_tracking;
    wire        led_fault;

    assign clk = i_CLK;
    assign resetn = i_RESETN;
    assign master_serial = i_MASTER_SERIAL;

    slave22_top #(
        .NODE_ID(SLAVE_NODE_ID),
        .NODE_CNT(SLAVE_NODE_CNT),
        .BIT_PERIOD_DEFAULT(SLAVE_BIT_PERIOD_DEFAULT),
        .GUARD_TICKS_DEFAULT(SLAVE_GUARD_TICKS_DEFAULT)
    ) u_slave22_top (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_MASTER_SERIAL(master_serial),
        .i_PAYLOAD(FIXED_PAYLOAD),
        .o_SLAVE_SERIAL(slave_serial),
        .o_LINK_TRACKING(link_tracking),
        .o_HALTED(halted),
        .o_RATE_ERR(rate_err),
        .o_FAULT_STATE(fault_state_unused),
        .o_LATCHED_GUARD_TICKS(latched_guard_unused)
    );

    assign led_tracking = link_tracking;
    assign led_fault = halted | rate_err;

    assign o_SLAVE_SERIAL = slave_serial;
    assign o_LED_TRACKING = led_tracking;
    assign o_LED_FAULT = led_fault;

endmodule
