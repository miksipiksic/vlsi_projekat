module bcd (
    input [5:0] in,
    output reg [3:0] ones,
    output reg [3:0] tens
);

integer i;
integer d;

always @(in) begin
    d = 0;
    i = 0;
    for(i = 0; i < 6; i = i + 1) 
        if (in[i]) d = d + 2**i;
    ones = d % 10;
    tens = d / 10;
end
    
endmodule