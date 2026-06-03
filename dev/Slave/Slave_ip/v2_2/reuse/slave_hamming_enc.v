`timescale 1ns / 1ps

// slave_hamming_enc: Master-compatible systematic Hamming [42,35] SECDED encoder.
// codeword[41:0] = {i_DATA[34:0], p[5:0], p_overall}
module slave_hamming_enc (
    input  wire [34:0] i_DATA,
    output wire [41:0] o_CODEWORD
);

    wire [34:0] data;
    wire parity_0;
    wire parity_1;
    wire parity_2;
    wire parity_3;
    wire parity_4;
    wire parity_5;
    wire parity_overall;
    wire [41:0] codeword;

    assign data = i_DATA;

    assign parity_0 = data[0] ^ data[2] ^ data[4] ^ data[6] ^ data[8] ^ data[10] ^ data[12] ^ data[14]
                    ^ data[16] ^ data[18] ^ data[20] ^ data[22] ^ data[24] ^ data[26] ^ data[28] ^ data[30]
                    ^ data[32] ^ data[34];

    assign parity_1 = data[1] ^ data[2] ^ data[5] ^ data[6] ^ data[9] ^ data[10] ^ data[13] ^ data[14]
                    ^ data[17] ^ data[18] ^ data[21] ^ data[22] ^ data[25] ^ data[26] ^ data[29] ^ data[30]
                    ^ data[33] ^ data[34];

    assign parity_2 = data[3] ^ data[4] ^ data[5] ^ data[6] ^ data[11] ^ data[12] ^ data[13] ^ data[14]
                    ^ data[19] ^ data[20] ^ data[21] ^ data[22] ^ data[27] ^ data[28] ^ data[29] ^ data[30];

    assign parity_3 = data[7] ^ data[8] ^ data[9] ^ data[10] ^ data[11] ^ data[12] ^ data[13] ^ data[14]
                    ^ data[23] ^ data[24] ^ data[25] ^ data[26] ^ data[27] ^ data[28] ^ data[29] ^ data[30];

    assign parity_4 = data[15] ^ data[16] ^ data[17] ^ data[18] ^ data[19] ^ data[20] ^ data[21] ^ data[22]
                    ^ data[23] ^ data[24] ^ data[25] ^ data[26] ^ data[27] ^ data[28] ^ data[29] ^ data[30];

    assign parity_5 = data[31] ^ data[32] ^ data[33] ^ data[34];

    assign parity_overall = ^{data, parity_5, parity_4, parity_3, parity_2, parity_1, parity_0};

    assign codeword = {data, parity_5, parity_4, parity_3, parity_2, parity_1, parity_0, parity_overall};

    assign o_CODEWORD = codeword;

endmodule
