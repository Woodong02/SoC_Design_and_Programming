// slave_tx: NRZ transmitter for TDMA slave
// Bit period = 2*(div+1) clk cycles (same as master_rx)
// Frame: [preamble 8b = 0xAA][addr 3b][payload 32b][hamming 7b] = 50 bits
// Hamming sent order: p1, p2, p4, p8, p16, p32, p_overall (p1 first = MSB in frame)
module slave_tx (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [9:0]  div,
    input  wire        tx_trigger,
    input  wire        tx_enable,
    input  wire [2:0]  slave_addr,
    input  wire [31:0] tx_data,

    output wire        rx_line,
    output reg         tx_active,
    output reg         data_sent
);

    reg [49:0] frame;
    reg [5:0]  bit_cnt;
    reg [10:0] tx_cnt;
    reg        tx_bit;

    wire [10:0] cnt_max = {div, 1'b1}; // 2*DIV+1 (period = 2*(DIV+1))

    // ----------------------------------------------------------------
    // Hamming SEC-DED generation (combinatorial)
    // Input: 35-bit data = {slave_addr[2:0], tx_data[31:0]}
    // Output: 7-bit hamming = {p1, p2, p4, p8, p16, p32, p_overall}
    //
    // Hamming positions (1..41):
    //   parity at 1,2,4,8,16,32
    //   data at 3,5,6,7,9-15,17-31,33-41
    //
    // Data mapping (d[34:0] = {addr[2], addr[1], addr[0], pay[31:0]}):
    //   d[34]=addr[2]→pos3, d[33]=addr[1]→pos5, d[32]=addr[0]→pos6,
    //   d[31]=pay[31]→pos7, d[30]→pos9, ..., d[0]=pay[0]→pos41
    // ----------------------------------------------------------------
    wire [34:0] d = {slave_addr, tx_data};

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

    // 41-bit codeword for overall parity (data + 6 parity bits)
    wire [40:0] codeword41;
    // positions 1,2,4,8,16,32 = parity; others = data
    assign codeword41[0]  = p1;   // pos 1
    assign codeword41[1]  = p2;   // pos 2
    assign codeword41[2]  = d[34];// pos 3
    assign codeword41[3]  = p4;   // pos 4
    assign codeword41[4]  = d[33];// pos 5
    assign codeword41[5]  = d[32];// pos 6
    assign codeword41[6]  = d[31];// pos 7
    assign codeword41[7]  = p8;   // pos 8
    assign codeword41[8]  = d[30];// pos 9
    assign codeword41[9]  = d[29];// pos 10
    assign codeword41[10] = d[28];// pos 11
    assign codeword41[11] = d[27];// pos 12
    assign codeword41[12] = d[26];// pos 13
    assign codeword41[13] = d[25];// pos 14
    assign codeword41[14] = d[24];// pos 15
    assign codeword41[15] = p16;  // pos 16
    assign codeword41[16] = d[23];// pos 17
    assign codeword41[17] = d[22];// pos 18
    assign codeword41[18] = d[21];// pos 19
    assign codeword41[19] = d[20];// pos 20
    assign codeword41[20] = d[19];// pos 21
    assign codeword41[21] = d[18];// pos 22
    assign codeword41[22] = d[17];// pos 23
    assign codeword41[23] = d[16];// pos 24
    assign codeword41[24] = d[15];// pos 25
    assign codeword41[25] = d[14];// pos 26
    assign codeword41[26] = d[13];// pos 27
    assign codeword41[27] = d[12];// pos 28
    assign codeword41[28] = d[11];// pos 29
    assign codeword41[29] = d[10];// pos 30
    assign codeword41[30] = d[9]; // pos 31
    assign codeword41[31] = p32;  // pos 32
    assign codeword41[32] = d[8]; // pos 33
    assign codeword41[33] = d[7]; // pos 34
    assign codeword41[34] = d[6]; // pos 35
    assign codeword41[35] = d[5]; // pos 36
    assign codeword41[36] = d[4]; // pos 37
    assign codeword41[37] = d[3]; // pos 38
    assign codeword41[38] = d[2]; // pos 39
    assign codeword41[39] = d[1]; // pos 40
    assign codeword41[40] = d[0]; // pos 41

    wire p_overall = ^codeword41; // XOR of all 41 bits

    // hamming[6:0] sent as: p1 first (MSB of hamming field) ... p_overall last
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
            data_sent <= 1'b0; // default deassert

            if (!tx_active) begin
                tx_cnt  <= 11'd0;
                bit_cnt <= 6'd0;
                if (tx_trigger && tx_enable) begin
                    // latch frame at trigger
                    frame     <= {8'hAA, slave_addr, tx_data, hamming};
                    tx_active <= 1'b1;
                    tx_bit    <= 1'b1; // preamble starts with 1 (MSB of 0xAA)
                end
            end else begin
                if (tx_cnt == cnt_max) begin
                    tx_cnt <= 11'd0;
                    if (bit_cnt == 6'd49) begin
                        // last bit done
                        tx_active <= 1'b0;
                        data_sent <= 1'b1;
                        tx_bit    <= 1'b0;
                    end else begin
                        bit_cnt <= bit_cnt + 6'd1;
                        // next bit: frame[49] is MSB (first sent), shift left
                        tx_bit  <= frame[49 - (bit_cnt + 6'd1)];
                    end
                end else begin
                    tx_cnt <= tx_cnt + 11'd1;
                end
            end
        end
    end

    // tristate output
    assign rx_line = (tx_active && tx_enable) ? tx_bit : 1'bz;

endmodule
