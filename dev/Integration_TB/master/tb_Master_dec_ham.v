`timescale 1ns / 1ps
// tb_Master_dec_ham: Master_dec_ham 슬롯별 수신 복호기 단위 테스트
// T1: 정상 codeword(addr=2, data=0xCAFEBABE) → slot_out2 갱신
// T2: 다른 addr(slot=5, data=0x12345678) → slot_out5
// T3: 1비트 오류 → hamming_err_cnt 증가, slot_out은 교정 후 갱신
// T4: 2비트 오류 → slot_out 갱신 없음
// T5: preamble_err → preamble_err_cnt 증가
// T6: GPIO_in 없이 slot_change → silent_cnt 증가
module tb_Master_dec_ham;

    reg  clk, resetn;
    always #5 clk = ~clk;

    // DUT 입력
    reg         in_sig;
    reg  [9:0]  guard_ticks;
    reg  [41:0] data_in;
    reg  [7:0]  silent_th;
    reg  [2:0]  slot;
    reg         preamble_err_in;
    reg         slot_change;
    reg         gpio_in_r;
    reg  [1:0]  rx_stat;
    reg  [7:0]  halt_cmd;

    // DUT 출력
    wire [31:0] sout0,sout1,sout2,sout3,sout4,sout5,sout6,sout7;
    wire [31:0] ecnt0,ecnt1,ecnt2,ecnt3,ecnt4,ecnt5,ecnt6,ecnt7;

    Master_dec_ham uut (
        .resetn(resetn), .clk(clk),
        .in_sig(in_sig), .GUARD_TICKS(guard_ticks),
        .data_in(data_in), .SILENT_TH(silent_th),
        .slot(slot), .preamble_err(preamble_err_in),
        .slot_change(slot_change), .GPIO_in(gpio_in_r),
        .rx_stat(rx_stat), .halt_cmd(halt_cmd),
        .slot_out0(sout0),.slot_out1(sout1),.slot_out2(sout2),.slot_out3(sout3),
        .slot_out4(sout4),.slot_out5(sout5),.slot_out6(sout6),.slot_out7(sout7),
        .err_cnt0(ecnt0),.err_cnt1(ecnt1),.err_cnt2(ecnt2),.err_cnt3(ecnt3),
        .err_cnt4(ecnt4),.err_cnt5(ecnt5),.err_cnt6(ecnt6),.err_cnt7(ecnt7)
    );

    // codeword 생성 및 오류 주입용
    reg  [34:0] enc_in;
    wire [41:0] enc_cw;
    hamming_enc u_enc (.data(enc_in), .codeword(enc_cw));

    integer pass_cnt, fail_cnt;

    // in_sig 1클럭 펄스
    task pulse_in_sig;
        begin
            @(posedge clk); #1; in_sig=1;
            @(posedge clk); #1; in_sig=0;
            repeat(3) @(posedge clk);
        end
    endtask

    // slot_change 1클럭 펄스 (slot=0으로)
    task pulse_slot_change_0;
        begin
            @(posedge clk); #1; slot=3'd0; slot_change=1;
            @(posedge clk); #1; slot_change=0;
            repeat(2) @(posedge clk);
        end
    endtask

    task do_reset;
        begin
            @(posedge clk); #1; resetn=0;
            in_sig=0; slot=0; slot_change=0; gpio_in_r=0;
            preamble_err_in=0; rx_stat=2'b00; halt_cmd=8'h00;
            guard_ticks=10'd0; silent_th=8'd200;
            repeat(4) @(posedge clk); #1; resetn=1;
            repeat(2) @(posedge clk);
        end
    endtask

    task check;
        input        cond;
        input [255:0] tag;
        begin
            if (cond) begin $display("[PASS] %0s", tag); pass_cnt=pass_cnt+1; end
            else       begin $display("[FAIL] %0s", tag); fail_cnt=fail_cnt+1; end
        end
    endtask

    initial begin
        clk=0; resetn=0;
        in_sig=0; slot=0; slot_change=0; gpio_in_r=0;
        preamble_err_in=0; rx_stat=2'b00; halt_cmd=8'h00;
        guard_ticks=10'd0; silent_th=8'd200; enc_in=0;
        pass_cnt=0; fail_cnt=0;
        do_reset;

        // ── T1: slot=2, data=0xCAFEBABE 정상 수신 ────────────────────────────
        $display("\n--- T1: 정상 수신 slot=2, data=0xCAFEBABE ---");
        enc_in = {3'd2, 32'hCAFEBABE}; #1;
        data_in = enc_cw; slot = 3'd2; rx_stat = 2'b00; gpio_in_r=1;
        pulse_in_sig;
        check(sout2 === 32'hCAFEBABE, "T1a: slot_out2=0xCAFEBABE");
        check(ecnt2[15:8] === 8'd0,   "T1b: hamming_err_cnt2=0");

        // ── T2: slot=5, data=0x12345678 ──────────────────────────────────────
        $display("\n--- T2: 정상 수신 slot=5, data=0x12345678 ---");
        enc_in = {3'd5, 32'h12345678}; #1;
        data_in = enc_cw; slot = 3'd5; rx_stat = 2'b00; gpio_in_r=1;
        pulse_in_sig;
        check(sout5 === 32'h12345678, "T2a: slot_out5=0x12345678");

        // ── T3: 1비트 오류 → hamming_err_cnt += 4, slot_out 교정 ─────────────
        // codeword[41:7]=data, [6:1]=parity, [0]=overall
        // 데이터 비트 codeword[10] 플립 → ham_1bit_err=1, ham_2bit_err=0
        // hamming_dec이 교정 → fixed_data = 원래 {3'd2, 32'hDEADBEEF}
        $display("\n--- T3: 1비트 오류 (codeword[10] 플립) ---");
        enc_in = {3'd2, 32'hDEADBEEF}; #1;
        data_in = enc_cw ^ (42'h1 << 10); // 데이터 비트 플립 → 1비트 오류
        slot = 3'd2; rx_stat = 2'b00; gpio_in_r=1;
        begin : t3
            integer cnt_before;
            cnt_before = ecnt2[15:8];
            pulse_in_sig;
            check(sout2 === 32'hDEADBEEF,   "T3a: slot_out2 교정 후 갱신");
            check(ecnt2[15:8] > cnt_before,  "T3b: hamming_err_cnt2 증가");
        end

        // ── T4: 2비트 오류 → slot_out 갱신 없음, err_cnt 증가 ────────────────
        $display("\n--- T4: 2비트 오류 (rx_stat=10) ---");
        enc_in = {3'd2, 32'hAABBCCDD}; #1;
        data_in = enc_cw ^ 42'h3; // 2비트 플립 (ham_2bit_err 유발)
        slot = 3'd2; rx_stat = 2'b10; gpio_in_r=1;
        begin : t4
            reg [31:0] sout2_before;
            integer    ecnt_before;
            sout2_before = sout2;
            ecnt_before  = ecnt2[15:8];
            pulse_in_sig;
            check(sout2 === sout2_before,   "T4a: slot_out2 갱신 없음 (2비트 오류)");
            check(ecnt2[15:8] > ecnt_before,"T4b: hamming_err_cnt2 증가");
        end

        // ── T5: preamble_err → preamble_err_cnt 증가 ─────────────────────────
        $display("\n--- T5: preamble_err ---");
        slot = 3'd3;
        begin : t5
            integer pcnt_before;
            pcnt_before = ecnt3[31:24];
            @(posedge clk); #1; preamble_err_in=1;
            @(posedge clk); #1; preamble_err_in=0;
            repeat(2) @(posedge clk); #1;
            check(ecnt3[31:24] > pcnt_before, "T5: preamble_err_cnt3 증가");
        end

        // ── T6: GPIO_in 없이 slot_change → silent_cnt 증가 ───────────────────
        $display("\n--- T6: silent 감지 (GPIO_in=0 + slot_change) ---");
        do_reset;
        gpio_in_r=0; slot=3'd1;
        begin : t6
            integer sc_before;
            sc_before = ecnt1[7:0];
            // slot_change @ slot=0 → 모든 슬롯의 silent 카운터 업데이트
            @(posedge clk); #1; slot=3'd0; slot_change=1; gpio_in_r=0;
            @(posedge clk); #1; slot_change=0;
            repeat(3) @(posedge clk); #1;
            check(ecnt1[7:0] > sc_before, "T6: silent_cnt1 증가");
        end

        $display("\n========================================");
        $display("[DONE] Master_dec_ham: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        $display("========================================");
        $finish;
    end

endmodule
