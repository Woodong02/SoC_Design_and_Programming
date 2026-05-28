// =============================================================================
//  tb_master_top.v  -  Testbench for master_top
//
//  시뮬레이터: iverilog / ModelSim / VCS (Verilog-2001 호환)
//  실행 예시 (iverilog):
//    iverilog -o sim tb_master_top.v master_top.v Clock_and_slot_Master.v \
//             FSM_data_rx_Master_new.v error_with_hamming.v \
//             hamming_dec.v hamming_enc.v master_tx.v
//    vvp sim
//
//  NOTE: Master_top에 아직 남아있는 버그 목록 (테스트 실패 원인이 됩니다)
//  [BUG-1]  wire last_slot / slot / clk_cnt / data_bus 가 모두 1-bit 선언
//           → [2:0], [2:0], [10:0], [41:0] 이어야 함
//  [BUG-2]  Master_slot 인스턴스에 .slot() 포트 연결 누락
//           → slot 와이어가 항상 0으로 떠 있음
//  [BUG-3]  tx_trigger = (slot_change && slot==last_slot) → 항상 0
//           → GPIO_out 는 항상 Z (Master 브로드캐스트 안 됨)
//  [BUG-4]  halt_cmd[0..7] 전부 err_cnt0 기준
//           → halt_cmd[k] 는 err_cnt_k 를 봐야 함
//  [BUG-5]  hamming_dec: syndrome=1,2,4,8,16,32 일 때 데이터 비트 잘못 반전
// =============================================================================

