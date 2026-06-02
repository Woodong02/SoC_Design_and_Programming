// slave_tx: NRZ transmitter for TDMA slave
// Bit period = div clk cycles (master-compatible DIV convention)
// Frame: [preamble 8b = 0xAA][codeword 42b] = 50 bits
//   codeword = {addr[2:0], tx_data[31:0], p[5:0], p_overall}  (systematic SECDED)
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
    reg [9:0]  tx_cnt;
    reg        tx_bit;

    wire [9:0] cnt_max = div - 10'd1;  // DIV-1, period = DIV clocks

    // ----------------------------------------------------------------
    // Hamming systematic SECDED encoding via hamming_enc module
    // d[34:0] = {slave_addr[2:0], tx_data[31:0]}
    // codeword[41:0] = {d[34:0], p[5:0], p_overall}
    // ----------------------------------------------------------------
    wire [34:0] d = {slave_addr, tx_data};

    wire [41:0] codeword;
    hamming_enc u_enc (.data(d), .codeword(codeword));

    // ----------------------------------------------------------------
    // tx counter and frame shift register
    // ----------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_cnt   <= 10'd0;
            bit_cnt  <= 6'd0;
            tx_active<= 1'b0;
            data_sent<= 1'b0;
            frame    <= 50'd0;
            tx_bit   <= 1'b0;
        end else begin
            data_sent <= 1'b0; // default deassert

            if (!tx_active) begin
                tx_cnt  <= 10'd0;
                bit_cnt <= 6'd0;
                if (tx_trigger && tx_enable) begin
                    // latch frame at trigger
                    frame     <= {8'hAA, codeword};
                    tx_active <= 1'b1;
                    tx_bit    <= 1'b1; // preamble starts with 1 (MSB of 0xAA)
                end
            end else begin
                if (tx_cnt == cnt_max) begin
                    tx_cnt <= 10'd0;
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
                    tx_cnt <= tx_cnt + 10'd1;
                end
            end
        end
    end

    // tristate output
    assign rx_line = (tx_active && tx_enable) ? tx_bit : 1'bz;

endmodule
