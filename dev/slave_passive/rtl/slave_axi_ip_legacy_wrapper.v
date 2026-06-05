`timescale 1ns / 1ps

// ---------------------------------------------------------------------------
// slave_axi_ip_legacy_wrapper
// ---------------------------------------------------------------------------
// 새 AXI slave IP를 legacy master 통신 TB와 쉽게 연결하기 위한 얇은 wrapper다.
// 별도 동작 로직은 넣지 않고, legacy 이름의 serial 포트를 IP top 포트에
// 매핑하는 역할만 수행한다.
// ---------------------------------------------------------------------------
module slave_axi_ip_legacy_wrapper (
    input  wire        i_clk,
    input  wire        i_resetn,

    input  wire [5:0]  i_s_axi_awaddr,
    input  wire        i_s_axi_awvalid,
    output wire        o_s_axi_awready,
    input  wire [31:0] i_s_axi_wdata,
    input  wire [3:0]  i_s_axi_wstrb,
    input  wire        i_s_axi_wvalid,
    output wire        o_s_axi_wready,
    output wire [1:0]  o_s_axi_bresp,
    output wire        o_s_axi_bvalid,
    input  wire        i_s_axi_bready,

    input  wire [5:0]  i_s_axi_araddr,
    input  wire        i_s_axi_arvalid,
    output wire        o_s_axi_arready,
    output wire [31:0] o_s_axi_rdata,
    output wire [1:0]  o_s_axi_rresp,
    output wire        o_s_axi_rvalid,
    input  wire        i_s_axi_rready,

    input  wire        i_legacy_master_tx,
    input  wire [31:0] i_pl_payload6,
    input  wire        i_pl_payload6_valid,
    input  wire [31:0] i_pl_payload7,
    input  wire        i_pl_payload7_valid,
    output wire        o_legacy_slave_tx,
    output wire        o_legacy_slave_oe,
    output wire        o_irq
);

    // -----------------------------------------------------------------------
    // IP top 인스턴스 연결
    // -----------------------------------------------------------------------
    // 이 wrapper는 포트명 호환 계층이므로 내부 wire를 새로 만들지 않는다.
    // 모든 AXI 및 serial 신호는 slave_axi_ip_top으로 직접 전달한다.

    slave_axi_ip_top #(
        .C_S_AXI_ADDR_WIDTH(6)
    ) u_slave_axi_ip_top (
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
        .i_master_serial(i_legacy_master_tx),
        .i_pl_payload6(i_pl_payload6),
        .i_pl_payload6_valid(i_pl_payload6_valid),
        .i_pl_payload7(i_pl_payload7),
        .i_pl_payload7_valid(i_pl_payload7_valid),
        .o_slave_serial(o_legacy_slave_tx),
        .o_slave_oe(o_legacy_slave_oe),
        .o_irq(o_irq)
    );

endmodule
