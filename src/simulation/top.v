module top;

    reg [2:0] oc;
    reg [3:0] a;
    reg [3:0] b;
    wire [3:0] f;

    
    reg clk;
    reg rst_n;
    reg cl;
    reg ld;
    reg [3:0] in;
    reg inc;
    reg dec;
    reg sr;
    reg ir;
    reg sl;
    reg il;
    wire [3:0] out;

    alu alu_dut(oc,a,b,f);
    register register_dut(clk, rst_n, cl, ld, in, inc, dec, sr, ir, sl, il, out);


    integer i;
    //3 + 4 + 4 = 11 

    initial begin
        for (i=0; i < 2**11; i = i + 1 ) begin
            {oc, a, b} = i;
            #5;
        end
        $stop;

        cl = 1'b0;
        ld = 1'b0;
        in = 4'b0000;
        inc = 1'b0;
        dec = 1'b0;
        sr = 1'b0;
        ir = 1'b0;
        sl = 1'b0;
        il = 1'b0;

        #7 rst_n = 1'b1;
        
        repeat(1000) begin
            {cl, ld, in, inc, dec, sr, ir, sl, il} = $urandom_range(2**13);
            #10;
        end
        
       
        $finish;

    end
    
    initial begin
        $monitor("time = %6d, oc = %d, a = %d (a = %4b), b = %d (b = %4b), f = %d (f = %4b)", $time,  oc,a, a,b, b,f, f);
    end

    initial begin
        rst_n = 1'b0;
        clk = 1'b0;
        forever begin
            #5 clk = ~clk;
        end
    end

    always @(out)
        $strobe(
            "time = %6d, cl = %b, ld = %b, in = %4b, inc = %b, dec = %b, sr = %b, ir = %b, sl = %b, il = %b, out = %4b",
            $time, cl, ld, in, inc, dec, sr, ir, sl, il, out
        );


endmodule