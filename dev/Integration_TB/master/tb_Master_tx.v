`timescale 1ns / 1ps
// tb_Master_tx: Master_tx NRZ 송신기 단위 테스트
// T1: tx_trigger → 50비트 프레임 출력 (400클럭 완료)
// T2: preamble = 0xAA 확인
// T3: halt_cmd / GUARD_TICKS codeword 인코딩 검증 (hamming_dec 역추출)
// T4: 전송 중 tx_trigger 재인가 → 무시 확인
module tb_Master_tx;

    reg  clk, resetn;
    always #5 clk = ~clk;

    localparam [9:0] DIV = 10'd8;

    reg        tx_trigger;
    reg  [7:0] halt_in;
    reg  [9:0] guard_in;
    wire       gpio_out;

    Master_tx uut (
        .clk(clk), .resetn(resetn),
        .tx_trigger(tx_trigger),
        .halt_cmd(halt_in), .GUARD_TICKS(guard_in),
        .DIV(DIV),
        .GPIO_out(gpio_out)
    );

    // 기대 codeword 계산용 hamming_enc
    reg  [34:0] enc_in;
    wire [41:0] exp_cw;
    hamming_enc u_enc (.data(enc_in), .codeword(exp_cw));

    // 수신 데이터 복호용 hamming_dec
    reg  [41:0] rx_cw;
    wire [34:0] rx_data;
    wire        rx_1bit, rx_2bit;
    hamming_dec u_dec (.codeword(rx_cw), .data(rx_data), .ham_1bit_err(rx_1bit), .ham_2bit_err(rx_2bit));

    integer pass_cnt, fail_cnt;
    reg [49:0] captured;

    // GPIO_out 비트스트림 캡처: trigger 인가 후 DIV/2 오프셋에서 시작, DIV 간격으로 50비트 샘플
    task capture_frame;
        integer i;
        begin
            @(posedge clk); #1; tx_trigger = 1;
            @(posedge clk); #1; tx_trigger = 0;
            // 비트 0 중간점 (=DIV/2 클럭 후)
            repeat(DIV/2) @(posedge clk); #1;
            for (i = 0; i < 50; i = i+1) begin
                captured[49-i] = gpio_out;
                if (i < 49) repeat(DIV) @(posedge clk); #1;
            end
            repeat(DIV*2) @(posedge clk); // 여유
        end
    endtask

    task do_reset;
        begin
            @(posedge clk); #1; resetn = 0;
            repeat(4) @(posedge clk); #1; resetn = 1;
            repeat(2) @(posedge clk);
        end
    endtask

    task check;
        input        cond;
        input [63:0] tag;
        begin
            if (cond) begin $display("[PASS] %0s", tag); pass_cnt = pass_cnt+1; end
            else       begin $display("[FAIL] %0s", tag); fail_cnt = fail_cnt+1; end
        end
    endtask

    initial begin
        clk=0; resetn=0; tx_trigger=0; halt_in=0; guard_in=0;
        pass_cnt=0; fail_cnt=0;
        enc_in=0; rx_cw=0;
        do_reset;

        // ── T1: 프레임 전송 타이밍 (400클럭 완료) ──────────────────────────
        $display("\n--- T1: 프레임 전송 타이밍 (DIV=8, 50비트×8클럭=400클럭) ---");
        begin : t1
            integer start_time, end_time;
            @(posedge clk); #1; tx_trigger = 1;
            @(posedge clk); #1; tx_trigger = 0;
            start_time = $time;
            // gpio_out이 1이 되는 것 확인 (첫 비트 = preamble MSB = 1)
            check(gpio_out === 1'b1, "T1a: tx 직후 GPIO_out=1 (preamble MSB)");
            // 400클럭 내 완료 대기
            repeat(DIV*50 + DIV) @(posedge clk); #1;
            check(gpio_out === 1'b0, "T1b: 410클럭 후 GPIO_out=0 (전송 완료)");
        end

        // ── T2: preamble = 0xAA 확인 ────────────────────────────────────────
        $display("\n--- T2: preamble=0xAA, halt=0x00, guard=0 ---");
        halt_in = 8'h00; guard_in = 10'd0;
        do_reset;
        capture_frame;
        check(captured[49:42] === 8'hAA, "T2a: preamble=0xAA");

        // T2b: codeword 검증 (hamming_dec 역추출)
        enc_in = {halt_in, guard_in, 17'b0};
        #1; // combinational settle
        check(captured[41:0] === exp_cw, "T2b: codeword = hamming_enc({halt,guard,0})");
        rx_cw = captured[41:0]; #1;
        check(rx_data[34:27] === 8'h00, "T2c: decoded halt_cmd=0x00");
        check(rx_data[26:17] === 10'd0, "T2d: decoded guard_ticks=0");
        check(rx_1bit === 1'b0 && rx_2bit === 1'b0, "T2e: no hamming error");

        // ── T3: non-zero halt_cmd / GUARD_TICKS ──────────────────────────────
        $display("\n--- T3: halt=0xA5, guard=10'd256 ---");
        halt_in = 8'hA5; guard_in = 10'd256;
        do_reset;
        capture_frame;
        check(captured[49:42] === 8'hAA, "T3a: preamble=0xAA");
        enc_in = {halt_in, guard_in, 17'b0}; #1;
        check(captured[41:0] === exp_cw, "T3b: codeword correct");
        rx_cw = captured[41:0]; #1;
        check(rx_data[34:27] === 8'hA5, "T3c: decoded halt_cmd=0xA5");
        check(rx_data[26:17] === 10'd256, "T3d: decoded guard_ticks=256");

        // ── T4: 전송 중 tx_trigger 재인가 → 무시 ────────────────────────────
        $display("\n--- T4: 전송 중 tx_trigger 재인가 무시 ---");
        halt_in = 8'h00; guard_in = 10'd0;
        do_reset;
        // 첫 전송 시작
        @(posedge clk); #1; tx_trigger = 1;
        @(posedge clk); #1; tx_trigger = 0;
        // 전송 중간 (200클럭)에 재인가
        repeat(DIV*25) @(posedge clk);
        @(posedge clk); #1; tx_trigger = 1;
        @(posedge clk); #1; tx_trigger = 0;
        // 원래 프레임대로 400+여유 후 완료 확인
        repeat(DIV*25 + DIV*5) @(posedge clk); #1;
        check(gpio_out === 1'b0, "T4a: 재인가 무시 후 정상 종료 (GPIO_out=0)");
        // 단발 추가 전송이 없는지 확인 (trigger 인가 없으면 GPIO_out=0 유지)
        repeat(DIV*10) @(posedge clk); #1;
        check(gpio_out === 1'b0, "T4b: 추가 전송 없음");

        $display("\n========================================");
        $display("[DONE] Master_tx: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        $display("========================================");
        $finish;
    end

endmodule
