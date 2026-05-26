`timescale 1ns / 1ps

// Communication TB: slave_tx --> master_rx
// slave_tx: d = {addr[2:0], payload[31:0]}
// master_rx: bc_halt_cmd = fixed_data[34:27] = {addr[2:0], payload[31:27]}
module tb_slave_tx_master_rx;

    reg        clk, rst_n;
    reg [9:0]  div;
    reg        tx_trigger, tx_enable;
    reg [2:0]  slave_addr;
    reg [31:0] tx_data;

    wire rx_line;
    wire tx_active, data_sent;

    reg  err_inject;
    wire tx_raw  = (rx_line === 1'bz) ? 1'b0 : rx_line;
    wire rx_sync = tx_raw ^ err_inject;

    wire active_edge, bc_valid, bc_preamble_ok, bc_preamble_err, bc_hamming_err;
    wire [7:0] bc_halt_cmd;

    slave_tx u_tx (
        .clk(clk), .rst_n(rst_n), .div(div),
        .tx_trigger(tx_trigger), .tx_enable(tx_enable),
        .slave_addr(slave_addr), .tx_data(tx_data),
        .rx_line(rx_line), .tx_active(tx_active), .data_sent(data_sent)
    );

    master_rx u_rx (
        .clk(clk), .rst_n(rst_n), .enable(1'b1), .div(div),
        .tx_line_sync(rx_sync),
        .active_edge(active_edge), .bc_valid(bc_valid),
        .bc_preamble_ok(bc_preamble_ok), .bc_halt_cmd(bc_halt_cmd),
        .bc_hamming_err(bc_hamming_err), .bc_preamble_err(bc_preamble_err)
    );

    always #5 clk = ~clk;

    integer pass_cnt, fail_cnt;

    reg       bc_valid_seen, bc_hamming_err_seen;
    reg [7:0] recv_halt;

    always @(posedge clk) begin
        if (bc_valid)      begin bc_valid_seen <= 1'b1; recv_halt <= bc_halt_cmd; end
        if (bc_hamming_err) bc_hamming_err_seen <= 1'b1;
    end

    task clear_flags;
        begin bc_valid_seen = 0; bc_hamming_err_seen = 0; recv_halt = 0; end
    endtask

    // send_frame_inj: trigger TX, optionally inject 1~2 bit errors.
    // inject_bit N (0..41, codeword-relative) starts at cycle (N+8)*bp after tx_active.
    // FIX: use wait(tx_active) instead of @(posedge tx_active) — posedge already passed.
    task send_frame_inj;
        input [2:0]  addr;
        input [31:0] data;
        input integer inject_bit_a;   // -1 = none
        input integer inject_bit_b;   // -1 = none
        integer bp, wa, wb;
        begin
            @(posedge clk); #1;
            slave_addr = addr; tx_data = data; err_inject = 0;
            tx_trigger = 1'b1;
            @(posedge clk); #1;
            tx_trigger = 1'b0;

            bp = 2 * (div + 1);   // 8 clks for div=3
            wait(tx_active);      // tx_active already HIGH after trigger clock

            if (inject_bit_a >= 0) begin
                wa = (inject_bit_a + 8) * bp;
                repeat(wa) @(posedge clk);
                err_inject = 1;
                repeat(bp) @(posedge clk);
                err_inject = 0;
                if (inject_bit_b >= 0 && inject_bit_b != inject_bit_a) begin
                    wb = ((inject_bit_b + 8) - (inject_bit_a + 9)) * bp;
                    if (wb > 0) repeat(wb) @(posedge clk);
                    err_inject = 1;
                    repeat(bp) @(posedge clk);
                    err_inject = 0;
                end
            end

            repeat(500) @(posedge clk);
            err_inject = 0;
        end
    endtask

    task send_clean;
        input [2:0] addr; input [31:0] data;
        begin send_frame_inj(addr, data, -1, -1); end
    endtask

    // bc_halt_cmd = {addr[2:0], payload[31:27]}
    function [7:0] exp_halt;
        input [2:0] a; input [31:0] d;
        begin exp_halt = {a, d[31:27]}; end
    endfunction

    initial begin
        clk = 0; rst_n = 0; div = 10'd3;
        tx_trigger = 0; tx_enable = 1; err_inject = 0;
        slave_addr = 0; tx_data = 0;
        pass_cnt = 0; fail_cnt = 0; clear_flags;
        #30; @(posedge clk); rst_n = 1;
        repeat(5) @(posedge clk);

        // ── Test 1: Normal transmission ──
        $display("\n--- Test 1: Normal (3 pkts) ---");
        begin : t1
            integer i;
            reg [2:0]  addrs [0:2];
            reg [31:0] datas [0:2];
            reg [7:0]  eh;
            addrs[0]=3'd1; datas[0]=32'hDEADBEEF;
            addrs[1]=3'd5; datas[1]=32'hA5A5A5A5;
            addrs[2]=3'd7; datas[2]=32'hFFFFFFFF;
            for (i = 0; i < 3; i = i + 1) begin
                clear_flags;
                send_clean(addrs[i], datas[i]);
                eh = exp_halt(addrs[i], datas[i]);
                if (bc_valid_seen && recv_halt===eh && !bc_hamming_err_seen)
                    begin $display("[PASS] pkt%0d addr=%0d data=%08H bc_halt=%02H",i,addrs[i],datas[i],recv_halt); pass_cnt=pass_cnt+1; end
                else
                    begin $display("[FAIL] pkt%0d bv=%b herr=%b halt=%02H(exp%02H)",i,bc_valid_seen,bc_hamming_err_seen,recv_halt,eh); fail_cnt=fail_cnt+1; end
            end
        end

        // ── Test 2: 1-bit error → corrected ──
        // inject_bit=10 flips d[24]=payload[24]
        $display("\n--- Test 2: 1-bit err (cw[10]) -> correction ---");
        begin : t2
            reg [7:0] eh;
            eh = exp_halt(3'd3, 32'hDEADBEEF);
            clear_flags;
            send_frame_inj(3'd3, 32'hDEADBEEF, 10, -1);
            if (bc_valid_seen && recv_halt===eh && !bc_hamming_err_seen)
                begin $display("[PASS] corrected bc_halt=%02H",recv_halt); pass_cnt=pass_cnt+1; end
            else
                begin $display("[FAIL] bv=%b herr=%b halt=%02H(exp%02H)",bc_valid_seen,bc_hamming_err_seen,recv_halt,eh); fail_cnt=fail_cnt+1; end
        end

        // ── Test 3: 2-bit error → bc_hamming_err=1 ──
        $display("\n--- Test 3: 2-bit err (cw[10]+cw[11]) -> hamming_err ---");
        begin : t3
            clear_flags;
            send_frame_inj(3'd4, 32'h12345678, 10, 11);
            if (bc_hamming_err_seen && !bc_valid_seen)
                begin $display("[PASS] bc_hamming_err=1 bc_valid=0"); pass_cnt=pass_cnt+1; end
            else
                begin $display("[FAIL] herr=%b bv=%b",bc_hamming_err_seen,bc_valid_seen); fail_cnt=fail_cnt+1; end
        end

        $display("\n[DONE] slave_tx_master_rx: %0d PASS %0d FAIL",pass_cnt,fail_cnt);
        if (fail_cnt==0) $display("ALL PASS");
        $finish;
    end

endmodule
