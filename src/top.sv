`timescale 1ns / 1ps


module testbench();
    logic clk;
    logic reset;
    logic [63:0] writedata, dataadr;
    logic memwrite;

    top riscv(clk, reset, writedata, dataadr, memwrite);

    initial 
    begin 
        reset <= 1; #22; reset <= 0;
    end 

    always 
    begin 
        clk <= 1; #5; clk <= 0; #5;
    end

    always @(negedge clk)
    begin 
        if (memwrite) begin
            if (dataadr == 84 && writedata == 7) begin 
                $display("simulation succeeded");
                $stop;
            end else if (dataadr != 80) begin
                $display("simulation failed");
                $stop;
            end
        end
    end
endmodule

module top(input  logic        clk, reset,
           output logic [63:0] writedata, dataadr,
           output logic        memwrite);
    logic [31:0] instr;
    logic [63:0] pc, readdata;
    cpu cpu(clk, reset, pc, instr, memwrite, dataadr, writedata, readdata);
    imem imem(pc[7:2], instr);
    dmem dmem(clk, memwrite, dataadr, writedata, readdata);
endmodule

module dmem(input logic clk, we,
            input logic [63:0] a, wd,
            output logic [63:0] rd);
    logic [63:0] RAM[63:0];
    assign rd = RAM[a[63:2]];
    always_ff @(posedge clk)
        if (we) RAM[a[63:2]] <= wd;
endmodule

module imem(input logic [5:0] a,
            output logic [63:0] rd);
    logic [63:0] RAM[63:0];
    initial 
        $readmemh("C:\\riscv\\testdat\\test.dat",RAM);
    assign rd = RAM[a];
endmodule

