`timescale 1ns / 1ps

module slave21_tx (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire [2:0]  i_NODE_ID,
    input  wire [31:0] i_PAYLOAD,
    input  wire [15:0] i_BIT_PERIOD,
    input  wire        i_TX_TRIGGER,
    input  wire        i_TX_ENABLE,
    output wire        o_SERIAL_OUT,
    output wire        o_TX_ACTIVE,
    output wire        o_TX_DONE
);

    localparam [1:0] TX21_IDLE   = 2'd0;
    localparam [1:0] TX21_ACTIVE = 2'd1;
    localparam [1:0] TX21_DONE   = 2'd2;

    wire        clk;
    wire        resetn;
    wire [2:0]  node_id;
    wire [31:0] payload;
    wire [15:0] bit_period;
    wire        tx_trigger;
    wire        tx_enable;

    wire [15:0] bit_period_sanitized;
    wire [34:0] encoder_data;
    wire [41:0] encoder_codeword;
    wire [49:0] tx_frame;
    wire        start_request;
    wire        timer_expired;
    wire        active_last_bit_done;
    wire [5:0]  next_bit_index;
    wire [5:0]  next_frame_index;
    wire        serial_out;
    wire        tx_active;
    wire        tx_done;

    reg [1:0]  state_ff;
    reg [49:0] frame_ff;
    reg [5:0]  bit_index_ff;
    reg [15:0] period_ff;
    reg [15:0] timer_ff;
    reg        serial_bit_ff;
    reg        tx_done_ff;

    assign clk = i_CLK;
    assign resetn = i_RESETN;
    assign node_id = i_NODE_ID;
    assign payload = i_PAYLOAD;
    assign bit_period = i_BIT_PERIOD;
    assign tx_trigger = i_TX_TRIGGER;
    assign tx_enable = i_TX_ENABLE;

    assign bit_period_sanitized = (bit_period == 16'd0) ? 16'd1 : bit_period;
    assign encoder_data = {node_id, payload};

    slave_hamming_enc u_slave_hamming_enc (
        .i_DATA(encoder_data),
        .o_CODEWORD(encoder_codeword)
    );

    assign tx_frame = {8'hAA, encoder_codeword};
    assign start_request = (state_ff == TX21_IDLE) & tx_trigger & tx_enable;
    assign timer_expired = (timer_ff == 16'd0);
    assign active_last_bit_done = (state_ff == TX21_ACTIVE) & timer_expired & (bit_index_ff == 6'd49);
    assign next_bit_index = bit_index_ff + 6'd1;
    assign next_frame_index = 6'd49 - next_bit_index;

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            state_ff <= TX21_IDLE;
        end else begin
            if (state_ff == TX21_IDLE) begin
                if (start_request == 1'b1) begin
                    state_ff <= TX21_ACTIVE;
                end else begin
                    state_ff <= TX21_IDLE;
                end
            end else if (state_ff == TX21_ACTIVE) begin
                if (active_last_bit_done == 1'b1) begin
                    state_ff <= TX21_DONE;
                end else begin
                    state_ff <= TX21_ACTIVE;
                end
            end else if (state_ff == TX21_DONE) begin
                state_ff <= TX21_IDLE;
            end else begin
                state_ff <= TX21_IDLE;
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
            end else if (state_ff == TX21_ACTIVE) begin
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
            period_ff <= 16'd1;
        end else begin
            if (start_request == 1'b1) begin
                period_ff <= bit_period_sanitized;
            end else begin
                period_ff <= period_ff;
            end
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            timer_ff <= 16'd0;
        end else begin
            if (start_request == 1'b1) begin
                timer_ff <= bit_period_sanitized - 16'd1;
            end else if (state_ff == TX21_ACTIVE) begin
                if (timer_expired == 1'b1) begin
                    timer_ff <= period_ff - 16'd1;
                end else begin
                    timer_ff <= timer_ff - 16'd1;
                end
            end else begin
                timer_ff <= 16'd0;
            end
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            serial_bit_ff <= 1'b0;
        end else begin
            if (start_request == 1'b1) begin
                serial_bit_ff <= tx_frame[49];
            end else if (state_ff == TX21_ACTIVE) begin
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

    assign serial_out = (state_ff == TX21_ACTIVE) ? serial_bit_ff : 1'b0;
    assign tx_active = (state_ff == TX21_ACTIVE);
    assign tx_done = tx_done_ff;

    assign o_SERIAL_OUT = serial_out;
    assign o_TX_ACTIVE = tx_active;
    assign o_TX_DONE = tx_done;

endmodule
