`timescale 1ns / 1ps

// slave_hamming_dec: Master-compatible systematic Hamming [42,35] SECDED decoder.
module slave_hamming_dec (
    input  wire [41:0] i_CODEWORD,
    output wire [34:0] o_DATA,
    output wire        o_HAM_1BIT_ERR,
    output wire        o_HAM_2BIT_ERR
);

    wire [41:0] codeword;
    wire [34:0] received_data;
    wire [5:0] received_parity;
    wire parity_recalc_0;
    wire parity_recalc_1;
    wire parity_recalc_2;
    wire parity_recalc_3;
    wire parity_recalc_4;
    wire parity_recalc_5;
    wire [5:0] syndrome;
    wire all_xor;
    wire ham_1bit_err;
    wire ham_2bit_err;
    reg  [34:0] corrected_data;
    wire [34:0] output_data;

    assign codeword = i_CODEWORD;

    assign received_data = codeword[41:7];
    assign received_parity = codeword[6:1];

    assign parity_recalc_0 = received_data[0] ^received_data[2] ^received_data[4] ^received_data[6]
                           ^ received_data[8] ^received_data[10]^received_data[12]^received_data[14]
                           ^ received_data[16]^received_data[18]^received_data[20]^received_data[22]
                           ^ received_data[24]^received_data[26]^received_data[28]^received_data[30]
                           ^ received_data[32]^received_data[34];

    assign parity_recalc_1 = received_data[1] ^received_data[2] ^received_data[5] ^received_data[6]
                           ^ received_data[9] ^received_data[10]^received_data[13]^received_data[14]
                           ^ received_data[17]^received_data[18]^received_data[21]^received_data[22]
                           ^ received_data[25]^received_data[26]^received_data[29]^received_data[30]
                           ^ received_data[33]^received_data[34];

    assign parity_recalc_2 = received_data[3] ^received_data[4] ^received_data[5] ^received_data[6]
                           ^ received_data[11]^received_data[12]^received_data[13]^received_data[14]
                           ^ received_data[19]^received_data[20]^received_data[21]^received_data[22]
                           ^ received_data[27]^received_data[28]^received_data[29]^received_data[30];

    assign parity_recalc_3 = received_data[7] ^received_data[8] ^received_data[9] ^received_data[10]
                           ^ received_data[11]^received_data[12]^received_data[13]^received_data[14]
                           ^ received_data[23]^received_data[24]^received_data[25]^received_data[26]
                           ^ received_data[27]^received_data[28]^received_data[29]^received_data[30];

    assign parity_recalc_4 = received_data[15]^received_data[16]^received_data[17]^received_data[18]
                           ^ received_data[19]^received_data[20]^received_data[21]^received_data[22]
                           ^ received_data[23]^received_data[24]^received_data[25]^received_data[26]
                           ^ received_data[27]^received_data[28]^received_data[29]^received_data[30];

    assign parity_recalc_5 = received_data[31]^received_data[32]^received_data[33]^received_data[34];

    assign syndrome = {received_parity[5] ^ parity_recalc_5,
                       received_parity[4] ^ parity_recalc_4,
                       received_parity[3] ^ parity_recalc_3,
                       received_parity[2] ^ parity_recalc_2,
                       received_parity[1] ^ parity_recalc_1,
                       received_parity[0] ^ parity_recalc_0};

    assign all_xor = ^codeword;
    assign ham_1bit_err = (syndrome != 6'd0) & all_xor;
    assign ham_2bit_err = (syndrome != 6'd0) & ~all_xor;

    always @(*) begin
        corrected_data = received_data;
        if (ham_1bit_err && (syndrome >= 6'd1) && (syndrome <= 6'd35)) begin
            // Match Master source: these syndrome values are treated as parity-bit errors.
            if (syndrome != 6'd1  && syndrome != 6'd2  && syndrome != 6'd4 &&
                syndrome != 6'd8  && syndrome != 6'd16 && syndrome != 6'd32) begin
                corrected_data[syndrome - 1] = ~received_data[syndrome - 1];
            end
        end
    end

    assign output_data = corrected_data;

    assign o_DATA = output_data;
    assign o_HAM_1BIT_ERR = ham_1bit_err;
    assign o_HAM_2BIT_ERR = ham_2bit_err;

endmodule
