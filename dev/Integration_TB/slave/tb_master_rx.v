`timescale 1ns/1ps
// tb_master_rx: slave 측 master_rx 단위 테스트
// 컴파일: vlog hamming_enc.v hamming_dec.v master_rx.v tb_master_rx.v
// 실행: vsim -c tb_master_rx -do "run -all; quit"
//
// 검증: 마스터 브로드캐스트 50비트 NRZ 프레임 수신 후
//       active_edge, bc_valid, bc_halt_cmd, bc_guard_ticks 올바른지 확인
module tb_master_rx;

localparam CLK_HALF    = 5;
localparam [9:0] DIV   = 10'd4;
localparam [7:0] HALT  = 8'hA5;
localparam [9:0] GT    = 10'd20;

reg clk = 0, resetn = 0;
always #CLK_HALF clk = ~clk;

reg bus_a;
wire active_edge, bc_valid, bc_preamble_ok, bc_hamming_err, bc_preamble_err;
wire [7:0]  bc_halt_cmd;
wire [9:0]  bc_guard_ticks;

master_rx dut (
    .clk(clk), .rst_n(resetn),
    .enable(1'b1), .div(DIV),
    .tx_line_sync(bus_a),
    .active_edge(active_edge),
    .bc_valid(bc_valid),
    .bc_preamble_ok(bc_preamble_ok),
    .bc_halt_cmd(bc_halt_cmd),
    .bc_guard_ticks(bc_guard_ticks),
    .bc_hamming_err(bc_hamming_err),
    .bc_preamble_err(bc_preamble_err)
);

// 마스터 TX 프레임 빌드에 사용할 hamming_enc
// d = {halt_cmd[7:0], guard_ticks[9:0], 17'b0}
wire [34:0] enc_d = {HALT, GT, 17'b0};
wire [41:0] enc_cw;
hamming_enc u_enc (.data(enc_d), .codeword(enc_cw));

// 50비트 프레임 = {8'hAA, enc_cw}
reg [49:0] tx_frame;
reg [49:0] tx_frame_bad; // preamble 오류 테스트용

integer fail = 0, pass = 0;
task chk;
    input cond;
    input [255:0] msg;
    begin
        if (cond) begin $display("  PASS | %0s", msg); pass = pass + 1; end
        else      begin $display("  FAIL | %0s", msg); fail = fail + 1; end
    end
endtask

// NRZ 비트 스트림 구동 (DIV 클럭/비트)
task drive_frame;
    input [49:0] frame;
    integer b, d;
    begin
        for (b = 0; b < 50; b = b + 1) begin
            bus_a = frame[49-b];
            repeat(DIV) @(posedge clk);
        end
        bus_a = 0;
    end
endtask

reg ae_seen, valid_seen, pre_ok_seen, pre_err_seen;
integer cnt;

initial begin
    $dumpfile("tb_master_rx.vcd");
    $dumpvars(0, tb_master_rx);

    bus_a  = 0;
    resetn = 0;
    repeat(4) @(posedge clk);
    resetn = 1;
    // enc_cw가 조합회로이므로 1사이클 안정화
    repeat(2) @(posedge clk);
    tx_frame     = {8'hAA, enc_cw};
    tx_frame_bad = {8'hBB, enc_cw}; // 잘못된 preamble

    // --- SC1: 정상 프레임 수신 ---
    $display("[%0t] SC1: 정상 프레임 수신", $time);
    ae_seen = 0; valid_seen = 0; pre_ok_seen = 0;

    fork
        drive_frame(tx_frame);
        begin : mon1
            for (cnt = 0; cnt < 50*DIV + 20; cnt = cnt + 1) begin
                @(posedge clk);
                if (active_edge)   ae_seen    = 1;
                if (bc_preamble_ok) pre_ok_seen = 1;
                if (bc_valid)      valid_seen  = 1;
            end
        end
    join

    chk(ae_seen,    "active_edge pulsed");
    chk(pre_ok_seen, "bc_preamble_ok pulsed");
    chk(valid_seen, "bc_valid pulsed");
    chk(bc_halt_cmd    == HALT, "bc_halt_cmd correct");
    chk(bc_guard_ticks == GT,   "bc_guard_ticks correct");
    chk(bc_hamming_err == 0,    "no hamming error");

    // --- SC2: 잘못된 preamble ---
    $display("[%0t] SC2: 잘못된 preamble (0xBB)", $time);
    repeat(4) @(posedge clk);
    ae_seen = 0; pre_err_seen = 0; valid_seen = 0;

    fork
        drive_frame(tx_frame_bad);
        begin : mon2
            for (cnt = 0; cnt < 50*DIV + 20; cnt = cnt + 1) begin
                @(posedge clk);
                if (active_edge)   ae_seen    = 1;
                if (bc_preamble_err) pre_err_seen = 1;
                if (bc_valid)      valid_seen  = 1;
            end
        end
    join

    chk(ae_seen,      "active_edge pulsed (bad preamble)");
    chk(pre_err_seen, "bc_preamble_err pulsed");
    chk(!valid_seen,  "bc_valid NOT pulsed on bad preamble");

    // --- SC3: idle 후 두 번째 정상 프레임 ---
    $display("[%0t] SC3: idle 후 재수신", $time);
    repeat(10) @(posedge clk);
    ae_seen = 0; valid_seen = 0;

    fork
        drive_frame(tx_frame);
        begin : mon3
            for (cnt = 0; cnt < 50*DIV + 20; cnt = cnt + 1) begin
                @(posedge clk);
                if (active_edge) ae_seen   = 1;
                if (bc_valid)    valid_seen = 1;
            end
        end
    join

    chk(ae_seen && valid_seen, "second frame received correctly");

    $display("");
    $display("=== Result: %0d PASS  %0d FAIL ===", pass, fail);
    $finish;
end

initial begin #500_000; $display("TIMEOUT"); $finish; end

endmodule
