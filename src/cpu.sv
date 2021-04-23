`timescale 1ns / 1ps
module cpu (input logic clk, reset,
            output logic [63:0] pc,
            input logic [31:0] instr,
            output logic memwrite,
            output logic [63:0] aluresult, writedata,
            input logic [63:0] readdata);
    logic stype, branch, jtype, regwrite;
    logic alusrc, memtoreg, op32, lui, auipc, jalr;
    logic [5:0] alucontrol;

    controller c(instr, aluresult[0],
                 stype, branch, jtype, regwrite, alusrc, 
                 memtoreg, memwrite, op32, lui, auipc, jalr, 
                 alucontrol);
    datapath dp(clk, reset, pc, instr, aluresult, writedata, readdata,
                stype, branch, jtype, regwrite, alusrc, 
                memtoreg, op32, lui, auipc, jalr, alucontrol);
endmodule


module controller(input logic [31:0] instr,
                 input logic bflag,
                 output logic stype, branch, jtype, regwrite, alusrc, 
                              memtoreg, memwrite, op32, lui, auipc, jalr, 
                 output logic [5:0] alucontrol);
    logic [6:0] op;
    logic [2:0] funct3;
    logic [6:0] funct7;
    assign op = instr[6:0];
    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];
    maindec md(op, funct3, 
               stype, btype, jtype, regwrite, alusrc, 
               memtoreg, memwrite, op32, lui, auipc, jalr);
    aludec ad(op, funct3, funct7, alucontrol);
    assign branch = btype && bflag;
endmodule

module maindec(input logic [6:0] op,
               input logic [2:0] funct3, 
               output logic stype, btype, jtype, regwrite, alusrc, 
               output logic memtoreg, memwrite, op32, lui, auipc, jalr);
    logic [10:0] controls;
    assign {stype, btype, jtype, regwrite, alusrc,
            memtoreg, memwrite, op32, lui, auipc, jalr} = controls;
    always_comb begin 
        // order: RISCV reference1 p.130
        case (op)
            //LUI
            7'b0110111: controls = 11'b00010000100;
            //AUIPC
            7'b0010111: controls = 11'b00010000010;
            //JAL
            7'b1101111: controls = 11'b00110000000;
            //JALR
            7'b1100111: controls = 11'b00011000001;
            //branch系
            7'b1100011: controls = 11'b01000000000;
            //load系
            7'b0000011: controls = 11'b00011100000;
            //store系
            7'b0100011: controls = 11'b10001010000;
            //ADDI系
            7'b0010011: controls = 11'b00011000000;
            //ADD,MULDIV系
            7'b0110011: controls = 11'b00010000000;
            //FENCE, FENCE.I(NOP)
            7'b0001111: controls = 11'b00000000000;
            //32I系
            7'b0011011: controls = 11'b00011001000;
            //32系,MULDIV32系
            7'b0111011: controls = 11'b00010001000;
            default: controls = 11'bxxxxxxxxxxx;
        endcase
    end
endmodule

module aludec(input logic [6:0] op, 
              input logic [2:0] funct3, 
              input logic [6:0] funct7,
              output logic [5:0] alucontrol);
    always_comb begin 
        //load&store&jalr
        if (op == 7'b0000011 || op == 7'b0100011 || op == 7'b1100111) begin 
            alucontrol = 6'b000000;
        end 
        else begin
            alucontrol[5:3] = funct3;
            if (funct7[5] & 
                ((funct3==3'b101 & (op==7'b0010011 || op==7'b0110011 ||
                                    op==7'b0011011 || op==7'b0111011)) ||
                 (funct3==3'b000 & (op==7'b0110011 || op==7'b0111011)))
               ) alucontrol[0] = 1'b1;
            else alucontrol[0] = 1'b0;
            //branch
            if (op == 7'b1100011) alucontrol[2] = 1'b1;
            else alucontrol[2] = 1'b0;
            //muldiv
            if (op == 7'b0110011 && funct7[1:0] == 2'b01) alucontrol[1] = 1'b1;
            else alucontrol[1] = 1'b0;
        end
    end
endmodule

module datapath (input  logic        clk, reset, 
                 input  logic [63:0] pc, 
                 input  logic [31:0] instr, 
                 output logic [63:0] aluresult, writedata, 
                 input  logic [63:0] readdata,
                 input  logic        stype, branch, jtype, regwrite, alusrc, 
                 input  logic        memtoreg, op32, lui, auipc, jalr,
                 input  logic [5:0]  alucontrol);
    logic [63:0] pcplus4, pcnextbr, pcnext, pcbranch, pcjump, pcjal, pcoffset;
    logic [31:0] signimm12, aluout32;
    logic [63:0] srca, srcb;
    logic [63:0] immi, imms, immb, immis, immisb, immj, pcplusj;
    logic [63:0] signimm, signimmj;
    logic [63:0] result1, result2, result3, result4, aluout, aluout32ext;
    logic jump;
    logic zero, overflow, zero32, overflow32; //未使用
    assign jump = jtype | jalr;
    //pc更新
    flopr #(64) pcreg(clk, reset, pcnext, pc);
    mux2 #(64) muxjump(pcnextbr, pcjump, jump, pcnext);
    mux2 #(64) muxbr(pcplus4, pcbranch, branch, pcnextbr);
    adder #(64) pccounter(pc, 64'b100, pcplus4);
    //resultデータパス
    mux2 #(64) muxres1(aluresult, readdata, memtoreg, result1);
    mux2 #(64) muxres2(result1, pcoffset, auipc, result2);
    mux2 #(64) muxres3(result2, signimm12, lui, result3);
    mux2 #(64) muxres4(result3, pcplus4, jump, result4);
    //imm系計算
    immext extitype(instr[31:20],immi);
    immext extstype({instr[31:25],instr[11:7]},imms);
    branchext extbtype({instr[31],instr[7],instr[30:25],instr[11:8],1'b0},immb);
    mux2 #(64) muximms(immi, imms, stype, immis);
    mux2 #(64) muximmsb(immis, immb, branch, immisb);
    immext extimm(immisb, signimm);
    signext extlui({instr[31:12],12'b0},signimm12);
    adder #(64) adderoff(pc,signimm12,pcoffset);
    //jump,branch系補助計算
    jumpext extjump({instr[31],instr[19:12],instr[20],instr[30:21],1'b0},immj);
    adder #(64) adderj(pc, immj, pcplusj);
    adder #(64) adderbr(signimm, pc, pcbranch);
    mux2 #(64) muxjalr(pcplusj, {aluout[63:1],1'b0},jalr,pcjump);
    //ALU
    mux2 #(64) muxsrc(writedata, signimm, alusrc, srcb);
    alu mainalu(srca, srcb, alucontrol, aluout, overflow, zero);
    alu_32 subalu(srca[31:0], srcb[31:0], alucontrol, aluout32, overflow32, zero32);
    signext extalu(aluout32, aluout32ext);
    mux2 #(64) muxalu(aluout, aluout32ext, op32, aluresult);
    //レジスタファイル
    regfile rf(clk, regwrite, instr[19:15], instr[24:20],
               instr[11:7], result4, srca, writedata);
endmodule
/*
module datapath(input  logic        clk, reset,
                input  logic        memtoreg, pcsrc,
                input  logic        alusrc, regdst,
                input  logic        regwrite, jump,
                input  logic [2:0]  alucontrol,
                output logic        zero,
                output logic [31:0] pc,
                input  logic [31:0] instr,
                output logic [31:0] aluout, writedata,
                input  logic [31:0] readdata);
    logic [4:0] writereg;
    logic [31:0] pcnext, pcnextbr, pcplus4, pcbranch;
    logic [31:0] signimm, signimmsh;
    logic [31:0] srca, srcb;
    logic [31:0] result;
    logic cout;//現状使わないがalu用繰り上がり判定用ダミー

    //次のPC
    flopr #(32) pcreg(clk, reset, pcnext, pc);
    adder pccadd1(pc, 32'b100, pcplus4);
    sl2 immsh(signimm, signimmsh);
    adder pcadd2(pcplus4, signimmsh, pcbranch);
    mux2 #(32) pcbrmux(pcplus4, pcbranch, pcsrc, pcnextbr);
    mux2 #(32) pcmux(pcnextbr, {pcplus4[31:28], instr[25:0], 2'b00}, jump, pcnext);

    //レジスタ
    regfile rf(clk, regwrite, instr[25:21], instr[20:16],
               writereg, result, srca, writedata);
    mux2 #(5) wrmux(instr[20:16], instr[15:11], regdst, writereg);
    mux2 #(32) resmux(aluout, readdata, memtoreg, result);
    signext se(instr[15:0], signimm);

    //ALU
    mux2 #(32) srcbmux(writedata, signimm, alusrc, srcb);
    alu alu(srca, srcb, alucontrol, aluout, cout, zero);
endmodule
*/
/*
module controller(input logic [5:0] op, funct,
                  input logic zero,
                  output logic memtoreg, memwrite,
                  output logic pcsrc, alusrc,
                  output logic regdst, regwrite,
                  output logic jump,
                  output logic [2:0] alucontrol);
    logic [1:0] aluop;
    logic branch;
    maindec md(op, memtoreg, memwrite, branch,
               alusrc, regdst, regwrite, jump, aluop);
    aludec ad(funct, aluop, alucontrol);

    assign pcsrc = branch & zero;
endmodule

module maindec(input logic [5:0] op,
               output logic memtoreg, memwrite,
               output logic branch, alusrc,
               output logic regdst, regwrite,
               output logic jump,
               output logic [1:0] aluop);
    logic [8:0] controls;
    assign {regwrite, regdst, alusrc, branch, memwrite,
            memtoreg, jump, aluop} = controls;
    
    always_comb
        case (op)
            6'b000000: controls <= 9'b110000010;
            6'b100011: controls <= 9'b101001000;
            6'b101011: controls <= 9'b001010000;
            6'b000100: controls <= 9'b000100001;
            6'b001000: controls <= 9'b101000000;
            6'b000010: controls <= 9'b000000100;
            default:   controls <= 9'bxxxxxxxxx;
        endcase
endmodule

module aludec(input logic [5:0] funct,
              input logic [1:0] aluop,
              output logic [2:0] alucontrol);
    always_comb
        case(aluop)
            2'b00: alucontrol <= 3'b010; //add
            2'b01: alucontrol <= 3'b110; //sub
            default: case(funct)
                6'b100000: alucontrol <= 3'b010;
                6'b100010: alucontrol <= 3'b110;
                6'b100100: alucontrol <= 3'b000;
                6'b100101: alucontrol <= 3'b001;
                6'b101010: alucontrol <= 3'b111;
                default:   alucontrol <= 3'bxxx;
            endcase
        endcase 
endmodule

module datapath(input  logic        clk, reset,
                input  logic        memtoreg, pcsrc,
                input  logic        alusrc, regdst,
                input  logic        regwrite, jump,
                input  logic [2:0]  alucontrol,
                output logic        zero,
                output logic [31:0] pc,
                input  logic [31:0] instr,
                output logic [31:0] aluout, writedata,
                input  logic [31:0] readdata);
    logic [4:0] writereg;
    logic [31:0] pcnext, pcnextbr, pcplus4, pcbranch;
    logic [31:0] signimm, signimmsh;
    logic [31:0] srca, srcb;
    logic [31:0] result;
    logic cout;//現状使わないがalu用繰り上がり判定用ダミー

    //次のPC
    flopr #(32) pcreg(clk, reset, pcnext, pc);
    adder pccadd1(pc, 32'b100, pcplus4);
    sl2 immsh(signimm, signimmsh);
    adder pcadd2(pcplus4, signimmsh, pcbranch);
    mux2 #(32) pcbrmux(pcplus4, pcbranch, pcsrc, pcnextbr);
    mux2 #(32) pcmux(pcnextbr, {pcplus4[31:28], instr[25:0], 2'b00}, jump, pcnext);

    //レジスタ
    regfile rf(clk, regwrite, instr[25:21], instr[20:16],
               writereg, result, srca, writedata);
    mux2 #(5) wrmux(instr[20:16], instr[15:11], regdst, writereg);
    mux2 #(32) resmux(aluout, readdata, memtoreg, result);
    signext se(instr[15:0], signimm);

    //ALU
    mux2 #(32) srcbmux(writedata, signimm, alusrc, srcb);
    alu alu(srca, srcb, alucontrol, aluout, cout, zero);
endmodule
*/

/*
module mips(input logic clk, reset,
            output logic [31:0] pc,
            input logic [31:0] instr,
            output logic memwrite,
            output logic [31:0] aluout, writedata,
            input logic [31:0] readdata);
    logic memtoreg, alusrc, regdst,
          regwrite, jump, pcsrc, zero;
    logic [2:0] alucontrol;

    controller c(instr[31:26], instr[5:0], zero,
                 memtoreg, memwrite, pcsrc,
                 alusrc, regdst, regwrite, jump,
                 alucontrol);
    datapath dp(clk, reset, memtoreg, pcsrc,
                alusrc, regdst, regwrite, jump,
                alucontrol, zero, pc, instr,
                aluout, writedata, readdata);
endmodule*/