`timescale 1ns / 1ps

module tb_master_top;

// -----------------------------------------------------------------------------
//  파라미터
// -----------------------------------------------------------------------------
localparam CLK_HALF   = 5;           // 5 ns → 100 MHz
localparam DIV_VAL    = 10;          // 비트 주기 = DIV_VAL 클럭 (RX 기준)
localparam GUARD_VAL  = 20;
localparam NCNT_VAL   = 3;           // 4 노드: 슬롯 0..3
// 슬롯 주기 = (50 + GUARD_VAL) * DIV_VAL 클럭
localparam SLOT_CLKS  = (50 + GUARD_VAL) * DIV_VAL;  // = 700

// -----------------------------------------------------------------------------
//  DUT I/O
// -----------------------------------------------------------------------------
reg        clk, resetn;
reg  [9:0] DIV, GUARD_TICKS;
reg  [2:0] NODE_CNT;
reg        GPIO_in;

wire        GPIO_out;
wire [31:0] slot_out0, slot_out1, slot_out2, slot_out3,
             slot_out4, slot_out5, slot_out6, slot_out7;
wire [31:0] err_cnt0, err_cnt1, err_cnt2, err_cnt3,
             err_cnt4, err_cnt5, err_cnt6, err_cnt7;

// -----------------------------------------------------------------------------
//  DUT 인스턴스
// -----------------------------------------------------------------------------
master_top dut (
    .clk        (clk),
    .resetn     (resetn),
    .DIV        (DIV),
    .GUARD_TICKS(GUARD_TICKS),
    .NODE_CNT   (NODE_CNT),
    .GPIO_in    (GPIO_in),
    .GPIO_out   (GPIO_out),
    .slot_out0(slot_out0), .slot_out1(slot_out1),
    .slot_out2(slot_out2), .slot_out3(slot_out3),
    .slot_out4(slot_out4), .slot_out5(slot_out5),
    .slot_out6(slot_out6), .slot_out7(slot_out7),
    .err_cnt0 (err_cnt0),  .err_cnt1 (err_cnt1),
    .err_cnt2 (err_cnt2),  .err_cnt3 (err_cnt3),
    .err_cnt4 (err_cnt4),  .err_cnt5 (err_cnt5),
    .err_cnt6 (err_cnt6),  .err_cnt7 (err_cnt7)
);

// -----------------------------------------------------------------------------
//  클럭
// -----------------------------------------------------------------------------
initial clk = 1'b0;
always #CLK_HALF clk = ~clk;

// -----------------------------------------------------------------------------
//  Hamming [42,35] SECDED 인코더 (hamming_enc 와 동일한 수식)
//  data[34:32] = 노드 주소,  data[31:0] = 페이로드
// -----------------------------------------------------------------------------
function [41:0] ham_enc;
    input [34:0] d;
    reg p0,p1,p2,p3,p4,p5,po;
    begin
        p0 = d[0] ^d[2] ^d[4] ^d[6] ^d[8] ^d[10]^d[12]^d[14]
            ^d[16]^d[18]^d[20]^d[22]^d[24]^d[26]^d[28]^d[30]^d[32]^d[34];
        p1 = d[1] ^d[2] ^d[5] ^d[6] ^d[9] ^d[10]^d[13]^d[14]
            ^d[17]^d[18]^d[21]^d[22]^d[25]^d[26]^d[29]^d[30]^d[33]^d[34];
        p2 = d[3] ^d[4] ^d[5] ^d[6] ^d[11]^d[12]^d[13]^d[14]
            ^d[19]^d[20]^d[21]^d[22]^d[27]^d[28]^d[29]^d[30];
        p3 = d[7] ^d[8] ^d[9] ^d[10]^d[11]^d[12]^d[13]^d[14]
            ^d[23]^d[24]^d[25]^d[26]^d[27]^d[28]^d[29]^d[30];
        p4 = d[15]^d[16]^d[17]^d[18]^d[19]^d[20]^d[21]^d[22]
            ^d[23]^d[24]^d[25]^d[26]^d[27]^d[28]^d[29]^d[30];
        p5 = d[31]^d[32]^d[33]^d[34];
        po = ^{d, p5, p4, p3, p2, p1, p0};
        ham_enc = {d, p5, p4, p3, p2, p1, p0, po};
    end
endfunction

// -----------------------------------------------------------------------------
//  태스크: 50-bit 프레임을 GPIO_in 으로 전송 (MSB 먼저, 1비트 = DIV_VAL 클럭)
// -----------------------------------------------------------------------------
task send_raw;
    input [49:0] frame;
    integer i;
    begin
        for (i = 49; i >= 0; i = i - 1) begin
            GPIO_in = frame[i];
            repeat(DIV_VAL) @(posedge clk);
        end
        GPIO_in = 1'b0;  // 아이들
    end
endtask

// 에러 없는 정상 프레임
task send_ok;
    input [34:0] data;
    begin send_raw({8'hAA, ham_enc(data)}); end
endtask

// 1비트 에러 (codeword 내 flip_pos 비트 반전)
task send_1bit_err;
    input [34:0] data;
    input [5:0]  flip_pos;
    reg [41:0] cw;
    begin
        cw = ham_enc(data);
        cw[flip_pos] = ~cw[flip_pos];
        send_raw({8'hAA, cw});
    end
endtask

// 2비트 에러 (두 위치 동시 반전)
task send_2bit_err;
    input [34:0] data;
    input [5:0]  pa, pb;
    reg [41:0] cw;
    begin
        cw = ham_enc(data);
        cw[pa] = ~cw[pa];
        cw[pb] = ~cw[pb];
        send_raw({8'hAA, cw});
    end
endtask

// 잘못된 프리앰블
task send_bad_preamble;
    input [34:0] data;
    begin send_raw({8'h55, ham_enc(data)}); end  // 0x55 ≠ 0xAA
endtask

// -----------------------------------------------------------------------------
//  체크 헬퍼
// -----------------------------------------------------------------------------
integer pass_cnt, fail_cnt;

task chk;
    input [31:0] got, exp;
    input [24*8:1] name;     // 최대 24자 문자열
    begin
        if (got === exp) begin
            $display("  [PASS] %-24s = 0x%08h", name, got);
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  [FAIL] %-24s : got=0x%08h  exp=0x%08h", name, got, exp);
            fail_cnt = fail_cnt + 1;
        end
    end
endtask

task chk_x;  // X 또는 Z 체크 (버그 감지용)
    input [31:0] val;
    input [24*8:1] name;
    begin
        if (^val === 1'bx)
            $display("  [BUG]  %-24s contains X/Z = 0x%08h", name, val);
        else
            $display("  [OK]   %-24s = 0x%08h (no X)", name, val);
    end
endtask

// -----------------------------------------------------------------------------
//  메인 테스트
// -----------------------------------------------------------------------------
initial begin
    $dumpfile("tb_master_top.vcd");
    $dumpvars(0, tb_master_top);

    pass_cnt = 0;
    fail_cnt = 0;

    // 초기화
    GPIO_in     = 1'b0;
    DIV         = DIV_VAL;
    GUARD_TICKS = GUARD_VAL;
    NODE_CNT    = NCNT_VAL;
    resetn      = 1'b0;

    repeat(10) @(posedge clk);
    resetn = 1'b1;
    $display("[%0t ns] Reset released", $time);
    repeat(30) @(posedge clk);

    // =========================================================================
    //  TEST 1: 리셋 직후 초기값 확인
    // =========================================================================
    $display("\n=== TEST 1: 리셋 직후 초기값 ===");
    chk(slot_out0, 32'h0, "slot_out0 @ reset");
    chk(slot_out1, 32'h0, "slot_out1 @ reset");
    chk(err_cnt0,  32'h0, "err_cnt0  @ reset");

    // =========================================================================
    //  TEST 2: 정상 수신 - 노드별 개별 프레임
    //  [BUG-1,2] data_bus=1bit, slot=0 → 데이터가 제대로 전달되지 않을 수 있음
    // =========================================================================
    $display("\n=== TEST 2: 정상 수신 (노드 0~3 각 1프레임) ===");
    send_ok({3'd0, 32'hDEAD_0000});
    send_ok({3'd1, 32'h1111_1111});
    send_ok({3'd2, 32'h2222_2222});
    send_ok({3'd3, 32'h3333_3333});
    repeat(2 * SLOT_CLKS) @(posedge clk);

    chk(slot_out0, 32'hDEAD_0000, "slot_out0");
    chk(slot_out1, 32'h1111_1111, "slot_out1");
    chk(slot_out2, 32'h2222_2222, "slot_out2");
    chk(slot_out3, 32'h3333_3333, "slot_out3");

    // X/Z 점검 (BUG-1: 1-bit 와이어 때문에 내부적으로 X 발생 가능)
    chk_x(slot_out0, "slot_out0 X check");
    chk_x(slot_out1, "slot_out1 X check");

    // =========================================================================
    //  TEST 3: 1비트 에러 - 데이터 비트 위치 (Hamming 교정 성공해야 함)
    //  codeword[10] = data bit index 9 → 데이터 위치이므로 교정 가능
    // =========================================================================
    $display("\n=== TEST 3: 1비트 에러 교정 (데이터 비트) ===");
    send_1bit_err({3'd0, 32'hAAAA_BBBB}, 6'd10);  // codeword[10]: 데이터 위치
    repeat(2 * SLOT_CLKS) @(posedge clk);
    // Hamming 교정 성공 시 slot_out0 = 0xAAAA_BBBB
    chk(slot_out0, 32'hAAAA_BBBB, "slot_out0 (1-bit corrected)");

    // =========================================================================
    //  TEST 4: 1비트 에러 - 패리티 비트 위치 (hamming_dec 버그 노출)
    //  codeword[1] = p_rx[0] → syndrome=1 → BUG: data[0] 를 잘못 반전
    // =========================================================================
    $display("\n=== TEST 4: 1비트 에러 (패리티 비트 위치, BUG-5 노출) ===");
    // 노드2로 0xCAFE_0001 전송. codeword[1](=p_rx[0])에 에러 주입
    send_1bit_err({3'd2, 32'hCAFE_0001}, 6'd1);
    repeat(2 * SLOT_CLKS) @(posedge clk);
    $display("  [참고] BUG-5: syndrome=1 → hamming_dec 가 data[0] 를 반전시킴");
    $display("  slot_out2 = 0x%08h  (정상: 0xCAFE_0001, 버그시: data[0] 반전)",
             slot_out2);
    // 버그가 있으면 0xCAFE_0000, 없으면 0xCAFE_0001
    if (slot_out2 === 32'hCAFE_0001)
        $display("  [PASS] 패리티 에러 교정 올바름");
    else if (slot_out2 === 32'hCAFE_0000)
        $display("  [FAIL/BUG-5] data[0] 잘못 반전됨 → hamming_dec 수정 필요");
    else
        $display("  [UNKNOWN] slot_out2=0x%08h", slot_out2);

    // =========================================================================
    //  TEST 5: 2비트 에러 - slot_out 갱신 안 돼야 함 (ham_2bit_err=1)
    // =========================================================================
    $display("\n=== TEST 5: 2비트 에러 → slot_out 불변 ===");
    // 노드1에 0xDEAD_BEEF 전송, 두 비트 반전
    send_2bit_err({3'd1, 32'hDEAD_BEEF}, 6'd5, 6'd15);
    repeat(2 * SLOT_CLKS) @(posedge clk);
    // slot_out1 은 TEST2에서 받은 0x1111_1111 유지해야 함
    chk(slot_out1, 32'h1111_1111, "slot_out1 (2-bit: no update)");
    // err_cnt1[15:8] (hamming_err_cnt1) 가 증가했어야 함
    $display("  err_cnt1 = 0x%08h  [7:0]=silent [15:8]=hamming [23:16]=timeout [31:24]=preamble",
             err_cnt1);

    // =========================================================================
    //  TEST 6: 잘못된 프리앰블 - 프레임 버려져야 함
    // =========================================================================
    $display("\n=== TEST 6: 잘못된 프리앰블 (0x55) → 수신 거부 ===");
    send_bad_preamble({3'd0, 32'hBAD_FEED});
    repeat(2 * SLOT_CLKS) @(posedge clk);
    // slot_out0 = 마지막으로 받은 TEST3 값 유지 (0xAAAA_BBBB)
    chk(slot_out0, 32'hAAAA_BBBB, "slot_out0 (bad preamble: no update)");

    // =========================================================================
    //  TEST 7: GPIO_out 관찰 - tx_trigger 버그 노출
    //  [BUG-2,3] slot 미연결 + tx_trigger 조건 오류 → 항상 Z
    // =========================================================================
    $display("\n=== TEST 7: GPIO_out (Master TX 브로드캐스트) ===");
    repeat(4 * SLOT_CLKS) @(posedge clk);
    if (GPIO_out === 1'bz)
        $display("  [BUG-2,3 확인] GPIO_out = Z → tx_trigger 가 한 번도 안 됨");
    else
        $display("  [PASS] GPIO_out 활동 감지: %b", GPIO_out);

    // =========================================================================
    //  TEST 8: 동일 노드 연속 2프레임 - slot_out 최신값으로 갱신
    // =========================================================================
    $display("\n=== TEST 8: 동일 노드 연속 갱신 ===");
    send_ok({3'd0, 32'hFFFF_0000});
    repeat(SLOT_CLKS / 2) @(posedge clk);
    send_ok({3'd0, 32'h0000_FFFF});   // 두 번째 값이 최종
    repeat(2 * SLOT_CLKS) @(posedge clk);
    chk(slot_out0, 32'h0000_FFFF, "slot_out0 (latest frame wins)");

    // =========================================================================
    //  TEST 9: 비동기 리셋 - 수신 도중 리셋
    // =========================================================================
    $display("\n=== TEST 9: 수신 도중 비동기 리셋 ===");
    fork
        send_ok({3'd0, 32'hF0F0_F0F0});
        begin
            repeat(25) @(posedge clk);   // 프리앰블 수신 중간
            resetn = 1'b0;
            repeat(4) @(posedge clk);
            resetn = 1'b1;
            $display("  [%0t ns] 리셋 인가/해제", $time);
        end
    join
    repeat(2 * SLOT_CLKS) @(posedge clk);
    // 리셋으로 FSM 초기화 → 0xF0F0_F0F0 는 수신되지 않아야 함
    if (slot_out0 !== 32'hF0F0_F0F0)
        $display("  [PASS] 리셋 중 프레임 무시 (slot_out0=0x%08h)", slot_out0);
    else
        $display("  [FAIL] 리셋 중에도 프레임이 수신됨");

    // =========================================================================
    //  TEST 10: 리셋 후 복구
    // =========================================================================
    $display("\n=== TEST 10: 리셋 후 정상 복구 ===");
    repeat(30) @(posedge clk);
    send_ok({3'd0, 32'hC0DE_C0DE});
    send_ok({3'd1, 32'hBEEF_CAFE});
    repeat(2 * SLOT_CLKS) @(posedge clk);
    chk(slot_out0, 32'hC0DE_C0DE, "slot_out0 post-reset");
    chk(slot_out1, 32'hBEEF_CAFE, "slot_out1 post-reset");

    // =========================================================================
    //  TEST 11: slot 0 ~ 3 모두 silent_cnt 누적 확인
    //           (한 프레임 주기 동안 아무것도 안 보냄 → silent 증가)
    // =========================================================================
    $display("\n=== TEST 11: 무송신 → silent_cnt 누적 ===");
    // 4슬롯 이상 아무것도 보내지 않음
    repeat(5 * SLOT_CLKS) @(posedge clk);
    $display("  err_cnt0 = 0x%08h  [7:0]=silent_cnt0 (expect >0)", err_cnt0);
    $display("  err_cnt1 = 0x%08h  [7:0]=silent_cnt1 (expect >0)", err_cnt1);
    if (err_cnt0[7:0] > 0)
        $display("  [PASS] silent_cnt0 = %0d", err_cnt0[7:0]);
    else
        $display("  [INFO] silent_cnt0 = 0 (BUG-2: slot 미연결로 카운터 못 올라갈 수 있음)");

    // =========================================================================
    //  최종 집계
    // =========================================================================
    $display("\n========================================");
    $display("  PASS: %0d   FAIL: %0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0)
        $display("  모든 체크 통과");
    else
        $display("  %0d개 체크 실패 - 위 BUG 목록 참고", fail_cnt);
    $display("========================================");

    $finish;
end

// -----------------------------------------------------------------------------
//  타임아웃
// -----------------------------------------------------------------------------
initial begin
    #(10_000_000);   // 10 ms
    $display("[TIMEOUT] 시뮬레이션이 제한시간을 초과했습니다");
    $finish;
end

// -----------------------------------------------------------------------------
//  모니터: slot_out / GPIO_out 변화 추적
// -----------------------------------------------------------------------------
always @(slot_out0) $display("[%8t ns] slot_out0 → 0x%08h", $time, slot_out0);
always @(slot_out1) $display("[%8t ns] slot_out1 → 0x%08h", $time, slot_out1);
always @(slot_out2) $display("[%8t ns] slot_out2 → 0x%08h", $time, slot_out2);
always @(slot_out3) $display("[%8t ns] slot_out3 → 0x%08h", $time, slot_out3);

always @(GPIO_out) begin
    if (GPIO_out !== 1'bz)
        $display("[%8t ns] GPIO_out  → %b  (Master TX 활성)", $time, GPIO_out);
end

endmodule