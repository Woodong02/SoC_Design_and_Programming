`timescale 1ns / 1ps

module tb_slave_axi_ip_top_smoke;

    localparam [5:0] ADDR_CTRL      = 6'h00;
    localparam [5:0] ADDR_DIV       = 6'h04;
    localparam [5:0] ADDR_DATA_OUT0 = 6'h08;
    localparam [5:0] ADDR_STATUS    = 6'h20;
    localparam [5:0] ADDR_EVENT     = 6'h24;

    reg         clk;
    reg         resetn;
    reg  [5:0]  awaddr;
    reg         awvalid;
    wire        awready;
    reg  [31:0] wdata;
    reg  [3:0]  wstrb;
    reg         wvalid;
    wire        wready;
    wire [1:0]  bresp;
    wire        bvalid;
    reg         bready;
    reg  [5:0]  araddr;
    reg         arvalid;
    wire        arready;
    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rvalid;
    reg         rready;
    reg         master_serial;
    reg  [31:0] pl_payload6;
    reg         pl_payload6_valid;
    reg  [31:0] pl_payload7;
    reg         pl_payload7_valid;
    wire        slave_serial;
    wire        slave_oe;
    wire        irq;

    reg  [34:0] master_encoder_data;
    wire [41:0] master_codeword;
    reg  [34:0] slave_encoder_data;
    wire [41:0] slave_codeword;
    reg  [49:0] master_frame;
    reg  [49:0] expected_slave_frame;
    reg  [49:0] captured_slave_frame;
    integer     errors;
    integer     bit_index;
    reg  [31:0] read_value;

    slave_axi_ip_top u_slave_axi_ip_top (
        .i_clk(clk),
        .i_resetn(resetn),
        .i_s_axi_awaddr(awaddr),
        .i_s_axi_awvalid(awvalid),
        .o_s_axi_awready(awready),
        .i_s_axi_wdata(wdata),
        .i_s_axi_wstrb(wstrb),
        .i_s_axi_wvalid(wvalid),
        .o_s_axi_wready(wready),
        .o_s_axi_bresp(bresp),
        .o_s_axi_bvalid(bvalid),
        .i_s_axi_bready(bready),
        .i_s_axi_araddr(araddr),
        .i_s_axi_arvalid(arvalid),
        .o_s_axi_arready(arready),
        .o_s_axi_rdata(rdata),
        .o_s_axi_rresp(rresp),
        .o_s_axi_rvalid(rvalid),
        .i_s_axi_rready(rready),
        .i_master_serial(master_serial),
        .i_pl_payload6(pl_payload6),
        .i_pl_payload6_valid(pl_payload6_valid),
        .i_pl_payload7(pl_payload7),
        .i_pl_payload7_valid(pl_payload7_valid),
        .o_slave_serial(slave_serial),
        .o_slave_oe(slave_oe),
        .o_irq(irq)
    );

    slave_hamming_enc u_master_hamming_enc (
        .i_DATA(master_encoder_data),
        .o_CODEWORD(master_codeword)
    );

    slave_hamming_enc u_slave_hamming_enc (
        .i_DATA(slave_encoder_data),
        .o_CODEWORD(slave_codeword)
    );

    always begin
        clk = 1'b0;
        #5;
        clk = 1'b1;
        #5;
    end

    task check32;
        input [255:0] label_text;
        input [31:0] actual;
        input [31:0] expected;
        begin
            if (actual !== expected) begin
                $display("FAIL %0s actual=%h expected=%h time=%0t", label_text, actual, expected, $time);
                errors = errors + 1;
            end
        end
    endtask

    task check50;
        input [255:0] label_text;
        input [49:0] actual;
        input [49:0] expected;
        begin
            if (actual !== expected) begin
                $display("FAIL %0s actual=%h expected=%h time=%0t", label_text, actual, expected, $time);
                errors = errors + 1;
            end
        end
    endtask

    task axi_write;
        input [5:0]  addr;
        input [31:0] data;
        begin
            @(negedge clk);
            awaddr = addr;
            wdata = data;
            wstrb = 4'hF;
            awvalid = 1'b1;
            wvalid = 1'b1;
            bready = 1'b1;
            wait (awready && wready);
            @(negedge clk);
            awvalid = 1'b0;
            wvalid = 1'b0;
            wait (bvalid);
            @(negedge clk);
            bready = 1'b0;
        end
    endtask

    task axi_read;
        input [5:0] addr;
        output [31:0] data;
        begin
            @(negedge clk);
            araddr = addr;
            arvalid = 1'b1;
            rready = 1'b1;
            wait (arready);
            @(negedge clk);
            arvalid = 1'b0;
            wait (rvalid);
            data = rdata;
            @(negedge clk);
            rready = 1'b0;
        end
    endtask

    task send_master_frame;
        input [49:0] frame_value;
        integer send_index;
        begin
            @(negedge clk);
            for (send_index = 0; send_index < 50; send_index = send_index + 1) begin
                master_serial = frame_value[49 - send_index];
                @(negedge clk);
            end
            master_serial = 1'b0;
        end
    endtask

    task capture_slave_frame;
        integer wait_index;
        begin
            wait_index = 0;
            while ((slave_oe == 1'b0) && (wait_index < 200)) begin
                @(posedge clk);
                #1;
                wait_index = wait_index + 1;
            end
            if (slave_oe !== 1'b1) begin
                $display("FAIL slave oe timeout time=%0t", $time);
                errors = errors + 1;
            end

            captured_slave_frame = 50'd0;
            for (bit_index = 0; bit_index < 50; bit_index = bit_index + 1) begin
                @(negedge clk);
                captured_slave_frame = {captured_slave_frame[48:0], slave_serial};
                @(posedge clk);
                #1;
            end
        end
    endtask

    initial begin
        errors = 0;
        resetn = 1'b0;
        awaddr = 6'd0;
        awvalid = 1'b0;
        wdata = 32'd0;
        wstrb = 4'd0;
        wvalid = 1'b0;
        bready = 1'b0;
        araddr = 6'd0;
        arvalid = 1'b0;
        rready = 1'b0;
        master_serial = 1'b0;
        pl_payload6 = 32'h6000_0006;
        pl_payload6_valid = 1'b1;
        pl_payload7 = 32'h7000_0007;
        pl_payload7_valid = 1'b1;
        master_encoder_data = 35'd0;
        slave_encoder_data = 35'd0;
        master_frame = 50'd0;
        expected_slave_frame = 50'd0;
        captured_slave_frame = 50'd0;

        repeat (5) @(negedge clk);
        resetn = 1'b1;
        repeat (5) @(negedge clk);

        axi_write(ADDR_DIV, 32'd0);
        axi_write(ADDR_DATA_OUT0, 32'hCAFE_1234);
        axi_write(ADDR_CTRL, 32'd1 | (32'd4 << 1) | (32'h01 << 11));
        repeat (8) @(negedge clk);

        axi_read(ADDR_STATUS, read_value);
        check32("status enabled", read_value & 32'h0000_0001, 32'h0000_0001);

        master_encoder_data = {8'h00, 10'd4, 17'd0};
        slave_encoder_data = {3'd0, 32'hCAFE_1234};
        #1;
        master_frame = {8'hAA, master_codeword};
        expected_slave_frame = {8'hAA, slave_codeword};

        fork
            send_master_frame(master_frame);
            capture_slave_frame();
        join

        check50("slot0 slave response frame", captured_slave_frame, expected_slave_frame);

        repeat (4) @(negedge clk);
        axi_read(ADDR_EVENT, read_value);
        check32("event sync/tx bits", read_value & 32'h0000_0005, 32'h0000_0005);

        if (errors == 0) begin
            $display("PASS tb_slave_axi_ip_top_smoke");
        end else begin
            $display("FAIL tb_slave_axi_ip_top_smoke errors=%0d", errors);
        end
        $finish;
    end

endmodule
