`timescale 1ns / 1ps

module slave2_timebase (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire [2:0]  i_NODE_ID,
    input  wire [2:0]  i_NODE_CNT,
    input  wire [9:0]  i_BIT_DIV_DEFAULT,
    input  wire [9:0]  i_GUARD_TICKS,
    input  wire        i_SYNC_PULSE,
    input  wire        i_RX_ACTIVE,
    input  wire        i_TX_ACTIVE,
    output wire        o_LOCKED,
    output wire [15:0] o_BIT_PERIOD_EST,
    output wire [2:0]  o_SLOT,
    output wire [15:0] o_SLOT_CLK_CNT,
    output wire        o_SAMPLE_TICK,
    output wire        o_SAMPLE_EARLY_TICK,
    output wire        o_SAMPLE_LATE_TICK,
    output wire        o_TX_BIT_TICK,
    output wire        o_TX_TRIGGER,
    output wire        o_RATE_ERR
);

    parameter [1:0]  TB_UNLOCKED = 2'd0;
    parameter [1:0]  TB_ACQUIRE  = 2'd1;
    parameter [1:0]  TB_TRACKING = 2'd2;
    parameter [1:0]  TB_HOLDOVER = 2'd3;
    parameter [15:0] FRAME_BITS  = 16'd50;
    parameter [15:0] MAX_CORRECTION = 16'd2;
    parameter [31:0] LARGE_ERROR_TICKS = 32'd4096;

    wire        clk;
    wire        resetn;
    wire [2:0]  node_id;
    wire [2:0]  node_cnt;
    wire [9:0]  bit_div_default;
    wire [9:0]  guard_ticks;
    wire        sync_pulse;
    wire        rx_active;
    wire        tx_active;

    wire [15:0] default_period;
    wire [15:0] period_active;
    wire [15:0] sample_center;
    wire [15:0] sample_early;
    wire [15:0] sample_late;
    wire        sample_tick_next;
    wire        sample_early_tick_next;
    wire        sample_late_tick_next;
    wire        tx_bit_tick_next;
    wire [15:0] bit_counter_next_count;
    wire [15:0] bit_counter_after_sync;

    wire [15:0] slot_ticks;
    wire [15:0] sync_slot_preload;
    wire [15:0] tx_start_tick;
    wire        slot_last_tick;
    wire        node_has_slot;
    wire        tx_trigger_match;
    wire [2:0]  slot_next_count;
    wire [15:0] slot_clk_cnt_next_count;

    wire [31:0] cycle_count_next_count;
    wire [31:0] measured_cycle_ticks;
    wire [31:0] expected_slot_ticks;
    wire [31:0] expected_cycle_ticks;
    wire [31:0] denominator_ticks;
    wire signed [31:0] cycle_error_signed;
    wire signed [31:0] bit_step_raw;
    wire signed [31:0] bit_step_limited;
    wire signed [31:0] period_adjusted_signed;
    wire [15:0] period_adjusted;
    wire        interval_ready;
    wire        large_error;
    wire        active_block;
    wire        pending_apply;

    reg  [1:0]  state_ff;
    reg  [1:0]  state_next;
    reg  [15:0] bit_period_est_ff;
    reg  [15:0] bit_period_est_next;
    reg  [15:0] bit_counter_ff;
    reg  [15:0] bit_counter_next;
    reg  [2:0]  slot_ff;
    reg  [2:0]  slot_next;
    reg  [15:0] slot_clk_cnt_ff;
    reg  [15:0] slot_clk_cnt_next;
    reg  [31:0] cycle_count_ff;
    reg  [31:0] cycle_count_next;
    reg         have_sync_ff;
    reg         have_sync_next;
    reg         pending_update_ff;
    reg         pending_update_next;
    reg  [15:0] pending_period_ff;
    reg  [15:0] pending_period_next;
    reg         rate_err_ff;
    reg         rate_err_next;
    reg         sample_tick_ff;
    reg         sample_early_tick_ff;
    reg         sample_late_tick_ff;
    reg         tx_bit_tick_ff;
    reg         tx_trigger_ff;

    wire        locked;
    wire [15:0] bit_period_est;
    wire [2:0]  slot;
    wire [15:0] slot_clk_cnt;
    wire        sample_tick;
    wire        sample_early_tick;
    wire        sample_late_tick;
    wire        tx_bit_tick;
    wire        tx_trigger;
    wire        rate_err;

    assign clk = i_CLK;
    assign resetn = i_RESETN;
    assign node_id = i_NODE_ID;
    assign node_cnt = i_NODE_CNT;
    assign bit_div_default = i_BIT_DIV_DEFAULT;
    assign guard_ticks = i_GUARD_TICKS;
    assign sync_pulse = i_SYNC_PULSE;
    assign rx_active = i_RX_ACTIVE;
    assign tx_active = i_TX_ACTIVE;

    assign default_period = (bit_div_default == 10'd0) ? 16'd1 : {6'd0, bit_div_default};
    assign period_active = (bit_period_est_ff == 16'd0) ? default_period : bit_period_est_ff;
    assign sample_center = period_active >> 1;
    assign sample_early = (sample_center == 16'd0) ? 16'd0 : (sample_center - 16'd1);
    assign sample_late = (sample_center >= (period_active - 16'd1)) ? (period_active - 16'd1) : (sample_center + 16'd1);
    assign sample_tick_next = (bit_counter_ff == sample_center);
    assign sample_early_tick_next = (bit_counter_ff == sample_early);
    assign sample_late_tick_next = (bit_counter_ff == sample_late);
    assign tx_bit_tick_next = (bit_counter_ff == (period_active - 16'd1));
    assign bit_counter_next_count = tx_bit_tick_next ? 16'd0 : (bit_counter_ff + 16'd1);
    assign bit_counter_after_sync = sample_center;

    assign slot_ticks = (FRAME_BITS * period_active) + {6'd0, guard_ticks};
    assign sync_slot_preload = 16'd8 * period_active;
    assign tx_start_tick = {6'd0, (guard_ticks >> 1)};
    assign slot_last_tick = (slot_ticks != 16'd0) && (slot_clk_cnt_ff == (slot_ticks - 16'd1));
    assign node_has_slot = (node_id <= node_cnt);
    assign tx_trigger_match = (state_ff != TB_UNLOCKED) && node_has_slot && (slot_ff == node_id) &&
                              (slot_clk_cnt_ff == tx_start_tick);
    assign slot_next_count = (slot_last_tick && (slot_ff == node_cnt)) ? 3'd0 :
                             (slot_last_tick ? (slot_ff + 3'd1) : slot_ff);
    assign slot_clk_cnt_next_count = slot_last_tick ? 16'd0 : (slot_clk_cnt_ff + 16'd1);

    assign cycle_count_next_count = have_sync_ff ? (cycle_count_ff + 32'd1) : 32'd0;
    assign measured_cycle_ticks = cycle_count_ff;
    assign expected_slot_ticks = ({16'd0, period_active} * {16'd0, FRAME_BITS}) + {22'd0, guard_ticks};
    assign expected_cycle_ticks = ({29'd0, node_cnt} + 32'd1) * expected_slot_ticks;
    assign denominator_ticks = ({29'd0, node_cnt} + 32'd1) * {16'd0, FRAME_BITS};
    assign cycle_error_signed = $signed(measured_cycle_ticks) - $signed(expected_cycle_ticks);
    assign bit_step_raw = (denominator_ticks == 32'd0) ? 32'sd0 : (cycle_error_signed / $signed(denominator_ticks));
    assign bit_step_limited = (bit_step_raw > $signed({16'd0, MAX_CORRECTION})) ? $signed({16'd0, MAX_CORRECTION}) :
                              (bit_step_raw < -$signed({16'd0, MAX_CORRECTION})) ? -$signed({16'd0, MAX_CORRECTION}) :
                              bit_step_raw;
    assign period_adjusted_signed = $signed({16'd0, period_active}) + bit_step_limited;
    assign period_adjusted = (period_adjusted_signed < 32'sd1) ? 16'd1 : period_adjusted_signed[15:0];
    assign interval_ready = have_sync_ff && sync_pulse;
    assign large_error = interval_ready &&
                         ((cycle_error_signed > $signed(LARGE_ERROR_TICKS)) ||
                          (cycle_error_signed < -$signed(LARGE_ERROR_TICKS)));
    assign active_block = rx_active | tx_active;
    assign pending_apply = pending_update_ff && !active_block;

    always @(*) begin
        state_next = state_ff;

        if (sync_pulse == 1'b1) begin
            if (state_ff == TB_UNLOCKED) begin
                state_next = TB_ACQUIRE;
            end else if (large_error == 1'b1) begin
                state_next = TB_HOLDOVER;
            end else begin
                state_next = TB_TRACKING;
            end
        end
    end

    always @(*) begin
        bit_period_est_next = bit_period_est_ff;

        if (state_ff == TB_UNLOCKED) begin
            bit_period_est_next = default_period;
        end else if (pending_apply == 1'b1) begin
            bit_period_est_next = pending_period_ff;
        end else if ((interval_ready == 1'b1) && (large_error == 1'b0) && (active_block == 1'b0)) begin
            bit_period_est_next = period_adjusted;
        end
    end

    always @(*) begin
        bit_counter_next = bit_counter_next_count;

        if (sync_pulse == 1'b1) begin
            bit_counter_next = bit_counter_after_sync;
        end
    end

    always @(*) begin
        slot_next = slot_next_count;

        if (sync_pulse == 1'b1) begin
            slot_next = 3'd0;
        end else if (state_ff == TB_UNLOCKED) begin
            slot_next = 3'd0;
        end
    end

    always @(*) begin
        slot_clk_cnt_next = slot_clk_cnt_next_count;

        if (sync_pulse == 1'b1) begin
            slot_clk_cnt_next = sync_slot_preload;
        end else if (state_ff == TB_UNLOCKED) begin
            slot_clk_cnt_next = 16'd0;
        end
    end

    always @(*) begin
        cycle_count_next = cycle_count_next_count;

        if (sync_pulse == 1'b1) begin
            cycle_count_next = 32'd1;
        end
    end

    always @(*) begin
        have_sync_next = have_sync_ff;

        if (sync_pulse == 1'b1) begin
            have_sync_next = 1'b1;
        end
    end

    always @(*) begin
        pending_update_next = pending_update_ff;
        pending_period_next = pending_period_ff;

        if (pending_apply == 1'b1) begin
            pending_update_next = 1'b0;
        end

        if ((interval_ready == 1'b1) && (large_error == 1'b0) && (active_block == 1'b1)) begin
            pending_update_next = 1'b1;
            pending_period_next = period_adjusted;
        end
    end

    always @(*) begin
        rate_err_next = 1'b0;

        if (large_error == 1'b1) begin
            rate_err_next = 1'b1;
        end else if (state_next == TB_HOLDOVER) begin
            rate_err_next = 1'b1;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            state_ff <= TB_UNLOCKED;
        else
            state_ff <= state_next;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            bit_period_est_ff <= 16'd1;
        else
            bit_period_est_ff <= bit_period_est_next;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            bit_counter_ff <= 16'd0;
        else
            bit_counter_ff <= bit_counter_next;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            slot_ff <= 3'd0;
        else
            slot_ff <= slot_next;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            slot_clk_cnt_ff <= 16'd0;
        else
            slot_clk_cnt_ff <= slot_clk_cnt_next;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            cycle_count_ff <= 32'd0;
        else
            cycle_count_ff <= cycle_count_next;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            have_sync_ff <= 1'b0;
        else
            have_sync_ff <= have_sync_next;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            pending_update_ff <= 1'b0;
        else
            pending_update_ff <= pending_update_next;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            pending_period_ff <= 16'd1;
        else
            pending_period_ff <= pending_period_next;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            rate_err_ff <= 1'b0;
        else
            rate_err_ff <= rate_err_next;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            sample_tick_ff <= 1'b0;
        else
            sample_tick_ff <= sample_tick_next;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            sample_early_tick_ff <= 1'b0;
        else
            sample_early_tick_ff <= sample_early_tick_next;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            sample_late_tick_ff <= 1'b0;
        else
            sample_late_tick_ff <= sample_late_tick_next;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            tx_bit_tick_ff <= 1'b0;
        else
            tx_bit_tick_ff <= tx_bit_tick_next;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            tx_trigger_ff <= 1'b0;
        else
            tx_trigger_ff <= (!sync_pulse) && tx_trigger_match;
    end

    assign locked = (state_ff == TB_TRACKING);
    assign bit_period_est = bit_period_est_ff;
    assign slot = slot_ff;
    assign slot_clk_cnt = slot_clk_cnt_ff;
    assign sample_tick = sample_tick_ff;
    assign sample_early_tick = sample_early_tick_ff;
    assign sample_late_tick = sample_late_tick_ff;
    assign tx_bit_tick = tx_bit_tick_ff;
    assign tx_trigger = tx_trigger_ff;
    assign rate_err = rate_err_ff;

    assign o_LOCKED = locked;
    assign o_BIT_PERIOD_EST = bit_period_est;
    assign o_SLOT = slot;
    assign o_SLOT_CLK_CNT = slot_clk_cnt;
    assign o_SAMPLE_TICK = sample_tick;
    assign o_SAMPLE_EARLY_TICK = sample_early_tick;
    assign o_SAMPLE_LATE_TICK = sample_late_tick;
    assign o_TX_BIT_TICK = tx_bit_tick;
    assign o_TX_TRIGGER = tx_trigger;
    assign o_RATE_ERR = rate_err;

endmodule

