// master_rx: receives NRZ master broadcast frames
// Bit period = 2*(div+1) clk cycles; sample at clk_cnt == div+1
// Frame: [preamble 8b = 0xAA][data 42b = halt_cmd+reserved+hamming]
// Buffer: shift at every sample in PREAMBLE and DATA states.
//   After 9 PREAMBLE shifts + 41 DATA shifts = 50 total, DATA bit_cnt==41:
//   buffer[41:0] = {D0..D41} (42 data bits, D0 = halt_cmd[7])
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
    // Hamming SEC-DED (combinatorial on current buffer)
    //
    // buffer[41:7]  = rx_data[34:0] = {addr[2:0], payload[31:0]}
    //   rx_data[34] = buffer[41] = addr[2]   → Hamming pos 3
    //   rx_data[33] = buffer[40] = addr[1]   → pos 5
    //   rx_data[32] = buffer[39] = addr[0]   → pos 6
    //   rx_data[31] = buffer[38] = pay[31]   → pos 7
    //   ... (non-power-of-2 positions 3,5-7,9-15,17-31,33-41)
    //
    // buffer[6:0]  = rx_hamming[6:0]
    //   Hamming sent order: p1 first → p1 ends up at buffer[6]
    //   buffer[6]=p1, [5]=p2, [4]=p4, [3]=p8, [2]=p16, [1]=p32, [0]=p_overall
    // ----------------------------------------------------------------
    wire [6:0]  rx_hamming = buffer[6:0];
    wire [34:0] rx_data    = buffer[41:7];

    // parity extractions (transmitted p1 first → sits at MSB of rx_hamming)
    wire p1_rx  = rx_hamming[6];
    wire p2_rx  = rx_hamming[5];
    wire p4_rx  = rx_hamming[4];
    wire p8_rx  = rx_hamming[3];
    wire p16_rx = rx_hamming[2];
    wire p32_rx = rx_hamming[1];
    wire pov_rx = rx_hamming[0]; // overall parity

    // syndrome bits: parity over Hamming positions with each bit set
    wire s1 = p1_rx                                                     // pos 1
        ^ rx_data[34] ^ rx_data[33] ^ rx_data[31] ^ rx_data[30]        // pos 3,5,7,9
        ^ rx_data[28] ^ rx_data[26] ^ rx_data[24] ^ rx_data[23]        // 11,13,15,17
        ^ rx_data[21] ^ rx_data[19] ^ rx_data[17] ^ rx_data[15]        // 19,21,23,25
        ^ rx_data[13] ^ rx_data[11] ^ rx_data[9]  ^ rx_data[8]         // 27,29,31,33
        ^ rx_data[6]  ^ rx_data[4]  ^ rx_data[2]  ^ rx_data[0];        // 35,37,39,41

    wire s2 = p2_rx                                                     // pos 2
        ^ rx_data[34] ^ rx_data[32] ^ rx_data[31] ^ rx_data[29]        // 3,6,7,10
        ^ rx_data[28] ^ rx_data[25] ^ rx_data[24] ^ rx_data[22]        // 11,14,15,18
        ^ rx_data[21] ^ rx_data[18] ^ rx_data[17] ^ rx_data[14]        // 19,22,23,26
        ^ rx_data[13] ^ rx_data[10] ^ rx_data[9]  ^ rx_data[7]         // 27,30,31,34
        ^ rx_data[6]  ^ rx_data[3]  ^ rx_data[2];                      // 35,38,39

    wire s4 = p4_rx                                                     // pos 4
        ^ rx_data[33] ^ rx_data[32] ^ rx_data[31] ^ rx_data[27]        // 5,6,7,12
        ^ rx_data[26] ^ rx_data[25] ^ rx_data[24] ^ rx_data[20]        // 13,14,15,20
        ^ rx_data[19] ^ rx_data[18] ^ rx_data[17] ^ rx_data[12]        // 21,22,23,28
        ^ rx_data[11] ^ rx_data[10] ^ rx_data[9]  ^ rx_data[5]         // 29,30,31,36
        ^ rx_data[4]  ^ rx_data[3]  ^ rx_data[2];                      // 37,38,39

    wire s8 = p8_rx                                                     // pos 8
        ^ rx_data[30] ^ rx_data[29] ^ rx_data[28] ^ rx_data[27]        // 9,10,11,12
        ^ rx_data[26] ^ rx_data[25] ^ rx_data[24] ^ rx_data[16]        // 13,14,15,24
        ^ rx_data[15] ^ rx_data[14] ^ rx_data[13] ^ rx_data[12]        // 25,26,27,28
        ^ rx_data[11] ^ rx_data[10] ^ rx_data[9]  ^ rx_data[1]         // 29,30,31,40
        ^ rx_data[0];                                                   // 41

    wire s16 = p16_rx                                                   // pos 16
        ^ rx_data[23] ^ rx_data[22] ^ rx_data[21] ^ rx_data[20]        // 17,18,19,20
        ^ rx_data[19] ^ rx_data[18] ^ rx_data[17] ^ rx_data[16]        // 21,22,23,24
        ^ rx_data[15] ^ rx_data[14] ^ rx_data[13] ^ rx_data[12]        // 25,26,27,28
        ^ rx_data[11] ^ rx_data[10] ^ rx_data[9];                      // 29,30,31

    wire s32 = p32_rx                                                   // pos 32
        ^ rx_data[8]  ^ rx_data[7]  ^ rx_data[6]  ^ rx_data[5]         // 33,34,35,36
        ^ rx_data[4]  ^ rx_data[3]  ^ rx_data[2]  ^ rx_data[1]         // 37,38,39,40
        ^ rx_data[0];                                                   // 41

    wire [5:0] syndrome   = {s32, s16, s8, s4, s2, s1};
    wire       all_xor    = ^buffer;         // XOR of all 42 bits (should be 0 if no error)
    wire       h_2bit_err = (syndrome != 6'd0) && (all_xor == 1'b0);

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
            // buffer CURRENT = D0..D41 (50 total shifts into 42-bit buffer)
            if (state == DATA && at_sample && bit_cnt == 6'd41) begin
                if (h_2bit_err) begin
                    bc_hamming_err <= 1'b1;
                end else if (preamble_ok_latch) begin
                    bc_valid    <= 1'b1;
                    bc_halt_cmd <= buffer[41:34];
                end
            end
        end
    end

endmodule
