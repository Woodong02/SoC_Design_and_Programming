`timescale 1ns/1ps

module tb_slave_cfg_regs_status;

    localparam [5:0] ADDR_CTRL              = 6'h00;
    localparam [5:0] ADDR_DIV               = 6'h04;
    localparam [5:0] ADDR_DATA_OUT0         = 6'h08;
    localparam [5:0] ADDR_DATA_OUT5         = 6'h1C;
    localparam [5:0] ADDR_STATUS            = 6'h20;
    localparam [5:0] ADDR_EVENT             = 6'h24;
    localparam [5:0] ADDR_FAULT             = 6'h28;
    localparam [5:0] ADDR_DBG_BIT_PERIOD_LO = 6'h2C;
    localparam [5:0] ADDR_DBG_FRAME_LO      = 6'h30;
    localparam [5:0] ADDR_DBG_SLOT_LO       = 6'h34;
    localparam [5:0] ADDR_DBG_GUARD_HALF_LO = 6'h38;

    reg clk;
    reg resetn;

    reg  [5:0]  awaddr;
    reg         awvalid;
    wire        awready;
    reg  [31:0] wdata;
    reg  [3:0]  wstrb;
    reg         wvalid;
    wire        wready;
    wire [1:0]  bresp;
    wire        bvalid;
    reg         bready;
    reg  [5:0]  araddr;
    reg         arvalid;
    wire        arready;
    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rvalid;
    reg         rready;

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

    reg         cfg_freeze_pulse;
    reg         core_idle;
    wire        cfg_enable;
    wire [9:0]  cfg_guard_ticks;
    wire [7:0]  cfg_active_slot;
    wire [32:0] cfg_bit_period_ticks;
    wire [31:0] cfg_bit_period_reload;
    wire [31:0] cfg_data_out0;
    wire [31:0] cfg_data_out1;
    wire [31:0] cfg_data_out2;
    wire [31:0] cfg_data_out3;
    wire [31:0] cfg_data_out4;
    wire [31:0] cfg_data_out5;
    wire        cfg_commit_pulse;
    wire        cfg_pending;

    wire [31:0] status_reg_value;
    wire [31:0] event_reg_value;
    wire [31:0] fault_reg_value;
    wire        irq;

    reg sts_synced;
    reg sts_rx_active;
    reg sts_tx_active;
    reg [2:0] sts_current_slot;
    reg sts_slot_valid;
    reg [7:0] sts_halt_mask;
    reg sts_pl_payload6_valid;
    reg sts_pl_payload7_valid;

    reg evt_sync_detected;
    reg evt_rx_frame_done;
    reg evt_tx_done;
    reg evt_slot_cycle_done;
    reg evt_preamble_err;
    reg evt_ham_1bit_err;
    reg evt_ham_2bit_err;
    reg fault_tx_overlap;
    reg fault_slot_timing_invalid;
    reg fault_pl_payload6_invalid;
    reg fault_pl_payload7_invalid;
    reg fault_rx_ham_2bit;

    integer errors;
    reg [31:0] read_value;

    slave_axi_lite_regs #(
        .C_S_AXI_ADDR_WIDTH(6)
    ) u_regs (
        .i_clk(clk),
        .i_resetn(resetn),
        .i_s_axi_awaddr(awaddr),
        .i_s_axi_awvalid(awvalid),
        .o_s_axi_awready(awready),
        .i_s_axi_wdata(wdata),
        .i_s_axi_wstrb(wstrb),
        .i_s_axi_wvalid(wvalid),
        .o_s_axi_wready(wready),
        .o_s_axi_bresp(bresp),
        .o_s_axi_bvalid(bvalid),
        .i_s_axi_bready(bready),
        .i_s_axi_araddr(araddr),
        .i_s_axi_arvalid(arvalid),
        .o_s_axi_arready(arready),
        .o_s_axi_rdata(rdata),
        .o_s_axi_rresp(rresp),
        .o_s_axi_rvalid(rvalid),
        .i_s_axi_rready(rready),
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

    slave_cfg_shadow u_shadow (
        .i_clk(clk),
        .i_resetn(resetn),
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
        .i_cfg_freeze_pulse(cfg_freeze_pulse),
        .i_core_idle(core_idle),
        .o_cfg_enable(cfg_enable),
        .o_cfg_guard_ticks(cfg_guard_ticks),
        .o_cfg_active_slot(cfg_active_slot),
        .o_cfg_bit_period_ticks(cfg_bit_period_ticks),
        .o_cfg_bit_period_reload(cfg_bit_period_reload),
        .o_cfg_data_out0(cfg_data_out0),
        .o_cfg_data_out1(cfg_data_out1),
        .o_cfg_data_out2(cfg_data_out2),
        .o_cfg_data_out3(cfg_data_out3),
        .o_cfg_data_out4(cfg_data_out4),
        .o_cfg_data_out5(cfg_data_out5),
        .o_cfg_commit_pulse(cfg_commit_pulse),
        .o_cfg_pending(cfg_pending)
    );

    slave_status_event u_status (
        .i_clk(clk),
        .i_resetn(resetn),
        .i_sts_enabled(cfg_enable),
        .i_sts_synced(sts_synced),
        .i_sts_rx_active(sts_rx_active),
        .i_sts_tx_active(sts_tx_active),
        .i_sts_current_slot(sts_current_slot),
        .i_sts_slot_valid(sts_slot_valid),
        .i_sts_halt_mask(sts_halt_mask),
        .i_sts_cfg_pending(cfg_pending),
        .i_sts_pl_payload6_valid(sts_pl_payload6_valid),
        .i_sts_pl_payload7_valid(sts_pl_payload7_valid),
        .i_evt_sync_detected(evt_sync_detected),
        .i_evt_rx_frame_done(evt_rx_frame_done),
        .i_evt_tx_done(evt_tx_done),
        .i_evt_slot_cycle_done(evt_slot_cycle_done),
        .i_evt_preamble_err(evt_preamble_err),
        .i_evt_ham_1bit_err(evt_ham_1bit_err),
        .i_evt_ham_2bit_err(evt_ham_2bit_err),
        .i_evt_cfg_commit(cfg_commit_pulse),
        .i_fault_tx_overlap(fault_tx_overlap),
        .i_fault_slot_timing_invalid(fault_slot_timing_invalid),
        .i_fault_pl_payload6_invalid(fault_pl_payload6_invalid),
        .i_fault_pl_payload7_invalid(fault_pl_payload7_invalid),
        .i_fault_rx_ham_2bit(fault_rx_ham_2bit),
        .i_event_clear_mask(event_clear_mask),
        .i_fault_clear_mask(fault_clear_mask),
        .o_status_reg_value(status_reg_value),
        .o_event_reg_value(event_reg_value),
        .o_fault_reg_value(fault_reg_value),
        .o_irq(irq)
    );

    always begin
        clk = 1'b0;
        #5;
        clk = 1'b1;
        #5;
    end

    task check32;
        input [255:0] name;
        input [31:0]  actual;
        input [31:0]  expected;
        begin
            if (actual !== expected) begin
                $display("FAIL %0s actual=0x%08h expected=0x%08h", name, actual, expected);
                errors = errors + 1;
            end else begin
                $display("PASS %0s value=0x%08h", name, actual);
            end
        end
    endtask

    task check1;
        input [255:0] name;
        input         actual;
        input         expected;
        begin
            if (actual !== expected) begin
                $display("FAIL %0s actual=%b expected=%b", name, actual, expected);
                errors = errors + 1;
            end else begin
                $display("PASS %0s value=%b", name, actual);
            end
        end
    endtask

    task axi_write;
        input [5:0]  addr;
        input [31:0] data;
        input [3:0]  strb;
        begin
            @(negedge clk);
            awaddr  = addr;
            wdata   = data;
            wstrb   = strb;
            awvalid = 1'b1;
            wvalid  = 1'b1;
            bready  = 1'b1;
            wait (awready && wready);
            @(negedge clk);
            awvalid = 1'b0;
            wvalid  = 1'b0;
            wait (bvalid);
            @(negedge clk);
            bready = 1'b0;
        end
    endtask

    task axi_read;
        input  [5:0]  addr;
        output [31:0] data;
        begin
            @(negedge clk);
            araddr  = addr;
            arvalid = 1'b1;
            rready  = 1'b1;
            wait (arready);
            @(negedge clk);
            arvalid = 1'b0;
            wait (rvalid);
            data = rdata;
            @(negedge clk);
            rready = 1'b0;
        end
    endtask

    task clear_pulses;
        begin
            evt_sync_detected          = 1'b0;
            evt_rx_frame_done          = 1'b0;
            evt_tx_done                = 1'b0;
            evt_slot_cycle_done        = 1'b0;
            evt_preamble_err           = 1'b0;
            evt_ham_1bit_err           = 1'b0;
            evt_ham_2bit_err           = 1'b0;
            fault_tx_overlap           = 1'b0;
            fault_slot_timing_invalid  = 1'b0;
            fault_pl_payload6_invalid  = 1'b0;
            fault_pl_payload7_invalid  = 1'b0;
            fault_rx_ham_2bit          = 1'b0;
        end
    endtask

    initial begin
        errors = 0;
        resetn = 1'b0;
        awaddr = 6'd0;
        awvalid = 1'b0;
        wdata = 32'd0;
        wstrb = 4'd0;
        wvalid = 1'b0;
        bready = 1'b0;
        araddr = 6'd0;
        arvalid = 1'b0;
        rready = 1'b0;
        cfg_freeze_pulse = 1'b0;
        core_idle = 1'b0;
        sts_synced = 1'b0;
        sts_rx_active = 1'b0;
        sts_tx_active = 1'b0;
        sts_current_slot = 3'd0;
        sts_slot_valid = 1'b0;
        sts_halt_mask = 8'd0;
        sts_pl_payload6_valid = 1'b0;
        sts_pl_payload7_valid = 1'b0;
        clear_pulses();

        repeat (4) @(negedge clk);
        resetn = 1'b1;
        repeat (2) @(negedge clk);

        axi_read(ADDR_DBG_BIT_PERIOD_LO, read_value);
        check32("reset dbg bit period", read_value, 32'd1);
        axi_read(ADDR_DBG_FRAME_LO, read_value);
        check32("reset dbg frame", read_value, 32'd50);
        axi_read(ADDR_DBG_SLOT_LO, read_value);
        check32("reset dbg slot", read_value, 32'd50);
        axi_read(ADDR_DBG_GUARD_HALF_LO, read_value);
        check32("reset dbg guard half", read_value, 32'd0);

        axi_write(ADDR_CTRL, 32'hFFFF_FFFF, 4'hF);
        axi_read(ADDR_CTRL, read_value);
        check32("ctrl reserved bits read zero", read_value, 32'h0007_FFFF);

        axi_write(ADDR_CTRL, (32'd1 | (32'd5 << 1) | (32'hA5 << 11)), 4'hF);
        axi_write(ADDR_DIV, 32'd9, 4'hF);
        axi_write(ADDR_DATA_OUT0, 32'h1122_3344, 4'hF);
        axi_write(ADDR_DATA_OUT5, 32'h5566_7788, 4'hF);
        repeat (1) @(negedge clk);
        check1("pending while busy", cfg_pending, 1'b1);
        check32("shadow reload still reset", cfg_bit_period_reload, 32'd0);

        axi_read(ADDR_STATUS, read_value);
        check32("status pending bit", read_value & 32'h0001_0000, 32'h0001_0000);

        core_idle = 1'b1;
        repeat (3) @(negedge clk);
        check1("pending cleared after idle commit", cfg_pending, 1'b0);
        check1("cfg enable committed", cfg_enable, 1'b1);
        check32("cfg guard committed", {22'd0, cfg_guard_ticks}, 32'd5);
        check32("cfg active committed", {24'd0, cfg_active_slot}, 32'h0000_00A5);
        check32("cfg bit period ticks", cfg_bit_period_ticks[31:0], 32'd10);
        check32("cfg reload", cfg_bit_period_reload, 32'd9);
        check32("cfg data0", cfg_data_out0, 32'h1122_3344);
        check32("cfg data5", cfg_data_out5, 32'h5566_7788);

        axi_read(ADDR_EVENT, read_value);
        check32("cfg commit event sticky", read_value & 32'h0000_0080, 32'h0000_0080);
        check1("irq after event", irq, 1'b1);
        axi_write(ADDR_EVENT, 32'h0000_0080, 4'h1);
        repeat (2) @(negedge clk);
        axi_read(ADDR_EVENT, read_value);
        check32("cfg commit event W1C", read_value & 32'h0000_0080, 32'd0);

        evt_sync_detected = 1'b1;
        evt_tx_done = 1'b1;
        evt_preamble_err = 1'b1;
        evt_ham_2bit_err = 1'b1;
        fault_tx_overlap = 1'b1;
        fault_pl_payload7_invalid = 1'b1;
        repeat (1) @(negedge clk);
        clear_pulses();
        repeat (1) @(negedge clk);
        axi_read(ADDR_EVENT, read_value);
        check32("event sticky sources", read_value & 32'h0000_0055, 32'h0000_0055);
        axi_read(ADDR_FAULT, read_value);
        check32("fault sticky sources", read_value & 32'h0000_0009, 32'h0000_0009);

        axi_write(ADDR_EVENT, 32'h0000_0004, 4'h1);
        axi_write(ADDR_FAULT, 32'h0000_0001, 4'h1);
        repeat (2) @(negedge clk);
        axi_read(ADDR_EVENT, read_value);
        check32("event W1C only selected bit", read_value & 32'h0000_0055, 32'h0000_0051);
        axi_read(ADDR_FAULT, read_value);
        check32("fault W1C only selected bit", read_value & 32'h0000_0009, 32'h0000_0008);

        core_idle = 1'b0;
        @(negedge clk);
        cfg_freeze_pulse = 1'b1;
        awaddr  = ADDR_DIV;
        wdata   = 32'd20;
        wstrb   = 4'hF;
        awvalid = 1'b1;
        wvalid  = 1'b1;
        bready  = 1'b1;
        @(negedge clk);
        cfg_freeze_pulse = 1'b0;
        awvalid = 1'b0;
        wvalid  = 1'b0;
        wait (bvalid);
        @(negedge clk);
        bready = 1'b0;
        repeat (2) @(negedge clk);
        check32("same-cycle sync/write freezes old reload", cfg_bit_period_reload, 32'd9);
        check32("same-cycle sync/write leaves pending", {31'd0, cfg_pending}, 32'd1);

        core_idle = 1'b1;
        repeat (3) @(negedge clk);
        check32("new div commits after idle", cfg_bit_period_reload, 32'd20);
        check32("new bit period ticks", cfg_bit_period_ticks[31:0], 32'd21);

        axi_read(ADDR_DBG_BIT_PERIOD_LO, read_value);
        check32("debug bit period from raw register", read_value, 32'd21);
        axi_read(ADDR_DBG_FRAME_LO, read_value);
        check32("debug frame from raw register", read_value, 32'd1050);
        axi_read(ADDR_DBG_SLOT_LO, read_value);
        check32("debug slot from raw register", read_value, 32'd1055);
        axi_read(ADDR_DBG_GUARD_HALF_LO, read_value);
        check32("debug guard half from raw register", read_value, 32'd2);

        if (errors == 0) begin
            $display("PASS tb_slave_cfg_regs_status");
        end else begin
            $display("FAIL tb_slave_cfg_regs_status errors=%0d", errors);
        end
        $finish;
    end

endmodule
