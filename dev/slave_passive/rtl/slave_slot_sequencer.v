`timescale 1ns / 1ps

// ---------------------------------------------------------------------------
// slave_slot_sequencer
// ---------------------------------------------------------------------------
// sync 이후 slot 0..7을 순서대로 순회하면서 활성 슬롯에 대해서만 TX 명령을
// 발행한다. active slot 설정과 halt mask는 cycle 시작 시점에 snapshot하여
// 하나의 master cycle 안에서 슬롯 정책이 바뀌지 않게 한다.
// ---------------------------------------------------------------------------
module slave_slot_sequencer (
    input  wire       i_CLK,
    input  wire       i_RESETN,
    input  wire       i_CFG_ENABLE,
    input  wire       i_SYNC_PULSE,
    input  wire [7:0] i_CFG_ACTIVE_SLOT,
    input  wire [7:0] i_HALT_MASK_SNAPSHOT,
    input  wire [7:0] i_SLOT_TIME_MATCH,
    input  wire       i_TX_CMD_READY,
    input  wire       i_TX_CMD_ACCEPT,
    input  wire       i_TX_CMD_SKIP,
    input  wire       i_TX_DONE,
    output wire       o_TX_CMD_VALID,
    output wire [2:0] o_TX_CMD_SLOT_ID,
    output wire       o_TX_SKIP_INVALID_PAYLOAD,
    output wire       o_SLOT_CYCLE_DONE,
    output wire [2:0] o_STS_CURRENT_SLOT,
    output wire       o_STS_SLOT_VALID,
    output wire       o_FAULT_TX_OVERLAP
);

    // -----------------------------------------------------------------------
    // FSM 상태 정의
    // -----------------------------------------------------------------------
    // WAIT_TARGET에서 timing scheduler의 one-hot match를 기다린 뒤,
    // 활성 슬롯이면 ISSUE_TX/WAIT_TX_DONE을 거치고 비활성 슬롯이면 바로
    // NEXT_SLOT으로 이동한다.

    localparam [2:0] SEQ_IDLE         = 3'd0;
    localparam [2:0] SEQ_WAIT_TARGET  = 3'd1;
    localparam [2:0] SEQ_ISSUE_TX     = 3'd2;
    localparam [2:0] SEQ_WAIT_TX_DONE = 3'd3;
    localparam [2:0] SEQ_NEXT_SLOT    = 3'd4;
    localparam [2:0] SEQ_DONE         = 3'd5;

    // -----------------------------------------------------------------------
    // 내부 신호 선언
    // -----------------------------------------------------------------------

    wire       clk;
    wire       resetn;
    wire       cfg_enable;
    wire       sync_pulse;
    wire [7:0] cfg_active_slot;
    wire [7:0] halt_mask_snapshot;
    wire [7:0] slot_time_match;
    wire       tx_cmd_ready;
    wire       tx_cmd_accept;
    wire       tx_cmd_skip;
    wire       tx_done;

    wire       start_cycle;
    wire       selected_slot_active;
    wire       selected_slot_match;
    wire       selected_slot_last;
    wire [7:0] effective_active_slot;
    wire [7:0] selected_slot_mask;
    wire       issue_complete;
    wire       issue_blocked;
    wire [2:0] next_slot_index;

    reg [2:0] state_ff;
    reg [2:0] slot_index_ff;
    reg [7:0] active_slot_snapshot_ff;
    reg [7:0] halt_mask_snapshot_ff;
    reg       slot_cycle_done_ff;
    reg       tx_skip_invalid_payload_ff;
    reg       fault_tx_overlap_ff;

    wire       tx_cmd_valid;
    wire [2:0] tx_cmd_slot_id;
    wire       tx_skip_invalid_payload;
    wire       slot_cycle_done;
    wire [2:0] sts_current_slot;
    wire       sts_slot_valid;
    wire       fault_tx_overlap;

    // -----------------------------------------------------------------------
    // 포트 버퍼링
    // -----------------------------------------------------------------------

    assign clk = i_CLK;
    assign resetn = i_RESETN;
    assign cfg_enable = i_CFG_ENABLE;
    assign sync_pulse = i_SYNC_PULSE;
    assign cfg_active_slot = i_CFG_ACTIVE_SLOT;
    assign halt_mask_snapshot = i_HALT_MASK_SNAPSHOT;
    assign slot_time_match = i_SLOT_TIME_MATCH;
    assign tx_cmd_ready = i_TX_CMD_READY;
    assign tx_cmd_accept = i_TX_CMD_ACCEPT;
    assign tx_cmd_skip = i_TX_CMD_SKIP;
    assign tx_done = i_TX_DONE;

    // -----------------------------------------------------------------------
    // 조합 논리
    // -----------------------------------------------------------------------
    // effective_active_slot은 PS active mask에서 master halt mask를 제거한
    // 실제 송신 대상이다. selected_slot_mask는 현재 slot_index만 one-hot으로
    // 세워 match/active 계산을 단순화한다.

    assign start_cycle = cfg_enable & sync_pulse;
    assign effective_active_slot = active_slot_snapshot_ff & ~halt_mask_snapshot_ff;
    assign selected_slot_mask = (8'b0000_0001 << slot_index_ff);
    assign selected_slot_active = |(effective_active_slot & selected_slot_mask);
    assign selected_slot_match = |(slot_time_match & selected_slot_mask);
    assign selected_slot_last = (slot_index_ff == 3'd7);
    assign issue_complete = tx_cmd_accept | tx_cmd_skip;
    assign issue_blocked = (state_ff == SEQ_ISSUE_TX) & selected_slot_active & ~tx_cmd_ready;
    assign next_slot_index = slot_index_ff + 3'd1;

    // -----------------------------------------------------------------------
    // 순차 레지스터
    // -----------------------------------------------------------------------
    // FSM, 현재 슬롯, cycle snapshot, fault sticky를 분리된 FF 묶음으로 둔다.
    // overlap fault는 새 sync cycle에서 clear되고, TX 명령을 받아줄 수 없는
    // 상황이 관측되면 해당 cycle 동안 유지된다.

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            state_ff <= SEQ_IDLE;
        end else begin
            if (start_cycle == 1'b1) begin
                state_ff <= SEQ_WAIT_TARGET;
            end else if (cfg_enable == 1'b0) begin
                state_ff <= SEQ_IDLE;
            end else if (state_ff == SEQ_IDLE) begin
                state_ff <= SEQ_IDLE;
            end else if (state_ff == SEQ_WAIT_TARGET) begin
                if (selected_slot_match == 1'b1) begin
                    if (selected_slot_active == 1'b1) begin
                        state_ff <= SEQ_ISSUE_TX;
                    end else begin
                        state_ff <= SEQ_NEXT_SLOT;
                    end
                end else begin
                    state_ff <= SEQ_WAIT_TARGET;
                end
            end else if (state_ff == SEQ_ISSUE_TX) begin
                if (tx_cmd_accept == 1'b1) begin
                    state_ff <= SEQ_WAIT_TX_DONE;
                end else if (tx_cmd_skip == 1'b1) begin
                    state_ff <= SEQ_NEXT_SLOT;
                end else begin
                    state_ff <= SEQ_ISSUE_TX;
                end
            end else if (state_ff == SEQ_WAIT_TX_DONE) begin
                if (tx_done == 1'b1) begin
                    state_ff <= SEQ_NEXT_SLOT;
                end else begin
                    state_ff <= SEQ_WAIT_TX_DONE;
                end
            end else if (state_ff == SEQ_NEXT_SLOT) begin
                if (selected_slot_last == 1'b1) begin
                    state_ff <= SEQ_DONE;
                end else begin
                    state_ff <= SEQ_WAIT_TARGET;
                end
            end else if (state_ff == SEQ_DONE) begin
                state_ff <= SEQ_IDLE;
            end else begin
                state_ff <= SEQ_IDLE;
            end
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            slot_index_ff <= 3'd0;
        end else begin
            if (start_cycle == 1'b1) begin
                slot_index_ff <= 3'd0;
            end else if (state_ff == SEQ_NEXT_SLOT) begin
                if (selected_slot_last == 1'b1) begin
                    slot_index_ff <= 3'd0;
                end else begin
                    slot_index_ff <= next_slot_index;
                end
            end else if (state_ff == SEQ_IDLE) begin
                slot_index_ff <= 3'd0;
            end else begin
                slot_index_ff <= slot_index_ff;
            end
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            active_slot_snapshot_ff <= 8'd0;
        end else begin
            if (start_cycle == 1'b1) begin
                active_slot_snapshot_ff <= cfg_active_slot;
            end else begin
                active_slot_snapshot_ff <= active_slot_snapshot_ff;
            end
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            halt_mask_snapshot_ff <= 8'd0;
        end else begin
            if (start_cycle == 1'b1) begin
                halt_mask_snapshot_ff <= halt_mask_snapshot;
            end else begin
                halt_mask_snapshot_ff <= halt_mask_snapshot_ff;
            end
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            slot_cycle_done_ff <= 1'b0;
        end else begin
            slot_cycle_done_ff <= (state_ff == SEQ_DONE);
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            tx_skip_invalid_payload_ff <= 1'b0;
        end else begin
            tx_skip_invalid_payload_ff <= (state_ff == SEQ_ISSUE_TX) & tx_cmd_skip;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            fault_tx_overlap_ff <= 1'b0;
        end else begin
            if (start_cycle == 1'b1) begin
                fault_tx_overlap_ff <= 1'b0;
            end else if (issue_blocked == 1'b1) begin
                fault_tx_overlap_ff <= 1'b1;
            end else begin
                fault_tx_overlap_ff <= fault_tx_overlap_ff;
            end
        end
    end

    // -----------------------------------------------------------------------
    // 출력 버퍼링
    // -----------------------------------------------------------------------

    assign tx_cmd_valid = (state_ff == SEQ_ISSUE_TX);
    assign tx_cmd_slot_id = slot_index_ff;
    assign tx_skip_invalid_payload = tx_skip_invalid_payload_ff;
    assign slot_cycle_done = slot_cycle_done_ff;
    assign sts_current_slot = slot_index_ff;
    assign sts_slot_valid = (state_ff != SEQ_IDLE);
    assign fault_tx_overlap = fault_tx_overlap_ff;

    assign o_TX_CMD_VALID = tx_cmd_valid;
    assign o_TX_CMD_SLOT_ID = tx_cmd_slot_id;
    assign o_TX_SKIP_INVALID_PAYLOAD = tx_skip_invalid_payload;
    assign o_SLOT_CYCLE_DONE = slot_cycle_done;
    assign o_STS_CURRENT_SLOT = sts_current_slot;
    assign o_STS_SLOT_VALID = sts_slot_valid;
    assign o_FAULT_TX_OVERLAP = fault_tx_overlap;

endmodule
