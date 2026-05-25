// tdma_slave_top: top-level wrapper for TDMA slave IP
// Connects: clk_div, master_rx, slot_timer, slave_tx, fault_fsm, irq_ctrl, regfile
// 2-FF synchronizer on tx_line input; soft_rst generates 1-cycle internal reset.
module tdma_slave_top (
    input  wire        clk,
    input  wire        rst_n,

    // AXI-Lite slave
    input  wire [4:0]  s_axil_awaddr,
    input  wire        s_axil_awvalid,
    output wire        s_axil_awready,
    input  wire [31:0] s_axil_wdata,
    input  wire [3:0]  s_axil_wstrb,
    input  wire        s_axil_wvalid,
    output wire        s_axil_wready,
    output wire [1:0]  s_axil_bresp,
    output wire        s_axil_bvalid,
    input  wire        s_axil_bready,
    input  wire [4:0]  s_axil_araddr,
    input  wire        s_axil_arvalid,
    output wire        s_axil_arready,
    output wire [31:0] s_axil_rdata,
    output wire [1:0]  s_axil_rresp,
    output wire        s_axil_rvalid,
    input  wire        s_axil_rready,

    // TDMA physical interface
    input  wire        tx_line,
    output wire        rx_line,

    // Interrupt
    output wire        irq
);
    // ── 2-FF synchronizer for tx_line ──────────────────────────────────────
    reg tx_ff1, tx_ff2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) {tx_ff2, tx_ff1} <= 2'b0;
        else        {tx_ff2, tx_ff1} <= {tx_ff1, tx_line};
    end
    wire tx_line_sync = tx_ff2;

    // ── Config signals from regfile ─────────────────────────────────────────
    wire        enable, soft_rst;
    wire [9:0]  div, guard_ticks;
    wire [2:0]  slave_addr_cfg;
    wire [7:0]  fault_th, line_fault_th;
    wire [31:0] tx_data;
    wire [4:0]  irq_clr, irq_mask;

    // Combined reset: assert for 1 clock on soft_rst (synchronous soft-reset)
    wire rst_int_n = rst_n & ~soft_rst;

    // ── clk_div ────────────────────────────────────────────────────────────
    wire clk_tick; // available for future use / other submodules
    clk_div u_clk_div (
        .clk(clk), .rst_n(rst_int_n), .div(div),
        .clk_tick(clk_tick)
    );

    // ── master_rx ──────────────────────────────────────────────────────────
    wire        active_edge, bc_valid, bc_preamble_ok, bc_hamming_err, bc_preamble_err;
    wire [7:0]  bc_halt_cmd;
    master_rx u_master_rx (
        .clk(clk), .rst_n(rst_int_n),
        .enable(enable), .div(div),
        .tx_line_sync(tx_line_sync),
        .active_edge(active_edge),
        .bc_valid(bc_valid),
        .bc_preamble_ok(bc_preamble_ok),
        .bc_halt_cmd(bc_halt_cmd),
        .bc_hamming_err(bc_hamming_err),
        .bc_preamble_err(bc_preamble_err)
    );

    // ── slot_timer ─────────────────────────────────────────────────────────
    wire tx_trigger, no_broadcast;
    slot_timer u_slot_timer (
        .clk(clk), .rst_n(rst_int_n),
        .div(div), .guard_ticks(guard_ticks),
        .slave_addr(slave_addr_cfg),
        .active_edge(active_edge),
        .tx_trigger(tx_trigger),
        .no_broadcast(no_broadcast)
    );

    // ── fault_fsm ──────────────────────────────────────────────────────────
    wire        tx_enable, state_change;
    wire [2:0]  fsm_state;
    wire [7:0]  fault_cnt_out, line_cnt_out;
    wire        halt_cmd = bc_halt_cmd[slave_addr_cfg]; // bit-select for this slave

    fault_fsm u_fault_fsm (
        .clk(clk), .rst_n(rst_int_n),
        .fault_th(fault_th), .line_fault_th(line_fault_th),
        .active_edge(active_edge),
        .bc_valid(bc_valid), .bc_preamble_ok(bc_preamble_ok),
        .bc_hamming_err(bc_hamming_err), .bc_preamble_err(bc_preamble_err),
        .no_broadcast(no_broadcast), .halt_cmd(halt_cmd),
        .tx_enable(tx_enable), .state_change(state_change),
        .fsm_state(fsm_state),
        .fault_cnt_out(fault_cnt_out), .line_cnt_out(line_cnt_out)
    );

    // ── slave_tx ───────────────────────────────────────────────────────────
    wire        tx_active, data_sent;
    slave_tx u_slave_tx (
        .clk(clk), .rst_n(rst_int_n),
        .div(div), .tx_trigger(tx_trigger), .tx_enable(tx_enable),
        .slave_addr(slave_addr_cfg), .tx_data(tx_data),
        .rx_line(rx_line),
        .tx_active(tx_active), .data_sent(data_sent)
    );

    // ── irq_ctrl ───────────────────────────────────────────────────────────
    wire [4:0] irq_status;
    irq_ctrl u_irq_ctrl (
        .clk(clk), .rst_n(rst_int_n),
        .data_sent(data_sent), .no_broadcast(no_broadcast),
        .bc_hamming_err(bc_hamming_err), .halt_cmd(halt_cmd),
        .state_change(state_change),
        .irq_clr(irq_clr), .irq_mask(irq_mask),
        .irq_status(irq_status), .irq(irq)
    );

    // ── regfile ────────────────────────────────────────────────────────────
    regfile u_regfile (
        .clk(clk), .rst_n(rst_n), // regfile uses raw rst_n (not soft_rst)
        .s_axil_awaddr(s_axil_awaddr), .s_axil_awvalid(s_axil_awvalid),
        .s_axil_awready(s_axil_awready),
        .s_axil_wdata(s_axil_wdata), .s_axil_wstrb(s_axil_wstrb),
        .s_axil_wvalid(s_axil_wvalid), .s_axil_wready(s_axil_wready),
        .s_axil_bresp(s_axil_bresp), .s_axil_bvalid(s_axil_bvalid),
        .s_axil_bready(s_axil_bready),
        .s_axil_araddr(s_axil_araddr), .s_axil_arvalid(s_axil_arvalid),
        .s_axil_arready(s_axil_arready),
        .s_axil_rdata(s_axil_rdata), .s_axil_rresp(s_axil_rresp),
        .s_axil_rvalid(s_axil_rvalid), .s_axil_rready(s_axil_rready),
        .fsm_state(fsm_state),
        .fault_cnt(fault_cnt_out), .line_cnt(line_cnt_out),
        .ev_data_sent(data_sent), .ev_no_broadcast(no_broadcast),
        .ev_hamming_err(bc_hamming_err), .ev_halt_cmd(halt_cmd),
        .irq_status(irq_status),
        .enable(enable), .soft_rst(soft_rst),
        .div(div), .guard_ticks(guard_ticks),
        .slave_addr_cfg(slave_addr_cfg),
        .fault_th(fault_th), .line_fault_th(line_fault_th),
        .tx_data(tx_data),
        .irq_clr(irq_clr), .irq_mask(irq_mask)
    );

endmodule
