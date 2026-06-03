`timescale 1ns/1ps
// tb_slave_tx: slave_tx 단위 테스트
// 컴파일: vlog hamming_enc.v slave_tx.v tb_slave_tx.v
// 실행: vsim -c tb_slave_tx -do "run -all; quit"
//
// 검증: tx_trigger 후 50비트 NRZ 프레임 전송 (preamble=0xAA, addr/data 포함)
//       tx_enable=0 시 프레임 미전송 확인
module tb_slave_tx;

localparam CLK_HALF    = 5;
localparam [9:0] DIV   = 10'd4;
localparam [2:0] ADDR  = 3'd2;
localparam [31:0] DATA = 32'hDEAD_BEEF;

reg clk = 0, resetn = 0;
always #CLK_HALF clk = ~clk;

reg        tx_trigger, tx_enable;
wire       bus_b, tx_active, data_sent;

slave_tx dut (
    .clk(clk), .rst_n(resetn),
    .div(DIV), .tx_trigger(tx_trigger), .tx_enable(tx_enable),
    .slave_addr(ADDR), .tx_data(DATA),
    .bus_b(bus_b), .tx_active(tx_active), .data_sent(data_sent)
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

// 50비트 프레임 샘플링 (비트 중간 샘플)
task sample_frame;
    output [49:0] frame_out;
    integer b, d;
    begin
        for (b = 0; b < 50; b = b + 1) begin
            for (d = 0; d < DIV/2; d = d + 1) @(posedge clk);
            frame_out[49-b] = bus_b;
            for (d = DIV/2; d < DIV; d = d + 1) @(posedge clk);
        end
    end
endtask

reg [49:0] captured;
reg        data_sent_seen;
integer    cnt;

initial begin
    $dumpfile("tb_slave_tx.vcd");
    $dumpvars(0, tb_slave_tx);

    tx_trigger = 0; tx_enable = 0;
    resetn = 0;
    repeat(4) @(posedge clk);
    resetn = 1;
    repeat(2) @(posedge clk);

    // --- SC1: tx_enable=0, 트리거 무시 ---
    $display("[%0t] SC1: tx_enable=0 → 프레임 미전송", $time);
    tx_enable = 0;
    @(posedge clk); tx_trigger = 1;
    @(posedge clk); tx_trigger = 0;
    repeat(10) @(posedge clk);
    chk(tx_active == 0, "tx_active=0 when tx_enable=0");
    chk(bus_b == 0,     "bus_b=0 when disabled");

    // --- SC2: tx_enable=1, 정상 전송 ---
    $display("[%0t] SC2: tx_enable=1 → 50비트 프레임 전송", $time);
    tx_enable = 1;
    @(posedge clk); tx_trigger = 1;
    @(posedge clk); tx_trigger = 0;
    @(posedge clk); // NB assignment 반영 대기

    // tx_active가 올라왔는지 확인
    chk(tx_active == 1, "tx_active=1 after trigger");

    // 프레임 샘플
    sample_frame(captured);
    @(posedge clk); // NB assignment 반영 대기

    chk(captured[49:42] == 8'hAA, "preamble[7:0] == 0xAA");
    // codeword[41:39] = slave_addr (d[34:32])
    chk(captured[41:39] == ADDR,  "addr field == ADDR");
    chk(tx_active == 0,           "tx_active=0 after frame done");
    chk(bus_b == 0,               "bus_b=0 after frame done");

    // --- SC3: data_sent 펄스 확인 ---
    $display("[%0t] SC3: data_sent 펄스 확인", $time);
    @(posedge clk); tx_trigger = 1;
    @(posedge clk); tx_trigger = 0;

    data_sent_seen = 0;
    for (cnt = 0; cnt < 50*DIV + 10; cnt = cnt + 1) begin
        @(posedge clk);
        if (data_sent) data_sent_seen = 1;
    end
    chk(data_sent_seen, "data_sent pulsed after frame");

    $display("");
    $display("=== Result: %0d PASS  %0d FAIL ===", pass, fail);
    $finish;
end

initial begin #200_000; $display("TIMEOUT"); $finish; end

endmodule
