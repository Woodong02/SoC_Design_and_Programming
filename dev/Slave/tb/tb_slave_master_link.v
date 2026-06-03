module tb_slave_master_link;

    reg         clk;
    reg         resetn;
    reg         master_tx_trigger;
    reg  [7:0]  master_halt_cmd;
    reg  [9:0]  master_guard_ticks;
    reg  [9:0]  master_div;
    reg  [31:0] slave_payload;
    reg         master_rx_slot_pre_change;

    wire        master_to_slave_serial;
    wire        slave_to_master_serial;
    wire [41:0] master_rx_codeword;
    wire        master_rx_valid;
    wire        master_rx_preamble_err;
    wire [34:0] master_decoded_data;
    wire        master_ham_1bit_err;
    wire        master_ham_2bit_err;
    wire        slave_synced;
    wire        slave_halted;
    wire [9:0]  slave_latched_guard_ticks;

    parameter [2:0] TB_NODE_ID = 3'd1;
    parameter [2:0] TB_NODE_CNT = 3'd2;
    parameter [9:0] TB_BIT_DIV = 10'd4;
    parameter [9:0] TB_GUARD_TICKS = 10'd16;

    integer fail_count;
    integer wait_count;
    integer valid_count;

    Master_tx u_master_tx (
        .clk(clk),
        .resetn(resetn),
        .tx_trigger(master_tx_trigger),
        .halt_cmd(master_halt_cmd),
        .GUARD_TICKS(master_guard_ticks),
        .DIV(master_div),
        .GPIO_out(master_to_slave_serial)
    );

    slave_top #(
        .NODE_ID(TB_NODE_ID),
        .NODE_CNT(TB_NODE_CNT),
        .BIT_DIV(TB_BIT_DIV),
        .GUARD_TICKS_DEFAULT(TB_GUARD_TICKS)
    ) u_slave_top (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_MASTER_SERIAL(master_to_slave_serial),
        .i_PAYLOAD(slave_payload),
        .o_SLAVE_SERIAL(slave_to_master_serial),
        .o_SYNCED(slave_synced),
        .o_HALTED(slave_halted),
        .o_LATCHED_GUARD_TICKS(slave_latched_guard_ticks)
    );

    Master_rx u_master_rx (
        .clk(clk),
        .DIV(master_div),
        .GPIO_in(slave_to_master_serial),
        .resetn(resetn),
        .slot_pre_change(master_rx_slot_pre_change),
        .data_out(master_rx_codeword),
        .out_sig(master_rx_valid),
        .preamble_err(master_rx_preamble_err)
    );

    hamming_dec u_master_hamming_dec (
        .codeword(master_rx_codeword),
        .data(master_decoded_data),
        .ham_1bit_err(master_ham_1bit_err),
        .ham_2bit_err(master_ham_2bit_err)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        if (master_rx_valid) begin
            valid_count = valid_count + 1;
            $display("[WAVE] Master_rx valid data=0x%09x node=%0d payload=0x%08x time=%0t",
                     master_decoded_data, master_decoded_data[34:32], master_decoded_data[31:0], $time);
        end
    end

    task expect_bit;
        input [511:0] name;
        input got;
        input exp;
        begin
            if (got !== exp) begin
                $display("[FAIL] %0s got=%0b exp=%0b time=%0t", name, got, exp, $time);
                fail_count = fail_count + 1;
            end else begin
                $display("[PASS] %0s got=%0b time=%0t", name, got, $time);
            end
        end
    endtask

    task expect_value;
        input [511:0] name;
        input [31:0] got;
        input [31:0] exp;
        begin
            if (got !== exp) begin
                $display("[FAIL] %0s got=0x%08x exp=0x%08x time=%0t", name, got, exp, $time);
                fail_count = fail_count + 1;
            end else begin
                $display("[PASS] %0s got=0x%08x time=%0t", name, got, $time);
            end
        end
    endtask

    task pulse_master_broadcast;
        input [7:0] halt_cmd;
        input [9:0] guard_ticks;
        begin
            master_halt_cmd = halt_cmd;
            master_guard_ticks = guard_ticks;
            @(negedge clk);
            master_tx_trigger = 1'b1;
            @(negedge clk);
            master_tx_trigger = 1'b0;
            $display("[PHASE] Master_tx broadcast halt=0x%02x guard=%0d time=%0t",
                     halt_cmd, guard_ticks, $time);
        end
    endtask

    task wait_for_master_response;
        input [31:0] expected_payload;
        integer start_valid_count;
        begin
            start_valid_count = valid_count;
            wait_count = 0;
            while ((valid_count == start_valid_count) && (wait_count < 3000)) begin
                wait_count = wait_count + 1;
                @(posedge clk);
            end

            if (wait_count >= 3000) begin
                $display("[FAIL] timeout waiting for Master_rx response time=%0t", $time);
                fail_count = fail_count + 1;
            end else begin
                #1;
                expect_value("Master_rx decoded node id", {29'd0, master_decoded_data[34:32]}, {29'd0, TB_NODE_ID});
                expect_value("Master_rx decoded payload", master_decoded_data[31:0], expected_payload);
                expect_bit("Master_rx no 2bit hamming", master_ham_2bit_err, 1'b0);
                expect_bit("Master_rx no preamble error", master_rx_preamble_err, 1'b0);
            end
        end
    endtask

    initial begin
        fail_count = 0;
        wait_count = 0;
        valid_count = 0;
        resetn = 1'b0;
        master_tx_trigger = 1'b0;
        master_halt_cmd = 8'd0;
        master_guard_ticks = TB_GUARD_TICKS;
        master_div = TB_BIT_DIV;
        slave_payload = 32'h55aa33cc;
        master_rx_slot_pre_change = 1'b0;

        $display("[INFO] tb_slave_master_link start");
        repeat (6) @(posedge clk);
        resetn = 1'b1;
        repeat (4) @(posedge clk);

        pulse_master_broadcast(8'h00, 10'd123);
        wait_count = 0;
        while ((slave_latched_guard_ticks !== 10'd123) && (wait_count < 1000)) begin
            wait_count = wait_count + 1;
            @(posedge clk);
        end
        expect_value("Slave latched Master_tx guard", {22'd0, slave_latched_guard_ticks}, 32'd123);
        expect_bit("Slave synced by Master_tx", slave_synced, 1'b1);
        expect_bit("Slave active after clear halt", slave_halted, 1'b0);
        wait_for_master_response(32'h55aa33cc);

        pulse_master_broadcast(8'h02, 10'd124);
        wait_count = 0;
        while ((slave_latched_guard_ticks !== 10'd124) && (wait_count < 1000)) begin
            wait_count = wait_count + 1;
            @(posedge clk);
        end
        expect_value("Slave latched halt guard", {22'd0, slave_latched_guard_ticks}, 32'd124);
        expect_bit("Slave halted by Master_tx", slave_halted, 1'b1);

        valid_count = 0;
        repeat (1200) @(posedge clk);
        expect_value("No Master_rx response while halted", valid_count[31:0], 32'd0);

        slave_payload = 32'ha5a55a5a;
        pulse_master_broadcast(8'h00, 10'd125);
        wait_count = 0;
        while ((slave_latched_guard_ticks !== 10'd125) && (wait_count < 1000)) begin
            wait_count = wait_count + 1;
            @(posedge clk);
        end
        expect_bit("Slave resumed by clear halt", slave_halted, 1'b0);
        wait_for_master_response(32'ha5a55a5a);

        if (fail_count == 0)
            $display("PASS: tb_slave_master_link");
        else
            $display("FAIL: tb_slave_master_link fail_count=%0d", fail_count);

        $finish;
    end

endmodule

