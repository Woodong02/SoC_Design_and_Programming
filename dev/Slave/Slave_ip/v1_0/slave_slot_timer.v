`timescale 1ns / 1ps

module slave_slot_timer (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire [2:0]  i_NODE_ID,
    input  wire [2:0]  i_NODE_CNT,
    input  wire [9:0]  i_BIT_DIV,
    input  wire [9:0]  i_GUARD_TICKS,
    input  wire        i_SYNC_PULSE,
    input  wire [15:0] i_SYNC_CLK_CNT,
    output wire        o_SYNCED,
    output wire [2:0]  o_SLOT,
    output wire [15:0] o_CLK_CNT,
    output wire        o_TX_TRIGGER
);

    parameter [15:0] FRAME_BITS = 16'd50;

    wire        clk;
    wire        resetn;
    wire [2:0]  node_id;
    wire [2:0]  node_cnt;
    wire [9:0]  bit_div;
    wire [9:0]  guard_ticks;
    wire        sync_pulse;
    wire [15:0] sync_clk_cnt;

    wire [15:0] data_len_ticks;
    wire [15:0] slot_ticks;
    wire [15:0] tx_start_tick;
    wire        slot_last_tick;
    wire        node_has_slot;
    wire        trigger_match;
    wire        next_synced;
    wire [2:0]  next_slot;
    wire [15:0] next_clk_cnt;
    wire        next_tx_trigger;

    reg         ff_synced;
    reg  [2:0] ff_slot;
    reg  [15:0] ff_clk_cnt;
    reg         ff_tx_trigger;

    assign clk          = i_CLK;
    assign resetn       = i_RESETN;
    assign node_id      = i_NODE_ID;
    assign node_cnt     = i_NODE_CNT;
    assign bit_div      = i_BIT_DIV;
    assign guard_ticks  = i_GUARD_TICKS;
    assign sync_pulse   = i_SYNC_PULSE;
    assign sync_clk_cnt = i_SYNC_CLK_CNT;

    assign data_len_ticks = FRAME_BITS * {6'b0, bit_div};
    assign slot_ticks     = data_len_ticks + {6'b0, guard_ticks};
    // Future alternative under discussion: slot_ticks = (50 + GUARD_TICKS) * BIT_DIV.
    assign tx_start_tick  = {6'b0, (guard_ticks >> 1)};
    assign slot_last_tick = (slot_ticks != 16'd0) && (ff_clk_cnt == (slot_ticks - 16'd1));
    assign node_has_slot  = (node_id <= node_cnt);
    assign trigger_match  = ff_synced && node_has_slot && (ff_slot == node_id) && (ff_clk_cnt == tx_start_tick);

    assign next_synced = sync_pulse ? 1'b1 : ff_synced;

    assign next_slot = sync_pulse ? 3'd0 :
                       (!ff_synced) ? ff_slot :
                       (slot_last_tick && (ff_slot == node_cnt)) ? 3'd0 :
                       (slot_last_tick) ? (ff_slot + 3'd1) : ff_slot;

    assign next_clk_cnt = sync_pulse ? sync_clk_cnt :
                          (!ff_synced) ? 16'd0 :
                          (slot_last_tick) ? 16'd0 : (ff_clk_cnt + 16'd1);

    assign next_tx_trigger = (!sync_pulse) && trigger_match;

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            ff_synced <= 1'b0;
        else
            ff_synced <= next_synced;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            ff_slot <= 3'd0;
        else
            ff_slot <= next_slot;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            ff_clk_cnt <= 16'd0;
        else
            ff_clk_cnt <= next_clk_cnt;
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            ff_tx_trigger <= 1'b0;
        else
            ff_tx_trigger <= next_tx_trigger;
    end

    assign o_SYNCED     = ff_synced;
    assign o_SLOT       = ff_slot;
    assign o_CLK_CNT    = ff_clk_cnt;
    assign o_TX_TRIGGER = ff_tx_trigger;

endmodule
