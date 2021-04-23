`timescale 1ns / 1ps
module alu_32
    (input logic [31:0] A, B,
     input logic [5:0] alucontrol,
     output logic [31:0] Y,
     output logic overflow, zero);

    logic [31:0] T;

    assign Y = T;
    assign overflow = 0; //オーバーフロー 必要なら実装
    logic [63:0] MU, MSU, MS;
    logic [31:0] DU, DS, RU, RS;

    multiplier_u_32 mul1(A,B,MU);
    multiplier_su_32 mul2(A,B,MSU);
    multiplier_s_32 mul3(A,B,MS);
    divider_u_32 div1(A,B,DU);
    divider_s_32 div2(A,B,DS);
    reminder_u_32 rem1(A,B,RU);
    reminder_s_32 rem2(A,B,RS);

    //alucontrol: funct3(3)branch(1)muldiv(1)bit30(1)
    always_comb begin 
        case (alucontrol)
            //加算
            6'b000000: begin 
                T = A + B;
            end
            //減算
            6'b000001: begin 
                T = A - B;
            end
            //左シフト
            6'b001000: begin 
                T = A << B;
            end
            //右シフト(論理) 
            6'b101000: begin
                T = A >> B;
            end 
            //右シフト(算術) 
            6'b101001: begin
                T = A >>> B;
            end
            //乗算 
            6'b000010: begin
                T = MU[31:0];
            end
            //乗算(ss, higher)
            6'b001010: begin 
                T = MS[63:32];
            end
            //乗算(su, higher)
            6'b010010: begin 
                T = MSU[63:32];
            end
            //乗算(uu,higher)
            6'b011010: begin 
                T = MU[63:32];
            end
            //除算(s)
            6'b100010: begin 
                T = DS;
            end
            //除算(u)
            6'b101010: begin 
                T = DU;
            end
            //剰余(s)
            6'b110010: begin 
                T = RS;
            end 
            //剰余(u)
            6'b111010: begin 
                T = RU;
            end 
            default: begin 
                T = 0;
            end
        endcase 
    end 
    always_comb begin 
        if (T == 0) zero = 1'b1;
        else zero = 1'b0;
    end
endmodule

module multiplier_u_32(input logic [31:0] A,
                    input logic [31:0] B,
                    output logic [63:0] C);
    assign C = A * B;
endmodule

module multiplier_su_32(input logic signed [31:0] A,
                    input logic unsigned [31:0] B,
                    output logic signed [63:0] C);
    assign C = A * B;
endmodule

module multiplier_s_32(input logic signed [31:0] A,
                    input logic signed [31:0] B,
                    output logic signed [63:0] C);
    assign C = A * B;
endmodule

module divider_u_32(input logic [31:0] A,
                 input logic [31:0] B,
                 output logic [31:0] C);
    // cannot implement by single-cycle
    assign C = A;
endmodule
module divider_s_32(input logic [31:0] A,
                 input logic [31:0] B,
                 output logic [31:0] C);
    // cannot implement by single-cycle
    assign C = A;
endmodule
module reminder_u_32(input logic [31:0] A,
                 input logic [31:0] B,
                 output logic [31:0] C);
    // cannot implement by single-cycle
    assign C = A;
endmodule
module reminder_s_32(input logic [31:0] A,
                 input logic [31:0] B,
                 output logic [31:0] C);
    // cannot implement by single-cycle
    assign C = A;
endmodule
