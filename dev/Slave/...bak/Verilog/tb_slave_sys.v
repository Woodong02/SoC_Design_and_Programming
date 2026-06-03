`timescale 1ns / 1ps
// tb_slave_sys: tdma_slave_sys 검증 TB
// 시나리오 1: 정상 브로드캐스트 3회 → data_sent IRQ 3회 확인
// 시나리오 2: 브로드캐스트 중단 → no_broadcast 워치독 → DEAD
// 시나리오 3: HALT 커맨드 → 즉시 DEAD
module tb_slave_sys;

    // ── 파라미터 ──────────────────────────────────────────────────────────────
    localparam [9:0] P_DIV      = 10'd8;
    localparam [9:0] P_GUARD    = 10'd0;
    localparam [2:0] P_ADDR     = 3'd1;   // 슬롯 1
    localparam [7:0] P_FAULT_TH = 8'd10;
    localparam [7:0] P_LINE_TH  = 8'd10;
    // slot_ticks=400, tx_trigger@400clk, data_sent@~800clk, wdog@3600clk

    // ── DUT 포트 ──────────────────────────────────────────────────────────────
    reg        clk    = 1'b0;
    reg        rst_n;
    reg        tx_line;
    wire       rx_line;

    // ── DUT ──────────────────────────────────────────────────────────────────
    tdma_slave_sys #(
        .DIV          (P_DIV),
        .GUARD_TICKS  (P_GUARD),
        .SLAVE_ADDR   (P_ADDR),
        .FAULT_TH     (P_FAULT_TH),
        .LINE_FAULT_TH(P_LINE_TH)
    ) u_dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .tx_line(tx_line),
        .rx_line(rx_line)
    );

    // TB 검증용 내부 신호 직접 참조
    wire [4:0] irq_status = u_dut.u_slave.irq_status;
    wire [2:0] fsm_state  = u_dut.u_slave.fsm_state;

    always #10 clk = ~clk;  // 50 MHz

    // ── 해밍 인코더 (TB 로컬, 마스터 브로드캐스트 생성용) ──────────────────────
    // 브로드캐스트 코드워드: d = {halt_cmd[7:0], guard_ticks[9:0], 17'b0}
    function [41:0] ham_enc;
        input [34:0] d;
        reg p0,p1,p2,p3,p4,p5,po;
        begin
            p0 = d[0]^d[2]^d[4]^d[6]^d[8]^d[10]^d[12]^d[14]^d[16]^d[18]^d[20]^d[22]^d[24]^d[26]^d[28]^d[30]^d[32]^d[34];
            p1 = d[1]^d[2]^d[5]^d[6]^d[9]^d[10]^d[13]^d[14]^d[17]^d[18]^d[21]^d[22]^d[25]^d[26]^d[29]^d[30]^d[33]^d[34];
            p2 = d[3]^d[4]^d[5]^d[6]^d[11]^d[12]^d[13]^d[14]^d[19]^d[20]^d[21]^d[22]^d[27]^d[28]^d[29]^d[30];
            p3 = d[7]^d[8]^d[9]^d[10]^d[11]^d[12]^d[13]^d[14]^d[23]^d[24]^d[25]^d[26]^d[27]^d[28]^d[29]^d[30];
            p4 = d[15]^d[16]^d[17]^d[18]^d[19]^d[20]^d[21]^d[22]^d[23]^d[24]^d[25]^d[26]^d[27]^d[28]^d[29]^d[30];
            p5 = d[31]^d[32]^d[33]^d[34];
            po = ^{d, p5, p4, p3, p2, p1, p0};
            ham_enc = {d, p5, p4, p3, p2, p1, p0, po};
        end
    endfunction

    // ── Task: 마스터 브로드캐스트 프레임 주입 ─────────────────────────────────
    task inject_broadcast;
        input [7:0]  halt_cmd;
        input [9:0]  gticks;
        reg [41:0] cw;
        reg [49:0] frame;
        integer    i;
        begin
            cw    = ham_enc({halt_cmd, gticks, 17'b0});
            frame = {8'hAA, cw};
            @(negedge clk);
            for (i = 49; i >= 0; i = i - 1) begin
                tx_line = frame[i];
                repeat(P_DIV) @(negedge clk);
            end
            tx_line = 1'b0;
        end
    endtask

    // ── Task: 하드 리셋 ───────────────────────────────────────────────────────
    task do_reset;
        begin
            rst_n   = 1'b0;
            tx_line = 1'b0;
            repeat(10) @(posedge clk);
            rst_n = 1'b1;
            repeat(2) @(posedge clk);
        end
    endtask

    // ── Task: IRQ 전체 클리어 (내부 irq_clr 강제 인가, TB 전용) ─────────────────
    task clear_irq;
        begin
            @(posedge clk);
            force u_dut.u_slave.u_irq_ctrl.irq_status = 5'b0;
            @(posedge clk);
            release u_dut.u_slave.u_irq_ctrl.irq_status;
        end
    endtask

    // ── rx_line 프레임 디코더 ─────────────────────────────────────────────────
    // 슬레이브 송신 NRZ 프레임을 포착해 addr/tx_data를 출력한다.
    // 프레임: [preamble 8b=0xAA][codeword 42b]
    // codeword MSB부터: d[34:0] | p[5:0] | p_overall
    // d[34:32]=slave_addr, d[31:0]=tx_data
    wire       rx_val  = (rx_line === 1'bz) ? 1'b0 : rx_line;
    reg        rx_prev;
    reg [1:0]  rxd_st;   // 0=IDLE 1=PREAMBLE 2=DATA
    reg [9:0]  rxd_cnt;
    reg [5:0]  rxd_bit;
    reg [7:0]  rxd_pre;
    reg [41:0] rxd_cw;

    localparam RXD_IDLE = 2'd0, RXD_PRE = 2'd1, RXD_DATA = 2'd2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_prev <= 1'b0;
            rxd_st  <= RXD_IDLE;
            rxd_cnt <= 10'd0;
            rxd_bit <= 6'd0;
            rxd_pre <= 8'd0;
            rxd_cw  <= 42'd0;
        end else begin
            rx_prev <= rx_val;

            case (rxd_st)
                RXD_IDLE: begin
                    rxd_cnt <= 10'd0;
                    rxd_bit <= 6'd0;
                    if (!rx_prev && rx_val) begin  // 상승 에지 → 프리앰블 시작
                        rxd_st  <= RXD_PRE;
                        rxd_cnt <= 10'd1;
                    end
                end

                RXD_PRE: begin
                    rxd_cnt <= (rxd_cnt == P_DIV - 10'd1) ? 10'd0 : rxd_cnt + 10'd1;
                    if (rxd_cnt == (P_DIV >> 1)) begin  // 비트 중앙 샘플
                        rxd_pre <= {rxd_pre[6:0], rx_val};
                        rxd_bit <= rxd_bit + 6'd1;
                        if (rxd_bit == 6'd7) begin   // 8비트 수집 완료
                            rxd_st  <= RXD_DATA;
                            rxd_bit <= 6'd0;
                        end
                    end
                end

                RXD_DATA: begin
                    rxd_cnt <= (rxd_cnt == P_DIV - 10'd1) ? 10'd0 : rxd_cnt + 10'd1;
                    if (rxd_cnt == (P_DIV >> 1)) begin
                        rxd_cw  <= {rxd_cw[40:0], rx_val};
                        rxd_bit <= rxd_bit + 6'd1;
                        if (rxd_bit == 6'd41) begin  // 42비트 코드워드 수집 완료
                            rxd_st <= RXD_IDLE;
                            // rxd_pre: 프리앰블 8비트 (PRE 단계에서 완성)
                            // rxd_cw[40:38]: d[34:32] = slave_addr  (풀코드워드 기준 [41:39] = pre-shift [40:38])
                            // rxd_cw[37:6] : d[31:0]  = tx_data     (풀코드워드 기준 [38:7]  = pre-shift [37:6])
                            $display("[%0t ns] RX FRAME | preamble=%02h  addr=%0d  tx_data=0x%08h  %s",
                                $time,
                                rxd_pre,
                                rxd_cw[40:38],
                                rxd_cw[37:6],
                                (rxd_pre == 8'hAA) ? "PREAMBLE_OK" : "PREAMBLE_ERR");
                        end
                    end
                end
            endcase
        end
    end

    // ── IRQ 이벤트 모니터 (상승 에지에서만 1회 출력) ─────────────────────────
    wire irq_int = u_dut.u_slave.irq;
    reg  irq_prev;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) irq_prev <= 1'b0;
        else        irq_prev <= irq_int;
    end
    always @(posedge clk) begin
        if (irq_int && !irq_prev)
            $display("[%0t ns] IRQ | status=%05b (sent=%b nobc=%b hamerr=%b halt=%b stchg=%b) fsm=%0d",
                $time,
                irq_status,
                irq_status[0], irq_status[1], irq_status[2],
                irq_status[3], irq_status[4],
                fsm_state);
    end

    // ── 메인 시뮬레이션 ───────────────────────────────────────────────────────
    integer sent_cnt;
    integer sc_pass;

    initial begin
        sc_pass = 0;

        // ══════════════════════════════════════════════════════════════════════
        // 시나리오 1: 정상 브로드캐스트 3회 → data_sent(irq[0]) 3회 확인
        // ══════════════════════════════════════════════════════════════════════
        $display("\n=== Scenario 1: Normal broadcast x3 ===");
        do_reset;
        sent_cnt = 0;

        repeat(3) begin : sc1_loop
            inject_broadcast(8'h00, P_GUARD);
            // data_sent fires ~800 clk after active_edge
            // inject_broadcast consumed 400 clk; wait remaining ~500 clk max
            repeat(600) @(posedge clk);
            if (irq_status[0]) begin
                sent_cnt = sent_cnt + 1;
                $display("[%0t ns] SC1 data_sent #%0d  fsm=%0d  gen_cnt=0x%08h",
                    $time, sent_cnt, fsm_state, u_dut.u_gen.cnt);
            end else begin
                $display("[%0t ns] SC1 WARN: data_sent not seen after broadcast #%0d", $time, sent_cnt+1);
            end
            clear_irq;
            repeat(20) @(posedge clk);
        end

        if (sent_cnt == 3 && fsm_state == 3'd1)
            begin $display("SC1 PASS: sent=%0d fsm=NORMAL", sent_cnt); sc_pass = sc_pass + 1; end
        else
            $display("SC1 FAIL: sent=%0d fsm=%0d", sent_cnt, fsm_state);

        // ══════════════════════════════════════════════════════════════════════
        // 시나리오 2: 브로드캐스트 중단 → no_broadcast 워치독 → DEAD
        // wdog_cnt = 9 * slot_ticks = 9 * 400 = 3600 clk from active_edge
        // ══════════════════════════════════════════════════════════════════════
        $display("\n=== Scenario 2: No-broadcast watchdog ===");
        do_reset;

        // NORMAL 진입을 위해 브로드캐스트 1회
        inject_broadcast(8'h00, P_GUARD);
        repeat(600) @(posedge clk);
        clear_irq;

        // 이후 브로드캐스트 없음 → wdog 대기 (active_edge 기준 3600 clk)
        // 현재 시점은 active_edge로부터 약 1000 clk → 추가 3000 clk 대기
        repeat(3200) @(posedge clk);

        if (irq_status[1] && fsm_state == 3'd2)
            begin $display("SC2 PASS: no_broadcast IRQ set, fsm=DEAD"); sc_pass = sc_pass + 1; end
        else
            $display("SC2 FAIL: irq_status=%05b fsm=%0d", irq_status, fsm_state);

        // ══════════════════════════════════════════════════════════════════════
        // 시나리오 3: HALT 커맨드 → 즉시 DEAD
        // halt_cmd[SLAVE_ADDR=1] = 1 → halt_cmd 바이트 = 8'h02
        // ══════════════════════════════════════════════════════════════════════
        $display("\n=== Scenario 3: HALT command ===");
        do_reset;

        // NORMAL 진입
        inject_broadcast(8'h00, P_GUARD);
        repeat(600) @(posedge clk);
        clear_irq;
        repeat(20) @(posedge clk);

        // HALT 브로드캐스트 주입
        inject_broadcast(8'h02, P_GUARD);
        repeat(100) @(posedge clk);

        if (irq_status[3] && fsm_state == 3'd2)
            begin $display("SC3 PASS: halt_cmd IRQ set, fsm=DEAD  irq_status=%05b", irq_status); sc_pass = sc_pass + 1; end
        else
            $display("SC3 FAIL: irq_status=%05b fsm=%0d", irq_status, fsm_state);

        // ── 최종 결과 ────────────────────────────────────────────────────────
        $display("\n=== Result: %0d / 3 scenarios passed ===\n", sc_pass);
        #100;
        $finish;
    end

endmodule
