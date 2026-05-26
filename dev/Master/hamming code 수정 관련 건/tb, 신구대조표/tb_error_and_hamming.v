`timescale 1ns / 1ps

module tb_error_and_hamming;

    // DUT ports
    reg         clk;
    reg         resetn;
    reg         in_sig;
    reg  [9:0]  guard_ticks;
    reg  [41:0] data_in;
    reg  [3:0]  slot;
    reg  [10:0] clk_cnt;
    reg         preamble_err;

    wire [31:0] slot_out0, slot_out1, slot_out2, slot_out3;
    wire [31:0] slot_out4, slot_out5, slot_out6, slot_out7;
    wire [7:0]  preamble_err_cnt0, slot_timeout_cnt0, hamming_err_cnt0, silent_cnt0;
    wire [7:0]  preamble_err_cnt1, slot_timeout_cnt1, hamming_err_cnt1, silent_cnt1;
    wire [7:0]  preamble_err_cnt2, slot_timeout_cnt2, hamming_err_cnt2, silent_cnt2;
    wire [7:0]  preamble_err_cnt3, slot_timeout_cnt3, hamming_err_cnt3, silent_cnt3;
    wire [7:0]  preamble_err_cnt4, slot_timeout_cnt4, hamming_err_cnt4, silent_cnt4;
    wire [7:0]  preamble_err_cnt5, slot_timeout_cnt5, hamming_err_cnt5, silent_cnt5;
    wire [7:0]  preamble_err_cnt6, slot_timeout_cnt6, hamming_err_cnt6, silent_cnt6;
    wire [7:0]  preamble_err_cnt7, slot_timeout_cnt7, hamming_err_cnt7, silent_cnt7;

    error_and_hamming dut (
        .clk(clk), .resetn(resetn), .in_sig(in_sig),
        .guard_ticks(guard_ticks), .data_in(data_in),
        .slot(slot), .clk_cnt(clk_cnt), .preamble_err(preamble_err),
        .slot_out0(slot_out0), .preamble_err_cnt0(preamble_err_cnt0),
        .slot_timeout_cnt0(slot_timeout_cnt0), .hamming_err_cnt0(hamming_err_cnt0),
        .silent_cnt0(silent_cnt0),
        .slot_out1(slot_out1), .preamble_err_cnt1(preamble_err_cnt1),
        .slot_timeout_cnt1(slot_timeout_cnt1), .hamming_err_cnt1(hamming_err_cnt1),
        .silent_cnt1(silent_cnt1),
        .slot_out2(slot_out2), .preamble_err_cnt2(preamble_err_cnt2),
        .slot_timeout_cnt2(slot_timeout_cnt2), .hamming_err_cnt2(hamming_err_cnt2),
        .silent_cnt2(silent_cnt2),
        .slot_out3(slot_out3), .preamble_err_cnt3(preamble_err_cnt3),
        .slot_timeout_cnt3(slot_timeout_cnt3), .hamming_err_cnt3(hamming_err_cnt3),
        .silent_cnt3(silent_cnt3),
        .slot_out4(slot_out4), .preamble_err_cnt4(preamble_err_cnt4),
        .slot_timeout_cnt4(slot_timeout_cnt4), .hamming_err_cnt4(hamming_err_cnt4),
        .silent_cnt4(silent_cnt4),
        .slot_out5(slot_out5), .preamble_err_cnt5(preamble_err_cnt5),
        .slot_timeout_cnt5(slot_timeout_cnt5), .hamming_err_cnt5(hamming_err_cnt5),
        .silent_cnt5(silent_cnt5),
        .slot_out6(slot_out6), .preamble_err_cnt6(preamble_err_cnt6),
        .slot_timeout_cnt6(slot_timeout_cnt6), .hamming_err_cnt6(hamming_err_cnt6),
        .silent_cnt6(silent_cnt6),
        .slot_out7(slot_out7), .preamble_err_cnt7(preamble_err_cnt7),
        .slot_timeout_cnt7(slot_timeout_cnt7), .hamming_err_cnt7(hamming_err_cnt7),
        .silent_cnt7(silent_cnt7)
    );

    // encoder for generating test codewords
    reg  [34:0] enc_data_in;
    wire [41:0] enc_codeword;
    hamming_enc u_enc (.data(enc_data_in), .codeword(enc_codeword));

    // clock: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    integer pass_cnt, fail_cnt;

    // Send one data frame: pulse in_sig for one clock after setting data_in
    task send_frame;
        input [41:0] codeword;
        begin
            @(negedge clk);
            data_in = codeword;
            in_sig  = 1'b1;
            @(negedge clk);
            in_sig  = 1'b0;
            @(negedge clk); // wait one more cycle for registered output
        end
    endtask

    // Check slot_out for a given slot number
    function [31:0] get_slot_out;
        input [2:0] s;
        begin
            case (s)
                3'd0: get_slot_out = slot_out0;
                3'd1: get_slot_out = slot_out1;
                3'd2: get_slot_out = slot_out2;
                3'd3: get_slot_out = slot_out3;
                3'd4: get_slot_out = slot_out4;
                3'd5: get_slot_out = slot_out5;
                3'd6: get_slot_out = slot_out6;
                default: get_slot_out = slot_out7;
            endcase
        end
    endfunction

    function [7:0] get_hamming_err_cnt;
        input [2:0] s;
        begin
            case (s)
                3'd0: get_hamming_err_cnt = hamming_err_cnt0;
                3'd1: get_hamming_err_cnt = hamming_err_cnt1;
                3'd2: get_hamming_err_cnt = hamming_err_cnt2;
                3'd3: get_hamming_err_cnt = hamming_err_cnt3;
                3'd4: get_hamming_err_cnt = hamming_err_cnt4;
                3'd5: get_hamming_err_cnt = hamming_err_cnt5;
                3'd6: get_hamming_err_cnt = hamming_err_cnt6;
                default: get_hamming_err_cnt = hamming_err_cnt7;
            endcase
        end
    endfunction

    integer i;

    initial begin
        resetn      = 1'b0;
        in_sig      = 1'b0;
        data_in     = 42'd0;
        slot        = 4'd0;
        clk_cnt     = 11'd500;  // keep away from 1 to avoid err-cnt decrement
        guard_ticks = 10'd100;
        preamble_err = 1'b0;
        enc_data_in = 35'd0;
        pass_cnt = 0; fail_cnt = 0;

        repeat(4) @(negedge clk);
        resetn = 1'b1;
        repeat(2) @(negedge clk);

        // -------------------------------------------------------
        $display("=== Case 1: Normal reception, all 8 slots ===");
        for (i = 0; i < 8; i = i + 1) begin : slot_loop
            reg [34:0] payload;
            reg [31:0] exp_data;
            payload  = {i[2:0], 32'hA5A5_A500 | i[7:0]};
            exp_data = payload[31:0];
            enc_data_in = payload; #1;
            send_frame(enc_codeword);
            if (get_slot_out(i[2:0]) === exp_data) begin
                $display("[PASS] slot%0d normal: data=0x%H", i, get_slot_out(i[2:0]));
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("[FAIL] slot%0d normal: got=0x%H exp=0x%H",
                         i, get_slot_out(i[2:0]), exp_data);
                fail_cnt = fail_cnt + 1;
            end
        end

        // -------------------------------------------------------
        $display("\n=== Case 2: 1-bit error correction (slot 0) ===");
        begin : one_bit
            reg [34:0] payload;
            reg [31:0] exp_data;
            reg [7:0]  cnt_before;
            payload  = {3'd0, 32'hDEAD_BEEF};
            exp_data = payload[31:0];
            enc_data_in = payload; #1;
            cnt_before = hamming_err_cnt0;
            send_frame(enc_codeword ^ (42'd1 << 6'd15)); // flip d[8]: cw[7+8]=cw[15]
            if (slot_out0 === exp_data &&
                hamming_err_cnt0 === cnt_before + 8'd4) begin
                $display("[PASS] 1-bit err corrected: data=0x%H err_cnt=%0d",
                         slot_out0, hamming_err_cnt0);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("[FAIL] 1-bit err: data=0x%H(exp=0x%H) err_cnt=%0d(exp=%0d)",
                         slot_out0, exp_data,
                         hamming_err_cnt0, cnt_before + 8'd4);
                fail_cnt = fail_cnt + 1;
            end
        end

        // -------------------------------------------------------
        $display("\n=== Case 3: 2-bit error - data must be discarded (slot 1) ===");
        begin : two_bit
            reg [34:0] payload;
            reg [31:0] prev_out;
            reg [7:0]  cnt_before;
            payload   = {3'd1, 32'hCAFE_BABE};
            enc_data_in = payload; #1;
            // first send clean frame to set slot_out1
            send_frame(enc_codeword);
            prev_out   = slot_out1;
            cnt_before = hamming_err_cnt1;
            // now send 2-bit error frame
            send_frame(enc_codeword ^ (42'd1 << 6'd10) ^ (42'd1 << 6'd20));
            if (slot_out1 === prev_out &&           // data unchanged
                hamming_err_cnt1 === cnt_before + 8'd8) begin
                $display("[PASS] 2-bit err discarded: slot_out1 unchanged=0x%H cnt=%0d",
                         slot_out1, hamming_err_cnt1);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("[FAIL] 2-bit err: slot_out1=0x%H(prev=0x%H) cnt=%0d(exp=%0d)",
                         slot_out1, prev_out,
                         hamming_err_cnt1, cnt_before + 8'd8);
                fail_cnt = fail_cnt + 1;
            end
        end

        // -------------------------------------------------------
        $display("\n=== Case 4: Slot routing verification ===");
        begin : slot_route
            reg [34:0] payload;
            reg [31:0] exp_data;
            integer j;
            for (j = 0; j < 8; j = j + 1) begin
                payload  = {j[2:0], 32'h1234_0000 | j[7:0]};
                exp_data = payload[31:0];
                enc_data_in = payload; #1;
                send_frame(enc_codeword);
                if (get_slot_out(j[2:0]) === exp_data) begin
                    $display("[PASS] routing: slot%0d got=0x%H", j, get_slot_out(j[2:0]));
                    pass_cnt = pass_cnt + 1;
                end else begin
                    $display("[FAIL] routing: slot%0d got=0x%H exp=0x%H",
                             j, get_slot_out(j[2:0]), exp_data);
                    fail_cnt = fail_cnt + 1;
                end
            end
        end

        $display("\n[DONE] error_and_hamming tb: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display("ALL PASS");
        $finish;
    end

endmodule
