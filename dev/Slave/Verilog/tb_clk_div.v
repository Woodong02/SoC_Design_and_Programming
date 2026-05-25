`timescale 1ns / 1ps

module tb_clk_div;

    reg        clk;
    reg        rst_n;
    reg [9:0]  div;
    wire       clk_tick;

    clk_div uut (
        .clk(clk),
        .rst_n(rst_n),
        .div(div),
        .clk_tick(clk_tick)
    );

    always #5 clk = ~clk;

    integer tick_count;
    integer cycle_start;
    integer period;

    task check_period;
        input [9:0] test_div;
        input integer expected_period;
        begin
            div = test_div;
            tick_count = 0;
            @(posedge clk_tick);
            cycle_start = $time;
            @(posedge clk_tick);
            period = ($time - cycle_start) / 10; // ns to clk cycles (10ns period)
            if (period == expected_period)
                $display("[PASS] DIV=%0d : tick period = %0d clk cycles", test_div, period);
            else
                $display("[FAIL] DIV=%0d : expected %0d clk cycles, got %0d", test_div, expected_period, period);
        end
    endtask

    initial begin
        clk   = 0;
        rst_n = 0;
        div   = 10'd3;
        #30;
        @(posedge clk);
        rst_n = 1;
        repeat(5) @(posedge clk);

        check_period(10'd3,  4);   // DIV=3  → period = DIV+1 = 4
        check_period(10'd9,  10);  // DIV=9  → period = 10
        check_period(10'd99, 100); // DIV=99 → period = 100

        $display("[DONE] clk_div verification complete.");
        $finish;
    end

endmodule
