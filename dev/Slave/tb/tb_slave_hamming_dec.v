module tb_slave_hamming_dec;

    reg  [34:0] data_in;
    wire [41:0] encoded_codeword;
    reg  [41:0] test_codeword;
    wire [34:0] slave_data;
    wire        slave_ham_1bit_err;
    wire        slave_ham_2bit_err;
    wire [34:0] ref_data;
    wire        ref_ham_1bit_err;
    wire        ref_ham_2bit_err;

    integer error_count;
    integer check_count;
    integer data_index;
    integer codeword_index;
    integer sample_index;

    hamming_enc u_ref_enc (
        .data(data_in),
        .codeword(encoded_codeword)
    );

    hamming_dec u_ref_dec (
        .codeword(test_codeword),
        .data(ref_data),
        .ham_1bit_err(ref_ham_1bit_err),
        .ham_2bit_err(ref_ham_2bit_err)
    );

    slave_hamming_dec u_dut (
        .i_CODEWORD(test_codeword),
        .o_DATA(slave_data),
        .o_HAM_1BIT_ERR(slave_ham_1bit_err),
        .o_HAM_2BIT_ERR(slave_ham_2bit_err)
    );

    task set_data_and_codeword;
        input [34:0] next_data;
        begin
            data_in = next_data;
            #1;
            test_codeword = encoded_codeword;
            #1;
        end
    endtask

    task check_against_reference;
        input [8*80-1:0] phase_name;
        begin
            check_count = check_count + 1;
            if (slave_data !== ref_data ||
                slave_ham_1bit_err !== ref_ham_1bit_err ||
                slave_ham_2bit_err !== ref_ham_2bit_err) begin
                error_count = error_count + 1;
                $display("[FAIL][REF] %0s", phase_name);
                $display("       codeword=%042b", test_codeword);
                $display("       slave data=%035b 1bit=%0b 2bit=%0b",
                         slave_data, slave_ham_1bit_err, slave_ham_2bit_err);
                $display("       ref   data=%035b 1bit=%0b 2bit=%0b",
                         ref_data, ref_ham_1bit_err, ref_ham_2bit_err);
            end
            else begin
                $display("[PASS][REF] %0s", phase_name);
            end
        end
    endtask

    task check_expected;
        input [8*80-1:0] phase_name;
        input [34:0] expected_data;
        input        expected_1bit;
        input        expected_2bit;
        begin
            check_against_reference(phase_name);
            if (slave_data !== expected_data ||
                slave_ham_1bit_err !== expected_1bit ||
                slave_ham_2bit_err !== expected_2bit) begin
                error_count = error_count + 1;
                $display("[FAIL][EXP] %0s", phase_name);
                $display("       expected data=%035b 1bit=%0b 2bit=%0b",
                         expected_data, expected_1bit, expected_2bit);
                $display("       actual   data=%035b 1bit=%0b 2bit=%0b",
                         slave_data, slave_ham_1bit_err, slave_ham_2bit_err);
            end
            else begin
                $display("[PASS][EXP] %0s", phase_name);
            end
        end
    endtask

    task run_no_error_case;
        input [34:0] sample_data;
        begin
            set_data_and_codeword(sample_data);
            $display("");
            $display("PHASE no-error data=%035b", sample_data);
            check_expected("no-error", sample_data, 1'b0, 1'b0);
        end
    endtask

    task run_correctable_data_case;
        input [34:0] sample_data;
        input integer bit_index;
        begin
            set_data_and_codeword(sample_data);
            test_codeword[bit_index + 7] = ~test_codeword[bit_index + 7];
            #1;
            $display("");
            $display("PHASE data 1-bit correction data_index=%0d", bit_index);
            check_expected("data 1-bit correction", sample_data, 1'b1, 1'b0);
        end
    endtask

    task run_parity_bit_case;
        input [34:0] sample_data;
        input integer parity_codeword_index;
        begin
            set_data_and_codeword(sample_data);
            test_codeword[parity_codeword_index] = ~test_codeword[parity_codeword_index];
            #1;
            $display("");
            $display("PHASE parity bit 1-bit codeword_index=%0d", parity_codeword_index);
            check_expected("parity bit 1-bit", sample_data, 1'b1, 1'b0);
        end
    endtask

    task run_overall_parity_case;
        input [34:0] sample_data;
        begin
            set_data_and_codeword(sample_data);
            test_codeword[0] = ~test_codeword[0];
            #1;
            $display("");
            $display("PHASE overall parity 1-bit");
            check_expected("overall parity 1-bit", sample_data, 1'b0, 1'b0);
        end
    endtask

    task run_2bit_detection_case;
        input [34:0] sample_data;
        begin
            set_data_and_codeword(sample_data);
            test_codeword[9] = ~test_codeword[9];
            test_codeword[10] = ~test_codeword[10];
            #1;
            $display("");
            $display("PHASE 2-bit detection");
            check_against_reference("2-bit detection reference");
            if (slave_ham_1bit_err !== 1'b0 || slave_ham_2bit_err !== 1'b1) begin
                error_count = error_count + 1;
                $display("[FAIL][EXP] 2-bit detection flags actual 1bit=%0b 2bit=%0b",
                         slave_ham_1bit_err, slave_ham_2bit_err);
            end
            else begin
                $display("[PASS][EXP] 2-bit detection flags");
            end
        end
    endtask

    task run_reference_walk_case;
        input [34:0] sample_data;
        begin
            set_data_and_codeword(sample_data);
            $display("");
            $display("PHASE reference behavior walking single-bit errors");
            for (codeword_index = 0; codeword_index < 42; codeword_index = codeword_index + 1) begin
                set_data_and_codeword(sample_data);
                test_codeword[codeword_index] = ~test_codeword[codeword_index];
                #1;
                check_against_reference("walking single-bit reference compare");
            end
        end
    endtask

    initial begin
        error_count = 0;
        check_count = 0;
        data_in = 35'd0;
        test_codeword = 42'd0;
        data_index = 0;
        codeword_index = 0;
        sample_index = 0;

        $display("============================================================");
        $display("tb_slave_hamming_dec start");
        $display("Master-compatible SECDED decoder self-check");
        $display("============================================================");

        run_no_error_case(35'd0);
        run_no_error_case(35'h7FFFFFFFF);
        run_no_error_case(35'h155555555);
        run_no_error_case(35'h0A5A5A5A5);

        run_correctable_data_case(35'h012345678, 2);
        run_correctable_data_case(35'h155555555, 5);
        run_correctable_data_case(35'h0A5A5A5A5, 14);
        run_correctable_data_case(35'h1FFFFFFFF, 34);

        run_parity_bit_case(35'h012345678, 1);
        run_parity_bit_case(35'h012345678, 2);
        run_parity_bit_case(35'h012345678, 4);
        run_parity_bit_case(35'h012345678, 6);

        run_overall_parity_case(35'h012345678);

        run_2bit_detection_case(35'h012345678);
        run_2bit_detection_case(35'h155555555);

        run_reference_walk_case(35'h012345678);
        run_reference_walk_case(35'h155555555);

        $display("");
        $display("============================================================");
        if (error_count == 0) begin
            $display("PASS: tb_slave_hamming_dec completed %0d checks with no errors", check_count);
        end
        else begin
            $display("FAIL: tb_slave_hamming_dec completed %0d checks with %0d errors",
                     check_count, error_count);
        end
        $display("============================================================");
        $finish;
    end

endmodule
