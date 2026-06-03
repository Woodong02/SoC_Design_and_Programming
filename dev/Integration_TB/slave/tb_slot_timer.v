`timescale 1ns/1ps
// tb_slot_timer: slot_timer 단위 테스트
// 컴파일: vlog slot_timer.v tb_slot_timer.v
// 실행: vsim -c tb_slot_timer -do "run -all; quit"
//
// slot_ticks = 50*DIV + guard = 50*4+20 = 220
// tx_trigger는 registered output (NB assign): slot_cnt==trig_cnt 다음 클럭에 출력
// TB 측정도 NB 체크로 1클럭 늦음 → 측정값 = trig_cnt + 2
// slave_addr=0: trig_cnt=10  → measured 12
// slave_addr=1: trig_cnt=230 → measured 232
// slave_addr=2: trig_cnt=450 → measured 452
// no_broadcast: wdog_cnt=1980 → measured 1982
module tb_slot_timer;

localparam CLK_HALF    = 5;
localparam [9:0] DIV   = 10'd4;
localparam [9:0] GUARD = 10'd20;

reg clk = 0, resetn = 0;
always #CLK_HALF clk = ~clk;

reg  active_edge;
wire tx_trigger, no_broadcast;
reg [2:0] slave_addr_r;

slot_timer dut (
    .clk(clk), .rst_n(resetn),
    .div(DIV), .guard_ticks(GUARD),
    .slave_addr(slave_addr_r),
    .active_edge(active_edge),
    .tx_trigger(tx_trigger),
    .no_broadcast(no_broadcast)
);

integer fail = 0, pass = 0;
task chk;
    input cond;
    input [255:0] msg;
    begin
        if (cond) begin $display("  PASS | %0s", msg); pass = pass + 1; end
        else      begin $display("  FAIL | %0s", msg); fail = fail + 1; end
    end
endtask

// active_edge 후 tx_trigger까지의 클럭 수를 측정
task measure_trig_delay;
    output integer delay_out;
    integer cnt;
    begin
        // active_edge 1클럭 인가
        @(posedge clk); active_edge = 1;
        @(posedge clk); active_edge = 0;
        // tx_trigger 대기
        cnt = 0;
        begin : wait_trig
            forever begin
                @(posedge clk);
                cnt = cnt + 1;
                if (tx_trigger) disable wait_trig;
                if (cnt > 10000) begin
                    $display("  TIMEOUT waiting for tx_trigger");
                    disable wait_trig;
                end
            end
        end
        delay_out = cnt;
    end
endtask

integer delay;

initial begin
    $dumpfile("tb_slot_timer.vcd");
    $dumpvars(0, tb_slot_timer);

    active_edge   = 0;
    slave_addr_r  = 3'd0;
    resetn = 0;
    repeat(4) @(posedge clk);
    resetn = 1;
    repeat(2) @(posedge clk);

    // --- SC1: slave_addr=0, trig_cnt=10 ---
    $display("[%0t] SC1: slave_addr=0, 기대 trig_cnt=10", $time);
    slave_addr_r = 3'd0;
    measure_trig_delay(delay);
    $display("  measured delay = %0d (expected 12 = trig_cnt+2)", delay);
    chk(delay == 12, "tx_trigger fires at trig_cnt+2 (reg delay)");

    // 리셋 후 다음 테스트
    resetn = 0; repeat(2) @(posedge clk); resetn = 1; repeat(2) @(posedge clk);

    // --- SC2: slave_addr=1, trig_cnt=230 ---
    $display("[%0t] SC2: slave_addr=1, 기대 trig_cnt=230", $time);
    slave_addr_r = 3'd1;
    measure_trig_delay(delay);
    $display("  measured delay = %0d (expected 232 = trig_cnt+2)", delay);
    chk(delay == 232, "tx_trigger fires at trig_cnt+2");

    resetn = 0; repeat(2) @(posedge clk); resetn = 1; repeat(2) @(posedge clk);

    // --- SC3: slave_addr=2, trig_cnt=450 ---
    $display("[%0t] SC3: slave_addr=2, 기대 trig_cnt=450", $time);
    slave_addr_r = 3'd2;
    measure_trig_delay(delay);
    $display("  measured delay = %0d (expected 452 = trig_cnt+2)", delay);
    chk(delay == 452, "tx_trigger fires at trig_cnt+2");

    resetn = 0; repeat(2) @(posedge clk); resetn = 1; repeat(2) @(posedge clk);

    // --- SC4: no_broadcast 워치독 (slave_addr=0, 9*220=1980) ---
    $display("[%0t] SC4: no_broadcast 워치독 (기대 1980클럭 후)", $time);
    slave_addr_r = 3'd0;
    begin : wdog_test
        integer cnt2;
        integer trig_at, wdog_at;
        trig_at = 0; wdog_at = 0;
        @(posedge clk); active_edge = 1;
        @(posedge clk); active_edge = 0;
        for (cnt2 = 0; cnt2 < 2500; cnt2 = cnt2 + 1) begin
            @(posedge clk);
            if (tx_trigger  && trig_at==0) trig_at  = cnt2+1;
            if (no_broadcast && wdog_at==0) wdog_at = cnt2+1;
        end
        $display("  tx_trigger at %0d, no_broadcast at %0d (expected 1982 = wdog_cnt+2)", trig_at, wdog_at);
        chk(wdog_at == 1982, "no_broadcast fires at wdog_cnt+2");
    end

    $display("");
    $display("=== Result: %0d PASS  %0d FAIL ===", pass, fail);
    $finish;
end

initial begin #5_000_000; $display("TIMEOUT"); $finish; end

endmodule
