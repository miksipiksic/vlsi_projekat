module clk_div #(
    parameter DIVISOR = 50000000
) (
    input clk,
    input rst_n,
    output out
);

reg out_reg, out_next;
integer timer_next, timer_reg;

assign out = out_reg;


always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        out_reg <= 1'b0;
        timer_reg <= 0;
    end
    else begin
        out_reg <= out_next;
        timer_reg <= timer_next;
    end
end

always @(*) begin
    out_next = out_reg;
    timer_next = timer_reg;
    if(timer_reg == (DIVISOR / 2)) begin
        out_next = ~out_reg;
        timer_next = 0;
    end else begin
        timer_next = timer_reg + 1;
    end

    
end

endmodule