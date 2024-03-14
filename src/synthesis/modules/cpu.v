module cpu #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
) (
    input clk,
    input rst_n,
    input [DATA_WIDTH-1:0] mem_in,
    input [DATA_WIDTH-1:0] in,
    output reg mem_we,
    output reg [ADDR_WIDTH-1:0] mem_addr,
    output reg [DATA_WIDTH-1:0] mem_data,
    output wire [DATA_WIDTH-1:0] out,
    output wire [ADDR_WIDTH-1:0] pc,
    output wire [ADDR_WIDTH-1:0] sp
);


    reg pc_cl, pc_ld, pc_inc, pc_dec, pc_sr, pc_ir, pc_sl, pc_il;
    reg [5:0] pc_in;
    reg sp_cl, sp_ld, sp_inc, sp_dec, sp_sr, sp_ir, sp_sl, sp_il;
    reg [5:0] sp_in;
    reg irh_cl, irh_ld, irh_inc, irh_dec, irh_sr, irh_ir, irh_sl, irh_il;
    reg [15:0] irh_in;
    wire [15:0] irh_out;
    reg irl_cl, irl_ld, irl_inc, irl_dec, irl_sr, irl_ir, irl_sl, irl_il;
    reg [15:0] irl_in;
    wire [15:0] irl_out;
    reg a_cl, a_ld, a_inc, a_dec, a_sr, a_it, a_sl, a_il;
    reg [15:0] a_in;
    wire [15:0] a_out;
    
    wire [5:0] pc_out, sp_out;

    assign pc = pc_out;
    assign sp = sp_out;


    register #(6) PC(.clk(clk), .rst_n(rst_n), .cl(pc_cl), .ld(pc_ld), .in(pc_in), .inc(pc_inc), .dec(pc_dec), .sr(pc_sr), .ir(pc_ir), .sl(pc_sl), .il(pc_il), .out(pc_out) );
    register #(6) SP(.clk(clk), .rst_n(rst_n), .cl(sp_cl), .ld(sp_ld), .in(sp_in), .inc(sp_inc), .dec(sp_dec), .sr(sp_sr), .ir(sp_ir), .sl(sp_sl), .il(sp_il), .out(sp_out) );
    register #(16) IRH(.clk(clk), .rst_n(rst_n), .cl(irh_cl), .ld(irh_ld), .in(irh_in), .inc(irh_inc), .dec(irh_dec), .sr(irh_sr), .ir(irh_ir), .sl(irh_sl), .il(irh_il), .out(irh_out) );
    register #(16) IRL(.clk(clk), .rst_n(rst_n), .cl(irl_cl), .ld(irl_ld), .in(irl_in), .inc(irl_inc), .dec(irl_dec), .sr(irl_sr), .ir(irl_ir), .sl(irl_sl), .il(irl_il), .out(irl_out) );
    register #(16) A(.clk(clk), .rst_n(rst_n), .cl(a_cl), .ld(a_ld), .in(a_in), .inc(a_inc), .dec(a_dec), .sr(a_sr), .ir(a_ir), .sl(a_sl), .il(a_il), .out(a_out));

    reg [2:0] alu_oc;
    reg [DATA_WIDTH-1:0] alu_a, alu_b;
    wire [DATA_WIDTH-1:0] alu_f;

    alu #(DATA_WIDTH) alu_inst(.oc(alu_oc), .a(alu_a), .b(alu_b), .f(alu_f));
    

    reg [DATA_WIDTH-1:0] out_reg, out_next;

    reg [4:0] state_reg, state_next;
    // fetch, decode, execute, execute1, execute3, halt
    localparam setup = 5'b00000;
    localparam fetch1 = 5'b00001;
    localparam decode = 5'b00010;
    localparam execute1 = 5'b00011;
    localparam execute2 = 5'b00100;
    localparam execute3 = 5'b00101;
    localparam halt = 5'b00110;
    localparam load_irh = 5'b00111;
    localparam fetch2 = 5'b01000;
    localparam load_op1 = 5'b01001;
    localparam load_op2 = 5'b01010;
    localparam load_op3 = 5'b01011;
    localparam decode1 = 5'b01100;
    localparam decode2 = 5'b01101;
    localparam decode3 = 5'b01110;
    localparam decode4 = 5'b01111;
    localparam decode5 = 5'b10000;
    localparam out_operand1 = 5'b10001;
    localparam out_operand2 = 5'b10010;
    localparam execute_mov = 5'b10011;
    localparam load_irl = 5'b10100;
    localparam execute = 5'b10101;
    localparam execute_alu = 5'b10110;
    localparam execute_alu1 = 5'b10111;
    localparam out_operand3 = 5'b11000;
    

    reg mem_inddir_operand1, mem_inddir_operand2, mem_inddir_operand3;
    reg [2:0] addr_operand1, addr_operand2, addr_operand3;
    reg [DATA_WIDTH-1:0] val_operand1, val_operand2, val_operand3;

    assign out = out_reg;
    reg [3:0] oc;

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            out_reg <= {DATA_WIDTH{1'b0}};
            state_reg <= 5'b00000; 
        end 
        else begin
            out_reg <= out_next;
            state_reg <= state_next;
        end
    end

    always @(*) begin

        out_next = out_reg;
        state_next = state_reg;
        mem_addr = 0;
        mem_data = 0;
        mem_we = 0;
        pc_ld = 1'b0;
        pc_in = 6'b000000;  
        
        pc_inc = 1'b0;
        irl_ld = 1'b0;
        irl_in = {16{1'b0}};
        irh_in = {16{1'b0}};
        oc = 4'b0000;
        mem_inddir_operand1 = 0;
        mem_inddir_operand2 = 0;
        mem_inddir_operand3 = 0;

        addr_operand1 = 0;
        addr_operand2 = 0;
        addr_operand3 = 0;
        val_operand1 = 0;
        alu_a = 0;
        alu_b = 0;
        val_operand2 = 0;
        val_operand3 = 0;
        alu_oc = 0;
        irh_ld = 1'b0;
        
        pc_ld = 1'b0;
        a_ld = 1'b0;
        a_in = 6'b000000;


        case(state_reg)

            setup: begin      
                
                pc_ld = 1'b1;
                pc_in = 6'b001000;     
                state_next = fetch1;
            end

            fetch1: begin
                // IR31...16 <= MEM[PC]
                
                mem_addr = pc;
                mem_we = 1'b0;
                // PC <= PC + 1
                pc_inc = 1'b1;
                state_next = load_irh;
                
            end

            load_irh: begin
                irh_ld = 1;
                irh_in = mem_in;
                state_next = decode;
            end

            fetch2: begin
                
                mem_addr = pc;
                mem_we = 1'b0;
                pc_inc = 1'b1;
                state_next = load_irl;
            end

            load_irl: begin
                irl_ld = 1;
                irl_in = mem_in;
                state_next = execute_mov;
            end

            decode: begin
                mem_inddir_operand1 = irh_out[11];
                mem_addr = irh_out[10:8];
                addr_operand1 = irh_out[10:8];
                mem_we = 0;
                if(mem_inddir_operand1) begin
                    state_next = decode1;
                end else begin
                    state_next = load_op1;
                end
            end

            decode1: begin
                mem_addr = mem_in;
                addr_operand1 = mem_in;
                irh_in = {irh_out[15:11], addr_operand1, irh_out[7:0]};
                irh_ld = 1'b1;
                mem_we = 1'b0;
                state_next = load_op1;
            end

            load_op1: begin
                a_in = mem_in;
                a_ld = 1'b1;
                state_next = decode2;
            end

            decode2: begin
                mem_inddir_operand2 = irh_out[7];
                mem_addr = irh_out[6:4];
                addr_operand2 = irh_out[6:4];
                mem_we = 1'b0;
                if(mem_inddir_operand2) begin
                    state_next = decode3;
                end else if (irh_out[15:12] == 0)
                    state_next = load_op2;
                else
                    state_next = decode4;

            end

            decode3: begin
                mem_addr = mem_in;
                addr_operand2 = mem_in;
                irh_in = {irh_out[15:7], addr_operand2, irh_out[3:0]};
                irh_ld = 1'b1;
                mem_we = 1'b0;
                state_next = load_op2;
            end

            load_op2: begin
                a_in = mem_in;
                a_ld = 1'b1;
                state_next = decode4;
            end

            decode4: begin
                mem_inddir_operand3 = irh_out[3];
                mem_addr = irh_out[2:0];
                addr_operand3 = irh_out[2:0];
                mem_we = 1'b0;
                if(mem_inddir_operand3) begin
                    state_next = decode5;
                end else begin
                    state_next = load_op3;
                end
            end

            decode5: begin
                mem_addr = mem_in;
                addr_operand3 = mem_in;
                irh_in = {irh_out[15:3], addr_operand3};
                irh_ld = 1'b1;
                mem_we = 1'b0;
                state_next = load_op3;
            end
            
            load_op3: begin
                val_operand3 = mem_in;
                state_next = execute;
            end

            execute: begin
                oc = irh_out[15:12];
                case(oc) 
                    4'b0000: begin
                        // mov
                        mem_addr = irh_out[2:0]; //addr_operand3
                        mem_we = 1'b0;
                        state_next = execute1;
                    end
                    4'b0001: begin
                        // ADD
                        mem_addr = irh_out[6:4]; // addr op 2
                        mem_we = 1'b0;
                        state_next = execute_alu;
                    end
                    4'b0010: begin
                        // SUB
                        mem_addr = irh_out[6:4]; // addr op 2
                        mem_we = 1'b0;
                        state_next = execute_alu;
                    end
                    4'b0011: begin
                        // MUL
                        mem_addr = irh_out[6:4]; // addr op 2
                        mem_we = 1'b0;
                        state_next = execute_alu;
                    end
                    
                    4'b0100: begin
                        // DIV
                        state_next = fetch1;
                    end
                    4'b1111: begin
                        // STOP
                        mem_addr = irh_out[10:8];
                        mem_we = 1'b0;
                        state_next = out_operand1;
                    end
                    4'b0111: begin
                        // IN
                        mem_addr = irh_out[10:8]; // addr_operand1
                        mem_data = in;
                        mem_we = 1'b1;
                        state_next = fetch1;
                    end
                    4'b1000: begin
                        // OUT
                        //out_next = val_operand1;
                        out_next = a_out;

                        state_next = fetch1;
                    end
                    default: state_next = halt;

                endcase
            end

            execute1: begin
                
                val_operand3 = mem_in;
                    
                if (val_operand3 == 4'b1000) begin
                    state_next = fetch2;
                end else begin
                    
                mem_addr = irh_out[10:8]; // addr_operand1    
                mem_data = a_out; // operand 2
                mem_we = 1'b1;
                state_next = fetch1;
                end
                
            end

            execute_mov: begin
                mem_addr = irh_out[10:8];
                mem_data = a_out;
                mem_we = 1'b1;
                state_next = fetch1;
            end

            execute_alu: begin
                a_in = mem_in; // A = operand 2;
                a_ld = 1'b1;
                mem_addr = irh_out[2:0]; // addr op 3;
                mem_we = 1'b0;
                state_next = execute_alu1; 
            end

            execute_alu1: begin
                alu_a = a_out; // operand 2
                alu_b = mem_in; // operand 3

                case (irh_out[15:12] ) 
                    4'b0001: alu_oc = 3'b000;
                    4'b0010: alu_oc = 3'b001;
                    4'b0011: alu_oc = 3'b010;
                    4'b0100: alu_oc = 3'b011;
                    default: alu_oc = 3'b000;

                endcase

                mem_addr = irh_out[10:8]; // addr op1
                mem_data = alu_f; // rezultat
                mem_we = 1'b1;
                state_next = fetch1;
            end

       

            out_operand1: begin
                val_operand1 = mem_in;
                if (val_operand1 != 16'h00)
                    out_next = val_operand1;
                mem_addr = irh_out[6:4];
                mem_we = 1'b0;
                state_next = out_operand2;
            end

            out_operand2: begin
                val_operand2 = mem_in;

                if(val_operand2 != 16'h00)
                    out_next = val_operand2;
                mem_addr = irh_out[2:0];
                mem_we = 1'b0;
                state_next = out_operand3;
            end

            out_operand3: begin
                val_operand3 = mem_in;
                if(val_operand3 != 16'h00)
                    out_next = val_operand3;
                state_next = halt;
            end

            halt: begin
                
            end

        endcase 
    end
    

    
endmodule