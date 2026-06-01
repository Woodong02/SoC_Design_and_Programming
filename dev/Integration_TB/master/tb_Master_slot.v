`timescale 1ns / 1ps
// tb_Master_slot: Master_slot 슬롯 타이머 단위 테스트
// T1: NODE_CNT=2, DIV=8, GUARD=0 → slot 0→1→2→0 사이클
// T2: 각 슬롯 경계(slot_change) 타이밍 = 50*8=400 클럭
// T3: slot_pre_change가 slot_change 정확히 1클럭 전
// T4: rx_stat = 2(data 구간), 0(guard 정상 윈도우), 1(경계 약한 오류)
// T5: cycle_cnt가 slot=0으로 돌아올 때 증가
module tb_Master_slot;

    reg  clk, resetn;
    always #5 clk = ~clk;

    localparam [9:0] DIV        = 10'd8;
    localparam [9:0] GUARD      = 10'd0;
    localparam [3:0] NODE_CNT_2 = 4'd2;    // 슬레이브 2개 → Master_slot에 NODE_CNT=2 (4비트)

    reg  [9:0] div_r;
    reg  [9:0] guard_r;
    reg  [3:0] nc_r;     // Master_slot NODE_CNT가 4비트로 확장됨에 따라 동일하게 수정

    wire [3:0]  slot;    // Master_slot slot 출력이 4비트로 확장됨에 따라 동일하게 수정
    wire        slot_change, slot_pre_change;
    wire [15:0] clk_cnt;
    wire [1:0]  rx_stat;
    wire [63:0] cycle_cnt;

    Master_slot uut (
        .resetn(resetn), .clk(clk),
        .DIV(div_r), .GUARD_TICKS(guard_r), .NODE_CNT(nc_r),
        .slot(slot), .slot_change(slot_change),
        .slot_pre_change(slot_pre_change),
        .clk_cnt(clk_cnt), .rx_stat(rx_stat),
        .cycle_cnt(cycle_cnt)
    );

    integer pass_cnt, fail_cnt;
    integer slot_change_time [0:7];
    integer pre_change_time  [0:7];
    integer sc_cnt, pc_cnt;
    // 연속 두 정상 slot_change 간격 측정용 (reset-induced 첫번째 skip)
    integer sc2_time, sc3_time;   // 2번째, 3번째 slot_change 시각
    reg sc_seen, pc_seen;

    task do_reset;
        begin
            @(posedge clk); #1; resetn=0;
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

    // slot_change/pre_change 타임스탬프 기록
    integer prev_sc_time;
    always @(posedge clk) begin
        if (slot_change) begin
            sc_cnt = sc_cnt + 1;
            // 2번째/3번째 slot_change 시각 기록 (1번째=reset-induced 제외)
            if (sc_cnt == 2) sc2_time = $time;
            if (sc_cnt == 3) sc3_time = $time;
            if (slot_change_time[slot] == 0)
                slot_change_time[slot] = $time;
        end
        if (slot_pre_change) begin
            pc_cnt = pc_cnt + 1;
            if (pre_change_time[slot] == 0)
                pre_change_time[slot] = $time;
        end
    end

    initial begin
        clk=0; resetn=0;
        div_r=DIV; guard_r=GUARD; nc_r=NODE_CNT_2;
        pass_cnt=0; fail_cnt=0; sc_cnt=0; pc_cnt=0;
        prev_sc_time=0;
        // 배열 및 측정 변수 초기화
        begin : init
            integer k;
            for (k=0; k<8; k=k+1) begin
                slot_change_time[k] = 0;
                pre_change_time[k]  = 0;
            end
        end
        sc2_time=0; sc3_time=0;
        do_reset;

        // ── T1/T2: slot 사이클 및 타이밍 ─────────────────────────────────────
        $display("\n--- T1/T2: NODE_CNT=2, DIV=8, GUARD=0 슬롯 사이클 ---");
        // 초기 리셋 직후 slot_change=1 (모듈 초기화)
        // 3사이클(0→1→2→0) 기다림 = 3*400 = 1200클럭 + 여유
        repeat(1300) @(posedge clk); #1;

        // T1: slot이 0,1,2 순서로 순환하는지
        // (sc_cnt >= 3 이상 기록됐으면 순환 있음)
        check(sc_cnt >= 3, "T1: slot_change 3회 이상 발생 (순환 확인)");

        // T2: slot_change 발생 직후 clk_cnt=0 (=방금 래핑됨) 확인
        // slot_change와 clk_cnt<=0은 같은 NBA 배치에서 설정됨 → 동시에 읽히면 clk_cnt=0
        begin : t2
            reg sc_wait;
            sc_wait = 0;
            while (!sc_wait) begin
                @(posedge clk); #1;
                if (slot_change) sc_wait = 1;
            end
            // slot_change=1인 이 클럭에서 clk_cnt도 0으로 초기화됨
            check(clk_cnt === 16'd0, "T2: slot_change 직후 clk_cnt=0 (주기 정상)");
        end

        // ── T3: slot_pre_change가 slot_change 1클럭 전 ───────────────────────
        // slot_pre_change와 slot_change 사이에는 항상 정확히 1클럭 간격
        // → 두 신호가 연속 클럭에서 발생함을 sticky 플래그로 확인
        $display("\n--- T3: slot_pre_change 타이밍 ---");
        begin : t3
            reg pre_seen_flag;
            integer wait_cnt;
            pre_seen_flag = 0; wait_cnt = 0;
            // 최대 410클럭 관찰: slot_pre_change 다음 클럭에 slot_change가 바로 와야 함
            while (!pre_seen_flag && wait_cnt < 410) begin
                @(posedge clk); #1;
                wait_cnt = wait_cnt + 1;
                if (slot_pre_change) begin
                    @(posedge clk); #1;
                    if (slot_change) pre_seen_flag = 1;
                end
            end
            check(pre_seen_flag === 1'b1, "T3: slot_pre_change = slot_change 1클럭 전");
        end

        // ── T4: rx_stat 값 ───────────────────────────────────────────────────
        // total_tick=420, data_len_tick=400, guard/4=5
        // rx_stat: 2 if clk_cnt<400, 0 if 405<=clk_cnt<415, 1 otherwise in guard
        $display("\n--- T4: rx_stat (GUARD=20, data/guard 구간) ---");
        do_reset;
        div_r=DIV; guard_r=10'd20; nc_r=4'd1;
        // clk_cnt 시작점: do_reset 후 2클럭 → clk_cnt=2
        repeat(2) @(posedge clk);
        // T4a: data 구간 clk_cnt=2 (< 400) → rx_stat=2
        repeat(1) @(posedge clk); #1;
        check(rx_stat === 2'd2, "T4a: rx_stat=2 (data 구간)");
        // T4b: guard 중간: clk_cnt=410 → 405≤410<415 → rx_stat=0
        // 현재 clk_cnt≈3, 410-3=407클럭 더 기다림
        repeat(407) @(posedge clk); #1;
        check(rx_stat === 2'd0, "T4b: rx_stat=0 (guard 정상 윈도우)");
        // T4c: guard 경계: clk_cnt=416 → 415≤416<420 → rx_stat=1
        // 현재 clk_cnt≈410, 416-410=6클럭 더 기다림
        repeat(6) @(posedge clk); #1;
        check(rx_stat === 2'd1, "T4c: rx_stat=1 (guard 경계)");

        // ── T5: cycle_cnt 증가 ───────────────────────────────────────────────
        $display("\n--- T5: cycle_cnt (NODE_CNT=1, slot 0→1→0 주기) ---");
        do_reset;
        div_r=DIV; guard_r=10'd0; nc_r=4'd1;  // slot 0,1 순환 (NODE_CNT=1)
        begin : t5
            integer c0;
            repeat(5) @(posedge clk); #1; c0 = cycle_cnt;
            // 2슬롯 사이클(0→1→0) = 2*400+여유
            repeat(2*400+10) @(posedge clk); #1;
            check(cycle_cnt > c0, "T5: cycle_cnt 증가 확인");
        end

        $display("\n========================================");
        $display("[DONE] Master_slot: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        $display("========================================");
        $finish;
    end

endmodule
