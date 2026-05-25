// master_tx: NRZ transmitter for TDMA master broadcast
// Bit period = 2*(div+1) clk cycles (same as slave_tx)
// Frame: [preamble 8b = 0xAA][halt_cmd 8b][reserved 27b][hamming 7b] = 50 bits
// Hamming covers 35-bit data = {halt_cmd[7:0], 27'b0}
// tx_line is driven high/low while active; released (high-Z) when idle.
module master_tx (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [9:0]  div,
    input  wire        tx_trigger,
    input  wire        tx_enable,
    input  wire [7:0]  halt_cmd,

    output wire        tx_line,
    output reg         tx_active,
    output reg         data_sent
);

    reg [49:0] frame;
    reg [5:0]  bit_cnt;
    reg [10:0] tx_cnt;
    reg        tx_bit;

    wire [10:0] cnt_max = {div, 1'b1}; // 2*DIV+1

    // ----------------------------------------------------------------
    // Hamming SEC-DED generation (combinatorial)
    // d[34:0] = {halt_cmd[7:0], 27'b0}
    // Same position mapping as slave_tx; data bits 13..41 are all zero.
    // ----------------------------------------------------------------
    wire [34:0] d = {halt_cmd, 27'b0};

    wire p1 = d[34]^d[33]^d[31]^d[30]^d[28]^d[26]^d[24]^d[23]
             ^d[21]^d[19]^d[17]^d[15]^d[13]^d[11]^d[9] ^d[8]
             ^d[6] ^d[4] ^d[2] ^d[0];

    wire p2 = d[34]^d[32]^d[31]^d[29]^d[28]^d[25]^d[24]^d[22]
             ^d[21]^d[18]^d[17]^d[14]^d[13]^d[10]^d[9] ^d[7]
             ^d[6] ^d[3] ^d[2];

    wire p4 = d[33]^d[32]^d[31]^d[27]^d[26]^d[25]^d[24]^d[20]
             ^d[19]^d[18]^d[17]^d[12]^d[11]^d[10]^d[9] ^d[5]
             ^d[4] ^d[3] ^d[2];

    wire p8 = d[30]^d[29]^d[28]^d[27]^d[26]^d[25]^d[24]^d[16]
             ^d[15]^d[14]^d[13]^d[12]^d[11]^d[10]^d[9] ^d[1]
             ^d[0];

    wire p16 = d[23]^d[22]^d[21]^d[20]^d[19]^d[18]^d[17]^d[16]
              ^d[15]^d[14]^d[13]^d[12]^d[11]^d[10]^d[9];

    wire p32 = d[8]^d[7]^d[6]^d[5]^d[4]^d[3]^d[2]^d[1]^d[0];

    wire [40:0] codeword41;
    assign codeword41[0]  = p1;    assign codeword41[1]  = p2;
    assign codeword41[2]  = d[34]; assign codeword41[3]  = p4;
    assign codeword41[4]  = d[33]; assign codeword41[5]  = d[32];
    assign codeword41[6]  = d[31]; assign codeword41[7]  = p8;
    assign codeword41[8]  = d[30]; assign codeword41[9]  = d[29];
    assign codeword41[10] = d[28]; assign codeword41[11] = d[27];
    assign codeword41[12] = d[26]; assign codeword41[13] = d[25];
    assign codeword41[14] = d[24]; assign codeword41[15] = p16;
    assign codeword41[16] = d[23]; assign codeword41[17] = d[22];
    assign codeword41[18] = d[21]; assign codeword41[19] = d[20];
    assign codeword41[20] = d[19]; assign codeword41[21] = d[18];
    assign codeword41[22] = d[17]; assign codeword41[23] = d[16];
    assign codeword41[24] = d[15]; assign codeword41[25] = d[14];
    assign codeword41[26] = d[13]; assign codeword41[27] = d[12];
    assign codeword41[28] = d[11]; assign codeword41[29] = d[10];
    assign codeword41[30] = d[9];  assign codeword41[31] = p32;
    assign codeword41[32] = d[8];  assign codeword41[33] = d[7];
    assign codeword41[34] = d[6];  assign codeword41[35] = d[5];
    assign codeword41[36] = d[4];  assign codeword41[37] = d[3];
    assign codeword41[38] = d[2];  assign codeword41[39] = d[1];
    assign codeword41[40] = d[0];

    wire p_overall = ^codeword41;
    wire [6:0] hamming = {p1, p2, p4, p8, p16, p32, p_overall};

    // ----------------------------------------------------------------
    // tx counter and frame shift register
    // ----------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_cnt   <= 11'd0;
            bit_cnt  <= 6'd0;
            tx_active<= 1'b0;
            data_sent<= 1'b0;
            frame    <= 50'd0;
            tx_bit   <= 1'b0;
        end else begin
            data_sent <= 1'b0;

            if (!tx_active) begin
                tx_cnt  <= 11'd0;
                bit_cnt <= 6'd0;
                if (tx_trigger && tx_enable) begin
                    frame     <= {8'hAA, halt_cmd, 27'b0, hamming};
                    tx_active <= 1'b1;
                    tx_bit    <= 1'b1; // preamble MSB of 0xAA = 1
                end
            end else begin
                if (tx_cnt == cnt_max) begin
                    tx_cnt <= 11'd0;
                    if (bit_cnt == 6'd49) begin
                        tx_active <= 1'b0;
                        data_sent <= 1'b1;
                        tx_bit    <= 1'b0;
                    end else begin
                        bit_cnt <= bit_cnt + 6'd1;
                        tx_bit  <= frame[49 - (bit_cnt + 6'd1)];
                    end
                end else begin
                    tx_cnt <= tx_cnt + 11'd1;
                end
            end
        end
    end

    assign tx_line = (tx_active && tx_enable) ? tx_bit : 1'bz;

endmodule
