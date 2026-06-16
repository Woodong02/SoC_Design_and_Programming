`timescale 1ns / 1ps
// ---------------------------------------------------------------------------
// tb_axi_master_slave_comm
// ---------------------------------------------------------------------------
// Master PS+PL 전체 + Slave PL 통합 TB.
//
// PS 시뮬레이션: main.c의 Master_node_init(DIV, GUARD_TICKS, NODE_CNT=4,
//               FAULT_TH=244, SILENT_TH=244, ENABLE=1) 을
//               AXI-Lite write 트랜잭션으로 재현.
//
// AXI 레지스터 (Master_v1_0_S00_AXI 기준):
//   offset 0x00 = slv_reg0: [23]=ENABLE, [22:20]=NODE_CNT-1, [19:10]=GUARD_TICKS
//   offset 0x04 = slv_reg1: DIV (master 내부에서 DIV+1 사용)
//   offset 0x08 = slv_reg2: [15:8]=SILENT_TH, [7:0]=FAULT_TH
//
// 검증용 축소 파라미터: DIV=200, GUARD_TICKS=50, NODE_CNT=4 (슬롯 0~3)
// Slave DATA_OUT0=0 .. DATA_OUT3=3
// 기대 결과: slot_out0=0, slot_out1=1, slot_out2=2, slot_out3=3
// ---------------------------------------------------------------------------

module tb_axi_master_slave_comm;

    // ------------------------------------------------------------------
    // 파라미터
    // ------------------------------------------------------------------
    localparam CLK_HALF = 20;           // 25 MHz (40 ns 주기)

    // AXI 초기화 시 쓸 레지스터 값 (main.c Master_node_init 재현)
    localparam [31:0] DIV_VAL   = 32'd200;   // 검증용 (실제: 2500000)
    localparam [9:0]  GTKS_VAL  = 10'd4;     // 검증용 bit period 단위 (실제: 4~8)
    localparam [2:0]  NCNT_M1   = 3'd3;      // NODE_CNT-1 = 3 (4슬롯)
    localparam [7:0]  FAULT_TH  = 8'd244;
    localparam [7:0]  SILENT_TH = 8'd244;

    // slv_reg0 = ENABLE(23) | NODE_CNT-1(22:20) | GUARD_TICKS(19:10)
    localparam [31:0] REG0_VAL = (1'b1 << 23) | (NCNT_M1 << 20) | (GTKS_VAL << 10);
    // slv_reg1 = DIV
    localparam [31:0] REG1_VAL = DIV_VAL;
    // slv_reg2 = SILENT_TH(15:8) | FAULT_TH(7:0)
    localparam [31:0] REG2_VAL = {16'h0000, SILENT_TH, FAULT_TH};

    // slave 파라미터: DIV_REG = DIV → bit_period = DIV+1 = master DIV_p1
    localparam [31:0] SLV_DIV  = DIV_VAL;
    localparam [9:0]  SLV_GTKS = GTKS_VAL;

    localparam FINISH_CYCLES = 10;

    // ------------------------------------------------------------------
    // 클럭 / 리셋
    // ------------------------------------------------------------------
    reg clk;
    reg resetn;

    initial clk = 0;
    always #CLK_HALF clk = ~clk;

    initial begin
        resetn = 0;
        repeat (20) @(posedge clk);
        resetn = 1;
    end

    // ------------------------------------------------------------------
    // AXI-Lite 마스터 신호 (PS 시뮬레이션)
    // ------------------------------------------------------------------
    reg  [6:0]  axi_awaddr;
    reg         axi_awvalid;
    reg  [31:0] axi_wdata;
    reg  [3:0]  axi_wstrb;
    reg         axi_wvalid;
    reg         axi_bready;
    reg  [6:0]  axi_araddr;
    reg         axi_arvalid;
    reg         axi_rready;

    wire        axi_awready;
    wire        axi_wready;
    wire [1:0]  axi_bresp;
    wire        axi_bvalid;
    wire        axi_arready;
    wire [31:0] axi_rdata;
    wire [1:0]  axi_rresp;
    wire        axi_rvalid;

    initial begin
        axi_awaddr  = 0; axi_awvalid = 0;
        axi_wdata   = 0; axi_wstrb   = 4'hF; axi_wvalid = 0;
        axi_bready  = 0;
        axi_araddr  = 0; axi_arvalid = 0; axi_rready = 0;
    end

    // ------------------------------------------------------------------
    // 통신 신호
    // ------------------------------------------------------------------
    wire master_serial;   // master GPIO_out → slave i_master_serial
    wire slave_serial;    // slave o_slave_serial → master GPIO_in
    wire [1:0] led;

    // Master 출력 (모니터링용 계층 참조)
    wire [31:0] slot_out0 = u_master_axi.slot_out0;
    wire [31:0] slot_out1 = u_master_axi.slot_out1;
    wire [31:0] slot_out2 = u_master_axi.slot_out2;
    wire [31:0] slot_out3 = u_master_axi.slot_out3;
    wire [31:0] err_cnt0  = u_master_axi.err_cnt0;
    wire [31:0] err_cnt1  = u_master_axi.err_cnt1;
    wire [31:0] err_cnt2  = u_master_axi.err_cnt2;
    wire [31:0] err_cnt3  = u_master_axi.err_cnt3;
    wire [31:0] cycle_cnt        = u_master_axi.mt0.cycle_cnt;
    wire [2:0]  slot_sig         = u_master_axi.mt0.s0.slot;
    wire        slot_pre_change  = u_master_axi.mt0.s0.slot_pre_change;
    wire        in_sig_w         = u_master_axi.mt0.sig_bus;
    wire [41:0] data_bus_w       = u_master_axi.mt0.data_bus;
    wire [34:0] fixed_data_w     = u_master_axi.mt0.dh0.fixed_data;

    // Slave 송신 측 참조
    wire        slv_tx_frame_valid = u_slave.u_slave_ip_top.tx_frame_valid;
    wire        slv_tx_frame_ready = u_slave.u_slave_ip_top.tx_frame_ready;
    wire [49:0] slv_tx_frame       = u_slave.u_slave_ip_top.tx_frame;
    wire [2:0]  slv_tx_slot_id     = u_slave.u_slave_ip_top.selected_payload_slot_id;
    wire [31:0] slv_tx_payload     = u_slave.u_slave_ip_top.selected_payload;

    // ------------------------------------------------------------------
    // Master_v1_0_S00_AXI (PS AXI wrapper + master_top 포함)
    // ------------------------------------------------------------------
    Master_v1_0_S00_AXI u_master_axi (
        // 하드웨어 포트
        .clk            (clk),
        .resetn_bt      (resetn),
        .GPIO_in        (slave_serial),
        .GPIO_out       (master_serial),
        .DIP_SW         (4'b0),
        // 미연결 출력 (디스플레이)
        .seg_en         (),
        .seg_data       (),
        .intr           (),
        .opclk          (),
        .Hsync          (),
        .Vsync          (),
        .R              (),
        .G              (),
        .B              (),
        .TFTLCD_Tpower  (),
        .TFTLCD_DE_out  (),
        // AXI-Lite 슬레이브 포트 (PS 시뮬레이션)
        .S_AXI_ACLK     (clk),
        .S_AXI_ARESETN  (resetn),
        .S_AXI_AWADDR   (axi_awaddr),
        .S_AXI_AWPROT   (3'b0),
        .S_AXI_AWVALID  (axi_awvalid),
        .S_AXI_AWREADY  (axi_awready),
        .S_AXI_WDATA    (axi_wdata),
        .S_AXI_WSTRB    (axi_wstrb),
        .S_AXI_WVALID   (axi_wvalid),
        .S_AXI_WREADY   (axi_wready),
        .S_AXI_BRESP    (axi_bresp),
        .S_AXI_BVALID   (axi_bvalid),
        .S_AXI_BREADY   (axi_bready),
        .S_AXI_ARADDR   (axi_araddr),
        .S_AXI_ARPROT   (3'b0),
        .S_AXI_ARVALID  (axi_arvalid),
        .S_AXI_ARREADY  (axi_arready),
        .S_AXI_RDATA    (axi_rdata),
        .S_AXI_RRESP    (axi_rresp),
        .S_AXI_RVALID   (axi_rvalid),
        .S_AXI_RREADY   (axi_rready)
    );

    // ------------------------------------------------------------------
    // slave_pl_top (DUT)
    // ------------------------------------------------------------------
    slave_pl_top #(
        .ACTIVE_SLOT (8'b0000_1111),
        .DIV_REG     (SLV_DIV),
        .GUARD_TICKS (SLV_GTKS),
        .DATA_OUT0   (32'h0),
        .DATA_OUT1   (32'h1),
        .DATA_OUT2   (32'h2),
        .DATA_OUT3   (32'h3),
        .DATA_OUT4   (32'h4),
        .DATA_OUT5   (32'h5)
    ) u_slave (
        .i_clk           (clk),
        .i_resetn        (resetn),
        .i_master_serial (master_serial),
        .o_slave_serial  (slave_serial),
        .o_led           (led)
    );

    // ------------------------------------------------------------------
    // AXI-Lite 단일 쓰기 태스크
    // ------------------------------------------------------------------
    task axi_write;
        input [6:0]  addr;
        input [31:0] data;
        begin
            @(negedge clk);
            axi_awaddr  = addr;
            axi_awvalid = 1;
            axi_wdata   = data;
            axi_wvalid  = 1;
            axi_wstrb   = 4'hF;
            // AWREADY & WREADY 대기 (동시 어서트)
            @(posedge clk);
            while (!(axi_awready && axi_wready)) @(posedge clk);
            @(negedge clk);
            axi_awvalid = 0;
            axi_wvalid  = 0;
            axi_bready  = 1;
            // BVALID 대기
            @(posedge clk);
            while (!axi_bvalid) @(posedge clk);
            @(negedge clk);
            axi_bready = 0;
            @(posedge clk);
        end
    endtask

    // ------------------------------------------------------------------
    // PS 초기화 시퀀스 (main.c Master_node_init 재현)
    // ------------------------------------------------------------------
    initial begin
        // 리셋 해제 대기
        @(posedge resetn);
        repeat (5) @(posedge clk);

        // SET_DIV(200): slv_reg1 = DIV
        axi_write(7'h04, REG1_VAL);
        // SET_NODE_CNT/SET_GUARD_TICKS/SET_ENABLE: slv_reg0
        axi_write(7'h00, REG0_VAL);
        // SET_FAULT_TH/SET_SILENT_TH: slv_reg2
        axi_write(7'h08, REG2_VAL);

        $display("[%0t ns] AXI init done: DIV=%0d GUARD=%0d NODE_CNT=4 ENABLE=1",
                 $time, DIV_VAL, GTKS_VAL);
    end

    // ------------------------------------------------------------------
    // 모니터링 / 검증
    // ------------------------------------------------------------------
    // slv_tx_frame_valid & ready: 직렬화기가 프레임을 적재하는 순간 (1클럭).
    // slv_tx_frame[49:42] = preamble, [41:0] = 해밍 코드워드.
    always @(posedge clk) begin
        if (resetn && slv_tx_frame_valid && slv_tx_frame_ready &&
            cycle_cnt >= 1 && cycle_cnt <= FINISH_CYCLES) begin
            $display("  [TX] cycle=%0d slot_id=%0d  codeword=%011b_%011b_%011b_%011b  payload=0x%08h",
                cycle_cnt, slv_tx_slot_id,
                slv_tx_frame[41:33], slv_tx_frame[32:22],
                slv_tx_frame[21:11], slv_tx_frame[10:0],
                slv_tx_payload);
        end
    end

    // in_sig_w: 마스터 RX가 50비트 수신 완료 시 1클럭 발화.
    // data_bus_w = raw 42비트 해밍 코드워드, fixed_data_w = 해밍 디코딩 후 35비트.
    always @(posedge clk) begin
        if (resetn && in_sig_w && cycle_cnt >= 1 && cycle_cnt <= FINISH_CYCLES) begin
            $display("  [RX] cycle=%0d cur_slot=%0d  raw=%011b_%011b_%011b_%011b  slot_id=%0d  data=0x%08h",
                cycle_cnt, slot_sig,
                data_bus_w[41:33], data_bus_w[32:22], data_bus_w[21:11], data_bus_w[10:0],
                fixed_data_w[34:32], fixed_data_w[31:0]);
        end
    end

    // slot_pre_change: 슬롯 경계 1클럭 전에 발화. 이 시점의 slot_sig가
    // 방금 완료된 슬롯 번호이며, slot_out은 해당 슬롯의 최신 수신값이다.
    always @(posedge clk) begin
        if (resetn && slot_pre_change && cycle_cnt >= 1 && cycle_cnt <= FINISH_CYCLES) begin
            $display("cycle=%0d  slot=%0d done  =>  slot_out={%0d,%0d,%0d,%0d}  err={%08h,%08h,%08h,%08h}",
                cycle_cnt, slot_sig,
                slot_out0, slot_out1, slot_out2, slot_out3,
                err_cnt0, err_cnt1, err_cnt2, err_cnt3);
        end
    end

    always @(posedge clk) begin
        if (resetn && cycle_cnt >= FINISH_CYCLES) begin
            $display("----------------------------------------------------");
            $display("RESULT after %0d cycles:", cycle_cnt);
            $display("  slot_out0=%0d  (expect 0)", slot_out0);
            $display("  slot_out1=%0d  (expect 1)", slot_out1);
            $display("  slot_out2=%0d  (expect 2)", slot_out2);
            $display("  slot_out3=%0d  (expect 3)", slot_out3);
            if (slot_out0===32'd0 && slot_out1===32'd1 &&
                slot_out2===32'd2 && slot_out3===32'd3 &&
                err_cnt0===32'd0 && err_cnt1===32'd0 &&
                err_cnt2===32'd0 && err_cnt3===32'd0)
                $display("PASS tb_axi_master_slave_comm");
            else begin
                $display("FAIL tb_axi_master_slave_comm");
                if (!(slot_out0===32'd0 && slot_out1===32'd1 &&
                      slot_out2===32'd2 && slot_out3===32'd3))
                    $display("  FAIL reason: slot_out mismatch");
                if (!(err_cnt0===32'd0 && err_cnt1===32'd0 &&
                      err_cnt2===32'd0 && err_cnt3===32'd0))
                    $display("  FAIL reason: err_cnt non-zero (severe_err occurred)");
            end
            $display("----------------------------------------------------");
            $finish;
        end
    end

endmodule
