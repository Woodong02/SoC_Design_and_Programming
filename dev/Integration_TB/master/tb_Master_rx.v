`timescale 1ns / 1ps
// tb_Master_rx: Master_rx NRZ 수신기 단위 테스트
// T1: 유효 프레임 수신 → out_sig=1, data_out=codeword
// T2: preamble 불일치 → preamble_err=1
// T3: slot_pre_change 수신 중 리셋
// T4: non-zero halt/guard 검증
module tb_Master_rx;

    reg  clk, resetn;
    always #5 clk = ~clk;

    localparam [9:0] DIV = 10'd8;

    reg  gpio_in, slot_pre_chg;
    wire [41:0] data_out;
    wire        out_sig, preamble_err;

    Master_rx uut (
        .clk(clk), .DIV(DIV),
        .GPIO_in(gpio_in), .resetn(resetn),
        .slot_pre_change(slot_pre_chg),
        .data_out(data_out), .out_sig(out_sig),
        .preamble_err(preamble_err)
    );

    // codeword 생성용
    reg  [34:0] enc_in;
    wire [41:0] enc_cw;
    hamming_enc u_enc (.data(enc_in), .codeword(enc_cw));

    integer pass_cnt, fail_cnt;
    reg out_seen, perr_seen;

    always @(posedge clk) begin
        if (out_sig)      out_seen  <= 1;
        if (preamble_err) perr_seen <= 1;
    end

    task drive_bit;
        input bval;
        begin gpio_in = bval; repeat(DIV) @(posedge clk); end
    endtask

    task send_frame;
        input [7:0]  preamble;
        input [41:0] codeword;
        integer i;
        begin
            for (i = 7; i >= 0; i = i-1) drive_bit(preamble[i]);
            for (i = 41; i >= 0; i = i-1) drive_bit(codeword[i]);
            gpio_in = 0;
            repeat(DIV*3) @(posedge clk);
        end
    endtask

    task do_reset;
        begin
            @(posedge clk); #1; resetn=0; gpio_in=0; slot_pre_chg=0;
            repeat(4) @(posedge clk); #1; resetn=1;
            repeat(2) @(posedge clk);
            out_seen=0; perr_seen=0;
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
        clk=0; resetn=0; gpio_in=0; slot_pre_chg=0;
        pass_cnt=0; fail_cnt=0; out_seen=0; perr_seen=0; enc_in=0;
        do_reset;

        // ── T1: 유효 프레임 (halt=0x00, guard=0) ─────────────────────────────
        $display("\n--- T1: 유효 프레임 halt=0x00 guard=0 ---");
        enc_in = {8'h00, 10'd0, 17'b0}; #1;
        send_frame(8'hAA, enc_cw);
        repeat(DIV*2) @(posedge clk); #1;
        check(out_seen  === 1'b1, "T1a: out_sig 수신됨");
        check(perr_seen === 1'b0, "T1b: preamble_err 없음");
        check(data_out  === enc_cw,"T1c: data_out=codeword");

        // ── T2: preamble 불일치 ───────────────────────────────────────────────
        // 0xFF = 11111111: bit7=1에서 감지 시작 → buffer={1,1,1,1,1,1,1,X}
        // enc_in=0이면 codeword[41]=0 → buffer=0xFE ≠ 0xAA. 이후 all-zero codeword로
        // 추가 '1' 없어 out_sig도 발생하지 않음.
        $display("\n--- T2: preamble=0xFF (불일치) ---");
        do_reset;
        enc_in = 35'b0; #1;  // codeword all-zero 보장
        send_frame(8'hFF, enc_cw);
        repeat(DIV*2) @(posedge clk); #1;
        check(out_seen  === 1'b0, "T2a: out_sig 없음");
        check(perr_seen === 1'b1, "T2b: preamble_err=1");

        // ── T3: 수신 중 slot_pre_change 리셋 ─────────────────────────────────
        // slot_pre_change 후 gpio_in=0 유지 → 추가 수신 없음 확인
        $display("\n--- T3: 수신 중 slot_pre_change 리셋 ---");
        do_reset;
        // 프리앰블 4비트 (1010) 보낸 뒤 slot_pre_change
        drive_bit(1); drive_bit(0); drive_bit(1); drive_bit(0);
        @(posedge clk); #1; slot_pre_chg=1;
        @(posedge clk); #1; slot_pre_chg=0;
        // gpio_in=0 유지 (수신기가 IDLE로 리셋된 상태 그대로)
        gpio_in=0; repeat(DIV*60) @(posedge clk); #1;
        check(out_seen === 1'b0, "T3: slot_pre_change 리셋 후 out_sig 없음");

        // ── T4: non-zero halt/guard ──────────────────────────────────────────
        $display("\n--- T4: halt=0xAB guard=100 ---");
        do_reset;
        enc_in = {8'hAB, 10'd100, 17'b0}; #1;
        send_frame(8'hAA, enc_cw);
        repeat(DIV*2) @(posedge clk); #1;
        check(out_seen === 1'b1, "T4a: out_sig 수신됨");
        check(data_out === enc_cw,"T4b: data_out correct");

        $display("\n========================================");
        $display("[DONE] Master_rx: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        $display("========================================");
        $finish;
    end

endmodule
