// slave_rx: NRZ receiver for TDMA slave data frames (master-side)
// Bit period = 2*(div+1) clk cycles; sample at clk_cnt == div+1
// Frame: [preamble 8b = 0xAA][codeword 42b] = 50 bits
//   codeword = {addr[2:0], payload[31:0], p[5:0], p_overall}  (systematic SECDED)
// Buffer after 42 shifts: buffer[41:0] = codeword; decoded via hamming_dec
module slave_rx (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,
    input  wire [9:0]  div,
    input  wire        rx_line_sync,

    output reg         active_edge,
    output reg         frame_valid,
    output reg  [2:0]  frame_addr,
    output reg  [31:0] frame_data,
    output reg         hamming_err,
    output reg         preamble_err,
    output reg         preamble_ok
);

    localparam IDLE     = 2'd0;
    localparam PREAMBLE = 2'd1;
    localparam DATA     = 2'd2;

    reg [1:0]  state;
    reg [10:0] clk_cnt;
    reg [5:0]  bit_cnt;
    reg [41:0] buffer;
    reg        rx_prev;
    reg        preamble_ok_latch;

    wire [10:0] cnt_max    = {div, 1'b1};
    wire [10:0] samp_point = {1'b0, div} + 11'd1;
    wire        at_sample  = (clk_cnt == samp_point);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) rx_prev <= 1'b0;
        else        rx_prev <= rx_line_sync;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_cnt <= 11'd0;
        else begin
            case (state)
                IDLE:    clk_cnt <= (enable && !rx_prev && rx_line_sync) ? 11'd1 : 11'd0;
                default: clk_cnt <= (clk_cnt == cnt_max) ? 11'd0 : clk_cnt + 11'd1;
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bit_cnt <= 6'd0;
        else begin
            case (state)
                IDLE: bit_cnt <= 6'd0;
                PREAMBLE:
                    if (at_sample) bit_cnt <= (bit_cnt == 6'd8) ? 6'd0 : bit_cnt + 6'd1;
                DATA:
                    if (at_sample) bit_cnt <= (bit_cnt == 6'd41) ? 6'd0 : bit_cnt + 6'd1;
                default: bit_cnt <= 6'd0;
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            buffer <= 42'd0;
        else begin
            if (state == DATA && at_sample && bit_cnt == 6'd41)
                buffer <= 42'd0;
            else if ((state == PREAMBLE || state == DATA) && at_sample)
                buffer <= {buffer[40:0], rx_line_sync};
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else if (!enable)
            state <= IDLE;
        else begin
            case (state)
                IDLE:     if (!rx_prev && rx_line_sync)         state <= PREAMBLE;
                PREAMBLE: if (at_sample && bit_cnt == 6'd8)     state <= DATA;
                DATA:     if (at_sample && bit_cnt == 6'd41)    state <= IDLE;
                default:  state <= IDLE;
            endcase
        end
    end

    // ----------------------------------------------------------------
    // Hamming systematic SECDED decode via hamming_dec module
    // buffer[41:0] = codeword = {d[34:0], p[5:0], p_overall}
    //   d = {addr[2:0], payload[31:0]}
    // ----------------------------------------------------------------
    wire [34:0] fixed_data;
    wire        ham_1bit_err, ham_2bit_err;

    hamming_dec u_dec (
        .codeword    (buffer[41:0]),
        .data        (fixed_data),
        .ham_1bit_err(ham_1bit_err),
        .ham_2bit_err(ham_2bit_err)
    );

    // ----------------------------------------------------------------
    // Output registers
    // ----------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active_edge      <= 1'b0;
            frame_valid      <= 1'b0;
            frame_addr       <= 3'd0;
            frame_data       <= 32'd0;
            hamming_err      <= 1'b0;
            preamble_err     <= 1'b0;
            preamble_ok      <= 1'b0;
            preamble_ok_latch<= 1'b0;
        end else begin
            active_edge  <= 1'b0;
            frame_valid  <= 1'b0;
            hamming_err  <= 1'b0;
            preamble_err <= 1'b0;
            preamble_ok  <= 1'b0;

            if (state == IDLE && enable && !rx_prev && rx_line_sync)
                active_edge <= 1'b1;

            if (state == PREAMBLE && at_sample && bit_cnt == 6'd8) begin
                if (buffer[7:0] == 8'hAA) begin
                    preamble_ok       <= 1'b1;
                    preamble_ok_latch <= 1'b1;
                end else begin
                    preamble_err      <= 1'b1;
                    preamble_ok_latch <= 1'b0;
                end
            end

            if (state == DATA && at_sample && bit_cnt == 6'd41) begin
                if (ham_2bit_err) begin
                    hamming_err <= 1'b1;
                end else if (preamble_ok_latch) begin
                    frame_valid <= 1'b1;
                    frame_addr  <= fixed_data[34:32];
                    frame_data  <= fixed_data[31:0];
                end
            end
        end
    end

endmodule
