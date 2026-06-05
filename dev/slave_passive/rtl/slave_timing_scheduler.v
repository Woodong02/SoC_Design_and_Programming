`timescale 1ns / 1ps

// ---------------------------------------------------------------------------
// slave_timing_scheduler
// ---------------------------------------------------------------------------
// master sync pulse를 기준으로 frame/slot/guard-half tick을 계산하고,
// slot 0..7의 송신 목표 tick에서 one-hot match pulse를 만든다.
// 타이밍 계산 결과는 sync 시점에 FF로 잡아 cycle_done까지 고정한다.
// ---------------------------------------------------------------------------
module slave_timing_scheduler (
    input  wire        clk,
    input  wire        resetn,
    input  wire        cfg_enable,
    input  wire        sync_pulse,
    input  wire        cycle_done,
    input  wire [32:0] cfg_bit_period_ticks,
    input  wire [9:0]  cfg_guard_ticks,
    output wire        schedule_active,
    output wire [63:0] sync_tick_counter,
    output wire [63:0] frame_ticks,
    output wire [63:0] slot_ticks,
    output wire [63:0] guard_half_ticks,
    output wire [7:0]  slot_time_match,
    output wire [63:0] slot_target_tick0,
    output wire [63:0] slot_target_tick1,
    output wire [63:0] slot_target_tick2,
    output wire [63:0] slot_target_tick3,
    output wire [63:0] slot_target_tick4,
    output wire [63:0] slot_target_tick5,
    output wire [63:0] slot_target_tick6,
    output wire [63:0] slot_target_tick7
);

    // ---------------------------------------------------------------------------
    // 포트 버퍼링
    // ---------------------------------------------------------------------------
    // 외부 설정 및 sync 입력을 내부 core_* wire로 고정한다.

    wire        core_clk;
    wire        core_resetn;
    wire        cfg_enable_core;
    wire        sync_pulse_core;
    wire        cycle_done_core;
    wire [32:0] cfg_bit_period_ticks_core;
    wire [9:0]  cfg_guard_ticks_core;

    assign core_clk = clk;
    assign core_resetn = resetn;
    assign cfg_enable_core = cfg_enable;
    assign sync_pulse_core = sync_pulse;
    assign cycle_done_core = cycle_done;
    assign cfg_bit_period_ticks_core = cfg_bit_period_ticks;
    assign cfg_guard_ticks_core = cfg_guard_ticks;

    // ---------------------------------------------------------------------------
    // 타이밍 계산 조합 논리
    // ---------------------------------------------------------------------------
    // bit period는 DIV_REG raw 값 + 1로 들어온 cfg_bit_period_ticks를 사용한다.
    // guard_half는 bit shift로 계산해 1의 자리를 버린다.

    wire [63:0] bit_period_ticks_64;
    wire [63:0] guard_ticks_64;
    wire [63:0] frame_ticks_calc;
    wire [63:0] slot_ticks_calc;
    wire [63:0] guard_half_ticks_calc;
    wire [63:0] slot_target_tick0_calc;
    wire [63:0] slot_target_tick1_calc;
    wire [63:0] slot_target_tick2_calc;
    wire [63:0] slot_target_tick3_calc;
    wire [63:0] slot_target_tick4_calc;
    wire [63:0] slot_target_tick5_calc;
    wire [63:0] slot_target_tick6_calc;
    wire [63:0] slot_target_tick7_calc;
    wire        schedule_start;
    wire [63:0] sync_tick_counter_next_value;
    wire [7:0]  slot_time_match_next_value;

    reg         schedule_active_ff;
    reg  [63:0] sync_tick_counter_ff;
    reg  [63:0] frame_ticks_ff;
    reg  [63:0] slot_ticks_ff;
    reg  [63:0] guard_half_ticks_ff;
    reg  [63:0] slot_target_tick0_ff;
    reg  [63:0] slot_target_tick1_ff;
    reg  [63:0] slot_target_tick2_ff;
    reg  [63:0] slot_target_tick3_ff;
    reg  [63:0] slot_target_tick4_ff;
    reg  [63:0] slot_target_tick5_ff;
    reg  [63:0] slot_target_tick6_ff;
    reg  [63:0] slot_target_tick7_ff;
    reg  [7:0]  slot_time_match_ff;

    assign bit_period_ticks_64 = {31'd0, cfg_bit_period_ticks_core};
    assign guard_ticks_64 = {54'd0, cfg_guard_ticks_core};

    // 타이밍 기준식:
    // frame = 50 * bit_period_ticks, slot = frame + guard,
    // target[n] = frame + n * slot + (guard >> 1).
    assign frame_ticks_calc = bit_period_ticks_64 * 64'd50;
    assign slot_ticks_calc = frame_ticks_calc + guard_ticks_64;
    assign guard_half_ticks_calc = {55'd0, cfg_guard_ticks_core[9:1]};
    assign slot_target_tick0_calc = frame_ticks_calc + guard_half_ticks_calc;
    assign slot_target_tick1_calc = slot_target_tick0_calc + slot_ticks_calc;
    assign slot_target_tick2_calc = slot_target_tick1_calc + slot_ticks_calc;
    assign slot_target_tick3_calc = slot_target_tick2_calc + slot_ticks_calc;
    assign slot_target_tick4_calc = slot_target_tick3_calc + slot_ticks_calc;
    assign slot_target_tick5_calc = slot_target_tick4_calc + slot_ticks_calc;
    assign slot_target_tick6_calc = slot_target_tick5_calc + slot_ticks_calc;
    assign slot_target_tick7_calc = slot_target_tick6_calc + slot_ticks_calc;

    assign schedule_start = cfg_enable_core & sync_pulse_core;

    assign sync_tick_counter_next_value =
        (schedule_start == 1'b1) ? 64'd0 :
        ((cycle_done_core == 1'b1) ? 64'd0 :
        ((schedule_active_ff == 1'b1) ? (sync_tick_counter_ff + 64'd1) : 64'd0));

    assign slot_time_match_next_value[0] =
        (cfg_enable_core == 1'b1) & (schedule_start == 1'b0) &
        (schedule_active_ff == 1'b1) &
        (sync_tick_counter_next_value == slot_target_tick0_ff);
    assign slot_time_match_next_value[1] =
        (cfg_enable_core == 1'b1) & (schedule_start == 1'b0) &
        (schedule_active_ff == 1'b1) &
        (sync_tick_counter_next_value == slot_target_tick1_ff);
    assign slot_time_match_next_value[2] =
        (cfg_enable_core == 1'b1) & (schedule_start == 1'b0) &
        (schedule_active_ff == 1'b1) &
        (sync_tick_counter_next_value == slot_target_tick2_ff);
    assign slot_time_match_next_value[3] =
        (cfg_enable_core == 1'b1) & (schedule_start == 1'b0) &
        (schedule_active_ff == 1'b1) &
        (sync_tick_counter_next_value == slot_target_tick3_ff);
    assign slot_time_match_next_value[4] =
        (cfg_enable_core == 1'b1) & (schedule_start == 1'b0) &
        (schedule_active_ff == 1'b1) &
        (sync_tick_counter_next_value == slot_target_tick4_ff);
    assign slot_time_match_next_value[5] =
        (cfg_enable_core == 1'b1) & (schedule_start == 1'b0) &
        (schedule_active_ff == 1'b1) &
        (sync_tick_counter_next_value == slot_target_tick5_ff);
    assign slot_time_match_next_value[6] =
        (cfg_enable_core == 1'b1) & (schedule_start == 1'b0) &
        (schedule_active_ff == 1'b1) &
        (sync_tick_counter_next_value == slot_target_tick6_ff);
    assign slot_time_match_next_value[7] =
        (cfg_enable_core == 1'b1) & (schedule_start == 1'b0) &
        (schedule_active_ff == 1'b1) &
        (sync_tick_counter_next_value == slot_target_tick7_ff);

    // ---------------------------------------------------------------------------
    // 순차 레지스터
    // ---------------------------------------------------------------------------
    // schedule_active, sync tick counter, 계산된 timing snapshot, slot match를
    // 분리된 FF로 잡아 sequencer가 조합 계산 없이 match만 보게 한다.
    // sequencer의 slot_cycle_done이 들어오면 schedule_active를 내려 idle
    // commit 경계가 다시 열리게 한다.

    always @(posedge core_clk or negedge core_resetn) begin
        if (core_resetn == 1'b0) begin
            schedule_active_ff <= 1'b0;
        end else if (cfg_enable_core == 1'b0) begin
            schedule_active_ff <= 1'b0;
        end else if (sync_pulse_core == 1'b1) begin
            schedule_active_ff <= 1'b1;
        end else if (cycle_done_core == 1'b1) begin
            schedule_active_ff <= 1'b0;
        end
    end

    always @(posedge core_clk or negedge core_resetn) begin
        if (core_resetn == 1'b0) begin
            sync_tick_counter_ff <= 64'd0;
        end else if (cfg_enable_core == 1'b0) begin
            sync_tick_counter_ff <= 64'd0;
        end else begin
            sync_tick_counter_ff <= sync_tick_counter_next_value;
        end
    end

    always @(posedge core_clk or negedge core_resetn) begin
        if (core_resetn == 1'b0) begin
            frame_ticks_ff <= 64'd0;
        end else if (schedule_start == 1'b1) begin
            frame_ticks_ff <= frame_ticks_calc;
        end
    end

    always @(posedge core_clk or negedge core_resetn) begin
        if (core_resetn == 1'b0) begin
            slot_ticks_ff <= 64'd0;
        end else if (schedule_start == 1'b1) begin
            slot_ticks_ff <= slot_ticks_calc;
        end
    end

    always @(posedge core_clk or negedge core_resetn) begin
        if (core_resetn == 1'b0) begin
            guard_half_ticks_ff <= 64'd0;
        end else if (schedule_start == 1'b1) begin
            guard_half_ticks_ff <= guard_half_ticks_calc;
        end
    end

    always @(posedge core_clk or negedge core_resetn) begin
        if (core_resetn == 1'b0) begin
            slot_target_tick0_ff <= 64'd0;
        end else if (schedule_start == 1'b1) begin
            slot_target_tick0_ff <= slot_target_tick0_calc;
        end
    end

    always @(posedge core_clk or negedge core_resetn) begin
        if (core_resetn == 1'b0) begin
            slot_target_tick1_ff <= 64'd0;
        end else if (schedule_start == 1'b1) begin
            slot_target_tick1_ff <= slot_target_tick1_calc;
        end
    end

    always @(posedge core_clk or negedge core_resetn) begin
        if (core_resetn == 1'b0) begin
            slot_target_tick2_ff <= 64'd0;
        end else if (schedule_start == 1'b1) begin
            slot_target_tick2_ff <= slot_target_tick2_calc;
        end
    end

    always @(posedge core_clk or negedge core_resetn) begin
        if (core_resetn == 1'b0) begin
            slot_target_tick3_ff <= 64'd0;
        end else if (schedule_start == 1'b1) begin
            slot_target_tick3_ff <= slot_target_tick3_calc;
        end
    end

    always @(posedge core_clk or negedge core_resetn) begin
        if (core_resetn == 1'b0) begin
            slot_target_tick4_ff <= 64'd0;
        end else if (schedule_start == 1'b1) begin
            slot_target_tick4_ff <= slot_target_tick4_calc;
        end
    end

    always @(posedge core_clk or negedge core_resetn) begin
        if (core_resetn == 1'b0) begin
            slot_target_tick5_ff <= 64'd0;
        end else if (schedule_start == 1'b1) begin
            slot_target_tick5_ff <= slot_target_tick5_calc;
        end
    end

    always @(posedge core_clk or negedge core_resetn) begin
        if (core_resetn == 1'b0) begin
            slot_target_tick6_ff <= 64'd0;
        end else if (schedule_start == 1'b1) begin
            slot_target_tick6_ff <= slot_target_tick6_calc;
        end
    end

    always @(posedge core_clk or negedge core_resetn) begin
        if (core_resetn == 1'b0) begin
            slot_target_tick7_ff <= 64'd0;
        end else if (schedule_start == 1'b1) begin
            slot_target_tick7_ff <= slot_target_tick7_calc;
        end
    end

    always @(posedge core_clk or negedge core_resetn) begin
        if (core_resetn == 1'b0) begin
            slot_time_match_ff <= 8'd0;
        end else if (cfg_enable_core == 1'b0) begin
            slot_time_match_ff <= 8'd0;
        end else begin
            slot_time_match_ff <= slot_time_match_next_value;
        end
    end

    // ---------------------------------------------------------------------------
    // 출력 버퍼링
    // ---------------------------------------------------------------------------
    // debug/status와 sequencer가 볼 수 있도록 timing snapshot과 match를 노출한다.

    assign schedule_active = schedule_active_ff;
    assign sync_tick_counter = sync_tick_counter_ff;
    assign frame_ticks = frame_ticks_ff;
    assign slot_ticks = slot_ticks_ff;
    assign guard_half_ticks = guard_half_ticks_ff;
    assign slot_time_match = slot_time_match_ff;
    assign slot_target_tick0 = slot_target_tick0_ff;
    assign slot_target_tick1 = slot_target_tick1_ff;
    assign slot_target_tick2 = slot_target_tick2_ff;
    assign slot_target_tick3 = slot_target_tick3_ff;
    assign slot_target_tick4 = slot_target_tick4_ff;
    assign slot_target_tick5 = slot_target_tick5_ff;
    assign slot_target_tick6 = slot_target_tick6_ff;
    assign slot_target_tick7 = slot_target_tick7_ff;

endmodule
