`timescale 1ns / 1ps

// Communication TB: master_tx --> slave_rx
// master_tx: d = {halt_cmd[7:0], 27'b0}
// slave_rx:  frame_addr = halt_cmd[7:5],  frame_data = {halt_cmd[4:0], 27'b0}
module tb_master_tx_slave_rx;

    reg        clk, rst_n;
    reg [9:0]  div;
    reg        tx_trigger, tx_enable;
    reg [7:0]  halt_cmd;

    wire tx_line;
    wire tx_active, data_sent;

    reg  err_inject;
    wire tx_raw  = (tx_line === 1'bz) ? 1'b0 : tx_line;
    wire rx_sync = tx_raw ^ err_inject;

    wire active_edge, frame_valid, preamble_ok, preamble_err, hamming_err;
    wire [2:0]  frame_addr;
    wire [31:0] frame_data;

    master_tx u_tx (
        .clk(clk), .rst_n(rst_n), .div(div),
        .tx_trigger(tx_trigger), .tx_enable(tx_enable),
        .halt_cmd(halt_cmd),
        .tx_line(tx_line), .tx_active(tx_active), .data_sent(data_sent)
    );

    slave_rx u_rx (
        .clk(clk), .rst_n(rst_n), .enable(1'b1), .div(div),
        .rx_line_sync(rx_sync),
        .active_edge(active_edge), .frame_valid(frame_valid),
        .frame_addr(frame_addr), .frame_data(frame_data),
        .hamming_err(hamming_err), .preamble_err(preamble_err),
        .preamble_ok(preamble_ok)
    );

    always #5 clk = ~clk;

    integer pass_cnt, fail_cnt;

    reg        frame_valid_seen, hamming_err_seen;
    reg [2:0]  recv_addr;
    reg [31:0] recv_data;

    always @(posedge clk) begin
        if (frame_valid) begin frame_valid_seen<=1'b1; recv_addr<=frame_addr; recv_data<=frame_data; end
        if (hamming_err) hamming_err_seen <= 1'b1;
    end

    task clear_flags;
        begin frame_valid_seen=0; hamming_err_seen=0; recv_addr=0; recv_data=0; end
    endtask

    // FIX: wait(tx_active) instead of @(posedge tx_active)
    task send_frame_inj;
        input [7:0]  hcmd;
        input integer inject_bit_a;
        input integer inject_bit_b;
        integer bp, wa, wb;
        begin
            @(posedge clk); #1;
            halt_cmd = hcmd; err_inject = 0;
            tx_trigger = 1'b1;
            @(posedge clk); #1;
            tx_trigger = 1'b0;

            bp = 2 * (div + 1);
            wait(tx_active);

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
        input [7:0] hcmd;
        begin send_frame_inj(hcmd, -1, -1); end
    endtask

    // frame_addr = halt_cmd[7:5],  frame_data = {halt_cmd[4:0], 27'b0}
    function [2:0]  exp_addr; input [7:0] h; begin exp_addr = h[7:5]; end endfunction
    function [31:0] exp_data; input [7:0] h; begin exp_data = {h[4:0], 27'b0}; end endfunction

    initial begin
        clk = 0; rst_n = 0; div = 10'd3;
        tx_trigger = 0; tx_enable = 1; err_inject = 0; halt_cmd = 0;
        pass_cnt = 0; fail_cnt = 0; clear_flags;
        #30; @(posedge clk); rst_n = 1;
        repeat(5) @(posedge clk);

        // ── Test 1: Normal transmission ──
        $display("\n--- Test 1: Normal (3 pkts) ---");
        begin : t1
            integer i;
            reg [7:0]  cmds [0:2];
            reg [2:0]  ea;
            reg [31:0] ed;
            cmds[0]=8'hDE; cmds[1]=8'hAD; cmds[2]=8'hFF;
            for (i = 0; i < 3; i = i + 1) begin
                clear_flags;
                send_clean(cmds[i]);
                ea = exp_addr(cmds[i]); ed = exp_data(cmds[i]);
                if (frame_valid_seen && recv_addr===ea && recv_data===ed && !hamming_err_seen)
                    begin $display("[PASS] pkt%0d halt=%02H -> addr=%0d data=%08H",i,cmds[i],recv_addr,recv_data); pass_cnt=pass_cnt+1; end
                else
                    begin $display("[FAIL] pkt%0d fv=%b herr=%b addr=%0d(exp%0d) data=%08H(exp%08H)",i,frame_valid_seen,hamming_err_seen,recv_addr,ea,recv_data,ed); fail_cnt=fail_cnt+1; end
            end
        end

        // ── Test 2: 1-bit error → corrected ──
        // inject_bit=10 flips d[24] (zero-pad region); correction restores it
        $display("\n--- Test 2: 1-bit err (cw[10]) -> correction ---");
        begin : t2
            reg [2:0]  ea;
            reg [31:0] ed;
            ea = exp_addr(8'hA5); ed = exp_data(8'hA5);
            clear_flags;
            send_frame_inj(8'hA5, 10, -1);
            if (frame_valid_seen && recv_addr===ea && recv_data===ed && !hamming_err_seen)
                begin $display("[PASS] corrected addr=%0d data=%08H",recv_addr,recv_data); pass_cnt=pass_cnt+1; end
            else
                begin $display("[FAIL] fv=%b herr=%b addr=%0d(exp%0d) data=%08H(exp%08H)",frame_valid_seen,hamming_err_seen,recv_addr,ea,recv_data,ed); fail_cnt=fail_cnt+1; end
        end

        // ── Test 3: 2-bit error → hamming_err=1 ──
        $display("\n--- Test 3: 2-bit err (cw[5]+cw[6]) -> hamming_err ---");
        begin : t3
            clear_flags;
            send_frame_inj(8'h3C, 5, 6);
            if (hamming_err_seen && !frame_valid_seen)
                begin $display("[PASS] hamming_err=1 frame_valid=0"); pass_cnt=pass_cnt+1; end
            else
                begin $display("[FAIL] herr=%b fv=%b",hamming_err_seen,frame_valid_seen); fail_cnt=fail_cnt+1; end
        end

        $display("\n[DONE] master_tx_slave_rx: %0d PASS %0d FAIL",pass_cnt,fail_cnt);
        if (fail_cnt==0) $display("ALL PASS");
        $finish;
    end

endmodule
