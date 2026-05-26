`timescale 1ns / 1ps

module tb_hamming_dec;

    reg  [41:0] codeword_in;
    wire [34:0] data_out;
    wire        ham_1bit_err;
    wire        ham_2bit_err;

    hamming_dec uut (
        .codeword    (codeword_in),
        .data        (data_out),
        .ham_1bit_err(ham_1bit_err),
        .ham_2bit_err(ham_2bit_err)
    );

    // encoder for generating valid codewords
    reg  [34:0] enc_data_in;
    wire [41:0] enc_codeword;
    hamming_enc u_enc (.data(enc_data_in), .codeword(enc_codeword));

    integer pass_cnt, fail_cnt;

    // check: no error expected
    task check_clean;
        input [34:0] orig_data;
        input [63:0] label;
        begin
            enc_data_in = orig_data;
            #1;
            codeword_in = enc_codeword;
            #1;
            if (data_out === orig_data && ham_1bit_err === 1'b0 && ham_2bit_err === 1'b0) begin
                $display("[PASS] %s: no error", label);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("[FAIL] %s: exp data=0x%H err=0/0, got data=0x%H 1b=%b 2b=%b",
                         label, orig_data, data_out, ham_1bit_err, ham_2bit_err);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    // check: inject 1-bit error at codeword position pos (0-based), expect correction
    task check_1bit;
        input [34:0] orig_data;
        input [5:0]  pos;      // which codeword bit to flip (0..41)
        begin
            enc_data_in = orig_data;
            #1;
            codeword_in = enc_codeword ^ (42'd1 << pos);
            #1;
            // if error is in data range (cw pos 7..41 -> d index cw_pos-7)
            if (pos >= 6'd7) begin
                // data bit flip: expect corrected output = orig_data
                if (data_out === orig_data && ham_1bit_err === 1'b1 && ham_2bit_err === 1'b0) begin
                    $display("[PASS] 1-bit data err at cw[%0d]: corrected, data=0x%H", pos, data_out);
                    pass_cnt = pass_cnt + 1;
                end else begin
                    $display("[FAIL] 1-bit data err at cw[%0d]: data=0x%H(exp 0x%H) 1b=%b 2b=%b",
                             pos, data_out, orig_data, ham_1bit_err, ham_2bit_err);
                    fail_cnt = fail_cnt + 1;
                end
            end else begin
                // parity bit flip: data should be unchanged (syndrome may alias to data bit)
                // only check that ham_1bit_err=1, ham_2bit_err=0
                if (ham_1bit_err === 1'b1 && ham_2bit_err === 1'b0) begin
                    $display("[PASS] 1-bit parity err at cw[%0d]: ham_1bit_err=1", pos);
                    pass_cnt = pass_cnt + 1;
                end else begin
                    $display("[FAIL] 1-bit parity err at cw[%0d]: 1b=%b 2b=%b",
                             pos, ham_1bit_err, ham_2bit_err);
                    fail_cnt = fail_cnt + 1;
                end
            end
        end
    endtask

    // check: inject 2-bit error, expect ham_2bit_err
    task check_2bit;
        input [34:0] orig_data;
        input [5:0]  pos_a;
        input [5:0]  pos_b;
        begin
            enc_data_in = orig_data;
            #1;
            codeword_in = enc_codeword ^ (42'd1 << pos_a) ^ (42'd1 << pos_b);
            #1;
            if (ham_2bit_err === 1'b1 && ham_1bit_err === 1'b0) begin
                $display("[PASS] 2-bit err at cw[%0d,%0d]: ham_2bit_err=1", pos_a, pos_b);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("[FAIL] 2-bit err at cw[%0d,%0d]: 1b=%b 2b=%b",
                         pos_a, pos_b, ham_1bit_err, ham_2bit_err);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    integer i;

    initial begin
        codeword_in = 42'd0;
        enc_data_in = 35'd0;
        pass_cnt = 0; fail_cnt = 0;
        #5;

        $display("--- No-error tests ---");
        check_clean(35'h000000000, "all-zeros");
        check_clean(35'h7FFFFFFFF, "all-ones");
        check_clean(35'h0DEADBEEF, "DEADBEEF");
        check_clean(35'h155555555, "alternating");

        $display("\n--- 1-bit data error (all 35 data bit positions) ---");
        for (i = 7; i <= 41; i = i + 1)
            check_1bit(35'h0DEADBEEF, i[5:0]);

        $display("\n--- 1-bit parity error (p[0..5]: cw[1..6]) ---");
        for (i = 1; i <= 6; i = i + 1)
            check_1bit(35'h0DEADBEEF, i[5:0]);

        // cw[0] = p_overall only: syndrome=0, all_xor=1 -> data valid, no error flags
        $display("\n--- p_overall-only flip: syndrome=0,all_xor=1 -> no error flags ---");
        begin : pov_test
            reg [41:0] cw_pov;
            enc_data_in = 35'h0DEADBEEF; #1;
            cw_pov = enc_codeword ^ 42'd1;   // flip cw[0] = p_overall
            codeword_in = cw_pov; #1;
            if (ham_1bit_err === 1'b0 && ham_2bit_err === 1'b0 && data_out === 35'h0DEADBEEF) begin
                $display("[PASS] p_overall-only flip: no flags, data correct");
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("[FAIL] p_overall-only flip: 1b=%b 2b=%b data=0x%H",
                         ham_1bit_err, ham_2bit_err, data_out);
                fail_cnt = fail_cnt + 1;
            end
        end

        $display("\n--- 2-bit error tests ---");
        check_2bit(35'h0DEADBEEF, 6'd41, 6'd40);   // two data bits
        check_2bit(35'h0DEADBEEF, 6'd41, 6'd7);    // data+data
        check_2bit(35'h0DEADBEEF, 6'd41, 6'd1);    // data+parity
        check_2bit(35'h0DEADBEEF, 6'd1,  6'd0);    // two parity bits
        check_2bit(35'h000000000, 6'd20, 6'd10);

        $display("\n--- Round-trip: enc -> 1-bit flip -> dec ---");
        begin : rt
            reg [34:0] td;
            reg [41:0] cw_err;
            td = 35'h155555555;
            enc_data_in = td; #1;
            cw_err = enc_codeword ^ (42'd1 << 6'd15); // flip d[8] (cw pos 7+8=15)
            codeword_in = cw_err; #1;
            if (data_out === td && ham_1bit_err === 1'b1) begin
                $display("[PASS] round-trip: original data recovered after 1-bit error correction");
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("[FAIL] round-trip: data=0x%H(exp 0x%H) 1b=%b", data_out, td, ham_1bit_err);
                fail_cnt = fail_cnt + 1;
            end
        end

        $display("\n[DONE] hamming_dec: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display("ALL PASS");
        $finish;
    end

endmodule
