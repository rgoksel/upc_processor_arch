`timescale 1ns / 1ps

module PC(
    input clk,
    input en,
    input reset_ni,
    input [31:0] pc_next,
    output reg [31:0] PC
    );
    
//    initial begin
//        PC <= 32'h80000000;
//    end 
    
    always @(posedge clk) begin
        if ( !en) begin
            if(!reset_ni)
                PC <= 32'h80000000;
            else
                PC <= pc_next;
       end
    end
endmodule

module plus_four (
    input reset_ni,
    input [31:0] PC,
    output reg [31:0] PC_plus4
);

always @(*) begin
    if (!reset_ni)
        PC_plus4 = 32'h80000004;
    else
        PC_plus4 = PC + 32'd4;
end

endmodule

module plus_imm_ext1 (
    input reset_ni,
    input [31:0] PC,
    input [31:0] Imm_Ext,
    output reg [31:0] PC_Target
);

always @(*) begin
    if (!reset_ni)
        PC_Target = 32'h80000004;
    else
        PC_Target = PC + Imm_Ext; 
end

endmodule

