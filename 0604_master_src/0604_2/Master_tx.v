// master_tx: NRZ transmitter for TDMA master broadcast
// Bit period = div clk cycles (same as slave_tx)
// Frame: [preamble 8b = 0xAA][codeword 42b] = 50 bits
//   codeword = {halt_cmd[7:0], 27'b0, p[5:0], p_overall}  (systematic SECDED)
// GPIO_out is driven high/low while active; released (high-Z) when idle.
module Master_tx (
    input  wire        clk,
    input  wire        resetn,
    input  wire        tx_trigger,
    input  wire [7:0]  halt_cmd,
    input  wire [9:0]  GUARD_TICKS,
    input  wire [31:0]  DIV,

    output wire        GPIO_out
);

    reg [49:0] frame;
    reg [5:0]  bit_cnt;
    reg [31:0] tx_cnt;
    reg        tx_bit;
    reg       tx_active;


    // ----------------------------------------------------------------
    // Hamming systematic SECDED encoding via hamming_enc module
    // d[34:0] = {halt_cmd, GUARD_TICKS, DIV, 17'b0};
    // codeword[41:0] = {d[34:0], p[5:0], p_overall}
    // ----------------------------------------------------------------
    wire [34:0] d = {halt_cmd, GUARD_TICKS, 17'b0};

    wire [41:0] codeword;
    hamming_enc u_enc (.data(d), .codeword(codeword));

    // ----------------------------------------------------------------
    // tx counter and frame shift register
    // ----------------------------------------------------------------
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            tx_cnt   <= 32'd0;
            bit_cnt  <= 6'd0;
            tx_active<= 1'b0;
            frame    <= 50'd0;
            tx_bit   <= 1'b0;
        end else begin
            if (!tx_active) begin
                tx_cnt  <= 32'd0;
                bit_cnt <= 6'd0;
                if (tx_trigger) begin
                    frame     <= {8'hAA, codeword};
                    tx_active <= 1'b1;
                    tx_bit    <= 1'b1; // preamble MSB of 0xAA = 1
                end
            end else begin
                if (tx_cnt == DIV-1) begin
                    tx_cnt <= 32'd0;
                    if (bit_cnt == 6'd49) begin
                        tx_active <= 1'b0;
                        tx_bit    <= 1'b0;
                    end else begin
                        bit_cnt <= bit_cnt + 6'd1;
                        tx_bit  <= frame[49 - (bit_cnt + 6'd1)];
                    end
                end else begin
                    tx_cnt <= tx_cnt + 32'd1;
                end
            end
        end
    end

    assign GPIO_out = (tx_active) ? tx_bit : 1'b0;

endmodule
