`timescale 1ns / 1ps
// tb_master_top: master_top 통합 테스트
// slave 통신 모듈 연결: master_rx(Bus A 수신), slave_tx(Bus B 송신)
//
// Bus A: master_top.GPIO_out → 2-FF → slave master_rx (bc_valid 확인)
// Bus B: slave_tx → tristate→ 2-FF → master_top.GPIO_in → slot_out 갱신
//
// T1: 자동 브로드캐스트 → slave master_rx에서 bc_valid 수신
// T2: cycle_cnt 증가 (slot 순환 확인)
// T3: slave_tx 응답 주입 → slot_out0=0xDEAD1234 (Bus B)
// T4: ENABLE=0 → bc_valid 없음 (동작 중지)
//
// 주의: T3에서 GUARD_TICKS=200 사용 (total_tick=600, slot_pre_change=clk_cnt=598)
//        slave_tx 전송(400클럭)이 slot_pre_change 전에 완료되도록 여유 확보
module tb_master_top;

    reg  clk;
    reg  resetn_bt;
    always #5 clk = ~clk;

    localparam [9:0] DIV       = 10'd8;
    localparam [2:0] NODE_CNT  = 3'd1;   // 슬레이브 1개 → NODE_CNT_p1=2, slot 0,1,2 순환
    localparam [7:0] FAULT_TH  = 8'd30;
    localparam [7:0] SILENT_TH = 8'd200;

    reg  [9:0]  guard_tks;   // 테스트별 조정
    reg  [3:0]  dip_sw;
    reg         enable;

    // Bus A: master_top.GPIO_out
    wire gpio_out_a;

    // Bus B: slave_tx → 2-FF → master_top.GPIO_in
    // gpio_in_sync은 wire (b_ff2로 assign)
    wire gpio_in_sync;

    // master_top 출력
    wire        intr;
    wire [15:0] clk_cnt_out;
    wire [2:0]  m_slot_out;
    wire [7:0]  seg_en, seg_data;
    wire [63:0] cycle_cnt;
    wire [31:0] mso0,mso1,mso2,mso3,mso4,mso5,mso6,mso7;
    wire [31:0] ec0,ec1,ec2,ec3,ec4,ec5,ec6,ec7;

    master_top u_top (
        .clk(clk), .resetn_bt(resetn_bt),
        .DIV(DIV), .GUARD_TICKS(guard_tks), .NODE_CNT(NODE_CNT),
        .GPIO_in(gpio_in_sync),
        .DIP_SW(dip_sw), .ENABLE(enable),
        .FAULT_TH(FAULT_TH), .SILENT_TH(SILENT_TH),
        .seg_en(seg_en), .seg_data(seg_data),
        .GPIO_out(gpio_out_a),
        .intr(intr),
        .clk_cnt_out(clk_cnt_out), .slot_out(m_slot_out),
        .err_cnt0(ec0),.err_cnt1(ec1),.err_cnt2(ec2),.err_cnt3(ec3),
        .err_cnt4(ec4),.err_cnt5(ec5),.err_cnt6(ec6),.err_cnt7(ec7),
        .slot_out0(mso0),.slot_out1(mso1),.slot_out2(mso2),.slot_out3(mso3),
        .slot_out4(mso4),.slot_out5(mso5),.slot_out6(mso6),.slot_out7(mso7),
        .cycle_cnt(cycle_cnt)
    );

    // ── Bus A: master_top.GPIO_out → 2-FF → slave master_rx ─────────────────
    reg a_ff1, a_ff2;
    always @(posedge clk or negedge resetn_bt)
        if (!resetn_bt) {a_ff2, a_ff1} <= 2'b0;
        else            {a_ff2, a_ff1} <= {a_ff1, gpio_out_a};
    wire tx_line_sync_a = a_ff2;

    wire       ae, bc_valid, bc_pok, bc_herr, bc_perr;
    wire [7:0] bc_halt_out;
    wire [9:0] bc_guard_out;

    master_rx u_srx (
        .clk(clk), .rst_n(resetn_bt), .enable(1'b1),
        .div(DIV), .tx_line_sync(tx_line_sync_a),
        .active_edge(ae), .bc_valid(bc_valid),
        .bc_preamble_ok(bc_pok),
        .bc_halt_cmd(bc_halt_out), .bc_guard_ticks(bc_guard_out),
        .bc_hamming_err(bc_herr), .bc_preamble_err(bc_perr)
    );

    // ── Bus B: slave_tx → tristate resolve → 2-FF → master_top.GPIO_in ──────
    reg  [2:0]  sl_addr;
    reg  [31:0] sl_data;
    reg         sl_trig, sl_en;
    wire        rx_line_b;
    wire        sl_active, sl_sent;

    slave_tx u_stx (
        .clk(clk), .rst_n(resetn_bt), .div(DIV),
        .tx_trigger(sl_trig), .tx_enable(sl_en),
        .slave_addr(sl_addr), .tx_data(sl_data),
        .rx_line(rx_line_b), .tx_active(sl_active), .data_sent(sl_sent)
    );

    wire rx_raw = (rx_line_b === 1'bz) ? 1'b0 : rx_line_b;
    reg b_ff1, b_ff2;
    always @(posedge clk or negedge resetn_bt)
        if (!resetn_bt) {b_ff2, b_ff1} <= 2'b0;
        else            {b_ff2, b_ff1} <= {b_ff1, rx_raw};
    assign gpio_in_sync = b_ff2;

    // ── 보조 ─────────────────────────────────────────────────────────────────
    integer pass_cnt, fail_cnt;
    reg bc_valid_seen, ae_seen;

    always @(posedge clk) begin
        if (bc_valid) bc_valid_seen <= 1;
        if (ae)       ae_seen       <= 1;
    end

    task clear_flags;
        begin bc_valid_seen = 0; ae_seen = 0; end
    endtask

    task do_reset;
        begin
            @(posedge clk); #1;
            resetn_bt = 0;
            sl_trig = 0; sl_en = 0; sl_addr = 0; sl_data = 0;
            repeat(5) @(posedge clk); #1; resetn_bt = 1;
            repeat(3) @(posedge clk);
        end
    endtask

    task check;
        input        cond;
        input [255:0] tag;
        begin
            if (cond) begin $display("[PASS] %0s", tag); pass_cnt = pass_cnt + 1; end
            else       begin $display("[FAIL] %0s", tag); fail_cnt = fail_cnt + 1; end
        end
    endtask

    initial begin
        clk = 0; resetn_bt = 0;
        guard_tks = 10'd0; dip_sw = 4'h0; enable = 1;
        sl_trig = 0; sl_en = 0; sl_addr = 0; sl_data = 0;
        pass_cnt = 0; fail_cnt = 0;
        clear_flags;
        do_reset;

        // ── T1: 자동 브로드캐스트 → bc_valid (Bus A) ─────────────────────────
        // NODE_CNT=1 → NODE_CNT_p1=2 → slot 0,1,2 순환, 각 400클럭 (DIV=8, GUARD=0)
        // tx_trigger: slot=2에서 slot_pre_change 발생 ≈ 리셋 후 1198클럭
        // Master_tx 브로드캐스트 완료: +400클럭 → bc_valid ≈ 1600클럭
        // slave master_rx에서 bc_valid까지 2000클럭 대기
        $display("\n--- T1: 자동 브로드캐스트 → bc_valid (Bus A) ---");
        clear_flags;
        repeat(2000) @(posedge clk); #1;
        check(bc_valid_seen === 1'b1, "T1: bc_valid 수신 (slave master_rx)");

        // ── T2: cycle_cnt 증가 (slot 순환 확인) ──────────────────────────────
        // 전체 사이클 = 3슬롯 × 400클럭 = 1200클럭. 추가 2500클럭 대기
        $display("\n--- T2: cycle_cnt 증가 (slot 순환 확인) ---");
        begin : t2
            reg [63:0] cc0;
            cc0 = cycle_cnt;
            repeat(2500) @(posedge clk); #1;
            check(cycle_cnt > cc0, "T2: cycle_cnt 증가");
        end

        // ── T3: slave_tx 응답 → slot_out0 갱신 (Bus B) ───────────────────────
        // GUARD_TICKS=200: total_tick=600클럭, slot_pre_change=clk_cnt=598
        // slave_tx: 리셋 직후 ~10클럭에서 시작, 400클럭 전송 → 완료 ~410 << 598
        // Master_dec_ham: fixed_data[34:32]=addr=0 → slot_out0 업데이트
        $display("\n--- T3: slave_tx → slot_out0=0xDEAD1234 (Bus B) ---");
        do_reset;
        guard_tks = 10'd200;   // slot_pre_change를 598클럭으로 밀어 전송 완료(410) 후 발생
        clear_flags;
        sl_addr = 3'd0; sl_data = 32'hDEAD1234; sl_en = 1;
        @(posedge clk); #1; sl_trig = 1;
        @(posedge clk); #1; sl_trig = 0;
        repeat(600) @(posedge clk); #1;
        check(mso0 === 32'hDEAD1234, "T3: slot_out0=0xDEAD1234");
        guard_tks = 10'd0;   // 복원

        // ── T4: ENABLE=0 → 동작 중지 확인 ───────────────────────────────────
        // wire resetn = resetn_bt && ENABLE → ENABLE=0이면 내부 resetn=0
        // master_top 모든 서브모듈 정지 → GPIO_out=0 → bc_valid 없음
        $display("\n--- T4: ENABLE=0 → bc_valid 없음 ---");
        do_reset;
        clear_flags;
        enable = 0;
        repeat(2000) @(posedge clk); #1;
        check(bc_valid_seen === 1'b0, "T4: ENABLE=0 → bc_valid 없음");
        enable = 1;

        $display("\n========================================");
        $display("[DONE] master_top: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        $display("========================================");
        $finish;
    end

endmodule
