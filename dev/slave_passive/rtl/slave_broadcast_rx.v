`timescale 1ns / 1ps

// ---------------------------------------------------------------------------
// slave_broadcast_rx
// ---------------------------------------------------------------------------
// sync 감지 이후 master broadcast 50-bit 프레임을 bit 중앙에서 샘플링한다.
// preamble 8-bit(8'hAA)를 먼저 확인하고, 정상 preamble이면 42-bit Hamming
// codeword를 수집해 decoder로 넘긴다.
// ---------------------------------------------------------------------------
module slave_broadcast_rx (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire        i_SERIAL_IN,
    input  wire        i_CFG_ENABLE,
    input  wire [31:0] i_CFG_BIT_PERIOD_RELOAD,
    input  wire        i_SYNC_PULSE,
    output wire [41:0] o_RX_CODEWORD,
    output wire        o_RX_CODEWORD_VALID,
    output wire        o_RX_FRAME_DONE,
    output wire        o_RX_PREAMBLE_OK,
    output wire        o_RX_PREAMBLE_ERR,
    output wire        o_RX_ACTIVE
);

    // -----------------------------------------------------------------------
    // FSM 상태 정의
    // -----------------------------------------------------------------------
    // RX_ERROR는 preamble 실패 후 남은 codeword 길이만큼 시간을 소비해,
    // 잘못된 프레임 중간의 에지가 다음 sync로 오인되는 일을 줄인다.

    localparam [2:0] RX_IDLE     = 3'd0;
    localparam [2:0] RX_PREAMBLE = 3'd1;
    localparam [2:0] RX_CODEWORD = 3'd2;
    localparam [2:0] RX_ERROR    = 3'd3;
    localparam [2:0] RX_DONE     = 3'd4;

    // -----------------------------------------------------------------------
    // 내부 신호 선언
    // -----------------------------------------------------------------------

    wire        clk;
    wire        resetn;
    wire        serial_in;
    wire        cfg_enable;
    wire [31:0] cfg_bit_period_reload;
    wire        sync_pulse;

    wire [32:0] bit_period_ticks;
    wire [32:0] start_half_ticks;
    wire [31:0] start_sample_delay;
    wire        immediate_start_sample;
    wire        start_request;
    wire        timer_expired;
    wire        timed_sample;
    wire        sample_commit;
    wire        preamble_sample;
    wire        codeword_sample;
    wire        error_sample;
    wire        preamble_last_sample;
    wire        codeword_last_sample;
    wire        error_last_sample;
    wire [7:0]  shifted_preamble;
    wire [41:0] shifted_codeword;
    wire        preamble_success;
    wire        preamble_failure;
    wire        rx_active;

    reg [2:0]  state_ff;
    reg [5:0]  bit_count_ff;
    reg [31:0] period_reload_ff;
    reg [31:0] sample_timer_ff;
    reg [7:0]  preamble_shift_ff;
    reg [41:0] codeword_shift_ff;
    reg [41:0] codeword_out_ff;
    reg        codeword_valid_ff;
    reg        frame_done_ff;
    reg        preamble_ok_ff;
    reg        preamble_err_ff;

    wire [41:0] rx_codeword;
    wire        rx_codeword_valid;
    wire        rx_frame_done;
    wire        rx_preamble_ok;
    wire        rx_preamble_err;

    // -----------------------------------------------------------------------
    // 포트 버퍼링
    // -----------------------------------------------------------------------

    assign clk = i_CLK;
    assign resetn = i_RESETN;
    assign serial_in = i_SERIAL_IN;
    assign cfg_enable = i_CFG_ENABLE;
    assign cfg_bit_period_reload = i_CFG_BIT_PERIOD_RELOAD;
    assign sync_pulse = i_SYNC_PULSE;

    // -----------------------------------------------------------------------
    // 조합 논리
    // -----------------------------------------------------------------------
    // 첫 sample은 sync edge 이후 half bit 지점에 맞추고, 이후 sample은
    // period_reload_ff를 반복 적재하여 동일 bit period로 진행한다.
    // bit_period_ticks는 DIV_REG raw 값 + 1로 계산된다.

    assign bit_period_ticks = {1'b0, cfg_bit_period_reload} + 33'd1;
    assign start_half_ticks = bit_period_ticks >> 1;
    assign start_sample_delay = (start_half_ticks == 33'd0) ? 32'd0 : (start_half_ticks[31:0] - 32'd1);
    assign immediate_start_sample = start_request & (bit_period_ticks == 33'd1);
    assign start_request = cfg_enable & sync_pulse & (state_ff == RX_IDLE);
    assign timer_expired = (sample_timer_ff == 32'd0);
    assign timed_sample = ((state_ff == RX_PREAMBLE) | (state_ff == RX_CODEWORD) | (state_ff == RX_ERROR)) & timer_expired;
    assign sample_commit = immediate_start_sample | timed_sample;
    assign preamble_sample = immediate_start_sample | ((state_ff == RX_PREAMBLE) & timed_sample);
    assign codeword_sample = (state_ff == RX_CODEWORD) & timed_sample;
    assign error_sample = (state_ff == RX_ERROR) & timed_sample;
    assign preamble_last_sample = preamble_sample & (bit_count_ff == 6'd7);
    assign codeword_last_sample = codeword_sample & (bit_count_ff == 6'd41);
    assign error_last_sample = error_sample & (bit_count_ff == 6'd41);
    assign shifted_preamble = {preamble_shift_ff[6:0], serial_in};
    assign shifted_codeword = {codeword_shift_ff[40:0], serial_in};
    assign preamble_success = preamble_last_sample & (shifted_preamble == 8'hAA);
    assign preamble_failure = preamble_last_sample & (shifted_preamble != 8'hAA);
    assign rx_active = (state_ff == RX_PREAMBLE) | (state_ff == RX_CODEWORD) | (state_ff == RX_ERROR);

    // -----------------------------------------------------------------------
    // 순차 레지스터
    // -----------------------------------------------------------------------
    // FSM, bit counter, sample timer, preamble/codeword shift register,
    // 완료/오류 pulse를 각각 분리해 수신 경로의 책임을 추적하기 쉽게 한다.

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            state_ff <= RX_IDLE;
        end else if (cfg_enable == 1'b0) begin
            state_ff <= RX_IDLE;
        end else if (state_ff == RX_IDLE) begin
            if (start_request == 1'b1) begin
                state_ff <= RX_PREAMBLE;
            end else begin
                state_ff <= RX_IDLE;
            end
        end else if (state_ff == RX_PREAMBLE) begin
            if (preamble_success == 1'b1) begin
                state_ff <= RX_CODEWORD;
            end else if (preamble_failure == 1'b1) begin
                state_ff <= RX_ERROR;
            end else begin
                state_ff <= RX_PREAMBLE;
            end
        end else if (state_ff == RX_CODEWORD) begin
            if (codeword_last_sample == 1'b1) begin
                state_ff <= RX_DONE;
            end else begin
                state_ff <= RX_CODEWORD;
            end
        end else if (state_ff == RX_ERROR) begin
            if (error_last_sample == 1'b1) begin
                state_ff <= RX_IDLE;
            end else begin
                state_ff <= RX_ERROR;
            end
        end else if (state_ff == RX_DONE) begin
            state_ff <= RX_IDLE;
        end else begin
            state_ff <= RX_IDLE;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            bit_count_ff <= 6'd0;
        end else if (preamble_success | preamble_failure | codeword_last_sample | error_last_sample) begin
            bit_count_ff <= 6'd0;
        end else if (preamble_sample | codeword_sample | error_sample) begin
            bit_count_ff <= bit_count_ff + 6'd1;
        end else if ((cfg_enable == 1'b0) | (state_ff == RX_IDLE) | (state_ff == RX_DONE)) begin
            bit_count_ff <= 6'd0;
        end else begin
            bit_count_ff <= bit_count_ff;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            period_reload_ff <= 32'd0;
        end else if (start_request == 1'b1) begin
            period_reload_ff <= cfg_bit_period_reload;
        end else if ((state_ff == RX_DONE) | error_last_sample | (cfg_enable == 1'b0)) begin
            period_reload_ff <= 32'd0;
        end else begin
            period_reload_ff <= period_reload_ff;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            sample_timer_ff <= 32'd0;
        end else if (cfg_enable == 1'b0) begin
            sample_timer_ff <= 32'd0;
        end else if (start_request == 1'b1) begin
            sample_timer_ff <= start_sample_delay;
        end else if (sample_commit == 1'b1) begin
            sample_timer_ff <= period_reload_ff;
        end else if (((state_ff == RX_PREAMBLE) | (state_ff == RX_CODEWORD) | (state_ff == RX_ERROR)) & (sample_timer_ff != 32'd0)) begin
            sample_timer_ff <= sample_timer_ff - 32'd1;
        end else if ((state_ff == RX_DONE) | (state_ff == RX_IDLE)) begin
            sample_timer_ff <= 32'd0;
        end else begin
            sample_timer_ff <= sample_timer_ff;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            preamble_shift_ff <= 8'd0;
        end else if (preamble_sample == 1'b1) begin
            preamble_shift_ff <= shifted_preamble;
        end else if ((state_ff == RX_IDLE) & (start_request == 1'b0)) begin
            preamble_shift_ff <= 8'd0;
        end else if (state_ff == RX_DONE) begin
            preamble_shift_ff <= 8'd0;
        end else begin
            preamble_shift_ff <= preamble_shift_ff;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            codeword_shift_ff <= 42'd0;
        end else if (codeword_sample == 1'b1) begin
            codeword_shift_ff <= shifted_codeword;
        end else if ((state_ff == RX_IDLE) | (state_ff == RX_DONE)) begin
            codeword_shift_ff <= 42'd0;
        end else begin
            codeword_shift_ff <= codeword_shift_ff;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            codeword_out_ff <= 42'd0;
        end else if (codeword_last_sample == 1'b1) begin
            codeword_out_ff <= shifted_codeword;
        end else begin
            codeword_out_ff <= codeword_out_ff;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            codeword_valid_ff <= 1'b0;
        end else begin
            codeword_valid_ff <= codeword_last_sample;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            frame_done_ff <= 1'b0;
        end else begin
            frame_done_ff <= codeword_last_sample | preamble_failure;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            preamble_ok_ff <= 1'b0;
        end else begin
            preamble_ok_ff <= preamble_success;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            preamble_err_ff <= 1'b0;
        end else begin
            preamble_err_ff <= preamble_failure;
        end
    end

    // -----------------------------------------------------------------------
    // 출력 버퍼링
    // -----------------------------------------------------------------------

    assign rx_codeword = codeword_out_ff;
    assign rx_codeword_valid = codeword_valid_ff;
    assign rx_frame_done = frame_done_ff;
    assign rx_preamble_ok = preamble_ok_ff;
    assign rx_preamble_err = preamble_err_ff;

    assign o_RX_CODEWORD = rx_codeword;
    assign o_RX_CODEWORD_VALID = rx_codeword_valid;
    assign o_RX_FRAME_DONE = rx_frame_done;
    assign o_RX_PREAMBLE_OK = rx_preamble_ok;
    assign o_RX_PREAMBLE_ERR = rx_preamble_err;
    assign o_RX_ACTIVE = rx_active;

endmodule
