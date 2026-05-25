// slot_timer: generates tx_trigger and watchdog (no_broadcast) for TDMA slot timing
// slot_ticks = 50 * 2*(div+1) + guard_ticks = 100*(div+1) + guard_ticks
// tx_trigger  : 1-clock pulse at slot_cnt == slave_addr * slot_ticks (after active_edge)
// no_broadcast: 1-clock pulse at slot_cnt == 9 * slot_ticks (watchdog)
module slot_timer (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [9:0]  div,
    input  wire [9:0]  guard_ticks,
    input  wire [2:0]  slave_addr,
    input  wire        active_edge,

    output reg         tx_trigger,
    output reg         no_broadcast
);
    wire [31:0] div32      = {22'b0, div};
    wire [31:0] guard32    = {22'b0, guard_ticks};
    wire [31:0] slot_ticks = 32'd100 * (div32 + 32'd1) + guard32;
    wire [31:0] trig_cnt   = {29'b0, slave_addr} * slot_ticks;
    wire [31:0] wdog_cnt   = 32'd9 * slot_ticks;

    reg [31:0] slot_cnt;
    reg        armed;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            slot_cnt     <= 32'd0;
            tx_trigger   <= 1'b0;
            no_broadcast <= 1'b0;
            armed        <= 1'b0;
        end else begin
            tx_trigger   <= 1'b0;
            no_broadcast <= 1'b0;

            if (active_edge) begin
                armed    <= 1'b1;
                slot_cnt <= 32'd0;
            end else if (armed) begin
                slot_cnt <= slot_cnt + 32'd1;
            end

            // tx_trigger fires 1 clock after active_edge for slave_addr==0 (trig_cnt==0)
            // fires at slot_cnt==N*slot_ticks for slave_addr==N>0
            if (!active_edge && armed && slot_cnt == trig_cnt)
                tx_trigger <= 1'b1;

            // watchdog: 9 slot periods without new active_edge
            if (!active_edge && armed && slot_cnt == wdog_cnt)
                no_broadcast <= 1'b1;
        end
    end

endmodule
