// master_rx: receives NRZ master broadcast frames
// Bit period = 2*(div+1) clk cycles; sample at clk_cnt == div+1
// Frame: [preamble 8b = 0xAA][codeword 42b] = 50 bits
//   codeword = {halt_cmd[7:0], 27'b0, p[5:0], p_overall}  (systematic SECDED)
// Buffer[41:0] = codeword; decoded via hamming_dec
module master_rx (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,
    input  wire [9:0]  div,
    input  wire        tx_line_sync,

    output reg         active_edge,
    output reg         bc_valid,
    output reg         bc_preamble_ok,
    output reg  [7:0]  bc_halt_cmd,
    output reg         bc_hamming_err,
    output reg         bc_preamble_err
);

    localparam IDLE     = 2'd0;
    localparam PREAMBLE = 2'd1;
    localparam DATA     = 2'd2;

    reg [1:0]  state;
    reg [10:0] clk_cnt;
    reg [5:0]  bit_cnt;
    reg [41:0] buffer;
    reg        tx_prev;
    reg        preamble_ok_latch;

    wire [10:0] cnt_max    = {div, 1'b1};          // 2*DIV+1
    wire [10:0] samp_point = {1'b0, div} + 11'd1;  // DIV+1
    wire        at_sample  = (clk_cnt == samp_point);

    // tx_prev for edge detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) tx_prev <= 1'b0;
        else        tx_prev <= tx_line_sync;
    end

    // clk_cnt: starts at 1 on rising edge, 0..cnt_max thereafter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_cnt <= 11'd0;
        else begin
            case (state)
                IDLE:
                    clk_cnt <= (enable && !tx_prev && tx_line_sync) ? 11'd1 : 11'd0;
                default:
                    clk_cnt <= (clk_cnt == cnt_max) ? 11'd0 : clk_cnt + 11'd1;
            endcase
        end
    end

    // bit_cnt
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bit_cnt <= 6'd0;
        else begin
            case (state)
                IDLE: bit_cnt <= 6'd0;
                PREAMBLE:
                    if (at_sample)
                        bit_cnt <= (bit_cnt == 6'd8) ? 6'd0 : bit_cnt + 6'd1;
                DATA:
                    if (at_sample)
                        bit_cnt <= (bit_cnt == 6'd41) ? 6'd0 : bit_cnt + 6'd1;
                default: bit_cnt <= 6'd0;
            endcase
        end
    end

    // buffer: shift in at every sample point in PREAMBLE and DATA
    // (same pattern as FSM_data_rx_Master — shift unconditionally)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            buffer <= 42'd0;
        else begin
            if (state == DATA && at_sample && bit_cnt == 6'd41)
                buffer <= 42'd0;   // clear after capture
            else if ((state == PREAMBLE || state == DATA) && at_sample)
                buffer <= {buffer[40:0], tx_line_sync};
        end
    end

    // state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else if (!enable)
            state <= IDLE;
        else begin
            case (state)
                IDLE:     if (!tx_prev && tx_line_sync)          state <= PREAMBLE;
                PREAMBLE: if (at_sample && bit_cnt == 6'd8)      state <= DATA;
                DATA:     if (at_sample && bit_cnt == 6'd41)     state <= IDLE;
                default:  state <= IDLE;
            endcase
        end
    end

    // ----------------------------------------------------------------
    // Hamming systematic SECDED decode via hamming_dec module
    // buffer[41:0] = codeword = {d[34:0], p[5:0], p_overall}
    //   d = {halt_cmd[7:0], 27'b0}
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
    // output registers (1-clock pulses at frame boundaries)
    // ----------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active_edge      <= 1'b0;
            bc_valid         <= 1'b0;
            bc_preamble_ok   <= 1'b0;
            bc_halt_cmd      <= 8'd0;
            bc_hamming_err   <= 1'b0;
            bc_preamble_err  <= 1'b0;
            preamble_ok_latch<= 1'b0;
        end else begin
            active_edge     <= 1'b0;
            bc_valid        <= 1'b0;
            bc_preamble_ok  <= 1'b0;
            bc_hamming_err  <= 1'b0;
            bc_preamble_err <= 1'b0;

            // rising edge while IDLE → active_edge pulse
            if (state == IDLE && enable && !tx_prev && tx_line_sync)
                active_edge <= 1'b1;

            // preamble check at 9th PREAMBLE sample (bit_cnt==8)
            // buffer CURRENT has 8 preamble bits at [7:0] (before this edge's shift)
            if (state == PREAMBLE && at_sample && bit_cnt == 6'd8) begin
                if (buffer[7:0] == 8'hAA) begin
                    bc_preamble_ok    <= 1'b1;
                    preamble_ok_latch <= 1'b1;
                end else begin
                    bc_preamble_err   <= 1'b1;
                    preamble_ok_latch <= 1'b0;
                end
            end

            // data frame complete at DATA bit_cnt==41
            // buffer[41:0] = codeword; fixed_data from hamming_dec
            if (state == DATA && at_sample && bit_cnt == 6'd41) begin
                if (ham_2bit_err) begin
                    bc_hamming_err <= 1'b1;
                end else if (preamble_ok_latch) begin
                    bc_valid    <= 1'b1;
                    bc_halt_cmd <= fixed_data[34:27];
                end
            end
        end
    end

endmodule
