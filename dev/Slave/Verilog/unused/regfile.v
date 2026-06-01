// regfile: AXI-Lite slave register file for TDMA slave IP
// Registers: CTRL(0x00) LINK_CFG(0x04) SLAVE_CFG(0x08) FAULT_CFG(0x0C)
//            TX_DATA(0x10) STATUS(0x14) IRQ_STATUS(0x18) IRQ_MASK(0x1C)
// Simplified: awready=wready=arready=1 always; simultaneous aw+w assumed for writes.
module regfile (
    input  wire        clk,
    input  wire        rst_n,

    // AXI-Lite slave
    input  wire [4:0]  s_axil_awaddr,
    input  wire        s_axil_awvalid,
    output wire        s_axil_awready,
    input  wire [31:0] s_axil_wdata,
    input  wire [3:0]  s_axil_wstrb,
    input  wire        s_axil_wvalid,
    output wire        s_axil_wready,
    output reg  [1:0]  s_axil_bresp,
    output reg         s_axil_bvalid,
    input  wire        s_axil_bready,
    input  wire [4:0]  s_axil_araddr,
    input  wire        s_axil_arvalid,
    output wire        s_axil_arready,
    output reg  [31:0] s_axil_rdata,
    output reg  [1:0]  s_axil_rresp,
    output reg         s_axil_rvalid,
    input  wire        s_axil_rready,

    // Status inputs (RO)
    input  wire [2:0]  fsm_state,
    input  wire [7:0]  fault_cnt,
    input  wire [7:0]  line_cnt,
    // W1C event pulses for STATUS[22:19]
    input  wire        ev_data_sent,
    input  wire        ev_no_broadcast,
    input  wire        ev_hamming_err,
    input  wire        ev_halt_cmd,
    // IRQ_STATUS from irq_ctrl (for readback of 0x18)
    input  wire [4:0]  irq_status,

    // Config outputs
    output reg         enable,
    output reg         soft_rst,
    output reg [9:0]   div,
    output reg [9:0]   guard_ticks,
    output reg [2:0]   slave_addr_cfg,
    output reg [7:0]   fault_th,
    output reg [7:0]   line_fault_th,
    output reg [31:0]  tx_data,
    output reg [4:0]   irq_clr,
    output reg [4:0]   irq_mask
);
    // Always-ready handshake
    assign s_axil_awready = 1'b1;
    assign s_axil_wready  = 1'b1;
    assign s_axil_arready = 1'b1;

    // STATUS W1C sticky bits [22:19]
    reg st_data_sent, st_no_broadcast, st_hamming_err, st_halt_cmd;

    // Write enable (simultaneous awvalid+wvalid)
    wire wr_en   = s_axil_awvalid & s_axil_wvalid;
    wire [4:0] wr_addr = s_axil_awaddr;
    wire [31:0] wr_data = s_axil_wdata;

    // Byte-enable mask application
    function [31:0] apply_strb;
        input [31:0] old_val;
        input [31:0] new_val;
        input [3:0]  strb;
        begin
            apply_strb[7:0]   = strb[0] ? new_val[7:0]   : old_val[7:0];
            apply_strb[15:8]  = strb[1] ? new_val[15:8]  : old_val[15:8];
            apply_strb[23:16] = strb[2] ? new_val[23:16] : old_val[23:16];
            apply_strb[31:24] = strb[3] ? new_val[31:24] : old_val[31:24];
        end
    endfunction

    wire [31:0] wr_masked = apply_strb(32'd0, wr_data, s_axil_wstrb);

    // ---- Write logic ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable        <= 1'b0;
            soft_rst      <= 1'b0;
            div           <= 10'd0;
            guard_ticks   <= 10'd0;
            slave_addr_cfg<= 3'd0;
            fault_th      <= 8'd30;
            line_fault_th <= 8'd30;
            tx_data       <= 32'd0;
            irq_clr       <= 5'd0;
            irq_mask      <= 5'd0;
            st_data_sent  <= 1'b0;
            st_no_broadcast  <= 1'b0;
            st_hamming_err   <= 1'b0;
            st_halt_cmd      <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp  <= 2'b00;
        end else begin
            // auto-clear SOFT_RST after 1 clock
            if (soft_rst)
                soft_rst <= 1'b0;
            // auto-clear irq_clr (pulse, set by W1C write, deassert next cycle)
            irq_clr <= 5'd0;

            // STATUS W1C sticky bits: set by event, cleared by W1C write
            st_data_sent  <= (st_data_sent  | ev_data_sent)    &
                             ~(wr_en && wr_addr[4:2]==3'd5 && wr_masked[19]);
            st_no_broadcast <= (st_no_broadcast | ev_no_broadcast) &
                               ~(wr_en && wr_addr[4:2]==3'd5 && wr_masked[20]);
            st_hamming_err  <= (st_hamming_err  | ev_hamming_err)  &
                               ~(wr_en && wr_addr[4:2]==3'd5 && wr_masked[21]);
            st_halt_cmd     <= (st_halt_cmd     | ev_halt_cmd)     &
                               ~(wr_en && wr_addr[4:2]==3'd5 && wr_masked[22]);

            // Register writes
            if (wr_en) begin
                case (wr_addr[4:2])
                    3'd0: begin // 0x00 CTRL
                        enable   <= wr_masked[0];
                        soft_rst <= wr_masked[1];
                    end
                    3'd1: begin // 0x04 LINK_CFG
                        div         <= wr_masked[9:0];
                        guard_ticks <= wr_masked[19:10];
                    end
                    3'd2: begin // 0x08 SLAVE_CFG
                        slave_addr_cfg <= wr_masked[2:0];
                    end
                    3'd3: begin // 0x0C FAULT_CFG
                        fault_th      <= wr_masked[7:0];
                        line_fault_th <= wr_masked[15:8];
                    end
                    3'd4: begin // 0x10 TX_DATA
                        tx_data <= wr_masked;
                    end
                    3'd5: begin // 0x14 STATUS — W1C only, no RW fields; handled above
                    end
                    3'd6: begin // 0x18 IRQ_STATUS — W1C: generate irq_clr pulse
                        irq_clr <= wr_masked[4:0];
                    end
                    3'd7: begin // 0x1C IRQ_MASK
                        irq_mask <= wr_masked[4:0];
                    end
                    default: ;
                endcase
                s_axil_bvalid <= 1'b1;
                s_axil_bresp  <= 2'b00; // OKAY
            end else if (s_axil_bready) begin
                s_axil_bvalid <= 1'b0;
            end
        end
    end

    // ---- Read logic ----
    wire [31:0] status_reg = {9'd0,
                               st_halt_cmd, st_hamming_err,
                               st_no_broadcast, st_data_sent,
                               line_cnt, fault_cnt, fsm_state};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_rvalid <= 1'b0;
            s_axil_rdata  <= 32'd0;
            s_axil_rresp  <= 2'b00;
        end else begin
            if (s_axil_arvalid && !s_axil_rvalid) begin
                s_axil_rvalid <= 1'b1;
                s_axil_rresp  <= 2'b00;
                case (s_axil_araddr[4:2])
                    3'd0: s_axil_rdata <= {30'd0, soft_rst, enable};
                    3'd1: s_axil_rdata <= {12'd0, guard_ticks, div};
                    3'd2: s_axil_rdata <= {29'd0, slave_addr_cfg};
                    3'd3: s_axil_rdata <= {16'd0, line_fault_th, fault_th};
                    3'd4: s_axil_rdata <= tx_data;
                    3'd5: s_axil_rdata <= status_reg;
                    3'd6: s_axil_rdata <= {27'd0, irq_status};
                    3'd7: s_axil_rdata <= {27'd0, irq_mask};
                    default: s_axil_rdata <= 32'd0;
                endcase
            end else if (s_axil_rready) begin
                s_axil_rvalid <= 1'b0;
            end
        end
    end

endmodule
