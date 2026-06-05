`timescale 1ns / 1ps

// ---------------------------------------------------------------------------
// slave_axi_ip_top
// ---------------------------------------------------------------------------
// AXI-Lite register file과 slave_ip_top 코어를 연결하는 얇은 glue 모듈이다.
// Vivado IP packaging 시 이 모듈이 AXI-Lite slave 인터페이스를 노출하는
// 최상위가 되며, 생성된 wrapper는 이 모듈을 감싸게 된다.
// 동작 로직은 slave_ip_top에, AXI 프로토콜은 slave_axi_lite_regs에 있다.
// ---------------------------------------------------------------------------
module slave_axi_ip_top #(
    parameter C_S_AXI_ADDR_WIDTH = 6,
    parameter [9:0] MIN_GUARD_TICKS = 10'd4
) (
    input  wire                          i_clk,
    input  wire                          i_resetn,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0] i_s_axi_awaddr,
    input  wire                          i_s_axi_awvalid,
    output wire                          o_s_axi_awready,
    input  wire [31:0]                   i_s_axi_wdata,
    input  wire [3:0]                    i_s_axi_wstrb,
    input  wire                          i_s_axi_wvalid,
    output wire                          o_s_axi_wready,
    output wire [1:0]                    o_s_axi_bresp,
    output wire                          o_s_axi_bvalid,
    input  wire                          i_s_axi_bready,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0] i_s_axi_araddr,
    input  wire                          i_s_axi_arvalid,
    output wire                          o_s_axi_arready,
    output wire [31:0]                   o_s_axi_rdata,
    output wire [1:0]                    o_s_axi_rresp,
    output wire                          o_s_axi_rvalid,
    input  wire                          i_s_axi_rready,

    input  wire                          i_master_serial,
    input  wire [31:0]                   i_pl_payload6,
    input  wire                          i_pl_payload6_valid,
    input  wire [31:0]                   i_pl_payload7,
    input  wire                          i_pl_payload7_valid,
    output wire                          o_slave_serial,
    output wire                          o_slave_oe,
    output wire                          o_irq
);

    // -----------------------------------------------------------------------
    // AXI register file → core 연결 wire
    // -----------------------------------------------------------------------
    wire        reg_enable;
    wire [9:0]  reg_guard_ticks;
    wire [7:0]  reg_active_slot;
    wire [31:0] reg_div;
    wire [31:0] reg_data_out0;
    wire [31:0] reg_data_out1;
    wire [31:0] reg_data_out2;
    wire [31:0] reg_data_out3;
    wire [31:0] reg_data_out4;
    wire [31:0] reg_data_out5;
    wire        reg_write_pulse;
    wire [31:0] event_clear_mask;
    wire [31:0] fault_clear_mask;

    wire [31:0] status_reg_value;
    wire [31:0] event_reg_value;
    wire [31:0] fault_reg_value;

    // -----------------------------------------------------------------------
    // AXI-Lite 레지스터 파일
    // -----------------------------------------------------------------------
    slave_axi_lite_regs #(
        .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
    ) u_slave_axi_lite_regs (
        .i_clk(i_clk),
        .i_resetn(i_resetn),
        .i_s_axi_awaddr(i_s_axi_awaddr),
        .i_s_axi_awvalid(i_s_axi_awvalid),
        .o_s_axi_awready(o_s_axi_awready),
        .i_s_axi_wdata(i_s_axi_wdata),
        .i_s_axi_wstrb(i_s_axi_wstrb),
        .i_s_axi_wvalid(i_s_axi_wvalid),
        .o_s_axi_wready(o_s_axi_wready),
        .o_s_axi_bresp(o_s_axi_bresp),
        .o_s_axi_bvalid(o_s_axi_bvalid),
        .i_s_axi_bready(i_s_axi_bready),
        .i_s_axi_araddr(i_s_axi_araddr),
        .i_s_axi_arvalid(i_s_axi_arvalid),
        .o_s_axi_arready(o_s_axi_arready),
        .o_s_axi_rdata(o_s_axi_rdata),
        .o_s_axi_rresp(o_s_axi_rresp),
        .o_s_axi_rvalid(o_s_axi_rvalid),
        .i_s_axi_rready(i_s_axi_rready),
        .i_status_reg_value(status_reg_value),
        .i_event_reg_value(event_reg_value),
        .i_fault_reg_value(fault_reg_value),
        .o_reg_enable(reg_enable),
        .o_reg_guard_ticks(reg_guard_ticks),
        .o_reg_active_slot(reg_active_slot),
        .o_reg_div(reg_div),
        .o_reg_data_out0(reg_data_out0),
        .o_reg_data_out1(reg_data_out1),
        .o_reg_data_out2(reg_data_out2),
        .o_reg_data_out3(reg_data_out3),
        .o_reg_data_out4(reg_data_out4),
        .o_reg_data_out5(reg_data_out5),
        .o_reg_write_pulse(reg_write_pulse),
        .o_event_clear_mask(event_clear_mask),
        .o_fault_clear_mask(fault_clear_mask)
    );

    // -----------------------------------------------------------------------
    // passive slave 통신 코어
    // -----------------------------------------------------------------------
    slave_ip_top #(
        .MIN_GUARD_TICKS(MIN_GUARD_TICKS)
    ) u_slave_ip_top (
        .i_clk(i_clk),
        .i_resetn(i_resetn),
        .i_reg_enable(reg_enable),
        .i_reg_guard_ticks(reg_guard_ticks),
        .i_reg_active_slot(reg_active_slot),
        .i_reg_div(reg_div),
        .i_reg_data_out0(reg_data_out0),
        .i_reg_data_out1(reg_data_out1),
        .i_reg_data_out2(reg_data_out2),
        .i_reg_data_out3(reg_data_out3),
        .i_reg_data_out4(reg_data_out4),
        .i_reg_data_out5(reg_data_out5),
        .i_reg_write_pulse(reg_write_pulse),
        .i_event_clear_mask(event_clear_mask),
        .i_fault_clear_mask(fault_clear_mask),
        .o_status_reg_value(status_reg_value),
        .o_event_reg_value(event_reg_value),
        .o_fault_reg_value(fault_reg_value),
        .i_master_serial(i_master_serial),
        .i_pl_payload6(i_pl_payload6),
        .i_pl_payload6_valid(i_pl_payload6_valid),
        .i_pl_payload7(i_pl_payload7),
        .i_pl_payload7_valid(i_pl_payload7_valid),
        .o_slave_serial(o_slave_serial),
        .o_slave_oe(o_slave_oe),
        .o_irq(o_irq)
    );

endmodule
