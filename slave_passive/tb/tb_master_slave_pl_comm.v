`timescale 1ns / 1ps
// ---------------------------------------------------------------------------
// tb_master_slave_pl_comm
// ---------------------------------------------------------------------------
// Master leaf 모듈(Master_slot/tx/rx + Master_dec_ham)과 slave_pl_top을
// 직접 연결하는 통합 통신 검증 TB.
//
// 설정:  DIV=2500000, GUARD_TICKS=1000, 슬롯 0~3 활성
// 기대:  slave slot_out0=0, slot_out1=1, slot_out2=2, slot_out3=3
// ---------------------------------------------------------------------------

module tb_master_slave_pl_comm;

    // ------------------------------------------------------------------
    // 파라미터
    // ------------------------------------------------------------------
    localparam CLK_HALF    = 20;       // 25 MHz (40 ns 주기)
    localparam [31:0] DIV  = 32'd200;  // 검증용 축소값 (실제: 2500000)
    localparam [9:0]  GTKS = 10'd50;   // 검증용 축소값 (실제: 1000)
    localparam [2:0]  NCNT = 3'd3;     // NODE_CNT: 슬롯 0~3

    // slave_pl_top: bit_period = DIV_REG+1 = DIV+1 → DIV_REG = DIV
    localparam [31:0] SLV_DIV  = DIV;
    localparam [9:0]  SLV_GTKS = GTKS;

    // 5 마스터 사이클 후 종료
    localparam FINISH_CYCLES = 5;

    // ------------------------------------------------------------------
    // 신호
    // ------------------------------------------------------------------
    reg  clk;
    reg  resetn;

    wire master_serial;   // master GPIO_out → slave i_master_serial
    wire slave_serial;    // slave o_slave_serial → master GPIO_in
    wire [1:0] led;

    // master 내부
    wire [2:0]  m_slot;
    wire        m_slot_change;
    wire        m_slot_pre_change;
    wire [37:0] m_clk_cnt;
    wire [1:0]  m_rx_stat;
    wire [31:0] m_cycle_cnt;

    wire m_tx_trigger = (m_slot_pre_change && m_slot == NCNT);

    wire [41:0] m_rx_data;
    wire        m_rx_sig;
    wire        m_preamble_err;
    wire [31:0] m_buf_out;

    wire [31:0] slot_out0, slot_out1, slot_out2, slot_out3;
    wire [31:0] err_cnt0,  err_cnt1,  err_cnt2,  err_cnt3;

    // ------------------------------------------------------------------
    // 클럭 / 리셋
    // ------------------------------------------------------------------
    initial clk = 0;
    always #CLK_HALF clk = ~clk;

    initial begin
        resetn = 0;
        repeat (20) @(posedge clk);
        resetn = 1;
    end

    // ------------------------------------------------------------------
    // Master leaf 모듈
    // ------------------------------------------------------------------
    Master_slot u_master_slot (
        .resetn          (resetn),
        .clk             (clk),
        .DIV             (DIV + 32'd1),    // DIV_p1
        .GUARD_TICKS     (GTKS),
        .NODE_CNT        (NCNT),
        .slot            (m_slot),
        .slot_change     (m_slot_change),
        .slot_pre_change (m_slot_pre_change),
        .clk_cnt         (m_clk_cnt),
        .rx_stat         (m_rx_stat),
        .cycle_cnt       (m_cycle_cnt)
    );

    Master_tx u_master_tx (
        .clk        (clk),
        .resetn     (resetn),
        .tx_trigger (m_tx_trigger),
        .halt_cmd   (8'b0),          // 테스트용: 모든 슬롯 active
        .GUARD_TICKS(GTKS),
        .DIV        (DIV + 32'd1),
        .GPIO_out   (master_serial)
    );

    Master_rx u_master_rx (
        .clk             (clk),
        .DIV             (DIV + 32'd1),
        .GPIO_in         (slave_serial),
        .resetn          (resetn),
        .slot_pre_change (m_slot_pre_change),
        .data_out        (m_rx_data),
        .out_sig         (m_rx_sig),
        .preamble_err    (m_preamble_err),
        .buffer_out      (m_buf_out)
    );

    Master_dec_ham u_dec_ham (
        .resetn     (resetn),
        .clk        (clk),
        .in_sig     (m_rx_sig),
        .data_in    (m_rx_data),
        .SILENT_TH  (8'd200),
        .slot       (m_slot),
        .preamble_err(m_preamble_err),
        .slot_change(m_slot_change),
        .GPIO_in    (slave_serial),
        .rx_stat    (m_rx_stat),
        .halt_cmd   (8'b0),
        .slot_out0  (slot_out0), .slot_out1(slot_out1),
        .slot_out2  (slot_out2), .slot_out3(slot_out3),
        .slot_out4  (),          .slot_out5(),
        .slot_out6  (),          .slot_out7(),
        .err_cnt0   (err_cnt0),  .err_cnt1(err_cnt1),
        .err_cnt2   (err_cnt2),  .err_cnt3(err_cnt3),
        .err_cnt4   (),          .err_cnt5(),
        .err_cnt6   (),          .err_cnt7()
    );

    // ------------------------------------------------------------------
    // slave_pl_top (DUT)
    // ------------------------------------------------------------------
    slave_pl_top #(
        .ACTIVE_SLOT (8'b0000_1111),
        .DIV_REG     (SLV_DIV),
        .GUARD_TICKS (SLV_GTKS),
        .DATA_OUT0   (32'h0),
        .DATA_OUT1   (32'h1),
        .DATA_OUT2   (32'h2),
        .DATA_OUT3   (32'h3),
        .DATA_OUT4   (32'h4),
        .DATA_OUT5   (32'h5)
    ) u_slave (
        .i_clk          (clk),
        .i_resetn        (resetn),
        .i_master_serial (master_serial),
        .o_slave_serial  (slave_serial),
        .o_led           (led)
    );

    // ------------------------------------------------------------------
    // 모니터링 / 검증
    // ------------------------------------------------------------------
    reg [31:0] prev_cycle;
    initial prev_cycle = 32'hFFFF_FFFF;

    always @(posedge clk) begin
        if (resetn && m_cycle_cnt != prev_cycle) begin
            prev_cycle <= m_cycle_cnt;
            $display("[%0t ns] cycle=%0d  slot_out={%0d,%0d,%0d,%0d}  err={%08h,%08h,%08h,%08h}",
                $time, m_cycle_cnt,
                slot_out0, slot_out1, slot_out2, slot_out3,
                err_cnt0, err_cnt1, err_cnt2, err_cnt3);
        end
    end

    always @(posedge clk) begin
        if (resetn && m_cycle_cnt >= FINISH_CYCLES) begin
            $display("----------------------------------------------------");
            $display("RESULT after %0d cycles:", m_cycle_cnt);
            $display("  slot_out0=%0d  (expect 0)", slot_out0);
            $display("  slot_out1=%0d  (expect 1)", slot_out1);
            $display("  slot_out2=%0d  (expect 2)", slot_out2);
            $display("  slot_out3=%0d  (expect 3)", slot_out3);
            if (slot_out0===32'd0 && slot_out1===32'd1 &&
                slot_out2===32'd2 && slot_out3===32'd3)
                $display("PASS tb_master_slave_pl_comm");
            else
                $display("FAIL tb_master_slave_pl_comm");
            $display("----------------------------------------------------");
            $finish;
        end
    end

endmodule
