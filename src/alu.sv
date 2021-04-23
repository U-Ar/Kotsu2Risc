`timescale 1ns / 1ps
module alu 
    (input logic [63:0] A, B,
     input logic [5:0] alucontrol,
     output logic [63:0] Y,
     output logic overflow, zero);

    logic [63:0] T;

    assign Y = T;
    assign overflow = 0; //オーバーフロー 必要なら実装
    logic [127:0] MU, MSU, MS;
    logic [63:0] DU, DS, RU, RS;

    multiplier_u mul1(A,B,MU);
    multiplier_su mul2(A,B,MSU);
    multiplier_s mul3(A,B,MS);
    divider_u div1(A,B,DU);
    divider_s div2(A,B,DS);
    reminder_u rem1(A,B,RU);
    reminder_s rem2(A,B,RS);

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
            //SLT
            6'b010000: begin 
                if (A[63]^B[63]) begin 
                    if (B[63]) T = 1;
                    else T = 0;
                end
                else begin 
                    if (A < B) T = 1;
                    else T = 0;
                end
            end
            //SLTU
            6'b011000: begin 
                if (A < B) T = 1;
                else T = 0;
            end
            //XOR
            6'b100000: begin 
                T = A ^ B;
            end
            //OR
            6'b110000: begin 
                T = A | B;
            end
            //AND
            6'b111000: begin 
                T = A & B;
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

            //beq
            6'b000100: begin 
                if (A == B) T = 1;
                else T = 0;
            end
            //bne
            6'b001100: begin 
                if (A == B) T = 0;
                else T = 1;
            end 
            //blt
            6'b100100: begin 
                if (A[63]^B[63]) begin 
                    if (B[63]) T = 1;
                    else T = 0;
                end
                else begin 
                    if (A < B) T = 1;
                    else T = 0;
                end
            end
            //bltu
            6'b110100: begin 
                if (A < B) T = 1;
                else T = 0;
            end
            //bge
            6'b101100: begin 
                if (A[63]^B[63]) begin 
                    if (B[63]) T = 0;
                    else T = 1;
                end
                else begin 
                    if (A < B) T = 0;
                    else T = 1;
                end
            end
            //bgeu
            6'b111100: begin 
                if (A < B) T = 0;
                else T = 1;
            end
            

            //乗算 
            6'b000010: begin
                T = MU[63:0];
            end
            //乗算(ss, higher)
            6'b001010: begin 
                T = MS[127:64];
            end
            //乗算(su, higher)
            6'b010010: begin 
                T = MSU[127:64];
            end
            //乗算(uu,higher)
            6'b011010: begin 
                T = MU[127:64];
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

module multiplier_u(input logic [63:0] A,
                    input logic [63:0] B,
                    output logic [127:0] C);
    assign C = A * B;
endmodule

module multiplier_su(input logic signed [63:0] A,
                    input logic unsigned [63:0] B,
                    output logic signed [127:0] C);
    assign C = A * B;
endmodule

module multiplier_s(input logic signed [63:0] A,
                    input logic signed [63:0] B,
                    output logic signed [127:0] C);
    assign C = A * B;
endmodule

module divider_u(input logic [63:0] A,
                 input logic [63:0] B,
                 output logic [63:0] C);
    // cannot implement by single-cycle
    assign C = A;
endmodule
module divider_s(input logic [63:0] A,
                 input logic [63:0] B,
                 output logic [63:0] C);
    // cannot implement by single-cycle
    assign C = A;
endmodule
module reminder_u(input logic [63:0] A,
                 input logic [63:0] B,
                 output logic [63:0] C);
    // cannot implement by single-cycle
    assign C = A;
endmodule
module reminder_s(input logic [63:0] A,
                 input logic [63:0] B,
                 output logic [63:0] C);
    // cannot implement by single-cycle
    assign C = A;
endmodule