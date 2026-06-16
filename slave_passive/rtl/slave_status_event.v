// ---------------------------------------------------------------------------
// slave_status_event
// ---------------------------------------------------------------------------
// 코어 상태, pulse 이벤트, fault source를 AXI register view로 집계한다.
// EVENT/FAULT는 sticky register이며, PS가 W1C 방식으로 clear한다.
// ---------------------------------------------------------------------------

module slave_status_event (
    input  wire        i_clk,
    input  wire        i_resetn,

    input  wire        i_sts_enabled,
    input  wire        i_sts_synced,
    input  wire        i_sts_rx_active,
    input  wire        i_sts_tx_active,
    input  wire [2:0]  i_sts_current_slot,
    input  wire        i_sts_slot_valid,
    input  wire [7:0]  i_sts_halt_mask,
    input  wire        i_sts_cfg_pending,
    input  wire        i_sts_pl_payload6_valid,
    input  wire        i_sts_pl_payload7_valid,

    input  wire        i_evt_sync_detected,
    input  wire        i_evt_rx_frame_done,
    input  wire        i_evt_tx_done,
    input  wire        i_evt_slot_cycle_done,
    input  wire        i_evt_preamble_err,
    input  wire        i_evt_ham_1bit_err,
    input  wire        i_evt_ham_2bit_err,
    input  wire        i_evt_cfg_commit,

    input  wire        i_fault_tx_overlap,
    input  wire        i_fault_slot_timing_invalid,
    input  wire        i_fault_pl_payload6_invalid,
    input  wire        i_fault_pl_payload7_invalid,
    input  wire        i_fault_rx_ham_2bit,

    input  wire [31:0] i_event_clear_mask,
    input  wire [31:0] i_fault_clear_mask,

    output wire [31:0] o_status_reg_value,
    output wire [31:0] o_event_reg_value,
    output wire [31:0] o_fault_reg_value,
    output wire        o_irq
);

    // -----------------------------------------------------------------------
    // 파라미터 및 유효 비트 마스크
    // -----------------------------------------------------------------------
    // 정의되지 않은 EVENT/FAULT bit는 항상 0으로 읽히고 clear write도 무시된다.

    localparam [31:0] EVENT_VALID_MASK = 32'h0000_00FF;
    localparam [31:0] FAULT_VALID_MASK = 32'h0000_001F;

    // -----------------------------------------------------------------------
    // 포트 버퍼링
    // -----------------------------------------------------------------------
    // 상태 입력, 이벤트 pulse, fault source, W1C clear mask를 내부 wire로
    // 고정해 register packing과 sticky 로직을 분리해서 읽을 수 있게 한다.

    wire        clk;
    wire        resetn;
    wire        sts_enabled;
    wire        sts_synced;
    wire        sts_rx_active;
    wire        sts_tx_active;
    wire [2:0]  sts_current_slot;
    wire        sts_slot_valid;
    wire [7:0]  sts_halt_mask;
    wire        sts_cfg_pending;
    wire        sts_pl_payload6_valid;
    wire        sts_pl_payload7_valid;
    wire        evt_sync_detected;
    wire        evt_rx_frame_done;
    wire        evt_tx_done;
    wire        evt_slot_cycle_done;
    wire        evt_preamble_err;
    wire        evt_ham_1bit_err;
    wire        evt_ham_2bit_err;
    wire        evt_cfg_commit;
    wire        fault_tx_overlap;
    wire        fault_slot_timing_invalid;
    wire        fault_pl_payload6_invalid;
    wire        fault_pl_payload7_invalid;
    wire        fault_rx_ham_2bit;
    wire [31:0] event_clear_mask;
    wire [31:0] fault_clear_mask;

    assign clk                       = i_clk;
    assign resetn                    = i_resetn;
    assign sts_enabled               = i_sts_enabled;
    assign sts_synced                = i_sts_synced;
    assign sts_rx_active             = i_sts_rx_active;
    assign sts_tx_active             = i_sts_tx_active;
    assign sts_current_slot          = i_sts_current_slot;
    assign sts_slot_valid            = i_sts_slot_valid;
    assign sts_halt_mask             = i_sts_halt_mask;
    assign sts_cfg_pending           = i_sts_cfg_pending;
    assign sts_pl_payload6_valid     = i_sts_pl_payload6_valid;
    assign sts_pl_payload7_valid     = i_sts_pl_payload7_valid;
    assign evt_sync_detected         = i_evt_sync_detected;
    assign evt_rx_frame_done         = i_evt_rx_frame_done;
    assign evt_tx_done               = i_evt_tx_done;
    assign evt_slot_cycle_done       = i_evt_slot_cycle_done;
    assign evt_preamble_err          = i_evt_preamble_err;
    assign evt_ham_1bit_err          = i_evt_ham_1bit_err;
    assign evt_ham_2bit_err          = i_evt_ham_2bit_err;
    assign evt_cfg_commit            = i_evt_cfg_commit;
    assign fault_tx_overlap          = i_fault_tx_overlap;
    assign fault_slot_timing_invalid = i_fault_slot_timing_invalid;
    assign fault_pl_payload6_invalid = i_fault_pl_payload6_invalid;
    assign fault_pl_payload7_invalid = i_fault_pl_payload7_invalid;
    assign fault_rx_ham_2bit         = i_fault_rx_ham_2bit;
    assign event_clear_mask          = i_event_clear_mask;
    assign fault_clear_mask          = i_fault_clear_mask;

    // -----------------------------------------------------------------------
    // STATUS packing 및 EVENT/FAULT next-value 조합 논리
    // -----------------------------------------------------------------------
    // status_value는 즉시 상태를 조합으로 pack하고, event/fault는 sticky
    // register의 다음 값을 계산한다.

    reg [31:0] event_sticky_ff;
    reg [31:0] fault_sticky_ff;

    wire [31:0] event_source_mask;
    wire [31:0] fault_source_mask;
    wire [31:0] event_clear_valid;
    wire [31:0] fault_clear_valid;
    wire [31:0] status_value;
    wire [31:0] event_next;
    wire [31:0] fault_next;

    assign event_source_mask = {24'd0,
                                evt_cfg_commit,
                                evt_ham_2bit_err,
                                evt_ham_1bit_err,
                                evt_preamble_err,
                                evt_slot_cycle_done,
                                evt_tx_done,
                                evt_rx_frame_done,
                                evt_sync_detected};

    assign fault_source_mask = {27'd0,
                                fault_rx_ham_2bit,
                                fault_pl_payload7_invalid,
                                fault_pl_payload6_invalid,
                                fault_slot_timing_invalid,
                                fault_tx_overlap};

    assign event_clear_valid = event_clear_mask & EVENT_VALID_MASK;
    assign fault_clear_valid = fault_clear_mask & FAULT_VALID_MASK;

    // 새 event/fault source는 같은 clock의 W1C clear보다 우선한다.
    // firmware가 오래된 sticky bit를 clear하는 edge에서 1-clock pulse가
    // 사라지지 않게 하기 위한 정책이다.
    assign event_next = ((event_sticky_ff & EVENT_VALID_MASK) & ~event_clear_valid)
                        | (event_source_mask & EVENT_VALID_MASK);
    assign fault_next = ((fault_sticky_ff & FAULT_VALID_MASK) & ~fault_clear_valid)
                        | (fault_source_mask & FAULT_VALID_MASK);

    assign status_value = {13'd0,
                           sts_pl_payload7_valid,
                           sts_pl_payload6_valid,
                           sts_cfg_pending,
                           sts_halt_mask,
                           sts_slot_valid,
                           sts_current_slot,
                           sts_tx_active,
                           sts_rx_active,
                           sts_synced,
                           sts_enabled};

    // -----------------------------------------------------------------------
    // 순차 레지스터
    // -----------------------------------------------------------------------
    // EVENT와 FAULT sticky FF를 분리해 clear/source 우선순위를 독립적으로
    // 확인할 수 있게 한다.

    always @(posedge clk) begin
        if (resetn == 1'b0) begin
            event_sticky_ff <= 32'd0;
        end else begin
            event_sticky_ff <= event_next;
        end
    end

    always @(posedge clk) begin
        if (resetn == 1'b0) begin
            fault_sticky_ff <= 32'd0;
        end else begin
            fault_sticky_ff <= fault_next;
        end
    end

    // -----------------------------------------------------------------------
    // 출력 버퍼링
    // -----------------------------------------------------------------------
    // IRQ는 유효 EVENT/FAULT bit 중 하나라도 set이면 level high로 유지된다.

    assign o_status_reg_value = status_value;
    assign o_event_reg_value  = event_sticky_ff & EVENT_VALID_MASK;
    assign o_fault_reg_value  = fault_sticky_ff & FAULT_VALID_MASK;
    assign o_irq              = |((event_sticky_ff & EVENT_VALID_MASK) |
                                  (fault_sticky_ff & FAULT_VALID_MASK));

endmodule
