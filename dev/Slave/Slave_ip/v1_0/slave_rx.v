`timescale 1ns / 1ps

module slave_rx (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire [9:0]  i_BIT_DIV,
    input  wire        i_SERIAL_IN,
    output wire [41:0] o_CODEWORD,
    output wire        o_CODEWORD_VALID,
    output wire        o_SYNC_PULSE,
    output wire [15:0] o_SYNC_CLK_CNT,
    output wire        o_PREAMBLE_ERR
);

    parameter [2:0] RX_IDLE     = 3'd0;
    parameter [2:0] RX_PREAMBLE = 3'd1;
    parameter [2:0] RX_CODEWORD = 3'd2;
    parameter [2:0] RX_DONE     = 3'd3;
    parameter [2:0] RX_ERROR    = 3'd4;

    wire        clk;
    wire        resetn;
    wire [9:0]  bit_div;
    wire        serial_in;

    wire [9:0]  bit_period;
    wire [9:0]  sample_point;
    wire [9:0]  bit_last_count;
    wire        idle_start;
    wire        idle_sample;
    wire        active_sample;
    wire        preamble_sample;
    wire        codeword_sample;
    wire        preamble_last_sample;
    wire        codeword_last_sample;
    wire [7:0]  shifted_preamble;
    wire [41:0] shifted_codeword;
    wire        preamble_success;
    wire        preamble_failure;
    wire [15:0] sync_preload;
    wire [2:0]  next_state;
    wire [9:0]  next_clk_cnt;
    wire [5:0]  next_bit_cnt;
    wire [7:0]  next_preamble_shift;
    wire [41:0] next_codeword_shift;
    wire [41:0] next_codeword_out;
    wire        next_sync_pulse;
    wire [15:0] next_sync_clk_cnt;
    wire        next_preamble_err;
    wire        next_codeword_valid;

    reg  [2:0]  ff_state;
    reg  [9:0]  ff_clk_cnt;
    reg  [5:0]  ff_bit_cnt;
    reg  [7:0]  ff_preamble_shift;
    reg  [41:0] ff_codeword_shift;
    reg  [41:0] ff_codeword_out;
    reg         ff_sync_pulse;
    reg  [15:0] ff_sync_clk_cnt;
    reg         ff_preamble_err;
    reg         ff_codeword_valid;

    assign clk       = i_CLK;
    assign resetn    = i_RESETN;
    assign bit_div   = i_BIT_DIV;
    assign serial_in = i_SERIAL_IN;

    assign bit_period      = (bit_div == 10'd0) ? 10'd1 : bit_div;
    assign sample_point    = bit_period >> 1;
    assign bit_last_count  = bit_period - 10'd1;
    assign idle_start      = (ff_state == RX_IDLE) && (serial_in == 1'b1);
    assign idle_sample     = idle_start && (sample_point == 10'd0);
    assign active_sample   = ((ff_state == RX_PREAMBLE) || (ff_state == RX_CODEWORD)) &&
                             (ff_clk_cnt == sample_point);
    assign preamble_sample = ((ff_state == RX_PREAMBLE) && active_sample) || idle_sample;
    assign codeword_sample = (ff_state == RX_CODEWORD) && active_sample;

    assign preamble_last_sample = preamble_sample && (ff_bit_cnt == 6'd7);
    assign codeword_last_sample = codeword_sample && (ff_bit_cnt == 6'd41);
    assign shifted_preamble     = {ff_preamble_shift[6:0], serial_in};
    assign shifted_codeword     = {ff_codeword_shift[40:0], serial_in};
    assign preamble_success     = preamble_last_sample && (shifted_preamble == 8'hAA);
    assign preamble_failure     = preamble_last_sample && (shifted_preamble != 8'hAA);
    assign sync_preload         = {3'b000, bit_div, 3'b000};

    assign next_state = (ff_state == RX_IDLE) ? (idle_start ? RX_PREAMBLE : RX_IDLE) :
                        (ff_state == RX_PREAMBLE) ? (preamble_success ? RX_CODEWORD :
                                                     (preamble_failure ? RX_ERROR : RX_PREAMBLE)) :
                        (ff_state == RX_CODEWORD) ? (codeword_last_sample ? RX_DONE : RX_CODEWORD) :
                        (ff_state == RX_DONE) ? RX_IDLE :
                        (ff_state == RX_ERROR) ? RX_IDLE : RX_IDLE;

    assign next_clk_cnt = (next_state == RX_IDLE) ? 10'd0 :
                          ((ff_state == RX_IDLE) && idle_start) ? ((bit_last_count == 10'd0) ? 10'd0 : 10'd1) :
                          ((ff_state == RX_PREAMBLE) || (ff_state == RX_CODEWORD)) ?
                              ((ff_clk_cnt == bit_last_count) ? 10'd0 : (ff_clk_cnt + 10'd1)) :
                          10'd0;

    assign next_bit_cnt = (preamble_sample && (ff_bit_cnt != 6'd7)) ? (ff_bit_cnt + 6'd1) :
                          (codeword_sample && (ff_bit_cnt != 6'd41)) ? (ff_bit_cnt + 6'd1) :
                          ((next_state == RX_PREAMBLE) || (next_state == RX_CODEWORD)) ?
                              ((preamble_last_sample || codeword_last_sample) ? 6'd0 : ff_bit_cnt) :
                          6'd0;

    assign next_preamble_shift = preamble_sample ? shifted_preamble :
                                 ((next_state == RX_IDLE) ? 8'd0 : ff_preamble_shift);

    assign next_codeword_shift = codeword_sample ? shifted_codeword :
                                 ((next_state == RX_IDLE) ? 42'd0 : ff_codeword_shift);

    assign next_codeword_out = codeword_last_sample ? shifted_codeword : ff_codeword_out;

    assign next_sync_pulse     = preamble_success;
    assign next_sync_clk_cnt   = preamble_success ? sync_preload : 16'd0;
    assign next_preamble_err   = preamble_failure;
    assign next_codeword_valid = codeword_last_sample;

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            ff_state <= RX_IDLE;
        else
            ff_state <= next_state;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            ff_clk_cnt <= 10'd0;
        else
            ff_clk_cnt <= next_clk_cnt;
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
            ff_sync_clk_cnt <= 16'd0;
        else
            ff_sync_clk_cnt <= next_sync_clk_cnt;
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

    assign o_CODEWORD        = ff_codeword_out;
    assign o_CODEWORD_VALID  = ff_codeword_valid;
    assign o_SYNC_PULSE      = ff_sync_pulse;
    assign o_SYNC_CLK_CNT    = ff_sync_clk_cnt;
    assign o_PREAMBLE_ERR    = ff_preamble_err;

endmodule
