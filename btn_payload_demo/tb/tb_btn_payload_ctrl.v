`timescale 1ns / 1ps

// ---------------------------------------------------------------------------
// tb_btn_payload_ctrl  —  full-case testbench
// ---------------------------------------------------------------------------
// 빠른 시뮬레이션: CLK_FREQ=10kHz, SAMPLE_MS=1 → SAMP_CNT=10 clk/tick
//
// wait_tick 설계 원칙
//   @(posedge DUT.sample_tick) : NBA에서 sample_tick 상승 (cnt=9 클럭 후)
//   @(posedge i_CLK)           : cnt=0, DUT가 btn_q/payload 갱신 (NBA 처리)
//   @(posedge i_CLK)           : cnt=1, payload 새 값 확정
//   #1                         : 클럭 엣지 사이(1ns)로 복귀 → 이후 BTN 드라이브 안전
//
// TC01 : 리셋 후 payload 전체 0
// TC02 : 정상 누름 (HIGH→LOW) → 슬롯별 1회 증가
// TC03 : 누른 채 유지 2회 → 추가 증가 없음
// TC04 : 해제 (LOW→HIGH) → 증가 없음
// TC05 : 두 번째 누름
// TC06 : 세 번째 누름 (해제 안정화 후 재누름)
// TC07 : 바운스 시뮬 — 기간 내 4회 토글, 틱 시점 LOW → 1회만 증가
// TC08 : 바운스 시뮬 — 틱 시점 HIGH로 끝남 → 미검출
// TC09 : 리셋 중 버튼 누름 → 리셋 해제 후 payload = 0
// TC10 : 리셋 해제 후 정상 누름 복원
// ---------------------------------------------------------------------------
module tb_btn_payload_ctrl;

    // -----------------------------------------------------------------------
    // 파라미터
    // -----------------------------------------------------------------------
    localparam integer CLK_FREQ = 10_000;
    localparam integer SAMP_MS  = 1;
    localparam integer SAMP_CNT = (CLK_FREQ / 1000) * SAMP_MS;  // 10
    localparam         CLK_HALF = 5;  // ns

    // -----------------------------------------------------------------------
    // DUT 포트
    // -----------------------------------------------------------------------
    reg        i_CLK   = 0;
    reg        i_RST_N = 0;
    reg        i_BTN   = 1;  // idle = 1 (active-low)

    wire [31:0] o_PAYLOAD0, o_PAYLOAD1, o_PAYLOAD2, o_PAYLOAD3;
    wire [31:0] o_PAYLOAD4, o_PAYLOAD5, o_PAYLOAD6, o_PAYLOAD7;

    // -----------------------------------------------------------------------
    // DUT 인스턴스
    // -----------------------------------------------------------------------
    btn_payload_ctrl #(
        .CLK_FREQ_HZ (CLK_FREQ),
        .SAMPLE_MS   (SAMP_MS)
    ) DUT (
        .i_CLK      (i_CLK),
        .i_RST_N    (i_RST_N),
        .i_BTN      (i_BTN),
        .o_PAYLOAD0 (o_PAYLOAD0), .o_PAYLOAD1 (o_PAYLOAD1),
        .o_PAYLOAD2 (o_PAYLOAD2), .o_PAYLOAD3 (o_PAYLOAD3),
        .o_PAYLOAD4 (o_PAYLOAD4), .o_PAYLOAD5 (o_PAYLOAD5),
        .o_PAYLOAD6 (o_PAYLOAD6), .o_PAYLOAD7 (o_PAYLOAD7)
    );

    always #CLK_HALF i_CLK = ~i_CLK;

    // -----------------------------------------------------------------------
    // 검증 카운터
    // -----------------------------------------------------------------------
    integer pass_cnt  = 0;
    integer fail_cnt  = 0;
    integer press_cnt = 0;  // 지금까지 검출된 유효 누름 횟수

    // -----------------------------------------------------------------------
    // task: N 클럭 대기
    // -----------------------------------------------------------------------
    task wait_clk;
        input integer n;
        integer k;
        begin
            for (k = 0; k < n; k = k + 1) @(posedge i_CLK);
        end
    endtask

    // -----------------------------------------------------------------------
    // task: 다음 sample_tick 처리 완료 후 안전 구간으로 복귀
    //
    //   반환 시점: cnt=1 posedge 후 1ns (클럭 엣지 사이)
    //   → 이후 i_BTN 드라이브는 다음 tick(cnt=9) 까지 8사이클 여유
    // -----------------------------------------------------------------------
    task wait_tick;
        begin
            @(posedge DUT.sample_tick);  // cnt=9 NBA: sample_tick 상승
            @(posedge i_CLK);            // cnt=0: DUT가 btn_q/payload 갱신
            @(posedge i_CLK);            // cnt=1: payload 새 값 확정
            #1;                          // 클럭 사이(1ns)로 진입 — BTN 드라이브 안전
        end
    endtask

    // -----------------------------------------------------------------------
    // task: payload 전체 검증 (press_cnt * step 과 비교)
    // -----------------------------------------------------------------------
    task check;
        input integer tc_id;
        reg ok;
        begin
            ok = (o_PAYLOAD0 === press_cnt *   1) &&
                 (o_PAYLOAD1 === press_cnt *   2) &&
                 (o_PAYLOAD2 === press_cnt *   4) &&
                 (o_PAYLOAD3 === press_cnt *   8) &&
                 (o_PAYLOAD4 === press_cnt *  16) &&
                 (o_PAYLOAD5 === press_cnt *  32) &&
                 (o_PAYLOAD6 === press_cnt *  64) &&
                 (o_PAYLOAD7 === press_cnt * 128);
            if (ok) begin
                $display("[PASS] TC%02d  press=%0d  P0=%0d P1=%0d P2=%0d P3=%0d P4=%0d P5=%0d P6=%0d P7=%0d",
                    tc_id, press_cnt,
                    o_PAYLOAD0, o_PAYLOAD1, o_PAYLOAD2, o_PAYLOAD3,
                    o_PAYLOAD4, o_PAYLOAD5, o_PAYLOAD6, o_PAYLOAD7);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("[FAIL] TC%02d  press=%0d", tc_id, press_cnt);
                if (o_PAYLOAD0 !== press_cnt *   1) $display("  S0: got=%0d exp=%0d", o_PAYLOAD0, press_cnt*1);
                if (o_PAYLOAD1 !== press_cnt *   2) $display("  S1: got=%0d exp=%0d", o_PAYLOAD1, press_cnt*2);
                if (o_PAYLOAD2 !== press_cnt *   4) $display("  S2: got=%0d exp=%0d", o_PAYLOAD2, press_cnt*4);
                if (o_PAYLOAD3 !== press_cnt *   8) $display("  S3: got=%0d exp=%0d", o_PAYLOAD3, press_cnt*8);
                if (o_PAYLOAD4 !== press_cnt *  16) $display("  S4: got=%0d exp=%0d", o_PAYLOAD4, press_cnt*16);
                if (o_PAYLOAD5 !== press_cnt *  32) $display("  S5: got=%0d exp=%0d", o_PAYLOAD5, press_cnt*32);
                if (o_PAYLOAD6 !== press_cnt *  64) $display("  S6: got=%0d exp=%0d", o_PAYLOAD6, press_cnt*64);
                if (o_PAYLOAD7 !== press_cnt * 128) $display("  S7: got=%0d exp=%0d", o_PAYLOAD7, press_cnt*128);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    // -----------------------------------------------------------------------
    // 메인 테스트 시퀀스
    // -----------------------------------------------------------------------
    initial begin
        $display("=================================================================");
        $display(" btn_payload_ctrl TB  (SAMP_CNT=%0d clk/tick)", SAMP_CNT);
        $display("=================================================================");

        // -------------------------------------------------------------------
        // TC01: 리셋 후 payload 전체 0
        // -------------------------------------------------------------------
        i_RST_N = 0;  i_BTN = 1;
        wait_clk(4);
        i_RST_N = 1;
        wait_clk(2);
        check(1);  // press_cnt=0 → 모두 0

        // -------------------------------------------------------------------
        // TC02: 정상 1회 누름
        //   tick1: i_BTN=1 → btn_q ← 1 (안정화)
        //   tick2: i_BTN=0 (누름), btn_q=1 → btn_pressed → 증가
        // -------------------------------------------------------------------
        wait_tick;      // tick: btn_q ← 1 (i_BTN=1 샘플)
        i_BTN = 0;      // press  (cnt=1+1ns, 다음 tick까지 8사이클 여유)
        wait_tick;      // tick: btn_q=1, i_BTN=0 → btn_pressed → 증가
        press_cnt = press_cnt + 1;
        check(2);

        // -------------------------------------------------------------------
        // TC03: 누른 채 유지 — 추가 증가 없음 (2회 확인)
        //   tick: btn_q=0 (직전 tick에서 갱신), i_BTN=0 → no press
        // -------------------------------------------------------------------
        wait_tick;      // tick: btn_q=0, i_BTN=0 → no press
        check(3);
        wait_tick;
        check(3);

        // -------------------------------------------------------------------
        // TC04: 해제 (LOW→HIGH) — 증가 없음
        //   tick: btn_q=0, i_BTN=1 → rising edge → no press
        // -------------------------------------------------------------------
        i_BTN = 1;
        wait_tick;      // tick: btn_q=0, i_BTN=1 → no press; btn_q←1
        check(4);

        // -------------------------------------------------------------------
        // TC05: 두 번째 누름
        //   tick: btn_q=1 (TC04에서 갱신), i_BTN=0 → pressed
        // -------------------------------------------------------------------
        i_BTN = 0;
        wait_tick;
        press_cnt = press_cnt + 1;
        check(5);

        // -------------------------------------------------------------------
        // TC06: 세 번째 누름 (해제 안정화 후 재누름)
        //   tick-a: btn_q=0 (TC05 갱신), i_BTN=1 → no press; btn_q←1
        //   tick-b: btn_q=1, i_BTN=0 → pressed
        // -------------------------------------------------------------------
        i_BTN = 1;
        wait_tick;      // 해제 안정화 tick: btn_q ← 1
        i_BTN = 0;
        wait_tick;      // press tick
        press_cnt = press_cnt + 1;
        check(6);

        // -------------------------------------------------------------------
        // TC07: 바운스 시뮬 — 기간 내 4회 토글, 틱 시점 LOW → 1회만 증가
        //
        //   사전: 해제 안정화 tick → btn_q=1
        //   bounce: cnt=2~5 사이 4회 토글 후 i_BTN=0 정착
        //   tick: btn_q=1, i_BTN=0 → pressed (바운스 무시, 1회만)
        //   연속 tick: btn_q=0, i_BTN=0 → no press (두 번째 검출 없음)
        // -------------------------------------------------------------------
        i_BTN = 1;
        wait_tick;      // 해제 안정화: btn_q ← 1

        // wait_tick 반환 시점: cnt=1 지난 직후(1ns) → 다음 tick까지 8사이클
        // cnt=2~5 구간에서 4회 토글
        i_BTN = 0; @(posedge i_CLK);   // cnt=2
        i_BTN = 1; @(posedge i_CLK);   // cnt=3
        i_BTN = 0; @(posedge i_CLK);   // cnt=4
        i_BTN = 1; @(posedge i_CLK);   // cnt=5
        i_BTN = 0;                      // cnt=5+1ns: LOW 정착 (tick 4사이클 전)

        wait_tick;      // tick: btn_q=1, i_BTN=0 → pressed (1회만 인식)
        press_cnt = press_cnt + 1;
        check(7);

        wait_tick;      // tick: btn_q=0, i_BTN=0 → no press (중복 검출 없음)
        check(7);       // press_cnt 동일

        // -------------------------------------------------------------------
        // TC08: 바운스 시뮬 — 틱 시점 HIGH로 끝남 → 미검출
        //
        //   사전: 해제 안정화 tick → btn_q=1
        //   bounce: 잠깐 LOW 갔다가 HIGH 복귀
        //   tick: btn_q=1, i_BTN=1 → no press
        // -------------------------------------------------------------------
        i_BTN = 1;
        wait_tick;      // 해제 안정화: btn_q ← 1

        i_BTN = 0; @(posedge i_CLK);   // 잠깐 LOW (bounce)
        i_BTN = 1; @(posedge i_CLK);   // HIGH 복귀

        wait_tick;      // tick: btn_q=1, i_BTN=1 → no press (1→1 변화 없음)
        check(8);       // press_cnt 그대로

        // -------------------------------------------------------------------
        // TC09: 리셋 중 버튼 누름 → 리셋 해제 후 payload = 0
        // -------------------------------------------------------------------
        i_BTN = 0;      // 버튼 누른 채
        i_RST_N = 0;    // 리셋 인가
        wait_clk(5);
        i_RST_N = 1;
        wait_clk(2);    // 리셋 해제 후 첫 tick 전 (cnt=2, 아직 tick 없음)
        press_cnt = 0;  // 리셋으로 payload 모두 0
        check(9);

        // -------------------------------------------------------------------
        // TC10: 리셋 해제 후 정상 누름 복원
        //   tick-a: i_BTN=1 → btn_q ← 1 (리셋값 btn_q=1이지만 안전하게 확정)
        //   tick-b: i_BTN=0 → pressed
        // -------------------------------------------------------------------
        i_BTN = 1;      // 해제 (리셋 후 i_BTN=0 상태였음)
        wait_tick;      // tick: btn_q=1(리셋값), i_BTN=1 → no press; btn_q ← 1
        i_BTN = 0;
        wait_tick;      // tick: btn_q=1, i_BTN=0 → pressed
        press_cnt = press_cnt + 1;
        check(10);

        // -------------------------------------------------------------------
        // TC11: 5회 연속 누름 자동 루프 — 누적값 검증
        //   매 누름마다 (해제 안정화 tick + 누름 tick) 패턴 반복
        // -------------------------------------------------------------------
        begin : tc11
            integer k;
            for (k = 0; k < 5; k = k + 1) begin
                i_BTN = 1;
                wait_tick;          // 해제 안정화: btn_q ← 1
                i_BTN = 0;
                wait_tick;          // 누름 검출
                press_cnt = press_cnt + 1;
            end
        end
        check(11);

        // -------------------------------------------------------------------
        // TC12: 누름 없이 10틱 대기 — payload 불변
        //   BTN=1 유지, 10회 tick → 어떤 증가도 없어야 함
        // -------------------------------------------------------------------
        i_BTN = 1;
        repeat(10) wait_tick;
        check(12);

        // -------------------------------------------------------------------
        // TC13: 틱 직전 1사이클 전에 BTN 변화 — 검출 확인 (후반부 타이밍)
        //   wait_tick 반환(cnt=1+1ns) 후 6사이클 대기 → cnt=7+1ns에서 BTN=0
        //   다음 틱(cnt=9→0)에서 정상 검출되어야 함
        // -------------------------------------------------------------------
        i_BTN = 1;
        wait_tick;              // 해제 안정화: btn_q ← 1
        wait_clk(6);            // cnt=7까지 대기 (다음 tick까지 2사이클 남음)
        i_BTN = 0;              // 틱 직전 LOW
        wait_tick;              // tick: btn_q=1, i_BTN=0 → pressed
        press_cnt = press_cnt + 1;
        check(13);

        // -------------------------------------------------------------------
        // TC14: 리셋 직후 첫 틱에서 즉시 누름 검출
        //   btn_q는 리셋값 1, BTN=0 → 첫 tick에서 바로 눌림으로 인식
        // -------------------------------------------------------------------
        i_BTN = 0;              // 누른 채로 리셋
        i_RST_N = 0;
        wait_clk(4);
        i_RST_N = 1;
        press_cnt = 0;          // 리셋으로 payload 초기화됨
        // BTN 여전히 0, btn_q=1 (리셋값)
        wait_tick;              // 첫 tick: btn_q=1, i_BTN=0 → pressed
        press_cnt = press_cnt + 1;
        check(14);

        // -------------------------------------------------------------------
        // TC15: 강한 바운스 6회 토글 + 최종 LOW — 1회만 검출
        //   안정화 tick 후, 기간 내 6회 빠른 토글 → LOW 정착 → 1회 검출
        //   이후 연속 tick: btn_q=0, i_BTN=0 → 추가 검출 없음
        // -------------------------------------------------------------------
        i_BTN = 1;
        wait_tick;              // btn_q ← 1 안정화
        // cnt=2~7 구간에서 6회 토글 후 LOW 정착
        i_BTN = 0; @(posedge i_CLK);
        i_BTN = 1; @(posedge i_CLK);
        i_BTN = 0; @(posedge i_CLK);
        i_BTN = 1; @(posedge i_CLK);
        i_BTN = 0; @(posedge i_CLK);
        i_BTN = 1; @(posedge i_CLK);
        i_BTN = 0;              // LOW 정착 (tick 1사이클 전)
        wait_tick;              // tick: btn_q=1, i_BTN=0 → 1회만 검출
        press_cnt = press_cnt + 1;
        check(15);
        wait_tick;              // tick: btn_q=0, i_BTN=0 → 추가 검출 없음
        check(15);

        // -------------------------------------------------------------------
        // TC16: 강한 바운스 6회 토글 + 최종 HIGH — 미검출
        //   안정화 tick 후, 6회 토글 → HIGH 정착 → 검출 없음
        // -------------------------------------------------------------------
        i_BTN = 1;
        wait_tick;              // btn_q ← 1 안정화
        i_BTN = 0; @(posedge i_CLK);
        i_BTN = 1; @(posedge i_CLK);
        i_BTN = 0; @(posedge i_CLK);
        i_BTN = 1; @(posedge i_CLK);
        i_BTN = 0; @(posedge i_CLK);
        i_BTN = 1;              // HIGH 정착
        wait_tick;              // tick: btn_q=1, i_BTN=1 → no press (1→1)
        check(16);

        // -------------------------------------------------------------------
        // TC17: 복수 리셋 사이 누름 패턴
        //   1차 리셋 → 1회 누름 → 2차 리셋 → 1회 누름 → 누적 확인
        // -------------------------------------------------------------------
        // 1차 리셋
        i_BTN = 1;
        i_RST_N = 0;
        wait_clk(4);
        i_RST_N = 1;
        press_cnt = 0;
        // 1회 누름
        wait_tick;              // btn_q ← 1 안정화
        i_BTN = 0;
        wait_tick;
        press_cnt = press_cnt + 1;
        check(17);
        // 2차 리셋
        i_BTN = 1;
        i_RST_N = 0;
        wait_clk(4);
        i_RST_N = 1;
        press_cnt = 0;
        // 1회 누름
        wait_tick;
        i_BTN = 0;
        wait_tick;
        press_cnt = press_cnt + 1;
        check(17);

        // -------------------------------------------------------------------
        // TC18: 리셋 후 정확히 첫 틱과 두 번째 틱 경계 검증
        //   tick1: BTN=0 (누름) → 검출됨
        //   tick2: BTN=0 (유지) → 미검출
        //   tick3: BTN=1 (해제) → 미검출
        //   tick4: BTN=0 (재누름) → 검출됨
        // -------------------------------------------------------------------
        i_BTN = 0;
        i_RST_N = 0;
        wait_clk(4);
        i_RST_N = 1;
        press_cnt = 0;
        // BTN=0, btn_q=1(리셋값) → tick1 에서 검출
        wait_tick;
        press_cnt = press_cnt + 1;
        check(18);
        // BTN 유지 0 → tick2 미검출
        wait_tick;
        check(18);
        // BTN=1 → tick3 미검출
        i_BTN = 1;
        wait_tick;
        check(18);
        // BTN=0 → tick4 검출
        i_BTN = 0;
        wait_tick;
        press_cnt = press_cnt + 1;
        check(18);

        // -------------------------------------------------------------------
        // TC19: 20회 연속 누름 루프 — 대량 누적값 검증
        // -------------------------------------------------------------------
        begin : tc19
            integer m;
            for (m = 0; m < 20; m = m + 1) begin
                i_BTN = 1;
                wait_tick;
                i_BTN = 0;
                wait_tick;
                press_cnt = press_cnt + 1;
            end
        end
        check(19);

        // -------------------------------------------------------------------
        // TC20: 전체 슬롯 최종 누적값 개별 출력 (grand total 확인)
        // -------------------------------------------------------------------
        $display("--- TC20: Grand Total (press_cnt=%0d) ---", press_cnt);
        $display("  SLOT0 (+1  each): %0d", o_PAYLOAD0);
        $display("  SLOT1 (+2  each): %0d", o_PAYLOAD1);
        $display("  SLOT2 (+4  each): %0d", o_PAYLOAD2);
        $display("  SLOT3 (+8  each): %0d", o_PAYLOAD3);
        $display("  SLOT4 (+16 each): %0d", o_PAYLOAD4);
        $display("  SLOT5 (+32 each): %0d", o_PAYLOAD5);
        $display("  SLOT6 (+64 each): %0d", o_PAYLOAD6);
        $display("  SLOT7 (+128 each): %0d", o_PAYLOAD7);
        check(20);

        // -------------------------------------------------------------------
        // 결과 요약
        // -------------------------------------------------------------------
        $display("=================================================================");
        $display(" RESULT: %0d PASS / %0d FAIL", pass_cnt, fail_cnt);
        if (fail_cnt == 0)
            $display(" ALL TESTS PASSED");
        else
            $display(" *** SOME TESTS FAILED ***");
        $display("=================================================================");
        $finish;
    end

    // 타임아웃 가드
    initial begin
        #2_000_000;
        $display("[TIMEOUT] Simulation exceeded time limit");
        $finish;
    end

endmodule
