`timescale 1ns / 1ps

module hazard_unit1 (
    input reset_ni,
    input [4:0] rs1D,
    input [4:0] rs2D,
    input [4:0] rdE,
    input [4:0] rs1E,
    input [4:0] rs2E,
    input       PC_srcE,
    input       res_srcE,
    input [4:0] rdM,
    input       reg_writeM,
    input [4:0] rdW,
    input       reg_writeW,
    
    input global_mem_stall,
    
    output reg  stallF,
    output reg  stallD, 
    output reg  flushD,
    output reg  flushE,
    output reg  [1:0] forwardAE,
    output reg  [1:0] forwardBE
    );
    

    always @(*) begin
        if (!reset_ni) begin
            stallF    = 0;
            stallD    = 0;  
            flushD    = 0;  
            flushE    = 0;
            forwardAE = 0;
            forwardBE = 0;
        end
        else begin
            // 1. FORWARDING LOGIC 
            if (((rs1E == rdM) & reg_writeM) & (rs1E != 5'd0)) begin
                forwardAE = 2'b10;
            end else if (((rs1E == rdW) & reg_writeW) & (rs1E != 5'd0)) begin
                forwardAE = 2'b01;
            end else begin 
                forwardAE = 2'b00;
            end
            if (((rs2E == rdM) & reg_writeM) & (rs2E != 5'd0)) begin
                forwardBE = 2'b10;
            end else if (((rs2E == rdW) & reg_writeW) & (rs2E != 5'd0)) begin
                forwardBE = 2'b01;
            end else begin
                forwardBE = 2'b00;
            end
            
            // STALL LOGIC 
            if (global_mem_stall) begin
                stallF = 1;
                stallD = 1;
            end else begin
                stallF = 0;
                stallD = 0;
            end
        end
        
        flushD = PC_srcE;
        flushE = PC_srcE; /// branch/ jump
   end
endmodule