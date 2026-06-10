`timescale 1ns / 1ps

module tb_legacy_master_slave_comm;

    localparam [5:0] ADDR_CTRL      = 6'h00;
    localparam [5:0] ADDR_DIV       = 6'h04;
    localparam [5:0] ADDR_DATA_OUT0 = 6'h08;
    localparam [5:0] ADDR_DATA_OUT1 = 6'h0C;
    localparam [5:0] ADDR_DATA_OUT2 = 6'h10;
    localparam [5:0] ADDR_DATA_OUT3 = 6'h14;
    localparam [5:0] ADDR_DATA_OUT4 = 6'h18;
    localparam [5:0] ADDR_DATA_OUT5 = 6'h1C;
    localparam [5:0] ADDR_STATUS    = 6'h20;

    localparam [9:0] MASTER_DIV_RAW   = 10'd0;
    localparam [9:0] MASTER_GUARD     = 10'd220;
    localparam [2:0] MASTER_NODE_CNT  = 3'd7;
    localparam [7:0] MASTER_FAULT_TH  = 8'hFF;
    localparam [7:0] MASTER_SILENT_TH = 8'hFF;

    reg         clk;
    reg         resetn;
    reg         master_enable;
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

    wire        master_gpio_out;
    wire        slave_gpio_out;
    wire        slave_oe;
    wire        slave_irq;
    wire [15:0] master_clk_cnt;
    wire [2:0]  master_slot;
    wire [31:0] err_cnt0;
    wire [31:0] err_cnt1;
    wire [31:0] err_cnt2;
    wire [31:0] err_cnt3;
    wire [31:0] err_cnt4;
    wire [31:0] err_cnt5;
    wire [31:0] err_cnt6;
    wire [31:0] err_cnt7;
    wire [31:0] slot_out0;
    wire [31:0] slot_out1;
    wire [31:0] slot_out2;
    wire [31:0] slot_out3;
    wire [31:0] slot_out4;
    wire [31:0] slot_out5;
    wire [31:0] slot_out6;
    wire [31:0] slot_out7;
    wire [63:0] cycle_cnt;
    wire [7:0]  silent_node;
    wire [7:0]  halt_cmd;
    wire [7:0]  seg_en;
    wire [7:0]  seg_data;

    reg  [31:0] read_value;
    integer     errors;
    integer     wait_index;
    integer     master_tx_rise_count;
    integer     slave_sync_count;
    integer     slave_oe_rise_count;
    integer     slave_tx_done_count;
    reg         master_gpio_out_prev;
    reg         slave_oe_prev;

    slave_axi_ip_legacy_wrapper u_slave_axi_ip_legacy_wrapper (
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
        .i_legacy_master_tx(master_gpio_out),
        .i_pl_payload6(32'h6600_0006),
        .i_pl_payload6_valid(1'b1),
        .i_pl_payload7(32'h7700_0007),
        .i_pl_payload7_valid(1'b1),
        .o_legacy_slave_tx(slave_gpio_out),
        .o_legacy_slave_oe(slave_oe),
        .o_irq(slave_irq)
    );

    legacy_master_fixed_wrapper u_master_top (
        .clk(clk),
        .resetn_bt(resetn),
        .DIV(MASTER_DIV_RAW),
        .GUARD_TICKS(MASTER_GUARD),
        .NODE_CNT(MASTER_NODE_CNT),
        .GPIO_in(slave_gpio_out),
        .DIP_SW(4'd0),
        .ENABLE(master_enable),
        .FAULT_TH(MASTER_FAULT_TH),
        .SILENT_TH(MASTER_SILENT_TH),
        .seg_en(seg_en),
        .seg_data(seg_data),
        .GPIO_out(master_gpio_out),
        .clk_cnt(master_clk_cnt),
        .slot(master_slot),
        .err_cnt0(err_cnt0),
        .err_cnt1(err_cnt1),
        .err_cnt2(err_cnt2),
        .err_cnt3(err_cnt3),
        .err_cnt4(err_cnt4),
        .err_cnt5(err_cnt5),
        .err_cnt6(err_cnt6),
        .err_cnt7(err_cnt7),
        .slot_out0(slot_out0),
        .slot_out1(slot_out1),
        .slot_out2(slot_out2),
        .slot_out3(slot_out3),
        .slot_out4(slot_out4),
        .slot_out5(slot_out5),
        .slot_out6(slot_out6),
        .slot_out7(slot_out7),
        .cycle_cnt(cycle_cnt),
        .Silent_node(silent_node),
        .halt_cmd(halt_cmd)
    );

    always begin
        clk = 1'b0;
        #5;
        clk = 1'b1;
        #5;
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            master_gpio_out_prev <= 1'b0;
            slave_oe_prev <= 1'b0;
            master_tx_rise_count <= 0;
            slave_sync_count <= 0;
            slave_oe_rise_count <= 0;
            slave_tx_done_count <= 0;
        end else begin
            master_gpio_out_prev <= master_gpio_out;
            slave_oe_prev <= slave_oe;
            if ((master_gpio_out_prev == 1'b0) && (master_gpio_out == 1'b1)) begin
                master_tx_rise_count <= master_tx_rise_count + 1;
            end
            if (u_slave_axi_ip_legacy_wrapper.u_slave_axi_ip_top.u_slave_ip_top.sync_pulse == 1'b1) begin
                slave_sync_count <= slave_sync_count + 1;
            end
            if ((slave_oe_prev == 1'b0) && (slave_oe == 1'b1)) begin
                slave_oe_rise_count <= slave_oe_rise_count + 1;
            end
            if (u_slave_axi_ip_legacy_wrapper.u_slave_axi_ip_top.u_slave_ip_top.tx_done == 1'b1) begin
                slave_tx_done_count <= slave_tx_done_count + 1;
            end
        end
    end

    task check32;
        input [255:0] label_text;
        input [31:0] actual;
        input [31:0] expected;
        begin
            if (actual !== expected) begin
                $display("FAIL %0s actual=%h expected=%h time=%0t", label_text, actual, expected, $time);
                errors = errors + 1;
            end
        end
    endtask

    task check8;
        input [255:0] label_text;
        input [7:0] actual;
        input [7:0] expected;
        begin
            if (actual !== expected) begin
                $display("FAIL %0s actual=%h expected=%h time=%0t", label_text, actual, expected, $time);
                errors = errors + 1;
            end
        end
    endtask

    task axi_write;
        input [5:0]  addr;
        input [31:0] data;
        begin
            @(negedge clk);
            awaddr = addr;
            wdata = data;
            wstrb = 4'hF;
            awvalid = 1'b1;
            wvalid = 1'b1;
            bready = 1'b1;
            wait (awready && wready);
            @(negedge clk);
            awvalid = 1'b0;
            wvalid = 1'b0;
            wait (bvalid);
            @(negedge clk);
            bready = 1'b0;
        end
    endtask

    task axi_read;
        input [5:0] addr;
        output [31:0] data;
        begin
            @(negedge clk);
            araddr = addr;
            arvalid = 1'b1;
            rready = 1'b1;
            wait (arready);
            @(negedge clk);
            arvalid = 1'b0;
            wait (rvalid);
            data = rdata;
            @(negedge clk);
            rready = 1'b0;
        end
    endtask

    function all_payloads_received;
        input dummy;
        begin
            all_payloads_received =
                (slot_out0 == 32'h1000_0000) &
                (slot_out1 == 32'h1000_0001) &
                (slot_out2 == 32'h1000_0002) &
                (slot_out3 == 32'h1000_0003) &
                (slot_out4 == 32'h1000_0004) &
                (slot_out5 == 32'h1000_0005) &
                (slot_out6 == 32'h6600_0006) &
                (slot_out7 == 32'h7700_0007);
        end
    endfunction

    initial begin
        errors = 0;
        resetn = 1'b0;
        master_enable = 1'b0;
        awaddr = 6'd0;
        awvalid = 1'b0;
        wdata = 32'd0;
        wstrb = 4'd0;
        wvalid = 1'b0;
        bready = 1'b0;
        araddr = 6'd0;
        arvalid = 1'b0;
        rready = 1'b0;

        repeat (8) @(negedge clk);
        resetn = 1'b1;
        repeat (8) @(negedge clk);

        axi_write(ADDR_DIV, {22'd0, MASTER_DIV_RAW});
        axi_write(ADDR_DATA_OUT0, 32'h1000_0000);
        axi_write(ADDR_DATA_OUT1, 32'h1000_0001);
        axi_write(ADDR_DATA_OUT2, 32'h1000_0002);
        axi_write(ADDR_DATA_OUT3, 32'h1000_0003);
        axi_write(ADDR_DATA_OUT4, 32'h1000_0004);
        axi_write(ADDR_DATA_OUT5, 32'h1000_0005);
        axi_write(ADDR_CTRL, 32'd1 | ({22'd0, MASTER_GUARD} << 1) | (32'hFF << 11));
        repeat (12) @(negedge clk);

        axi_read(ADDR_STATUS, read_value);
        check32("slave enabled before legacy master start", read_value & 32'h0000_0001, 32'h0000_0001);

        master_enable = 1'b1;

        wait_index = 0;
        while ((all_payloads_received(1'b0) == 1'b0) && (wait_index < 12000)) begin
            @(posedge clk);
            wait_index = wait_index + 1;
        end

        if (all_payloads_received(1'b0) != 1'b1) begin
            $display("FAIL legacy master did not receive all payloads by timeout");
            $display("debug master_tx_rise=%0d slave_sync=%0d slave_oe_rise=%0d slave_tx_done=%0d slot=%0d clk_cnt=%0d",
                     master_tx_rise_count, slave_sync_count, slave_oe_rise_count, slave_tx_done_count,
                     master_slot, master_clk_cnt);
            $display("debug master DIV_p1=%0d data_len_tick=%0d total_tick=%0d resetn_inner=%b enable=%b",
                     u_master_top.DIV_p1, u_master_top.s0.data_len_tick, u_master_top.s0.total_tick,
                     u_master_top.resetn, master_enable);
            $display("debug err_cnt0=%h err_cnt1=%h err_cnt2=%h err_cnt3=%h", err_cnt0, err_cnt1, err_cnt2, err_cnt3);
            $display("debug err_cnt4=%h err_cnt5=%h err_cnt6=%h err_cnt7=%h", err_cnt4, err_cnt5, err_cnt6, err_cnt7);
            $display("slot_out0=%h slot_out1=%h slot_out2=%h slot_out3=%h", slot_out0, slot_out1, slot_out2, slot_out3);
            $display("slot_out4=%h slot_out5=%h slot_out6=%h slot_out7=%h", slot_out4, slot_out5, slot_out6, slot_out7);
            errors = errors + 1;
        end

        repeat (20) @(posedge clk);

        check32("legacy slot0 payload", slot_out0, 32'h1000_0000);
        check32("legacy slot1 payload", slot_out1, 32'h1000_0001);
        check32("legacy slot2 payload", slot_out2, 32'h1000_0002);
        check32("legacy slot3 payload", slot_out3, 32'h1000_0003);
        check32("legacy slot4 payload", slot_out4, 32'h1000_0004);
        check32("legacy slot5 payload", slot_out5, 32'h1000_0005);
        check32("legacy slot6 payload", slot_out6, 32'h6600_0006);
        check32("legacy slot7 payload", slot_out7, 32'h7700_0007);
        check8("legacy halt mask remains clear", halt_cmd, 8'h00);

        if (errors == 0) begin
            $display("PASS tb_legacy_master_slave_comm");
        end else begin
            $display("FAIL tb_legacy_master_slave_comm errors=%0d", errors);
        end
        $finish;
    end

endmodule

module legacy_master_fixed_wrapper (
    input wire clk,
    input wire resetn_bt,
    input wire [9:0] DIV,
    input wire [9:0] GUARD_TICKS,
    input wire [2:0] NODE_CNT,
    input wire GPIO_in,
    input wire [3:0] DIP_SW,
    input wire ENABLE,
    input wire [7:0] FAULT_TH,
    input wire [7:0] SILENT_TH,

    output wire [7:0] seg_en,
    output wire [7:0] seg_data,

    output wire GPIO_out,
    output wire [15:0] clk_cnt,
    output wire [2:0] slot,

    output wire [31:0] err_cnt0,
    output wire [31:0] err_cnt1,
    output wire [31:0] err_cnt2,
    output wire [31:0] err_cnt3,
    output wire [31:0] err_cnt4,
    output wire [31:0] err_cnt5,
    output wire [31:0] err_cnt6,
    output wire [31:0] err_cnt7,
    output wire [31:0] slot_out0,
    output wire [31:0] slot_out1,
    output wire [31:0] slot_out2,
    output wire [31:0] slot_out3,
    output wire [31:0] slot_out4,
    output wire [31:0] slot_out5,
    output wire [31:0] slot_out6,
    output wire [31:0] slot_out7,

    output wire [63:0] cycle_cnt,
    output wire [7:0] Silent_node,
    output wire [7:0] halt_cmd
);

    wire slot_change;
    wire slot_pre_change;
    wire [9:0] DIV_p1;
    wire tx_trigger;
    wire [41:0] data_bus;
    wire sig_bus;
    wire preamble_err;
    wire [1:0] rx_stat;
    wire resetn;

    assign DIV_p1 = DIV + 10'd1;
    assign tx_trigger = slot_pre_change & (slot == NODE_CNT);
    assign resetn = resetn_bt & ENABLE;

    assign halt_cmd[0] = ((err_cnt0[31:24] + err_cnt0[23:16] + err_cnt0[15:8]) > FAULT_TH) ? 1'b1 : 1'b0;
    assign halt_cmd[1] = ((err_cnt1[31:24] + err_cnt1[23:16] + err_cnt1[15:8]) > FAULT_TH) ? 1'b1 : 1'b0;
    assign halt_cmd[2] = ((err_cnt2[31:24] + err_cnt2[23:16] + err_cnt2[15:8]) > FAULT_TH) ? 1'b1 : 1'b0;
    assign halt_cmd[3] = ((err_cnt3[31:24] + err_cnt3[23:16] + err_cnt3[15:8]) > FAULT_TH) ? 1'b1 : 1'b0;
    assign halt_cmd[4] = ((err_cnt4[31:24] + err_cnt4[23:16] + err_cnt4[15:8]) > FAULT_TH) ? 1'b1 : 1'b0;
    assign halt_cmd[5] = ((err_cnt5[31:24] + err_cnt5[23:16] + err_cnt5[15:8]) > FAULT_TH) ? 1'b1 : 1'b0;
    assign halt_cmd[6] = ((err_cnt6[31:24] + err_cnt6[23:16] + err_cnt6[15:8]) > FAULT_TH) ? 1'b1 : 1'b0;
    assign halt_cmd[7] = ((err_cnt7[31:24] + err_cnt7[23:16] + err_cnt7[15:8]) > FAULT_TH) ? 1'b1 : 1'b0;

    Master_slot s0 (
        .resetn(resetn),
        .clk(clk),
        .DIV(DIV_p1),
        .GUARD_TICKS(GUARD_TICKS),
        .NODE_CNT(NODE_CNT),
        .slot(slot),
        .slot_change(slot_change),
        .slot_pre_change(slot_pre_change),
        .clk_cnt(clk_cnt),
        .rx_stat(rx_stat),
        .cycle_cnt(cycle_cnt)
    );

    Master_tx t0 (
        .clk(clk),
        .resetn(resetn),
        .tx_trigger(tx_trigger),
        .halt_cmd(halt_cmd),
        .GUARD_TICKS(GUARD_TICKS),
        .DIV(DIV_p1),
        .GPIO_out(GPIO_out)
    );

    Master_rx r0 (
        .clk(clk),
        .DIV(DIV_p1),
        .GPIO_in(GPIO_in),
        .resetn(resetn),
        .slot_pre_change(slot_pre_change),
        .data_out(data_bus),
        .out_sig(sig_bus),
        .preamble_err(preamble_err)
    );

    Master_dec_ham dh0 (
        .resetn(resetn),
        .clk(clk),
        .in_sig(sig_bus),
        .GUARD_TICKS(GUARD_TICKS),
        .data_in(data_bus),
        .SILENT_TH(SILENT_TH),
        .slot(slot),
        .preamble_err(preamble_err),
        .slot_change(slot_change),
        .GPIO_in(GPIO_in),
        .rx_stat(rx_stat),
        .halt_cmd(halt_cmd),
        .slot_out0(slot_out0),
        .slot_out1(slot_out1),
        .slot_out2(slot_out2),
        .slot_out3(slot_out3),
        .slot_out4(slot_out4),
        .slot_out5(slot_out5),
        .slot_out6(slot_out6),
        .slot_out7(slot_out7),
        .err_cnt0(err_cnt0),
        .err_cnt1(err_cnt1),
        .err_cnt2(err_cnt2),
        .err_cnt3(err_cnt3),
        .err_cnt4(err_cnt4),
        .err_cnt5(err_cnt5),
        .err_cnt6(err_cnt6),
        .err_cnt7(err_cnt7)
    );

    assign Silent_node[0] = err_cnt0[7:0] > SILENT_TH;
    assign Silent_node[1] = err_cnt1[7:0] > SILENT_TH;
    assign Silent_node[2] = err_cnt2[7:0] > SILENT_TH;
    assign Silent_node[3] = err_cnt3[7:0] > SILENT_TH;
    assign Silent_node[4] = err_cnt4[7:0] > SILENT_TH;
    assign Silent_node[5] = err_cnt5[7:0] > SILENT_TH;
    assign Silent_node[6] = err_cnt6[7:0] > SILENT_TH;
    assign Silent_node[7] = err_cnt7[7:0] > SILENT_TH;

    assign seg_en = 8'd0;
    assign seg_data = {4'd0, DIP_SW};

endmodule
