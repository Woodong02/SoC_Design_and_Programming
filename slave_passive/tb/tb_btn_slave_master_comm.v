`timescale 1ns / 1ps
// ---------------------------------------------------------------------------
// tb_btn_slave_master_comm
// ---------------------------------------------------------------------------
// 버튼 → slave payload → master 수신 전체 경로 통합 검증 TB.
//
// DUT 구성:
//   btn_payload_ctrl  ─┐
//                      ├─ slave_ip_top ──(직렬)── Master_v1_0_S00_AXI
//                      └─ (pl_payload6/7)
//
// 시나리오:
//   TC01: 리셋 후 3 마스터 사이클 대기 → slot_out 전체 = 0 확인
//   TC02: 버튼 1회 누름 → 2 사이클 대기 → slot_out = {1,2,4,8,16,32,64,128}
//   TC03: 버튼 2회 누름 → 2 사이클 대기 → slot_out = {2,4,8,16,32,64,128,256}
//   TC04: 버튼 3회 누름 → 2 사이클 대기 → slot_out = {3,6,12,24,48,96,192,384}
//
// 주요 파라미터:
//   CLK_HALF     = 2  (250 MHz 시뮬레이션)
//   DIV          = 100_000   (사용자 지정, bit_period = 100001 clk = 400 μs)
//   GUARD_TICKS  = 100
//   ACTIVE_SLOT  = 8'b1111_1111  (슬롯 0~7 전체)
//   NODE_CNT     = 7 (REG0[22:20]=7 → 슬롯 0~7)
//
//   btn CLK_FREQ = 10_000 / SAMPLE_MS = 20  → SAMP_CNT = 200 사이클 (~800 ns)
//   실제 하드웨어(250 MHz/20 ms = 5,000,000)와 기능은 동일, 시뮬레이션 속도 단축용
//
// 예상 시뮬레이션 시간:
//   1 마스터 사이클 ≒ 8슬롯 × (50비트 + 100 guard) × 100001 clk ≒ 120M clk
//   TC01~TC04 완료 ≒ 10 사이클 × 120M clk = 1200M clk (250 MHz 기준 ≒ 4.8 초 실시간)
// ---------------------------------------------------------------------------
module tb_btn_slave_master_comm;

    // ------------------------------------------------------------------
    // 파라미터
    // ------------------------------------------------------------------
    localparam CLK_HALF = 2;                    // 250 MHz

    localparam [31:0] DIV       = 32'd100_000;
    localparam [9:0]  GTKS      = 10'd100;
    localparam [2:0]  NCNT_M1   = 3'd7;         // REG0[22:20]: 슬롯 0~7
    localparam [7:0]  FAULT_TH  = 8'd244;
    localparam [7:0]  SILENT_TH = 8'd244;

    // AXI 레지스터 값 (Master_node_init 재현)
    // REG0: [23]=ENABLE | [22:20]=NODE_CNT | [19:10]=GUARD_TICKS
    localparam [31:0] REG0_VAL = (32'd1 << 23) | ({29'd0, NCNT_M1} << 20) | ({22'd0, GTKS} << 10);
    localparam [31:0] REG1_VAL = DIV;
    localparam [31:0] REG2_VAL = {16'h0000, SILENT_TH, FAULT_TH};

    // btn_payload_ctrl 시뮬레이션 축소 파라미터 → SAMP_CNT = 200 사이클
    localparam integer BTN_CLK_FREQ = 10_000;
    localparam integer BTN_SAMP_MS  = 20;

    localparam MONITOR_CYCLES = 20;  // 모니터링 출력 최대 사이클

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
    // 버튼 입력
    // ------------------------------------------------------------------
    reg i_BTN;
    initial i_BTN = 1'b1;   // 평소 HIGH (active-low)

    // ------------------------------------------------------------------
    // AXI-Lite 신호 (PS 시뮬레이션)
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
    // 통신선
    // ------------------------------------------------------------------
    wire master_serial;
    wire slave_serial;

    // ------------------------------------------------------------------
    // btn_payload_ctrl
    //   CLK_FREQ_HZ = 10_000, SAMPLE_MS = 20 → SAMP_CNT = 200 사이클
    // ------------------------------------------------------------------
    wire [31:0] btn_payload0, btn_payload1, btn_payload2, btn_payload3;
    wire [31:0] btn_payload4, btn_payload5, btn_payload6, btn_payload7;

    btn_payload_ctrl #(
        .CLK_FREQ_HZ (BTN_CLK_FREQ),
        .SAMPLE_MS   (BTN_SAMP_MS)
    ) u_btn (
        .i_CLK      (clk),
        .i_RST_N    (resetn),
        .i_BTN      (i_BTN),
        .o_PAYLOAD0 (btn_payload0),
        .o_PAYLOAD1 (btn_payload1),
        .o_PAYLOAD2 (btn_payload2),
        .o_PAYLOAD3 (btn_payload3),
        .o_PAYLOAD4 (btn_payload4),
        .o_PAYLOAD5 (btn_payload5),
        .o_PAYLOAD6 (btn_payload6),
        .o_PAYLOAD7 (btn_payload7)
    );

    // ------------------------------------------------------------------
    // slave_ip_top  (test_src 수정판: slave_cfg_shadow 직통 pass-through)
    // ------------------------------------------------------------------
    wire slave_oe;
    wire irq;

    slave_ip_top u_slave_ip_top (
        .i_clk               (clk),
        .i_resetn            (resetn),

        .i_reg_enable        (1'b1),
        .i_reg_guard_ticks   (GTKS),
        .i_reg_active_slot   (8'b1111_1111),
        .i_reg_div           (DIV),
        .i_reg_data_out0     (btn_payload0),
        .i_reg_data_out1     (btn_payload1),
        .i_reg_data_out2     (btn_payload2),
        .i_reg_data_out3     (btn_payload3),
        .i_reg_data_out4     (btn_payload4),
        .i_reg_data_out5     (btn_payload5),
        .i_reg_write_pulse   (1'b1),
        .i_event_clear_mask  (32'b0),
        .i_fault_clear_mask  (32'b0),

        .o_status_reg_value  (),
        .o_event_reg_value   (),
        .o_fault_reg_value   (),

        .i_master_serial     (master_serial),
        .i_pl_payload6       (btn_payload6),
        .i_pl_payload6_valid (1'b1),
        .i_pl_payload7       (btn_payload7),
        .i_pl_payload7_valid (1'b1),
        .o_slave_serial      (slave_serial),
        .o_slave_oe          (slave_oe),
        .o_irq               (irq)
    );

    // ------------------------------------------------------------------
    // Master_v1_0_S00_AXI
    // ------------------------------------------------------------------
    Master_v1_0_S00_AXI u_master_axi (
        .clk            (clk),
        .resetn_bt      (resetn),
        .GPIO_in        (slave_serial),
        .GPIO_out       (master_serial),
        .DIP_SW         (4'b0),
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
    // 모니터링용 계층 참조 (마스터)
    // ------------------------------------------------------------------
    wire [31:0] slot_out0 = u_master_axi.slot_out0;
    wire [31:0] slot_out1 = u_master_axi.slot_out1;
    wire [31:0] slot_out2 = u_master_axi.slot_out2;
    wire [31:0] slot_out3 = u_master_axi.slot_out3;
    wire [31:0] slot_out4 = u_master_axi.slot_out4;
    wire [31:0] slot_out5 = u_master_axi.slot_out5;
    wire [31:0] slot_out6 = u_master_axi.slot_out6;
    wire [31:0] slot_out7 = u_master_axi.slot_out7;
    wire [31:0] err_cnt0  = u_master_axi.err_cnt0;
    wire [31:0] err_cnt1  = u_master_axi.err_cnt1;
    wire [31:0] err_cnt2  = u_master_axi.err_cnt2;
    wire [31:0] err_cnt3  = u_master_axi.err_cnt3;
    wire [31:0] err_cnt4  = u_master_axi.err_cnt4;
    wire [31:0] err_cnt5  = u_master_axi.err_cnt5;
    wire [31:0] err_cnt6  = u_master_axi.err_cnt6;
    wire [31:0] err_cnt7  = u_master_axi.err_cnt7;
    wire [31:0] cycle_cnt       = u_master_axi.mt0.cycle_cnt;
    wire [2:0]  slot_sig        = u_master_axi.mt0.s0.slot;
    wire        slot_pre_change = u_master_axi.mt0.s0.slot_pre_change;
    wire        in_sig_w        = u_master_axi.mt0.sig_bus;
    wire [41:0] data_bus_w      = u_master_axi.mt0.data_bus;
    wire [34:0] fixed_data_w    = u_master_axi.mt0.dh0.fixed_data;

    // 슬레이브 TX 참조
    wire        slv_tx_frame_valid = u_slave_ip_top.tx_frame_valid;
    wire        slv_tx_frame_ready = u_slave_ip_top.tx_frame_ready;
    wire [49:0] slv_tx_frame       = u_slave_ip_top.tx_frame;
    wire [2:0]  slv_tx_slot_id     = u_slave_ip_top.selected_payload_slot_id;
    wire [31:0] slv_tx_payload     = u_slave_ip_top.selected_payload;

    // ------------------------------------------------------------------
    // AXI 쓰기 태스크
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
            @(posedge clk);
            while (!(axi_awready && axi_wready)) @(posedge clk);
            @(negedge clk);
            axi_awvalid = 0;
            axi_wvalid  = 0;
            axi_bready  = 1;
            @(posedge clk);
            while (!axi_bvalid) @(posedge clk);
            @(negedge clk);
            axi_bready = 0;
            @(posedge clk);
        end
    endtask

    // ------------------------------------------------------------------
    // 버튼 누름 태스크
    // ------------------------------------------------------------------
    // btn_payload_ctrl의 falling-edge 검출 타이밍:
    //   1) sample_tick NBA 발생 사이클 T: btn_q 는 이전 사이클 값 유지
    //   2) 사이클 T+1: sample_tick(pre-NBA)=1 → btn_pressed = sample_tick & btn_q(old) & ~i_BTN
    //      → 이 사이클에 btn_q_NBA = i_BTN, payload_NBA += step
    //
    // 태스크 흐름:
    //   1. sample_tick 발생 직후 2클럭 + 1ns 대기 → BTN=0 드라이브
    //      (이 시점 btn_q = 1 확정: 방금 tick에서 HIGH로 샘플됨)
    //   2. 다음 sample_tick 발생 직후 2클럭 대기 (검출 사이클 통과)
    //      → payload 업데이트 완료
    //   3. BTN=1 복귀, press_cnt 증가
    //   4. 한 sample_tick 더 대기 (btn_q=0 안정화)
    // ------------------------------------------------------------------
    integer press_cnt;

    task press_btn;
        begin
            // step1: 현재 tick 직후 → BTN=0 드라이브
            @(posedge u_btn.sample_tick);
            @(posedge clk); @(posedge clk); #1;
            i_BTN = 1'b0;

            // step2: 다음 tick → btn_pressed=1 (payload NBA 발생)
            @(posedge u_btn.sample_tick);
            @(posedge clk); @(posedge clk); #1;

            // step3: 버튼 해제
            i_BTN = 1'b1;
            press_cnt = press_cnt + 1;
            $display("[%0t ns] BTN press #%0d complete: btn_payload={%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d}",
                $time, press_cnt,
                btn_payload0, btn_payload1, btn_payload2, btn_payload3,
                btn_payload4, btn_payload5, btn_payload6, btn_payload7);

            // step4: 다음 tick까지 대기 (btn_q=0 처리 후 새 사이클 준비)
            @(posedge u_btn.sample_tick);
            @(posedge clk); @(posedge clk); #1;
        end
    endtask

    // ------------------------------------------------------------------
    // 마스터 사이클 대기 태스크
    // ------------------------------------------------------------------
    task wait_cycle;
        input integer target;
        begin
            while (cycle_cnt < target) @(posedge clk);
            // 슬롯 스캔 경계에서 약간 더 대기 (slot_out 안정)
            repeat(10) @(posedge clk);
        end
    endtask

    // ------------------------------------------------------------------
    // 검증 태스크
    // ------------------------------------------------------------------
    integer pass_cnt;
    integer fail_cnt;

    task check_slots;
        input integer tc_id;
        input integer n_press;
        reg ok;
        reg err_ok;
        begin
            ok = (slot_out0 === n_press * 1)   &&
                 (slot_out1 === n_press * 2)   &&
                 (slot_out2 === n_press * 4)   &&
                 (slot_out3 === n_press * 8)   &&
                 (slot_out4 === n_press * 16)  &&
                 (slot_out5 === n_press * 32)  &&
                 (slot_out6 === n_press * 64)  &&
                 (slot_out7 === n_press * 128);
            err_ok = (err_cnt0 === 32'd0) && (err_cnt1 === 32'd0) &&
                     (err_cnt2 === 32'd0) && (err_cnt3 === 32'd0) &&
                     (err_cnt4 === 32'd0) && (err_cnt5 === 32'd0) &&
                     (err_cnt6 === 32'd0) && (err_cnt7 === 32'd0);

            if (ok && err_ok) begin
                $display("TC%0d PASS  press=%0d  slot={%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d}",
                    tc_id, n_press,
                    slot_out0, slot_out1, slot_out2, slot_out3,
                    slot_out4, slot_out5, slot_out6, slot_out7);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("TC%0d FAIL  press=%0d  cycle_cnt=%0d", tc_id, n_press, cycle_cnt);
                if (slot_out0 !== n_press*1)
                    $display("  slot0: got %0d  expect %0d", slot_out0, n_press*1);
                if (slot_out1 !== n_press*2)
                    $display("  slot1: got %0d  expect %0d", slot_out1, n_press*2);
                if (slot_out2 !== n_press*4)
                    $display("  slot2: got %0d  expect %0d", slot_out2, n_press*4);
                if (slot_out3 !== n_press*8)
                    $display("  slot3: got %0d  expect %0d", slot_out3, n_press*8);
                if (slot_out4 !== n_press*16)
                    $display("  slot4: got %0d  expect %0d", slot_out4, n_press*16);
                if (slot_out5 !== n_press*32)
                    $display("  slot5: got %0d  expect %0d", slot_out5, n_press*32);
                if (slot_out6 !== n_press*64)
                    $display("  slot6: got %0d  expect %0d", slot_out6, n_press*64);
                if (slot_out7 !== n_press*128)
                    $display("  slot7: got %0d  expect %0d", slot_out7, n_press*128);
                if (!err_ok)
                    $display("  err_cnt: {%08h,%08h,%08h,%08h,%08h,%08h,%08h,%08h}",
                        err_cnt0, err_cnt1, err_cnt2, err_cnt3,
                        err_cnt4, err_cnt5, err_cnt6, err_cnt7);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    // ------------------------------------------------------------------
    // 메인 테스트 시퀀스
    // ------------------------------------------------------------------
    initial begin
        pass_cnt  = 0;
        fail_cnt  = 0;
        press_cnt = 0;

        // AXI 초기화 (main.c Master_node_init 재현)
        @(posedge resetn);
        repeat (5) @(posedge clk);
        axi_write(7'h04, REG1_VAL);  // DIV = 100000
        axi_write(7'h00, REG0_VAL);  // ENABLE | NODE_CNT=7 | GUARD_TICKS=100
        axi_write(7'h08, REG2_VAL);  // FAULT_TH=244, SILENT_TH=244
        $display("[%0t ns] AXI init done: DIV=%0d GUARD_TICKS=%0d 8-slot ENABLE=1",
                 $time, DIV, GTKS);
        $display("  REG0=0x%08h REG1=0x%08h REG2=0x%08h", REG0_VAL, REG1_VAL, REG2_VAL);

        // TC01: 기준값 확인 — 3 마스터 사이클 후 slot_out 전체 = 0
        wait_cycle(3);
        check_slots(1, 0);

        // TC02: 버튼 1회 누름 → 2 사이클 후 확인
        press_btn();
        wait_cycle(cycle_cnt + 2);
        check_slots(2, 1);

        // TC03: 버튼 2회째 누름 → 2 사이클 후 확인
        press_btn();
        wait_cycle(cycle_cnt + 2);
        check_slots(3, 2);

        // TC04: 버튼 3회째 누름 → 2 사이클 후 확인
        press_btn();
        wait_cycle(cycle_cnt + 2);
        check_slots(4, 3);

        // 최종 결과
        $display("======================================================");
        $display("RESULT: %0d PASS / %0d FAIL", pass_cnt, fail_cnt);
        if (fail_cnt == 0)
            $display("PASS tb_btn_slave_master_comm");
        else
            $display("FAIL tb_btn_slave_master_comm");
        $display("======================================================");
        $finish;
    end

    // ------------------------------------------------------------------
    // 사이클 경계 모니터링
    // ------------------------------------------------------------------
    always @(posedge clk) begin
        if (resetn && slot_pre_change && cycle_cnt <= MONITOR_CYCLES) begin
            $display("[%0t ns] cycle=%0d slot=%0d  btn_pl={%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d}  slot_out={%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d}",
                $time, cycle_cnt, slot_sig,
                btn_payload0, btn_payload1, btn_payload2, btn_payload3,
                btn_payload4, btn_payload5, btn_payload6, btn_payload7,
                slot_out0, slot_out1, slot_out2, slot_out3,
                slot_out4, slot_out5, slot_out6, slot_out7);
        end
    end

    // 슬레이브 TX 프레임 모니터링
    always @(posedge clk) begin
        if (resetn && slv_tx_frame_valid && slv_tx_frame_ready &&
            cycle_cnt <= MONITOR_CYCLES) begin
            $display("  [TX] cycle=%0d slot_id=%0d payload=%0d (0x%08h)",
                cycle_cnt, slv_tx_slot_id, slv_tx_payload, slv_tx_payload);
        end
    end

    // 마스터 RX 수신 모니터링
    always @(posedge clk) begin
        if (resetn && in_sig_w && cycle_cnt <= MONITOR_CYCLES) begin
            $display("  [RX] cycle=%0d slot=%0d  slot_id=%0d data=%0d (0x%08h)",
                cycle_cnt, slot_sig, fixed_data_w[34:32],
                fixed_data_w[31:0], fixed_data_w[31:0]);
        end
    end

endmodule
