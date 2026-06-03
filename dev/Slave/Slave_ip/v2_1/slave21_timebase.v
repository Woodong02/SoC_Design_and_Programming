`timescale 1ns / 1ps

module slave21_timebase (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire [2:0]  i_NODE_ID,
    input  wire [2:0]  i_NODE_CNT,
    input  wire [15:0] i_BIT_PERIOD_DEFAULT,
    input  wire [9:0]  i_GUARD_TICKS,
    input  wire        i_GOOD_BROADCAST_COMMIT,
    input  wire        i_TX_ACTIVE,
    input  wire        i_TX_ALLOWED,
    output wire [15:0] o_BIT_PERIOD,
    output wire        o_PERIOD_VALID,
    output wire [2:0]  o_SLOT,
    output wire [15:0] o_SLOT_CLK_CNT,
    output wire        o_TX_TRIGGER,
    output wire        o_RATE_ERR
);

    localparam [2:0]  TB21_RESET       = 3'd0;
    localparam [2:0]  TB21_WAIT_FIRST  = 3'd1;
    localparam [2:0]  TB21_WAIT_SECOND = 3'd2;
    localparam [2:0]  TB21_TRACKING    = 3'd3;
    localparam [31:0] FRAME_BITS       = 32'd50;
    localparam signed [31:0] MAX_PERIOD_STEP = 32'sd2;
    localparam signed [31:0] MIN_PERIOD_STEP = -32'sd2;
    localparam signed [31:0] RATE_ERR_LIMIT_TICKS = 32'sd512;

    wire        clk;
    wire        resetn;
    wire [2:0]  node_id;
    wire [2:0]  node_cnt;
    wire [15:0] bit_period_default;
    wire [9:0]  guard_ticks;
    wire        good_broadcast_commit;
    wire        tx_active;
    wire        tx_allowed;

    wire [15:0] default_period;
    wire [15:0] period_active;
    wire [31:0] frame_ticks;
    wire [31:0] slot_ticks;
    wire [31:0] node_slots;
    wire [31:0] expected_interval;
    wire [31:0] denominator_bits;
    wire [31:0] measured_interval;
    wire signed [31:0] interval_error;
    wire signed [31:0] period_step_raw;
    wire signed [31:0] period_step_limited;
    wire signed [31:0] period_adjusted_signed;
    wire [15:0] period_adjusted;
    wire        interval_ready;
    wire        rate_error_event;

    wire [31:0] slot_preload_count;
    wire [31:0] guard_center_tick;
    wire        slot_last_tick;
    wire [2:0]  slot_increment_next;
    wire [31:0] slot_clk_cnt_increment_next;
    wire        node_has_slot;
    wire        tx_trigger_match;

    reg  [2:0]  state_ff;
    reg  [2:0]  state_next;
    reg  [15:0] bit_period_ff;
    reg  [15:0] bit_period_next;
    reg         period_valid_ff;
    reg         period_valid_next;
    reg  [2:0]  slot_ff;
    reg  [2:0]  slot_next;
    reg  [31:0] slot_clk_cnt_ff;
    reg  [31:0] slot_clk_cnt_next;
    reg  [31:0] interval_count_ff;
    reg  [31:0] interval_count_next;
    reg         interval_seen_ff;
    reg         interval_seen_next;
    reg         tx_trigger_ff;
    reg         tx_trigger_next;
    reg         rate_err_ff;
    reg         rate_err_next;

    wire [15:0] bit_period;
    wire        period_valid;
    wire [2:0]  slot;
    wire [15:0] slot_clk_cnt;
    wire        tx_trigger;
    wire        rate_err;

    assign clk = i_CLK;
    assign resetn = i_RESETN;
    assign node_id = i_NODE_ID;
    assign node_cnt = i_NODE_CNT;
    assign bit_period_default = i_BIT_PERIOD_DEFAULT;
    assign guard_ticks = i_GUARD_TICKS;
    assign good_broadcast_commit = i_GOOD_BROADCAST_COMMIT;
    assign tx_active = i_TX_ACTIVE;
    assign tx_allowed = i_TX_ALLOWED;

    assign default_period = (bit_period_default == 16'd0) ? 16'd1 : bit_period_default;
    assign period_active = (bit_period_ff == 16'd0) ? default_period : bit_period_ff;
    assign frame_ticks = {16'd0, period_active} * FRAME_BITS;
    assign slot_ticks = frame_ticks + {22'd0, guard_ticks};
    assign node_slots = {29'd0, node_cnt} + 32'd1;
    assign expected_interval = node_slots * slot_ticks;
    assign denominator_bits = node_slots * FRAME_BITS;
    assign measured_interval = interval_count_ff + 32'd1;
    assign interval_error = $signed(measured_interval) - $signed(expected_interval);
    assign period_step_raw = (denominator_bits == 32'd0) ? 32'sd0 :
                             (interval_error / $signed(denominator_bits));
    assign period_step_limited = (period_step_raw > MAX_PERIOD_STEP) ? MAX_PERIOD_STEP :
                                 (period_step_raw < MIN_PERIOD_STEP) ? MIN_PERIOD_STEP :
                                 period_step_raw;
    assign period_adjusted_signed = $signed({16'd0, period_active}) + period_step_limited;
    assign period_adjusted = (period_adjusted_signed < 32'sd1) ? 16'd1 :
                             (period_adjusted_signed > 32'sd65535) ? 16'hFFFF :
                             period_adjusted_signed[15:0];
    assign interval_ready = interval_seen_ff & good_broadcast_commit;
    assign rate_error_event = interval_ready &
                              ((interval_error > RATE_ERR_LIMIT_TICKS) |
                               (interval_error < -RATE_ERR_LIMIT_TICKS));

    assign slot_preload_count = frame_ticks;
    assign guard_center_tick = {22'd0, guard_ticks} >> 1;
    assign slot_last_tick = (slot_clk_cnt_ff >= (slot_ticks - 32'd1));
    assign slot_increment_next = (slot_ff >= node_cnt) ? 3'd0 : (slot_ff + 3'd1);
    assign slot_clk_cnt_increment_next = slot_last_tick ? 32'd0 : (slot_clk_cnt_ff + 32'd1);
    assign node_has_slot = (node_id <= node_cnt);
    assign tx_trigger_match = period_valid_ff & tx_allowed & ~tx_active & node_has_slot &
                              (slot_ff == node_id) & (slot_clk_cnt_ff == guard_center_tick);

    always @(*) begin
        state_next = state_ff;

        case (state_ff)
            TB21_RESET: begin
                state_next = TB21_WAIT_FIRST;
            end

            TB21_WAIT_FIRST: begin
                if (good_broadcast_commit == 1'b1) begin
                    state_next = TB21_WAIT_SECOND;
                end else begin
                    state_next = TB21_WAIT_FIRST;
                end
            end

            TB21_WAIT_SECOND: begin
                if (rate_error_event == 1'b1) begin
                    state_next = TB21_WAIT_FIRST;
                end else if (good_broadcast_commit == 1'b1) begin
                    state_next = TB21_TRACKING;
                end else begin
                    state_next = TB21_WAIT_SECOND;
                end
            end

            TB21_TRACKING: begin
                if (rate_error_event == 1'b1) begin
                    state_next = TB21_WAIT_FIRST;
                end else begin
                    state_next = TB21_TRACKING;
                end
            end

            default: begin
                state_next = TB21_WAIT_FIRST;
            end
        endcase
    end

    always @(*) begin
        bit_period_next = bit_period_ff;

        if (state_ff == TB21_RESET) begin
            bit_period_next = default_period;
        end else if (rate_error_event == 1'b1) begin
            bit_period_next = default_period;
        end else if (interval_ready == 1'b1) begin
            bit_period_next = period_adjusted;
        end else if (period_valid_ff == 1'b0) begin
            bit_period_next = default_period;
        end
    end

    always @(*) begin
        period_valid_next = period_valid_ff;

        if (rate_error_event == 1'b1) begin
            period_valid_next = 1'b0;
        end else if ((interval_ready == 1'b1) && (rate_error_event == 1'b0)) begin
            period_valid_next = 1'b1;
        end else if (state_ff == TB21_RESET) begin
            period_valid_next = 1'b0;
        end
    end

    always @(*) begin
        slot_next = slot_ff;

        if (good_broadcast_commit == 1'b1) begin
            slot_next = 3'd0;
        end else if (slot_last_tick == 1'b1) begin
            slot_next = slot_increment_next;
        end else if (state_ff == TB21_RESET) begin
            slot_next = 3'd0;
        end else if (state_ff == TB21_WAIT_FIRST) begin
            slot_next = 3'd0;
        end
    end

    always @(*) begin
        slot_clk_cnt_next = slot_clk_cnt_increment_next;

        if (good_broadcast_commit == 1'b1) begin
            slot_clk_cnt_next = slot_preload_count;
        end else if (state_ff == TB21_RESET) begin
            slot_clk_cnt_next = 32'd0;
        end else if (state_ff == TB21_WAIT_FIRST) begin
            slot_clk_cnt_next = 32'd0;
        end
    end

    always @(*) begin
        interval_count_next = interval_count_ff + 32'd1;

        if (good_broadcast_commit == 1'b1) begin
            interval_count_next = 32'd0;
        end else if (interval_seen_ff == 1'b0) begin
            interval_count_next = 32'd0;
        end
    end

    always @(*) begin
        interval_seen_next = interval_seen_ff;

        if (rate_error_event == 1'b1) begin
            interval_seen_next = 1'b0;
        end else if (good_broadcast_commit == 1'b1) begin
            interval_seen_next = 1'b1;
        end
    end

    always @(*) begin
        tx_trigger_next = tx_trigger_match & ~good_broadcast_commit;
    end

    always @(*) begin
        rate_err_next = rate_error_event;
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            state_ff <= TB21_RESET;
        end else begin
            state_ff <= state_next;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            bit_period_ff <= 16'd1;
        end else begin
            bit_period_ff <= bit_period_next;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            period_valid_ff <= 1'b0;
        end else begin
            period_valid_ff <= period_valid_next;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            slot_ff <= 3'd0;
        end else begin
            slot_ff <= slot_next;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            slot_clk_cnt_ff <= 32'd0;
        end else begin
            slot_clk_cnt_ff <= slot_clk_cnt_next;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            interval_count_ff <= 32'd0;
        end else begin
            interval_count_ff <= interval_count_next;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            interval_seen_ff <= 1'b0;
        end else begin
            interval_seen_ff <= interval_seen_next;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            tx_trigger_ff <= 1'b0;
        end else begin
            tx_trigger_ff <= tx_trigger_next;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            rate_err_ff <= 1'b0;
        end else begin
            rate_err_ff <= rate_err_next;
        end
    end

    assign bit_period = period_active;
    assign period_valid = period_valid_ff;
    assign slot = slot_ff;
    assign slot_clk_cnt = slot_clk_cnt_ff[15:0];
    assign tx_trigger = tx_trigger_ff;
    assign rate_err = rate_err_ff;

    assign o_BIT_PERIOD = bit_period;
    assign o_PERIOD_VALID = period_valid;
    assign o_SLOT = slot;
    assign o_SLOT_CLK_CNT = slot_clk_cnt;
    assign o_TX_TRIGGER = tx_trigger;
    assign o_RATE_ERR = rate_err;

endmodule
