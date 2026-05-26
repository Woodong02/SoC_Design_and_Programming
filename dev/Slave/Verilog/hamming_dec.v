// hamming_dec: Systematic Hamming [42,35] decoder with SECDED
// codeword[41:0] = { data[34:0], p[5:0], p_overall }
//   codeword[41:7] = d_rx[34:0]
//   codeword[6:1]  = p_rx[5:0]  (p_rx[5]=cw[6], p_rx[0]=cw[1])
//   codeword[0]    = p_overall_rx
//
// syndrome[k] = p_rx[k] ^ p_recomp[k]  (same XOR tree as encoder, on rx data)
// all_xor      = ^codeword[41:0]
//
// Error judgment:
//   syndrome==0, all_xor==0  -> no error
//   syndrome!=0, all_xor==1  -> 1-bit error: flip data[syndrome-1] if syndrome in 1..35
//   syndrome!=0, all_xor==0  -> 2-bit error: ham_2bit_err (data invalid)
//   syndrome==0, all_xor==1  -> p_overall itself wrong (data valid, counted as 1-bit)
module hamming_dec (
    input  wire [41:0] codeword,
    output wire [34:0] data,
    output wire        ham_1bit_err,
    output wire        ham_2bit_err
);

    wire [34:0] d_rx = codeword[41:7];
    wire [5:0]  p_rx = codeword[6:1];   // p_rx[5]=cw[6] .. p_rx[0]=cw[1]

    // recompute parity from received data bits (same formulas as encoder)
    wire pr0 = d_rx[0] ^d_rx[2] ^d_rx[4] ^d_rx[6] ^d_rx[8] ^d_rx[10]^d_rx[12]^d_rx[14]
              ^d_rx[16]^d_rx[18]^d_rx[20]^d_rx[22]^d_rx[24]^d_rx[26]^d_rx[28]^d_rx[30]
              ^d_rx[32]^d_rx[34];

    wire pr1 = d_rx[1] ^d_rx[2] ^d_rx[5] ^d_rx[6] ^d_rx[9] ^d_rx[10]^d_rx[13]^d_rx[14]
              ^d_rx[17]^d_rx[18]^d_rx[21]^d_rx[22]^d_rx[25]^d_rx[26]^d_rx[29]^d_rx[30]
              ^d_rx[33]^d_rx[34];

    wire pr2 = d_rx[3] ^d_rx[4] ^d_rx[5] ^d_rx[6] ^d_rx[11]^d_rx[12]^d_rx[13]^d_rx[14]
              ^d_rx[19]^d_rx[20]^d_rx[21]^d_rx[22]^d_rx[27]^d_rx[28]^d_rx[29]^d_rx[30];

    wire pr3 = d_rx[7] ^d_rx[8] ^d_rx[9] ^d_rx[10]^d_rx[11]^d_rx[12]^d_rx[13]^d_rx[14]
              ^d_rx[23]^d_rx[24]^d_rx[25]^d_rx[26]^d_rx[27]^d_rx[28]^d_rx[29]^d_rx[30];

    wire pr4 = d_rx[15]^d_rx[16]^d_rx[17]^d_rx[18]^d_rx[19]^d_rx[20]^d_rx[21]^d_rx[22]
              ^d_rx[23]^d_rx[24]^d_rx[25]^d_rx[26]^d_rx[27]^d_rx[28]^d_rx[29]^d_rx[30];

    wire pr5 = d_rx[31]^d_rx[32]^d_rx[33]^d_rx[34];

    wire [5:0] syndrome = {p_rx[5]^pr5, p_rx[4]^pr4, p_rx[3]^pr3,
                           p_rx[2]^pr2, p_rx[1]^pr1, p_rx[0]^pr0};

    wire all_xor = ^codeword;   // XOR of all 42 bits; 0 in valid codeword

    assign ham_1bit_err = (syndrome != 6'd0) & all_xor;
    assign ham_2bit_err = (syndrome != 6'd0) & ~all_xor;

    // single-bit correction: flip d_rx[syndrome-1] when syndrome in 1..35 and 1-bit error
    reg [34:0] corrected;
    integer    gi;
    always @(*) begin
        corrected = d_rx;
        if (ham_1bit_err && (syndrome >= 6'd1) && (syndrome <= 6'd35))
            corrected[syndrome - 1] = ~d_rx[syndrome - 1];
    end

    assign data = corrected;

endmodule
