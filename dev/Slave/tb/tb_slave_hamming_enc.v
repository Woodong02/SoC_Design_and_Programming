`timescale 1ns / 1ps

module tb_slave_hamming_enc;

    reg [34:0] data;
    wire [41:0] slave_codeword;
    wire [41:0] master_codeword;

    integer error_count;
    integer test_count;
    integer walk_index;

    slave_hamming_enc u_slave_hamming_enc (
        .i_DATA(data),
        .o_CODEWORD(slave_codeword)
    );

    hamming_enc u_master_hamming_enc (
        .data(data),
        .codeword(master_codeword)
    );

    function [41:0] reference_codeword;
        input [34:0] ref_data;
        reg ref_p0;
        reg ref_p1;
        reg ref_p2;
        reg ref_p3;
        reg ref_p4;
        reg ref_p5;
        reg ref_p_overall;
        begin
            ref_p0 = ref_data[0] ^ ref_data[2] ^ ref_data[4] ^ ref_data[6] ^ ref_data[8] ^ ref_data[10] ^ ref_data[12] ^ ref_data[14]
                   ^ ref_data[16] ^ ref_data[18] ^ ref_data[20] ^ ref_data[22] ^ ref_data[24] ^ ref_data[26] ^ ref_data[28] ^ ref_data[30]
                   ^ ref_data[32] ^ ref_data[34];

            ref_p1 = ref_data[1] ^ ref_data[2] ^ ref_data[5] ^ ref_data[6] ^ ref_data[9] ^ ref_data[10] ^ ref_data[13] ^ ref_data[14]
                   ^ ref_data[17] ^ ref_data[18] ^ ref_data[21] ^ ref_data[22] ^ ref_data[25] ^ ref_data[26] ^ ref_data[29] ^ ref_data[30]
                   ^ ref_data[33] ^ ref_data[34];

            ref_p2 = ref_data[3] ^ ref_data[4] ^ ref_data[5] ^ ref_data[6] ^ ref_data[11] ^ ref_data[12] ^ ref_data[13] ^ ref_data[14]
                   ^ ref_data[19] ^ ref_data[20] ^ ref_data[21] ^ ref_data[22] ^ ref_data[27] ^ ref_data[28] ^ ref_data[29] ^ ref_data[30];

            ref_p3 = ref_data[7] ^ ref_data[8] ^ ref_data[9] ^ ref_data[10] ^ ref_data[11] ^ ref_data[12] ^ ref_data[13] ^ ref_data[14]
                   ^ ref_data[23] ^ ref_data[24] ^ ref_data[25] ^ ref_data[26] ^ ref_data[27] ^ ref_data[28] ^ ref_data[29] ^ ref_data[30];

            ref_p4 = ref_data[15] ^ ref_data[16] ^ ref_data[17] ^ ref_data[18] ^ ref_data[19] ^ ref_data[20] ^ ref_data[21] ^ ref_data[22]
                   ^ ref_data[23] ^ ref_data[24] ^ ref_data[25] ^ ref_data[26] ^ ref_data[27] ^ ref_data[28] ^ ref_data[29] ^ ref_data[30];

            ref_p5 = ref_data[31] ^ ref_data[32] ^ ref_data[33] ^ ref_data[34];

            ref_p_overall = ^{ref_data, ref_p5, ref_p4, ref_p3, ref_p2, ref_p1, ref_p0};
            reference_codeword = {ref_data, ref_p5, ref_p4, ref_p3, ref_p2, ref_p1, ref_p0, ref_p_overall};
        end
    endfunction

    task check_vector;
        input [34:0] vector_data;
        input [127:0] phase_name;
        reg [41:0] expected_codeword;
        begin
            data = vector_data;
            #1;
            expected_codeword = reference_codeword(vector_data);
            test_count = test_count + 1;

            if ((slave_codeword !== expected_codeword) || (slave_codeword !== master_codeword)) begin
                error_count = error_count + 1;
                $display("[FAIL] phase=%0s data=0x%09h", phase_name, vector_data);
                $display("       expected=0x%011h slave=0x%011h master=0x%011h", expected_codeword, slave_codeword, master_codeword);
            end else begin
                $display("[OK]   phase=%0s data=0x%09h codeword=0x%011h", phase_name, vector_data, slave_codeword);
            end
        end
    endtask

    initial begin
        error_count = 0;
        test_count = 0;
        data = 35'd0;

        $display("============================================================");
        $display("tb_slave_hamming_enc: Master-compatible SECDED encoder test");
        $display("============================================================");

        // Phase 1: fixed boundary vectors.
        $display("[PHASE] all-zero / all-one");
        check_vector(35'd0, "all-zero");
        check_vector(35'h7ffffffff, "all-one");

        // Phase 2: every single data position must map through the parity tree.
        $display("[PHASE] walking-one over data[34:0]");
        for (walk_index = 0; walk_index < 35; walk_index = walk_index + 1) begin
            check_vector((35'd1 << walk_index), "walking-one");
        end

        // Phase 3: extra mixed patterns make waveform inspection less repetitive.
        $display("[PHASE] reference parity mixed patterns");
        check_vector(35'h00000aaaa, "mixed-a");
        check_vector(35'h155555555, "mixed-b");
        check_vector(35'h012345678, "mixed-c");
        check_vector(35'h6db6db6db, "mixed-d");

        $display("============================================================");
        if (error_count == 0) begin
            $display("PASS: tb_slave_hamming_enc completed %0d self-checking vectors with 0 mismatches.", test_count);
        end else begin
            $display("FAIL: tb_slave_hamming_enc completed %0d vectors with %0d mismatches.", test_count, error_count);
        end
        $display("============================================================");

        #1;
        $finish;
    end

endmodule
