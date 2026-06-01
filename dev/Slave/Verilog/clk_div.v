module clk_div (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [9:0]  div,
    output wire        clk_tick
);

    reg [9:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 10'd0;
        else if (cnt == div - 10'd1)   // period = DIV clocks (matches slave_tx/master_rx convention)
            cnt <= 10'd0;
        else
            cnt <= cnt + 10'd1;
    end

    assign clk_tick = (cnt == div - 10'd1);

endmodule
