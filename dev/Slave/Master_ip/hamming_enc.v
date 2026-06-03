`timescale 1ns / 1ps

// hamming_enc: Systematic Hamming [42,35] encoder with overall parity (SECDED)
// codeword[41:0] = { data[34:0], p[5:0], p_overall }
//   codeword[41:7] = data[34:0]
//   codeword[6:1]  = { p[5], p[4], p[3], p[2], p[1], p[0] }
//   codeword[0]    = p_overall  (XOR of all 41 bits above)
//
// Parity coverage (position = d-index + 1):
//   p[0]: positions where bit0=1  -> d[0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32,34]
//   p[1]: positions where bit1=1  -> d[1,2,5,6,9,10,13,14,17,18,21,22,25,26,29,30,33,34]
//   p[2]: positions where bit2=1  -> d[3,4,5,6,11,12,13,14,19,20,21,22,27,28,29,30]
//   p[3]: positions where bit3=1  -> d[7,8,9,10,11,12,13,14,23,24,25,26,27,28,29,30]
//   p[4]: positions where bit4=1  -> d[15..30]
//   p[5]: positions where bit5=1  -> d[31,32,33,34]
module hamming_enc (
    input  wire [34:0] data,
    output wire [41:0] codeword
);

    wire p0 = data[0] ^data[2] ^data[4] ^data[6] ^data[8] ^data[10]^data[12]^data[14]
             ^data[16]^data[18]^data[20]^data[22]^data[24]^data[26]^data[28]^data[30]
             ^data[32]^data[34];

    wire p1 = data[1] ^data[2] ^data[5] ^data[6] ^data[9] ^data[10]^data[13]^data[14]
             ^data[17]^data[18]^data[21]^data[22]^data[25]^data[26]^data[29]^data[30]
             ^data[33]^data[34];

    wire p2 = data[3] ^data[4] ^data[5] ^data[6] ^data[11]^data[12]^data[13]^data[14]
             ^data[19]^data[20]^data[21]^data[22]^data[27]^data[28]^data[29]^data[30];

    wire p3 = data[7] ^data[8] ^data[9] ^data[10]^data[11]^data[12]^data[13]^data[14]
             ^data[23]^data[24]^data[25]^data[26]^data[27]^data[28]^data[29]^data[30];

    wire p4 = data[15]^data[16]^data[17]^data[18]^data[19]^data[20]^data[21]^data[22]
             ^data[23]^data[24]^data[25]^data[26]^data[27]^data[28]^data[29]^data[30];

    wire p5 = data[31]^data[32]^data[33]^data[34];

    wire p_overall = ^{data, p5, p4, p3, p2, p1, p0};

    assign codeword = {data, p5, p4, p3, p2, p1, p0, p_overall};

endmodule
