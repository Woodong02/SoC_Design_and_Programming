// ---------------------------------------------------------------------------
// slave_cfg_shadow
// ---------------------------------------------------------------------------
// AXI 레지스터 파일의 raw 설정을 코어 동작 경계에 맞춰 shadow 설정으로
// commit한다. 프레임 동작 중에는 freeze snapshot을 사용해 한 master cycle
// 안에서 설정값이 바뀌지 않도록 한다.
// ---------------------------------------------------------------------------

module slave_cfg_shadow (
    input  wire        i_clk,
    input  wire        i_resetn,

    input  wire        i_reg_enable,
    input  wire [9:0]  i_reg_guard_ticks,
    input  wire [7:0]  i_reg_active_slot,
    input  wire [31:0] i_reg_div,
    input  wire [31:0] i_reg_data_out0,
    input  wire [31:0] i_reg_data_out1,
    input  wire [31:0] i_reg_data_out2,
    input  wire [31:0] i_reg_data_out3,
    input  wire [31:0] i_reg_data_out4,
    input  wire [31:0] i_reg_data_out5,
    input  wire        i_reg_write_pulse,

    input  wire        i_cfg_freeze_pulse,
    input  wire        i_core_idle,

    output wire        o_cfg_enable,
    output wire [9:0]  o_cfg_guard_ticks,
    output wire [7:0]  o_cfg_active_slot,
    output wire [32:0] o_cfg_bit_period_ticks,
    output wire [31:0] o_cfg_bit_period_reload,
    output wire [31:0] o_cfg_data_out0,
    output wire [31:0] o_cfg_data_out1,
    output wire [31:0] o_cfg_data_out2,
    output wire [31:0] o_cfg_data_out3,
    output wire [31:0] o_cfg_data_out4,
    output wire [31:0] o_cfg_data_out5,
    output wire        o_cfg_commit_pulse,
    output wire        o_cfg_pending
);

    // -----------------------------------------------------------------------
    // 포트 버퍼링
    // -----------------------------------------------------------------------
    // 외부 register-file 입력과 코어 상태 입력을 내부 wire로 고정한다.

    wire        clk;
    wire        resetn;
    wire        reg_enable;
    wire [9:0]  reg_guard_ticks;
    wire [7:0]  reg_active_slot;
    wire [31:0] reg_div;
    wire [31:0] reg_data_out0;
    wire [31:0] reg_data_out1;
    wire [31:0] reg_data_out2;
    wire [31:0] reg_data_out3;
    wire [31:0] reg_data_out4;
    wire [31:0] reg_data_out5;
    wire        reg_write_pulse;
    wire        cfg_freeze_pulse;
    wire        core_idle;

    assign clk              = i_clk;
    assign resetn           = i_resetn;
    assign reg_enable       = i_reg_enable;
    assign reg_guard_ticks  = i_reg_guard_ticks;
    assign reg_active_slot  = i_reg_active_slot;
    assign reg_div          = i_reg_div;
    assign reg_data_out0    = i_reg_data_out0;
    assign reg_data_out1    = i_reg_data_out1;
    assign reg_data_out2    = i_reg_data_out2;
    assign reg_data_out3    = i_reg_data_out3;
    assign reg_data_out4    = i_reg_data_out4;
    assign reg_data_out5    = i_reg_data_out5;
    assign reg_write_pulse  = i_reg_write_pulse;
    assign cfg_freeze_pulse = i_cfg_freeze_pulse;
    assign core_idle        = i_core_idle;

    // -----------------------------------------------------------------------
    // 설정 commit 및 선택 조합 논리
    // -----------------------------------------------------------------------
    // pending된 AXI 설정은 core_idle이거나 ENABLE down일 때만 shadow로
    // commit한다. freeze_active_ff가 켜진 동안은 sync 시점에 잡은 값이
    // 코어 출력으로 선택된다.

    reg        shadow_enable_ff;
    reg [9:0]  shadow_guard_ticks_ff;
    reg [7:0]  shadow_active_slot_ff;
    reg [31:0] shadow_div_ff;
    reg [31:0] shadow_data_out0_ff;
    reg [31:0] shadow_data_out1_ff;
    reg [31:0] shadow_data_out2_ff;
    reg [31:0] shadow_data_out3_ff;
    reg [31:0] shadow_data_out4_ff;
    reg [31:0] shadow_data_out5_ff;

    reg [9:0]  freeze_guard_ticks_ff;
    reg [7:0]  freeze_active_slot_ff;
    reg [31:0] freeze_div_ff;
    reg [31:0] freeze_data_out0_ff;
    reg [31:0] freeze_data_out1_ff;
    reg [31:0] freeze_data_out2_ff;
    reg [31:0] freeze_data_out3_ff;
    reg [31:0] freeze_data_out4_ff;
    reg [31:0] freeze_data_out5_ff;
    reg        freeze_active_ff;
    reg        pending_ff;
    reg        commit_pulse_ff;

    wire commit_allowed;
    wire commit_now;
    wire [9:0]  selected_guard_ticks;
    wire [7:0]  selected_active_slot;
    wire [31:0] selected_div;
    wire [31:0] selected_data_out0;
    wire [31:0] selected_data_out1;
    wire [31:0] selected_data_out2;
    wire [31:0] selected_data_out3;
    wire [31:0] selected_data_out4;
    wire [31:0] selected_data_out5;
    wire [32:0] selected_bit_period_ticks;

    // ENABLE down은 busy 중에도 commit할 수 있게 하여 새 작업 수락을 즉시
    // 멈출 수 있게 한다. 나머지 running update는 idle까지 기다린다.
    assign commit_allowed = (reg_enable == 1'b0) | core_idle;
    assign commit_now     = pending_ff & commit_allowed;

    assign selected_guard_ticks = freeze_active_ff ? freeze_guard_ticks_ff : shadow_guard_ticks_ff;
    assign selected_active_slot = freeze_active_ff ? freeze_active_slot_ff : shadow_active_slot_ff;
    assign selected_div         = freeze_active_ff ? freeze_div_ff         : shadow_div_ff;
    assign selected_data_out0   = freeze_active_ff ? freeze_data_out0_ff   : shadow_data_out0_ff;
    assign selected_data_out1   = freeze_active_ff ? freeze_data_out1_ff   : shadow_data_out1_ff;
    assign selected_data_out2   = freeze_active_ff ? freeze_data_out2_ff   : shadow_data_out2_ff;
    assign selected_data_out3   = freeze_active_ff ? freeze_data_out3_ff   : shadow_data_out3_ff;
    assign selected_data_out4   = freeze_active_ff ? freeze_data_out4_ff   : shadow_data_out4_ff;
    assign selected_data_out5   = freeze_active_ff ? freeze_data_out5_ff   : shadow_data_out5_ff;

    // DIV_REG는 지수값이 아니라 raw reload 값이다. raw zero는 합법이며
    // 1-clock bit period를 만든다.
    assign selected_bit_period_ticks = {1'b0, selected_div} + 33'd1;

    // -----------------------------------------------------------------------
    // 순차 레지스터
    // -----------------------------------------------------------------------

    // config, freeze, pending 상태는 같은 boundary policy를 공유한다.
    // 이 clock 이전에 pending이던 값만 commit하고, freeze 역시 이 clock
    // 이전에 shadow에 있던 값을 잡는다.
    always @(posedge clk) begin
        if (resetn == 1'b0) begin
            shadow_enable_ff      <= 1'b0;
            shadow_guard_ticks_ff <= 10'd0;
            shadow_active_slot_ff <= 8'd0;
            shadow_div_ff         <= 32'd0;
            shadow_data_out0_ff   <= 32'd0;
            shadow_data_out1_ff   <= 32'd0;
            shadow_data_out2_ff   <= 32'd0;
            shadow_data_out3_ff   <= 32'd0;
            shadow_data_out4_ff   <= 32'd0;
            shadow_data_out5_ff   <= 32'd0;
            freeze_guard_ticks_ff <= 10'd0;
            freeze_active_slot_ff <= 8'd0;
            freeze_div_ff         <= 32'd0;
            freeze_data_out0_ff   <= 32'd0;
            freeze_data_out1_ff   <= 32'd0;
            freeze_data_out2_ff   <= 32'd0;
            freeze_data_out3_ff   <= 32'd0;
            freeze_data_out4_ff   <= 32'd0;
            freeze_data_out5_ff   <= 32'd0;
            freeze_active_ff      <= 1'b0;
            pending_ff            <= 1'b0;
            commit_pulse_ff       <= 1'b0;
        end else begin
            commit_pulse_ff <= commit_now;
            pending_ff      <= (pending_ff & (~commit_now)) | reg_write_pulse;

            if (commit_now) begin
                shadow_enable_ff      <= reg_enable;
                shadow_guard_ticks_ff <= reg_guard_ticks;
                shadow_active_slot_ff <= reg_active_slot;
                shadow_div_ff         <= reg_div;
                shadow_data_out0_ff   <= reg_data_out0;
                shadow_data_out1_ff   <= reg_data_out1;
                shadow_data_out2_ff   <= reg_data_out2;
                shadow_data_out3_ff   <= reg_data_out3;
                shadow_data_out4_ff   <= reg_data_out4;
                shadow_data_out5_ff   <= reg_data_out5;
            end

            if (cfg_freeze_pulse) begin
                freeze_guard_ticks_ff <= shadow_guard_ticks_ff;
                freeze_active_slot_ff <= shadow_active_slot_ff;
                freeze_div_ff         <= shadow_div_ff;
                freeze_data_out0_ff   <= shadow_data_out0_ff;
                freeze_data_out1_ff   <= shadow_data_out1_ff;
                freeze_data_out2_ff   <= shadow_data_out2_ff;
                freeze_data_out3_ff   <= shadow_data_out3_ff;
                freeze_data_out4_ff   <= shadow_data_out4_ff;
                freeze_data_out5_ff   <= shadow_data_out5_ff;
                freeze_active_ff      <= 1'b1;
            end else if (core_idle) begin
                freeze_active_ff <= 1'b0;
            end
        end
    end

    // -----------------------------------------------------------------------
    // 출력 버퍼링
    // -----------------------------------------------------------------------
    // 코어는 selected_* 신호만 보므로 freeze/normal 선택 정책이 밖으로
    // 새지 않는다.

    assign o_cfg_enable            = shadow_enable_ff;
    assign o_cfg_guard_ticks       = selected_guard_ticks;
    assign o_cfg_active_slot       = selected_active_slot;
    assign o_cfg_bit_period_ticks  = selected_bit_period_ticks;
    assign o_cfg_bit_period_reload = selected_div;
    assign o_cfg_data_out0         = selected_data_out0;
    assign o_cfg_data_out1         = selected_data_out1;
    assign o_cfg_data_out2         = selected_data_out2;
    assign o_cfg_data_out3         = selected_data_out3;
    assign o_cfg_data_out4         = selected_data_out4;
    assign o_cfg_data_out5         = selected_data_out5;
    assign o_cfg_commit_pulse      = commit_pulse_ff;
    assign o_cfg_pending           = pending_ff;

endmodule
