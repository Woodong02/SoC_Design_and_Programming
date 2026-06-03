`timescale 1ns / 1ps

module slave21_rx (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire        i_SERIAL_IN,
    input  wire [15:0] i_BIT_PERIOD,
    output wire [41:0] o_CODEWORD,
    output wire        o_CODEWORD_VALID,
    output wire        o_FRAME_DONE,
    output wire        o_PREAMBLE_OK,
    output wire        o_PREAMBLE_ERR,
    output wire        o_RX_ACTIVE
);

    localparam [2:0] RX21_IDLE     = 3'd0;
    localparam [2:0] RX21_PREAMBLE = 3'd1;
    localparam [2:0] RX21_CODEWORD = 3'd2;
    localparam [2:0] RX21_DONE     = 3'd3;
    localparam [2:0] RX21_ERROR    = 3'd4;

    wire        clk;
    wire        resetn;
    wire        serial_in;
    wire [15:0] bit_period;

    wire        start_candidate;
    wire [15:0] normalized_bit_period;
    wire [15:0] start_half_period;
    wire [15:0] start_sample_delay;
    wire [15:0] period_reload_value;
    wire        immediate_start_sample;
    wire        timer_expired;
    wire        timed_sample;
    wire        sample_commit;
    wire        sample_bit;
    wire        preamble_sample;
    wire        codeword_sample;
    wire        preamble_last_sample;
    wire        codeword_last_sample;
    wire        error_sample;
    wire        error_last_sample;
    wire [7:0]  shifted_preamble;
    wire [41:0] shifted_codeword;
    wire        preamble_success;
    wire        preamble_failure;
    wire        rx_active;

    reg  [2:0]  state_ff;
    reg  [2:0]  state_next;
    reg  [5:0]  bit_count_ff;
    reg  [5:0]  bit_count_next;
    reg  [15:0] period_snapshot_ff;
    reg  [15:0] period_snapshot_next;
    reg  [15:0] sample_timer_ff;
    reg  [15:0] sample_timer_next;
    reg  [7:0]  preamble_shift_ff;
    reg  [7:0]  preamble_shift_next;
    reg  [41:0] codeword_shift_ff;
    reg  [41:0] codeword_shift_next;
    reg  [41:0] codeword_out_ff;
    reg  [41:0] codeword_out_next;
    reg         serial_prev_ff;
    reg         serial_prev_next;
    reg         codeword_valid_ff;
    reg         codeword_valid_next;
    reg         frame_done_ff;
    reg         frame_done_next;
    reg         preamble_ok_ff;
    reg         preamble_ok_next;
    reg         preamble_err_ff;
    reg         preamble_err_next;

    assign clk = i_CLK;
    assign resetn = i_RESETN;
    assign serial_in = i_SERIAL_IN;
    assign bit_period = i_BIT_PERIOD;

    assign start_candidate = (state_ff == RX21_IDLE) & (serial_prev_ff == 1'b0) & (serial_in == 1'b1);
    assign normalized_bit_period = (bit_period == 16'd0) ? 16'd1 : bit_period;
    assign start_half_period = normalized_bit_period >> 1;
    assign start_sample_delay = (start_half_period == 16'd0) ? 16'd0 : (start_half_period - 16'd1);
    assign period_reload_value = (period_snapshot_ff <= 16'd1) ? 16'd0 : (period_snapshot_ff - 16'd1);
    assign immediate_start_sample = start_candidate & (normalized_bit_period == 16'd1);
    assign timer_expired = (sample_timer_ff == 16'd0);
    assign timed_sample = ((state_ff == RX21_PREAMBLE) | (state_ff == RX21_CODEWORD) | (state_ff == RX21_ERROR)) & timer_expired;
    assign sample_commit = immediate_start_sample | timed_sample;
    assign sample_bit = serial_in;
    assign preamble_sample = immediate_start_sample | ((state_ff == RX21_PREAMBLE) & timed_sample);
    assign codeword_sample = (state_ff == RX21_CODEWORD) & timed_sample;
    assign error_sample = (state_ff == RX21_ERROR) & timed_sample;
    assign preamble_last_sample = preamble_sample & (bit_count_ff == 6'd7);
    assign codeword_last_sample = codeword_sample & (bit_count_ff == 6'd41);
    assign error_last_sample = error_sample & (bit_count_ff == 6'd41);
    assign shifted_preamble = {preamble_shift_ff[6:0], sample_bit};
    assign shifted_codeword = {codeword_shift_ff[40:0], sample_bit};
    assign preamble_success = preamble_last_sample & (shifted_preamble == 8'hAA);
    assign preamble_failure = preamble_last_sample & (shifted_preamble != 8'hAA);
    assign rx_active = (state_ff == RX21_PREAMBLE) | (state_ff == RX21_CODEWORD) | (state_ff == RX21_ERROR);

    always @(*) begin
        state_next = state_ff;

        case (state_ff)
            RX21_IDLE: begin
                if (start_candidate == 1'b1) begin
                    state_next = RX21_PREAMBLE;
                end else begin
                    state_next = RX21_IDLE;
                end
            end

            RX21_PREAMBLE: begin
                if (preamble_success == 1'b1) begin
                    state_next = RX21_CODEWORD;
                end else if (preamble_failure == 1'b1) begin
                    state_next = RX21_ERROR;
                end else begin
                    state_next = RX21_PREAMBLE;
                end
            end

            RX21_CODEWORD: begin
                if (codeword_last_sample == 1'b1) begin
                    state_next = RX21_DONE;
                end else begin
                    state_next = RX21_CODEWORD;
                end
            end

            RX21_DONE: begin
                state_next = RX21_IDLE;
            end

            RX21_ERROR: begin
                if (error_last_sample == 1'b1) begin
                    state_next = RX21_IDLE;
                end else begin
                    state_next = RX21_ERROR;
                end
            end

            default: begin
                state_next = RX21_IDLE;
            end
        endcase
    end

    always @(*) begin
        bit_count_next = bit_count_ff;

        if (state_ff == RX21_DONE) begin
            bit_count_next = 6'd0;
        end else if (preamble_success == 1'b1) begin
            bit_count_next = 6'd0;
        end else if (preamble_failure == 1'b1) begin
            bit_count_next = 6'd0;
        end else if (codeword_last_sample == 1'b1) begin
            bit_count_next = 6'd0;
        end else if (error_last_sample == 1'b1) begin
            bit_count_next = 6'd0;
        end else if (preamble_sample == 1'b1) begin
            bit_count_next = bit_count_ff + 6'd1;
        end else if (codeword_sample == 1'b1) begin
            bit_count_next = bit_count_ff + 6'd1;
        end else if (error_sample == 1'b1) begin
            bit_count_next = bit_count_ff + 6'd1;
        end else if (state_ff == RX21_IDLE) begin
            bit_count_next = 6'd0;
        end
    end

    always @(*) begin
        period_snapshot_next = period_snapshot_ff;

        if (start_candidate == 1'b1) begin
            period_snapshot_next = normalized_bit_period;
        end else if ((state_ff == RX21_DONE) | error_last_sample) begin
            period_snapshot_next = 16'd0;
        end
    end

    always @(*) begin
        sample_timer_next = sample_timer_ff;

        if (start_candidate == 1'b1) begin
            if (normalized_bit_period == 16'd1) begin
                sample_timer_next = 16'd0;
            end else begin
                sample_timer_next = start_sample_delay;
            end
        end else if (sample_commit == 1'b1) begin
            sample_timer_next = period_reload_value;
        end else if (((state_ff == RX21_PREAMBLE) | (state_ff == RX21_CODEWORD) | (state_ff == RX21_ERROR)) & (sample_timer_ff != 16'd0)) begin
            sample_timer_next = sample_timer_ff - 16'd1;
        end else if ((state_ff == RX21_DONE) | (state_ff == RX21_ERROR) | (state_ff == RX21_IDLE)) begin
            sample_timer_next = 16'd0;
        end
    end

    always @(*) begin
        preamble_shift_next = preamble_shift_ff;

        if (preamble_sample == 1'b1) begin
            preamble_shift_next = shifted_preamble;
        end else if ((state_ff == RX21_DONE) | (state_ff == RX21_ERROR) | (state_ff == RX21_IDLE)) begin
            preamble_shift_next = 8'd0;
        end
    end

    always @(*) begin
        codeword_shift_next = codeword_shift_ff;

        if (codeword_sample == 1'b1) begin
            codeword_shift_next = shifted_codeword;
        end else if ((state_ff == RX21_DONE) | (state_ff == RX21_ERROR) | (state_ff == RX21_IDLE)) begin
            codeword_shift_next = 42'd0;
        end
    end

    always @(*) begin
        codeword_out_next = codeword_out_ff;

        if (codeword_last_sample == 1'b1) begin
            codeword_out_next = shifted_codeword;
        end
    end

    always @(*) begin
        serial_prev_next = serial_in;
    end

    always @(*) begin
        codeword_valid_next = codeword_last_sample;
    end

    always @(*) begin
        frame_done_next = codeword_last_sample | preamble_failure;
    end

    always @(*) begin
        preamble_ok_next = preamble_success;
    end

    always @(*) begin
        preamble_err_next = preamble_failure;
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            state_ff <= RX21_IDLE;
        end else begin
            state_ff <= state_next;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            bit_count_ff <= 6'd0;
        end else begin
            bit_count_ff <= bit_count_next;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            period_snapshot_ff <= 16'd0;
        end else begin
            period_snapshot_ff <= period_snapshot_next;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            sample_timer_ff <= 16'd0;
        end else begin
            sample_timer_ff <= sample_timer_next;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            preamble_shift_ff <= 8'd0;
        end else begin
            preamble_shift_ff <= preamble_shift_next;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            codeword_shift_ff <= 42'd0;
        end else begin
            codeword_shift_ff <= codeword_shift_next;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            codeword_out_ff <= 42'd0;
        end else begin
            codeword_out_ff <= codeword_out_next;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            serial_prev_ff <= 1'b0;
        end else begin
            serial_prev_ff <= serial_prev_next;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            codeword_valid_ff <= 1'b0;
        end else begin
            codeword_valid_ff <= codeword_valid_next;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            frame_done_ff <= 1'b0;
        end else begin
            frame_done_ff <= frame_done_next;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            preamble_ok_ff <= 1'b0;
        end else begin
            preamble_ok_ff <= preamble_ok_next;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            preamble_err_ff <= 1'b0;
        end else begin
            preamble_err_ff <= preamble_err_next;
        end
    end

    assign o_CODEWORD = codeword_out_ff;
    assign o_CODEWORD_VALID = codeword_valid_ff;
    assign o_FRAME_DONE = frame_done_ff;
    assign o_PREAMBLE_OK = preamble_ok_ff;
    assign o_PREAMBLE_ERR = preamble_err_ff;
    assign o_RX_ACTIVE = rx_active;

endmodule
