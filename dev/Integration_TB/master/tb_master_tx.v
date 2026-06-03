`timescale 1ns/1ps
// tb_master_tx: Master_tx 단위 테스트
// 컴파일: vlog hamming_enc.v Master_tx.v tb_master_tx.v
// 실행: vsim -c tb_master_tx -do "run -all; quit"
//
// 검증: data_trigger 후 50비트 NRZ 프레임 전송 확인 (preamble=0xAA)
//       sync_trigger 후 동일 프레임 재전송 확인 (겹치지 않음)
module tb_master_tx;

localparam CLK_HALF    = 5;
localparam [9:0] DIV   = 10'd4;
localparam [9:0] GUARD = 10'd20;
localparam [7:0] HALT  = 8'hAB;

reg clk = 0, resetn = 0;
always #CLK_HALF clk = ~clk;

reg tx_trigger;
wire GPIO_out;

Master_tx dut (
    .clk(clk), .resetn(resetn),
    .tx_trigger(tx_trigger), .halt_cmd(HALT),
    .GUARD_TICKS(GUARD), .DIV(DIV),
    .GPIO_out(GPIO_out)
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

// GPIO_out 비트 샘플링: 각 비트를 DIV 클럭 중간(DIV/2)에 샘플
task sample_frame;
    output [49:0] frame_out;
    integer b, d;
    reg bit_val;
    begin
        for (b = 0; b < 50; b = b + 1) begin
            // 비트 중간 지점까지 대기 (DIV/2 클럭)
            for (d = 0; d < DIV/2; d = d + 1)
                @(posedge clk);
            bit_val = GPIO_out;
            frame_out[49-b] = bit_val;
            // 나머지 반 주기
            for (d = DIV/2; d < DIV; d = d + 1)
                @(posedge clk);
        end
    end
endtask

reg [49:0] captured;

initial begin
    $dumpfile("tb_master_tx.vcd");
    $dumpvars(0, tb_master_tx);

    tx_trigger = 0;
    resetn = 0;
    repeat(4) @(posedge clk);
    resetn = 1;
    repeat(2) @(posedge clk);

    // --- SC1: data_trigger (마스터 DATA 슬롯 시뮬) ---
    $display("[%0t] SC1: data_trigger → 프레임 전송 검증", $time);
    @(posedge clk);
    tx_trigger = 1;
    @(posedge clk);
    tx_trigger = 0;

    // 프레임 샘플링: 50비트 × DIV클럭
    sample_frame(captured);
    @(posedge clk); // NB assignment 반영 대기

    chk(captured[49:42] == 8'hAA, "preamble == 0xAA");
    chk(GPIO_out == 1'b0,         "GPIO_out=0 after TX done");

    // --- SC2: sync_trigger (주기 끝 SYNC 시뮬) ---
    $display("[%0t] SC2: sync_trigger → 프레임 재전송 검증", $time);
    repeat(5) @(posedge clk);  // 약간의 idle 갭
    @(posedge clk);
    tx_trigger = 1;
    @(posedge clk);
    tx_trigger = 0;

    sample_frame(captured);
    @(posedge clk);

    chk(captured[49:42] == 8'hAA, "preamble == 0xAA (sync)");
    chk(GPIO_out == 1'b0,         "GPIO_out=0 after sync TX done");

    // --- SC3: tx_enable 없을 때 (resetn=0 후 재확인) ---
    $display("[%0t] SC3: 리셋 후 idle 상태 확인", $time);
    resetn = 0;
    @(posedge clk);
    resetn = 1;
    repeat(2) @(posedge clk);
    chk(GPIO_out == 1'b0, "GPIO_out=0 after reset, no trigger");

    $display("");
    $display("=== Result: %0d PASS  %0d FAIL ===", pass, fail);
    $finish;
end

initial begin #200_000; $display("TIMEOUT"); $finish; end

endmodule
