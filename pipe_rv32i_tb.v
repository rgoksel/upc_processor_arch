`timescale 1ns / 1ps


module pipe_rv32i_tb();

    reg clk=0;
    reg reset;
    
    pipe_risc32i rvi_1(
    .clk(clk),
    .reset_ni(reset)
    );
    
    always #5 clk = ~clk;
    
    initial begin
        reset = 0;
        #10;
        reset = 1;
    end



endmodule

