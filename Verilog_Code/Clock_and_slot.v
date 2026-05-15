module clock_and_slot(
input	wire			resetn,
input	wire			clk,

output	reg		[3:0]	slot,
output	reg		[21:0]	clk_cnt
);



always @(posedge clk or negedge resetn)
begin
	if(!resetn) begin
		clk_cnt <= 0;
	end
	else begin
		if(clk_cnt == 21'd2499999)
			clk_cnt <= 21'd0;
		else 
			clk_cnt <= clk_cnt + 21'd1;
	end
end

always @(posedge clk or negedge resetn)
begin
	if(!resetn) begin
		slot <= 4'd0;
	end
	else begin
		if(clk_cnt == 21'd2499999) begin
			if(slot == 4'd9)
				slot <= 4'd0;
			else
				slot <= slot + 4'd1;
		end
	end
end

endmodule