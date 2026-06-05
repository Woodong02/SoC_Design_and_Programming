`timescale 1ns / 1ps

// ---------------------------------------------------------------------------
// slave_tx_serializer
// ---------------------------------------------------------------------------
// frame builder에서 받은 50-bit 프레임을 MSB-first로 직렬화한다.
// cfg_bit_period_reload는 DIV_REG raw 값이며, timer가 reload 값을 직접 다시
// 적재하므로 각 bit는 reload+1 clock 동안 유지된다.
// ---------------------------------------------------------------------------
module slave_tx_serializer (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire [49:0] i_TX_FRAME,
    input  wire        i_TX_FRAME_VALID,
    input  wire [31:0] i_CFG_BIT_PERIOD_RELOAD,
    output wire        o_TX_FRAME_READY,
    output wire        o_SLAVE_SERIAL,
    output wire        o_SLAVE_OE,
    output wire        o_TX_ACTIVE,
    output wire        o_TX_DONE
);

    // -----------------------------------------------------------------------
    // FSM 상태 정의
    // -----------------------------------------------------------------------
    // IDLE에서 frame_valid를 받으면 프레임을 latch하고 ACTIVE로 이동한다.
    // 50번째 bit 유지 시간이 끝나면 DONE pulse를 만든 뒤 IDLE로 돌아간다.

    localparam [1:0] TX_IDLE   = 2'd0;
    localparam [1:0] TX_ACTIVE = 2'd1;
    localparam [1:0] TX_DONE   = 2'd2;

    // -----------------------------------------------------------------------
    // 내부 신호 선언
    // -----------------------------------------------------------------------

    wire        clk;
    wire        resetn;
    wire [49:0] tx_frame;
    wire        tx_frame_valid;
    wire [31:0] cfg_bit_period_reload;

    wire        start_request;
    wire        timer_expired;
    wire        active_last_bit_done;
    wire [5:0]  next_bit_index;
    wire [5:0]  next_frame_index;
    wire        tx_frame_ready;
    wire        slave_serial;
    wire        slave_oe;
    wire        tx_active;
    wire        tx_done;

    reg [1:0]  state_ff;
    reg [49:0] frame_ff;
    reg [5:0]  bit_index_ff;
    reg [31:0] timer_ff;
    reg [31:0] reload_ff;
    reg        serial_bit_ff;
    reg        tx_done_ff;

    // -----------------------------------------------------------------------
    // 포트 버퍼링
    // -----------------------------------------------------------------------

    assign clk = i_CLK;
    assign resetn = i_RESETN;
    assign tx_frame = i_TX_FRAME;
    assign tx_frame_valid = i_TX_FRAME_VALID;
    assign cfg_bit_period_reload = i_CFG_BIT_PERIOD_RELOAD;

    // -----------------------------------------------------------------------
    // 조합 논리
    // -----------------------------------------------------------------------
    // timer_expired는 현재 bit의 유지 시간이 끝났다는 의미다.
    // next_frame_index는 MSB-first 출력을 위해 bit_index를 49..0 주소로 변환한다.

    assign start_request = (state_ff == TX_IDLE) & tx_frame_valid;
    assign timer_expired = (timer_ff == 32'd0);
    assign active_last_bit_done = (state_ff == TX_ACTIVE) & timer_expired & (bit_index_ff == 6'd49);
    assign next_bit_index = bit_index_ff + 6'd1;
    assign next_frame_index = 6'd49 - next_bit_index;

    // -----------------------------------------------------------------------
    // 순차 레지스터
    // -----------------------------------------------------------------------
    // FSM, 프레임 latch, bit index, reload/timer, serial bit, done pulse를
    // 분리해 두어 각 FF 묶음의 책임을 쉽게 추적할 수 있게 한다.

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            state_ff <= TX_IDLE;
        end else begin
            if (state_ff == TX_IDLE) begin
                if (start_request == 1'b1) begin
                    state_ff <= TX_ACTIVE;
                end else begin
                    state_ff <= TX_IDLE;
                end
            end else if (state_ff == TX_ACTIVE) begin
                if (active_last_bit_done == 1'b1) begin
                    state_ff <= TX_DONE;
                end else begin
                    state_ff <= TX_ACTIVE;
                end
            end else if (state_ff == TX_DONE) begin
                state_ff <= TX_IDLE;
            end else begin
                state_ff <= TX_IDLE;
            end
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            frame_ff <= 50'd0;
        end else begin
            if (start_request == 1'b1) begin
                frame_ff <= tx_frame;
            end else begin
                frame_ff <= frame_ff;
            end
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            bit_index_ff <= 6'd0;
        end else begin
            if (start_request == 1'b1) begin
                bit_index_ff <= 6'd0;
            end else if (state_ff == TX_ACTIVE) begin
                if (timer_expired == 1'b1) begin
                    if (bit_index_ff == 6'd49) begin
                        bit_index_ff <= 6'd0;
                    end else begin
                        bit_index_ff <= next_bit_index;
                    end
                end else begin
                    bit_index_ff <= bit_index_ff;
                end
            end else begin
                bit_index_ff <= 6'd0;
            end
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            reload_ff <= 32'd0;
        end else begin
            if (start_request == 1'b1) begin
                reload_ff <= cfg_bit_period_reload;
            end else begin
                reload_ff <= reload_ff;
            end
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            timer_ff <= 32'd0;
        end else begin
            if (start_request == 1'b1) begin
                timer_ff <= cfg_bit_period_reload;
            end else if (state_ff == TX_ACTIVE) begin
                if (timer_expired == 1'b1) begin
                    timer_ff <= reload_ff;
                end else begin
                    timer_ff <= timer_ff - 32'd1;
                end
            end else begin
                timer_ff <= 32'd0;
            end
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            serial_bit_ff <= 1'b0;
        end else begin
            if (start_request == 1'b1) begin
                serial_bit_ff <= tx_frame[49];
            end else if (state_ff == TX_ACTIVE) begin
                if (timer_expired == 1'b1) begin
                    if (bit_index_ff == 6'd49) begin
                        serial_bit_ff <= 1'b0;
                    end else begin
                        serial_bit_ff <= frame_ff[next_frame_index];
                    end
                end else begin
                    serial_bit_ff <= serial_bit_ff;
                end
            end else begin
                serial_bit_ff <= 1'b0;
            end
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            tx_done_ff <= 1'b0;
        end else begin
            tx_done_ff <= active_last_bit_done;
        end
    end

    // -----------------------------------------------------------------------
    // 출력 버퍼링
    // -----------------------------------------------------------------------

    assign tx_frame_ready = (state_ff == TX_IDLE);
    assign slave_serial = (state_ff == TX_ACTIVE) ? serial_bit_ff : 1'b0;
    assign slave_oe = (state_ff == TX_ACTIVE);
    assign tx_active = (state_ff == TX_ACTIVE);
    assign tx_done = tx_done_ff;

    assign o_TX_FRAME_READY = tx_frame_ready;
    assign o_SLAVE_SERIAL = slave_serial;
    assign o_SLAVE_OE = slave_oe;
    assign o_TX_ACTIVE = tx_active;
    assign o_TX_DONE = tx_done;

endmodule
