`timescale 1ns / 1ps
//レジスタファイル
module regfile(input logic clk,
               input logic we3,
               input logic [4:0] ra1, ra2, wa3,
               input logic [63:0] wd3,
               output logic [63:0] rd1, rd2);
    logic [63:0] rf[31:0];
    always_ff @(posedge clk)
        if (we3) rf[wa3] <= wd3;
    assign rd1 = (ra1 != 0) ? rf[ra1] : 0;
    assign rd2 = (ra2 != 0) ? rf[ra2] : 0;
endmodule 

//加算
module adder #(parameter WIDTH = 64)
             (input logic [WIDTH-1:0] a, b,
             output logic [WIDTH-1:0] y);
    assign y = a + b;
endmodule

//左12シフト
module sl12(input logic [63:0] a,
           output logic [63:0] y);
    assign y = {a[51:0], 12'b000000000000};
endmodule 

//符号拡張
module signext(input logic [31:0] a,
               output logic [63:0] y);
    assign y = {{32{a[31]}},a};
endmodule 

//ゼロ拡張
module zeroext(input logic [31:0] a,
               output logic [63:0] y);
    assign y = {32'b0,a};
endmodule 

//即値拡張
module immext(input logic [11:0] a,
              output logic [63:0] y);
    assign y = {{52{a[11]}},a};
endmodule

//branch拡張
module branchext(input logic [12:0] a,
              output logic [63:0] y);
    assign y = {{51{a[12]}},a};
endmodule

//jump拡張
module jumpext(input logic [20:0] a,
              output logic [63:0] y);
    assign y = {{43{a[20]}},a};
endmodule

//リセット付きフリップフロップ
module flopr #(parameter WIDTH = 64)
              (input logic clk,reset,
               input logic [WIDTH-1:0] d,
               output logic [WIDTH-1:0] q);
    always_ff @(posedge clk, posedge reset)
        if (reset) q <= 0;
        else       q <= d;
endmodule

module mux2 #(parameter WIDTH = 64)
            (input logic [WIDTH-1:0] d0, d1,
             input logic             s,
             output logic [WIDTH-1:0] y);
    assign y = s ? d1: d0;
endmodule
