module top #(parameter DIVISOR=50000000, 
            parameter FILE_NAME="mem_init.mif",
            parameter ADDR_WIDTH=6,
            parameter DATA_WIDTH=16) (
    input clk,
    input[2:0] btn,
    input [9:0] sw,
    output [9:0] led,
    output [27:0] hex
);

    wire clk_divided;
    clk_div #(DIVISOR) clk_div_inst(.clk(clk), .rst_n(rst_n), .out(clk_divided));

    assign rst_n = sw[9];
    
    wire mem_we;
    wire [ADDR_WIDTH-1:0] mem_addr;
    wire [DATA_WIDTH-1:0] mem_data;
    wire [DATA_WIDTH-1:0] mem_in;

    wire [ADDR_WIDTH-1:0] pc_out, sp_out;

    wire [DATA_WIDTH-1:0] cpu_out;

    assign led[4:0] = cpu_out[4:0];
    memory #(FILE_NAME, ADDR_WIDTH, DATA_WIDTH) memory_inst(
        .clk(clk_divided), 
        .we(mem_we),
        .addr(mem_addr), 
        .data(mem_data), 
        .out(mem_in)
    );

    wire [3:0] sp_tens, sp_ones;
    wire [3:0] pc_tens, pc_ones;

    bcd bcd_sp(.in(sp), .tens(sp_tens), .ones(sp_ones));
    bcd bcd_pc(.in(pc), .tens(pc_tens), .ones(pc_ones));

    ssd ssd_sp_tens (.in(sp_tens), .out(hex[27:21]));
    ssd ssd_sp_ones (.in(sp_ones), .out(hex[20:14]));
    ssd ssd_pc_tens (.in(pc_tens), .out(hex[13:7]));
    ssd ssd_pc_ones (.in(pc_ones), .out(hex[6:0]));

    cpu #(ADDR_WIDTH, DATA_WIDTH) cpu_inst (
        .clk(clk_divided),
        .rst_n(rst_n),
        .mem_in(mem_in),
        .in({{(DATA_WIDTH-4){1'b0}},{sw[3:0]}}),
        .mem_we(mem_we),
        .mem_addr(mem_addr),
        .mem_data(mem_data),
        .out(cpu_out),
        .pc(pc_out),
        .sp(sp_out)
    );
    
endmodule

/*module top #(
    parameter DIVISOR = 50_000_000,
    parameter FILE_NAME = "mem_init.mif",
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
) (
    input clk,
    input [2:0] btn,
    input [9:0] sw,
    output [9:0] led,
    output [27:0] hex
);

wire clk_divided;
assign rst_n = sw[9];

clk_div #(DIVISOR) CLK_DIV(
    .clk(clk),
    .rst_n(rst_n),
    .out(clk_divided)
);

wire [DATA_WIDTH - 1:0] mem_data, mem_in;
wire [ADDR_WIDTH - 1:0] mem_addr;
wire mem_we;
//wire [10:0] cpu_out_visak;
wire [5:0] pc_out, sp_out;

wire [DATA_WIDTH-1:0] cpu_out;

assign led[4:0] = cpu_out[4:0];

cpu #(ADDR_WIDTH, DATA_WIDTH) CPU(
    .clk(clk_divided), //
    .rst_n(rst_n),
    .mem_in(mem_in),
    .in({{12{1'b0}},sw[3:0]}),
    .mem_we(mem_we),
    .mem_addr(mem_addr),
    .mem_data(mem_data),
    .out(cpu_out),
    .pc(pc_out),
    .sp(sp_out)
);

memory #(FILE_NAME, ADDR_WIDTH, DATA_WIDTH) MEMORY(
    .clk(clk_divided), //
    .we(mem_we),
    .addr(mem_addr),
    .data(mem_data),
    .out(mem_in)
);


 wire [3:0] sp_tens, sp_ones;
    wire [3:0] pc_tens, pc_ones;

    bcd bcd_sp(.in(sp_out), .tens(sp_tens), .ones(sp_ones));
    bcd bcd_pc(.in(pc_out), .tens(pc_tens), .ones(pc_ones));

    ssd ssd_sp_tens (.in(sp_tens), .out(hex[27:21]));
    ssd ssd_sp_ones (.in(sp_ones), .out(hex[20:14]));
    ssd ssd_pc_tens (.in(pc_tens), .out(hex[13:7]));
    ssd ssd_pc_ones (.in(pc_ones), .out(hex[6:0]));

endmodule
*/