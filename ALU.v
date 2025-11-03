`timescale 1ns / 1ps

module ALU(
    input [31:0] A, B,
    input reset_ni,
    input [3:0] op,
    input u_s,
    output reg [31:0] FU,
    output reg zero
    );
    
    // Yalnýzca op kodu ALU'nun tüm birimlerine iletilir.
    wire [31:0] au_out, logic_out, shifter_out;
    wire zero_au;
    
    // Basitleþtirilmiþ Arithmetic_Unit
    Arithmetic_Unit au(
        .A_i(A),
        .B_i(B),
        .arith_op(op), // op kodu arith_op olarak kullanýlýyor
        .Sum_o(au_out),
        .zero_au(zero_au),
        .u_s(u_s)
    );
    
    // Logic_Unit (Basitleþtirme gerektirmedi)
    Logic_Unit lu(
        .A_i(A), 
        .B_i(B),
        .logic_op(op), // op kodu logic_op olarak kullanýlýyor
        .logic_out(logic_out)
    );
    
    // Shifter_Unit (Basitleþtirme gerektirmedi)
    Shifter_Unit su(
        .A_i(A), 
        .B_i(B),
        .shifter_op(op), // op kodu shifter_op olarak kullanýlýyor
        .shifter_out(shifter_out)
    );
    
    always @(*) begin
        if (!reset_ni) begin
            FU = 32'd0;
            zero = 1'b0;
        end else begin
            // 1. FU (Fonksiyonel Ünite) Çýkýþ Seçimi
            case (op)
                4'b0000, 4'b0001, 4'b1110: FU = au_out; // Toplama, Çýkarma, LUI/Load
                4'b0010, 4'b0100, 4'b0110: FU = shifter_out; // Kaydýrma
                4'b1000, 4'b1010, 4'b1100: FU = logic_out; // Mantýk
                
                4'b0011: begin // SLT/SLTU (Karþýlaþtýrma)
                    // SLT/SLTU talimatýnýn sonucu (1 veya 0) zero_au'dan gelmelidir.
                    // Bu mantýk hatalýydý, doðrusu au_out kullanmak.
                    // SLT/SLTU iþlemlerinde sonuç zaten Arithmetic_Unit'te hesaplanýp 
                    // Sum_o'ya (yani au_out'a) atanmalýdýr.
                    FU = au_out; 
                end
                default: FU = 32'd0;
            endcase

            // 2. Zero Flag Hesaplamasý
            // zero_au sadece karþýlaþtýrma ve dallanma iþlemleri için anlamlýdýr.
            if (op == 4'b0011 || op == 4'b0101 || op == 4'b0111 || op == 4'b1001 || op == 4'b1011) begin
                zero = zero_au;
            end else begin 
                zero = 1'b0;
            end
        end
    end
endmodule


module Arithmetic_Unit(
    input [31:0] A_i,
    input [31:0] B_i,
    input [3:0] arith_op,
    input u_s,
    output [31:0] Sum_o,
    output zero_au
    );
    
    wire [31:0] result_add_sub;
    
    wire slt_res, sltu_res;
    
    assign slt_res = ($signed(A_i) < $signed(B_i)) ? 1'b1 : 1'b0; 
    assign sltu_res = (A_i < B_i) ? 1'b1 : 1'b0;
    
    assign result_add_sub = (arith_op == 4'b0000) ? (A_i + B_i) :   
                        (arith_op == 4'b0001) ? (A_i - B_i) :   
                        (arith_op == 4'b1110) ? B_i :
                        32'd0;
    
    assign Sum_o = (arith_op == 4'b0011) ? (u_s ? sltu_res : slt_res) : result_add_sub;
    
    wire [31:0] diff = A_i - B_i;
    
    assign zero_au = 
        (arith_op == 4'b0011) ? (u_s ? sltu_res : slt_res) : // SLT/SLTU için (A<B) sonucunu döndür
        (arith_op == 4'b0101) ? (diff == 32'd0) : // BEQ (A==B)
        (arith_op == 4'b0111) ? (diff != 32'd0) : // BNE (A!=B)
        (arith_op == 4'b1001) ? slt_res : // BLT (A<B, signed)
        (arith_op == 4'b1011) ? ~slt_res : // BGE (A>=B, signed)
        (arith_op == 4'b1001 && u_s) ? sltu_res : // BLTU (A<B, unsigned)
        (arith_op == 4'b1011 && u_s) ? ~sltu_res : // BGEU (A>=B, unsigned)
        1'b0;
endmodule

module Logic_Unit(
    input [31:0] A_i, B_i,
    input [3:0] logic_op,
    output [31:0] logic_out
    );
    
    assign logic_out= (logic_op == 4'b1000) ? A_i & B_i :
                      (logic_op == 4'b1010) ? A_i ^ B_i :
                      (logic_op == 4'b1100) ? A_i | B_i :
                      A_i;
endmodule

module Shifter_Unit(
    input [31:0] A_i, B_i,
    input [3:0] shifter_op,
    output [31:0] shifter_out
    );
    
    wire [4:0] shamt = B_i[4:0];
    
    localparam [3:0] SLL = 4'b0010,  
                     SRL = 4'b0100,
                     SRA = 4'b0110;
                     
    assign shifter_out = (shifter_op == SLL) ? A_i << shamt :
                         (shifter_op == SRL) ? A_i >> shamt : // Mantýksal saða kaydýrma
                         (shifter_op == SRA) ? {32{(A_i[31])}} | (A_i >> shamt) : // Aritmetik saða kaydýrma ($signed ve >>> kullanýlýr)
                         A_i;
endmodule

module full_adder (
    input A_i,
    input B_i,
    input Cin,
    output Sum,
    output Cout
);

assign Sum = A_i ^ B_i ^ Cin;
assign Cout = (A_i & B_i) | (B_i & Cin) | (Cin & A_i);

endmodule