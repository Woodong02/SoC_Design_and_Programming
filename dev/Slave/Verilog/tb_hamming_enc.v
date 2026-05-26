`timescale 1ns / 1ps

module tb_hamming_enc;

    reg  [34:0] data_in;
    wire [41:0] codeword;

    hamming_enc uut (.data(data_in), .codeword(codeword));

    // ----------------------------------------------------------------
    // Reference parity calculation (matches hamming_enc formulas)
    // ----------------------------------------------------------------
    function [6:0] ref_parity;
        input [34:0] d;
        reg p0,p1,p2,p3,p4,p5,pov;
        begin
            p0 = d[0]^d[2]^d[4]^d[6]^d[8]^d[10]^d[12]^d[14]
                ^d[16]^d[18]^d[20]^d[22]^d[24]^d[26]^d[28]^d[30]
                ^d[32]^d[34];
            p1 = d[1]^d[2]^d[5]^d[6]^d[9]^d[10]^d[13]^d[14]
                ^d[17]^d[18]^d[21]^d[22]^d[25]^d[26]^d[29]^d[30]
                ^d[33]^d[34];
            p2 = d[3]^d[4]^d[5]^d[6]^d[11]^d[12]^d[13]^d[14]
                ^d[19]^d[20]^d[21]^d[22]^d[27]^d[28]^d[29]^d[30];
            p3 = d[7]^d[8]^d[9]^d[10]^d[11]^d[12]^d[13]^d[14]
                ^d[23]^d[24]^d[25]^d[26]^d[27]^d[28]^d[29]^d[30];
            p4 = d[15]^d[16]^d[17]^d[18]^d[19]^d[20]^d[21]^d[22]
                ^d[23]^d[24]^d[25]^d[26]^d[27]^d[28]^d[29]^d[30];
            p5 = d[31]^d[32]^d[33]^d[34];
            pov = ^{d, p5, p4, p3, p2, p1, p0};
            ref_parity = {p5, p4, p3, p2, p1, p0, pov};
        end
    endfunction

    integer pass_cnt, fail_cnt;

    task check;
        input [34:0] d;
        input [63:0] label;
        reg [6:0]  exp_p;
        reg [41:0] exp_cw;
        begin
            data_in = d;
            #1;
            exp_p  = ref_parity(d);
            exp_cw = {d, exp_p[6:1], exp_p[0]};   // {data, p[5:0], p_overall}
            if (codeword === exp_cw) begin
                $display("[PASS] %s", label);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("[FAIL] %s", label);
                $display("  data    = 35'h%H", d);
                $display("  exp cw  = 42'h%H", exp_cw);
                $display("  got cw  = 42'h%H", codeword);
                fail_cnt = fail_cnt + 1;
            end
            // always verify even overall parity
            if (^codeword !== 1'b0) begin
                $display("[FAIL] %s: overall parity not 0 (got ^cw=%b)", label, ^codeword);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    integer i;

    initial begin
        data_in  = 35'd0;
        pass_cnt = 0; fail_cnt = 0;
        #5;

        check(35'h000000000, "all-zeros");
        check(35'h7FFFFFFFF, "all-ones");
        check(35'h000000001, "d[0]=1 only");
        check(35'h200000000, "d[34]=1 only (MSB)");
        check(35'h155555555, "alternating 01 pattern");
        check(35'h2AAAAAAAA, "alternating 10 pattern");
        check(35'h0DEADBEEF, "DEADBEEF-like");
        check(35'h1A5A5A5A5, "A5A5 pattern");

        // single-bit walks: each d[i]=1, rest 0
        for (i = 0; i < 35; i = i + 1) begin
            check(35'd1 << i, "single-bit walk");
        end

        $display("\n[DONE] hamming_enc: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display("ALL PASS");
        $finish;
    end

endmodule
