`timescale 1ns / 1ps

module slave2_rx (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire        i_SERIAL_IN,
    input  wire        i_SAMPLE_TICK,
    input  wire        i_SAMPLE_EARLY_TICK,
    input  wire        i_SAMPLE_LATE_TICK,
    output wire [41:0] o_CODEWORD,
    output wire        o_CODEWORD_VALID,
    output wire        o_SYNC_PULSE,
    output wire        o_RX_ACTIVE,
    output wire        o_PREAMBLE_ERR
);

    parameter USE_MAJORITY = 1;

    parameter [2:0] RX2_IDLE     = 3'd0;
    parameter [2:0] RX2_PREAMBLE = 3'd1;
    parameter [2:0] RX2_CODEWORD = 3'd2;
    parameter [2:0] RX2_DONE     = 3'd3;
    parameter [2:0] RX2_ERROR    = 3'd4;

    wire        clk;
    wire        resetn;
    wire        serial_in;
    wire        sample_tick;
    wire        sample_early_tick;
    wire        sample_late_tick;

    wire        majority_bit;
    wire        center_commit_valid;
    wire        majority_commit_valid;
    wire        sample_commit_valid;
    wire        sample_commit_bit;
    wire        idle_start;
    wire        preamble_commit;
    wire        codeword_commit;
    wire        preamble_last_commit;
    wire        codeword_last_commit;
    wire [7:0]  shifted_preamble;
    wire [41:0] shifted_codeword;
    wire        preamble_success;
    wire        preamble_failure;
    wire [2:0]  next_state;
    wire [5:0]  next_bit_cnt;
    wire [7:0]  next_preamble_shift;
    wire [41:0] next_codeword_shift;
    wire [41:0] next_codeword_out;
    wire        next_sync_pulse;
    wire        next_preamble_err;
    wire        next_codeword_valid;
    wire        next_majority_early_sample;
    wire        next_majority_center_sample;
    wire        next_majority_pending;
    wire        rx_active;

    reg  [2:0]  ff_state;
    reg  [5:0]  ff_bit_cnt;
    reg  [7:0]  ff_preamble_shift;
    reg  [41:0] ff_codeword_shift;
    reg  [41:0] ff_codeword_out;
    reg         ff_sync_pulse;
    reg         ff_preamble_err;
    reg         ff_codeword_valid;
    reg         ff_majority_early_sample;
    reg         ff_majority_center_sample;
    reg         ff_majority_pending;

    assign clk               = i_CLK;
    assign resetn            = i_RESETN;
    assign serial_in         = i_SERIAL_IN;
    assign sample_tick       = i_SAMPLE_TICK;
    assign sample_early_tick = i_SAMPLE_EARLY_TICK;
    assign sample_late_tick  = i_SAMPLE_LATE_TICK;

    assign majority_bit = (ff_majority_early_sample & ff_majority_center_sample) |
                          (ff_majority_early_sample & serial_in) |
                          (ff_majority_center_sample & serial_in);

    assign center_commit_valid   = (USE_MAJORITY == 0) && sample_tick;
    assign majority_commit_valid = (USE_MAJORITY != 0) && sample_late_tick && ff_majority_pending;
    assign sample_commit_valid   = center_commit_valid || majority_commit_valid;
    assign sample_commit_bit     = (USE_MAJORITY == 0) ? serial_in : majority_bit;

    assign idle_start             = (ff_state == RX2_IDLE) && sample_commit_valid && (sample_commit_bit == 1'b1);
    assign preamble_commit        = ((ff_state == RX2_PREAMBLE) && sample_commit_valid) || idle_start;
    assign codeword_commit        = (ff_state == RX2_CODEWORD) && sample_commit_valid;
    assign preamble_last_commit   = preamble_commit && (ff_bit_cnt == 6'd7);
    assign codeword_last_commit   = codeword_commit && (ff_bit_cnt == 6'd41);
    assign shifted_preamble       = {ff_preamble_shift[6:0], sample_commit_bit};
    assign shifted_codeword       = {ff_codeword_shift[40:0], sample_commit_bit};
    assign preamble_success       = preamble_last_commit && (shifted_preamble == 8'hAA);
    assign preamble_failure       = preamble_last_commit && (shifted_preamble != 8'hAA);

    assign next_state = (ff_state == RX2_IDLE) ? (idle_start ? RX2_PREAMBLE : RX2_IDLE) :
                        (ff_state == RX2_PREAMBLE) ? (preamble_success ? RX2_CODEWORD :
                                                      (preamble_failure ? RX2_ERROR : RX2_PREAMBLE)) :
                        (ff_state == RX2_CODEWORD) ? (codeword_last_commit ? RX2_DONE : RX2_CODEWORD) :
                        (ff_state == RX2_DONE) ? RX2_IDLE :
                        (ff_state == RX2_ERROR) ? RX2_IDLE : RX2_IDLE;

    assign next_bit_cnt = (preamble_commit && (ff_bit_cnt != 6'd7)) ? (ff_bit_cnt + 6'd1) :
                          (codeword_commit && (ff_bit_cnt != 6'd41)) ? (ff_bit_cnt + 6'd1) :
                          ((next_state == RX2_PREAMBLE) || (next_state == RX2_CODEWORD)) ?
                              ((preamble_last_commit || codeword_last_commit) ? 6'd0 : ff_bit_cnt) :
                          6'd0;

    assign next_preamble_shift = preamble_commit ? shifted_preamble :
                                 ((next_state == RX2_IDLE) ? 8'd0 : ff_preamble_shift);

    assign next_codeword_shift = codeword_commit ? shifted_codeword :
                                 ((next_state == RX2_IDLE) ? 42'd0 : ff_codeword_shift);

    assign next_codeword_out = codeword_last_commit ? shifted_codeword : ff_codeword_out;
    assign next_sync_pulse = preamble_success;
    assign next_preamble_err = preamble_failure;
    assign next_codeword_valid = codeword_last_commit;

    assign next_majority_early_sample = ((USE_MAJORITY != 0) && sample_early_tick) ? serial_in :
                                        ff_majority_early_sample;

    assign next_majority_center_sample = ((USE_MAJORITY != 0) && sample_tick) ? serial_in :
                                         ff_majority_center_sample;

    assign next_majority_pending = (USE_MAJORITY == 0) ? 1'b0 :
                                   (sample_tick ? 1'b1 :
                                   (sample_late_tick ? 1'b0 : ff_majority_pending));

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            ff_state <= RX2_IDLE;
        else
            ff_state <= next_state;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            ff_bit_cnt <= 6'd0;
        else
            ff_bit_cnt <= next_bit_cnt;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            ff_preamble_shift <= 8'd0;
        else
            ff_preamble_shift <= next_preamble_shift;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            ff_codeword_shift <= 42'd0;
        else
            ff_codeword_shift <= next_codeword_shift;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            ff_codeword_out <= 42'd0;
        else
            ff_codeword_out <= next_codeword_out;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            ff_sync_pulse <= 1'b0;
        else
            ff_sync_pulse <= next_sync_pulse;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            ff_preamble_err <= 1'b0;
        else
            ff_preamble_err <= next_preamble_err;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            ff_codeword_valid <= 1'b0;
        else
            ff_codeword_valid <= next_codeword_valid;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            ff_majority_early_sample <= 1'b0;
        else
            ff_majority_early_sample <= next_majority_early_sample;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            ff_majority_center_sample <= 1'b0;
        else
            ff_majority_center_sample <= next_majority_center_sample;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            ff_majority_pending <= 1'b0;
        else
            ff_majority_pending <= next_majority_pending;
    end

    assign rx_active = (ff_state == RX2_PREAMBLE) || (ff_state == RX2_CODEWORD);

    assign o_CODEWORD       = ff_codeword_out;
    assign o_CODEWORD_VALID = ff_codeword_valid;
    assign o_SYNC_PULSE     = ff_sync_pulse;
    assign o_RX_ACTIVE      = rx_active;
    assign o_PREAMBLE_ERR   = ff_preamble_err;

endmodule
