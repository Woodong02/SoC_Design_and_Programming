// ---------------------------------------------------------------------------
// slave_axi_lite_regs
// ---------------------------------------------------------------------------
// PS가 접근하는 AXI-Lite register file이다. 설정 raw register, STATUS/EVENT/
// FAULT readback, W1C clear mask, debug timing readback을 담당한다.
// ---------------------------------------------------------------------------

module slave_axi_lite_regs #(
    parameter C_S_AXI_ADDR_WIDTH = 6
) (
    input  wire                          i_clk,
    input  wire                          i_resetn,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0] i_s_axi_awaddr,
    input  wire                          i_s_axi_awvalid,
    output wire                          o_s_axi_awready,
    input  wire [31:0]                   i_s_axi_wdata,
    input  wire [3:0]                    i_s_axi_wstrb,
    input  wire                          i_s_axi_wvalid,
    output wire                          o_s_axi_wready,
    output wire [1:0]                    o_s_axi_bresp,
    output wire                          o_s_axi_bvalid,
    input  wire                          i_s_axi_bready,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0] i_s_axi_araddr,
    input  wire                          i_s_axi_arvalid,
    output wire                          o_s_axi_arready,
    output wire [31:0]                   o_s_axi_rdata,
    output wire [1:0]                    o_s_axi_rresp,
    output wire                          o_s_axi_rvalid,
    input  wire                          i_s_axi_rready,

    input  wire [31:0]                   i_status_reg_value,
    input  wire [31:0]                   i_event_reg_value,
    input  wire [31:0]                   i_fault_reg_value,

    output wire                          o_reg_enable,
    output wire [9:0]                    o_reg_guard_ticks,
    output wire [7:0]                    o_reg_active_slot,
    output wire [31:0]                   o_reg_div,
    output wire [31:0]                   o_reg_data_out0,
    output wire [31:0]                   o_reg_data_out1,
    output wire [31:0]                   o_reg_data_out2,
    output wire [31:0]                   o_reg_data_out3,
    output wire [31:0]                   o_reg_data_out4,
    output wire [31:0]                   o_reg_data_out5,
    output wire                          o_reg_write_pulse,
    output wire [31:0]                   o_event_clear_mask,
    output wire [31:0]                   o_fault_clear_mask
);

    // -----------------------------------------------------------------------
    // 주소 및 유효 비트 마스크
    // -----------------------------------------------------------------------
    // 주소 offset은 32-bit word aligned AXI-Lite register map을 따른다.
    // *_VALID_MASK는 reserved bit가 읽기/쓰기 경로로 새지 않게 막는다.

    localparam [5:0] ADDR_CTRL              = 6'h00;
    localparam [5:0] ADDR_DIV               = 6'h04;
    localparam [5:0] ADDR_DATA_OUT0         = 6'h08;
    localparam [5:0] ADDR_DATA_OUT1         = 6'h0C;
    localparam [5:0] ADDR_DATA_OUT2         = 6'h10;
    localparam [5:0] ADDR_DATA_OUT3         = 6'h14;
    localparam [5:0] ADDR_DATA_OUT4         = 6'h18;
    localparam [5:0] ADDR_DATA_OUT5         = 6'h1C;
    localparam [5:0] ADDR_STATUS            = 6'h20;
    localparam [5:0] ADDR_EVENT             = 6'h24;
    localparam [5:0] ADDR_FAULT             = 6'h28;
    localparam [5:0] ADDR_DBG_BIT_PERIOD_LO = 6'h2C;
    localparam [5:0] ADDR_DBG_FRAME_LO      = 6'h30;
    localparam [5:0] ADDR_DBG_SLOT_LO       = 6'h34;
    localparam [5:0] ADDR_DBG_GUARD_HALF_LO = 6'h38;

    localparam [31:0] CTRL_VALID_MASK       = 32'h0007_FFFF;
    localparam [31:0] EVENT_VALID_MASK      = 32'h0000_00FF;
    localparam [31:0] FAULT_VALID_MASK      = 32'h0000_001F;

    // -----------------------------------------------------------------------
    // 포트 버퍼링
    // -----------------------------------------------------------------------
    // AXI 입력과 코어 상태 입력을 내부 wire로 버퍼링하여 register decode
    // 로직이 외부 포트명을 직접 참조하지 않게 한다.

    wire                          clk;
    wire                          resetn;
    wire [C_S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr;
    wire                          s_axi_awvalid;
    wire [31:0]                   s_axi_wdata;
    wire [3:0]                    s_axi_wstrb;
    wire                          s_axi_wvalid;
    wire                          s_axi_bready;
    wire [C_S_AXI_ADDR_WIDTH-1:0] s_axi_araddr;
    wire                          s_axi_arvalid;
    wire                          s_axi_rready;
    wire [31:0]                   status_reg_value;
    wire [31:0]                   event_reg_value;
    wire [31:0]                   fault_reg_value;

    assign clk              = i_clk;
    assign resetn           = i_resetn;
    assign s_axi_awaddr     = i_s_axi_awaddr;
    assign s_axi_awvalid    = i_s_axi_awvalid;
    assign s_axi_wdata      = i_s_axi_wdata;
    assign s_axi_wstrb      = i_s_axi_wstrb;
    assign s_axi_wvalid     = i_s_axi_wvalid;
    assign s_axi_bready     = i_s_axi_bready;
    assign s_axi_araddr     = i_s_axi_araddr;
    assign s_axi_arvalid    = i_s_axi_arvalid;
    assign s_axi_rready     = i_s_axi_rready;
    assign status_reg_value = i_status_reg_value;
    assign event_reg_value  = i_event_reg_value;
    assign fault_reg_value  = i_fault_reg_value;

    // -----------------------------------------------------------------------
    // 레지스터 저장소 및 AXI handshake 상태
    // -----------------------------------------------------------------------
    // 설정 register FF와 AXI address/data/response FF를 한 곳에 선언한다.
    // read/write decode에 필요한 helper function과 조합 wire도 이 섹션에서
    // 함께 정의해 register map을 한 화면에서 추적할 수 있게 한다.

    reg        reg_enable_ff;
    reg [9:0]  reg_guard_ticks_ff;
    reg [7:0]  reg_active_slot_ff;
    reg [31:0] reg_div_ff;
    reg [31:0] reg_data_out0_ff;
    reg [31:0] reg_data_out1_ff;
    reg [31:0] reg_data_out2_ff;
    reg [31:0] reg_data_out3_ff;
    reg [31:0] reg_data_out4_ff;
    reg [31:0] reg_data_out5_ff;

    reg                          aw_pending_ff;
    reg [C_S_AXI_ADDR_WIDTH-1:0] awaddr_ff;
    reg                          w_pending_ff;
    reg [31:0]                   wdata_ff;
    reg [3:0]                    wstrb_ff;
    reg                          bvalid_ff;
    reg                          rvalid_ff;
    reg [31:0]                   rdata_ff;
    reg                          reg_write_pulse_ff;
    reg [31:0]                   event_clear_mask_ff;
    reg [31:0]                   fault_clear_mask_ff;

    function [31:0] strobe_mask;
        input [3:0] byte_strobe;
        begin
            strobe_mask = { {8{byte_strobe[3]}},
                            {8{byte_strobe[2]}},
                            {8{byte_strobe[1]}},
                            {8{byte_strobe[0]}} };
        end
    endfunction

    function [31:0] merge_wstrb;
        input [31:0] old_value;
        input [31:0] write_value;
        input [3:0]  byte_strobe;
        reg   [31:0] mask_value;
        begin
            mask_value  = strobe_mask(byte_strobe);
            merge_wstrb = (old_value & ~mask_value) | (write_value & mask_value);
        end
    endfunction

    wire awready_int;
    wire wready_int;
    wire arready_int;
    wire aw_accept;
    wire w_accept;
    wire ar_accept;
    wire write_fire;
    wire [C_S_AXI_ADDR_WIDTH-1:0] write_addr;
    wire [31:0]                   write_data;
    wire [3:0]                    write_strobe;
    wire [5:0]                    write_offset;
    wire [5:0]                    read_offset;
    wire [31:0]                   write_byte_mask;
    wire [31:0]                   ctrl_read_value;
    wire [31:0]                   ctrl_write_value;
    wire [32:0]                   dbg_bit_period_ticks;
    wire [63:0]                   dbg_bit_period_ticks_64;
    wire [63:0]                   dbg_frame_ticks;
    wire [63:0]                   dbg_slot_ticks;
    wire [31:0]                   dbg_guard_half_lo;
    reg  [31:0]                   read_data_mux;

    assign awready_int = (~aw_pending_ff) & (~bvalid_ff);
    assign wready_int  = (~w_pending_ff) & (~bvalid_ff);
    assign arready_int = (~rvalid_ff);

    assign aw_accept   = awready_int & s_axi_awvalid;
    assign w_accept    = wready_int & s_axi_wvalid;
    assign ar_accept   = arready_int & s_axi_arvalid;

    assign write_fire  = ((aw_pending_ff | aw_accept) &
                          (w_pending_ff  | w_accept)  &
                          (~bvalid_ff));

    assign write_addr   = aw_pending_ff ? awaddr_ff : s_axi_awaddr;
    assign write_data   = w_pending_ff  ? wdata_ff  : s_axi_wdata;
    assign write_strobe = w_pending_ff  ? wstrb_ff  : s_axi_wstrb;
    assign write_offset = write_addr[5:0];
    assign read_offset  = s_axi_araddr[5:0];
    assign write_byte_mask = strobe_mask(write_strobe);

    assign ctrl_read_value        = {13'd0, reg_active_slot_ff, reg_guard_ticks_ff, reg_enable_ff};
    assign ctrl_write_value       = merge_wstrb(ctrl_read_value, write_data, write_strobe)
                                    & CTRL_VALID_MASK;
    assign dbg_bit_period_ticks   = {1'b0, reg_div_ff} + 33'd1;
    assign dbg_bit_period_ticks_64 = {31'd0, dbg_bit_period_ticks};
    assign dbg_frame_ticks        = dbg_bit_period_ticks_64 * 64'd50;
    assign dbg_slot_ticks         = dbg_frame_ticks + {54'd0, reg_guard_ticks_ff};
    assign dbg_guard_half_lo      = {22'd0, reg_guard_ticks_ff >> 1};

    // -----------------------------------------------------------------------
    // Read mux 조합 논리
    // -----------------------------------------------------------------------
    // read_offset만으로 register readback 값을 선택한다. 미정의 주소는
    // 0을 반환해 reserved 영역을 안정적으로 처리한다.

    always @(*) begin
        case (read_offset)
            ADDR_CTRL:              read_data_mux = ctrl_read_value;
            ADDR_DIV:               read_data_mux = reg_div_ff;
            ADDR_DATA_OUT0:         read_data_mux = reg_data_out0_ff;
            ADDR_DATA_OUT1:         read_data_mux = reg_data_out1_ff;
            ADDR_DATA_OUT2:         read_data_mux = reg_data_out2_ff;
            ADDR_DATA_OUT3:         read_data_mux = reg_data_out3_ff;
            ADDR_DATA_OUT4:         read_data_mux = reg_data_out4_ff;
            ADDR_DATA_OUT5:         read_data_mux = reg_data_out5_ff;
            ADDR_STATUS:            read_data_mux = status_reg_value;
            ADDR_EVENT:             read_data_mux = event_reg_value;
            ADDR_FAULT:             read_data_mux = fault_reg_value;
            ADDR_DBG_BIT_PERIOD_LO: read_data_mux = dbg_bit_period_ticks[31:0];
            ADDR_DBG_FRAME_LO:      read_data_mux = dbg_frame_ticks[31:0];
            ADDR_DBG_SLOT_LO:       read_data_mux = dbg_slot_ticks[31:0];
            ADDR_DBG_GUARD_HALF_LO: read_data_mux = dbg_guard_half_lo;
            default:                read_data_mux = 32'd0;
        endcase
    end

    // -----------------------------------------------------------------------
    // 순차 레지스터
    // -----------------------------------------------------------------------

    // AXI-Lite의 address/data/response 상태는 서로 묶여 움직여야 한다.
    // 하나의 always block에서 함께 갱신해 write address와 write data가 다른
    // transaction을 가리키는 상황을 막는다.
    always @(posedge clk) begin
        if (resetn == 1'b0) begin
            aw_pending_ff      <= 1'b0;
            awaddr_ff          <= {C_S_AXI_ADDR_WIDTH{1'b0}};
            w_pending_ff       <= 1'b0;
            wdata_ff           <= 32'd0;
            wstrb_ff           <= 4'd0;
            bvalid_ff          <= 1'b0;
            rvalid_ff          <= 1'b0;
            rdata_ff           <= 32'd0;
            reg_write_pulse_ff <= 1'b0;
            event_clear_mask_ff <= 32'd0;
            fault_clear_mask_ff <= 32'd0;
            reg_enable_ff       <= 1'b0;
            reg_guard_ticks_ff  <= 10'd0;
            reg_active_slot_ff  <= 8'd0;
            reg_div_ff          <= 32'd0;
            reg_data_out0_ff    <= 32'd0;
            reg_data_out1_ff    <= 32'd0;
            reg_data_out2_ff    <= 32'd0;
            reg_data_out3_ff    <= 32'd0;
            reg_data_out4_ff    <= 32'd0;
            reg_data_out5_ff    <= 32'd0;
        end else begin
            reg_write_pulse_ff  <= 1'b0;
            event_clear_mask_ff <= 32'd0;
            fault_clear_mask_ff <= 32'd0;

            if (bvalid_ff & s_axi_bready) begin
                bvalid_ff <= 1'b0;
            end

            if (rvalid_ff & s_axi_rready) begin
                rvalid_ff <= 1'b0;
            end

            if (aw_accept & (~write_fire)) begin
                aw_pending_ff <= 1'b1;
                awaddr_ff     <= s_axi_awaddr;
            end

            if (w_accept & (~write_fire)) begin
                w_pending_ff <= 1'b1;
                wdata_ff     <= s_axi_wdata;
                wstrb_ff     <= s_axi_wstrb;
            end

            if (write_fire) begin
                aw_pending_ff <= 1'b0;
                w_pending_ff  <= 1'b0;
                bvalid_ff     <= 1'b1;

                case (write_offset)
                    ADDR_CTRL: begin
                        reg_enable_ff      <= ctrl_write_value[0];
                        reg_guard_ticks_ff <= ctrl_write_value[10:1];
                        reg_active_slot_ff <= ctrl_write_value[18:11];
                        if (|write_strobe) begin
                            reg_write_pulse_ff <= 1'b1;
                        end
                    end
                    ADDR_DIV: begin
                        reg_div_ff <= merge_wstrb(reg_div_ff, write_data, write_strobe);
                        if (|write_strobe) begin
                            reg_write_pulse_ff <= 1'b1;
                        end
                    end
                    ADDR_DATA_OUT0: begin
                        reg_data_out0_ff <= merge_wstrb(reg_data_out0_ff, write_data, write_strobe);
                        if (|write_strobe) begin
                            reg_write_pulse_ff <= 1'b1;
                        end
                    end
                    ADDR_DATA_OUT1: begin
                        reg_data_out1_ff <= merge_wstrb(reg_data_out1_ff, write_data, write_strobe);
                        if (|write_strobe) begin
                            reg_write_pulse_ff <= 1'b1;
                        end
                    end
                    ADDR_DATA_OUT2: begin
                        reg_data_out2_ff <= merge_wstrb(reg_data_out2_ff, write_data, write_strobe);
                        if (|write_strobe) begin
                            reg_write_pulse_ff <= 1'b1;
                        end
                    end
                    ADDR_DATA_OUT3: begin
                        reg_data_out3_ff <= merge_wstrb(reg_data_out3_ff, write_data, write_strobe);
                        if (|write_strobe) begin
                            reg_write_pulse_ff <= 1'b1;
                        end
                    end
                    ADDR_DATA_OUT4: begin
                        reg_data_out4_ff <= merge_wstrb(reg_data_out4_ff, write_data, write_strobe);
                        if (|write_strobe) begin
                            reg_write_pulse_ff <= 1'b1;
                        end
                    end
                    ADDR_DATA_OUT5: begin
                        reg_data_out5_ff <= merge_wstrb(reg_data_out5_ff, write_data, write_strobe);
                        if (|write_strobe) begin
                            reg_write_pulse_ff <= 1'b1;
                        end
                    end
                    ADDR_EVENT: begin
                        event_clear_mask_ff <= write_data & write_byte_mask & EVENT_VALID_MASK;
                    end
                    ADDR_FAULT: begin
                        fault_clear_mask_ff <= write_data & write_byte_mask & FAULT_VALID_MASK;
                    end
                    default: begin
                        reg_write_pulse_ff  <= 1'b0;
                        event_clear_mask_ff <= 32'd0;
                        fault_clear_mask_ff <= 32'd0;
                    end
                endcase
            end

            if (ar_accept) begin
                rvalid_ff <= 1'b1;
                rdata_ff  <= read_data_mux;
            end
        end
    end

    // -----------------------------------------------------------------------
    // 출력 버퍼링
    // -----------------------------------------------------------------------
    // AXI response, raw 설정 register, W1C clear mask를 외부 포트로 노출한다.

    assign o_s_axi_awready = awready_int;
    assign o_s_axi_wready  = wready_int;
    assign o_s_axi_bresp   = 2'b00;
    assign o_s_axi_bvalid  = bvalid_ff;
    assign o_s_axi_arready = arready_int;
    assign o_s_axi_rdata   = rdata_ff;
    assign o_s_axi_rresp   = 2'b00;
    assign o_s_axi_rvalid  = rvalid_ff;

    assign o_reg_enable       = reg_enable_ff;
    assign o_reg_guard_ticks  = reg_guard_ticks_ff;
    assign o_reg_active_slot  = reg_active_slot_ff;
    assign o_reg_div          = reg_div_ff;
    assign o_reg_data_out0    = reg_data_out0_ff;
    assign o_reg_data_out1    = reg_data_out1_ff;
    assign o_reg_data_out2    = reg_data_out2_ff;
    assign o_reg_data_out3    = reg_data_out3_ff;
    assign o_reg_data_out4    = reg_data_out4_ff;
    assign o_reg_data_out5    = reg_data_out5_ff;
    assign o_reg_write_pulse  = reg_write_pulse_ff;
    assign o_event_clear_mask = event_clear_mask_ff;
    assign o_fault_clear_mask = fault_clear_mask_ff;

endmodule
