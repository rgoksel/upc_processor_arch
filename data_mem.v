`timescale 1ns / 1ps

/*
module data_mem  #(parameter w = 32, d = 256, d_bit = $clog2(d))(
    input clk,
    input [31:0] data_in,
    input [31:0] addr_in,
    input we,
    input [3:0] wstrb,
    input [3:0] wstrb_load,
    output reg [31:0] data_out
    );
    
    reg [w-1:0] data_mem [0:d];
    
    genvar i;
    generate
        for (i = 0 ; i < 257 ; i = i +1) begin
            initial data_mem[i] = 32'b0;
        end
    endgenerate
    
    wire [7:0] address;
    assign address = {addr_in[9:2]};

    always @(posedge clk) begin
        if (we) begin
            if (wstrb == 4'b0001)
                data_mem[address][7:0] <= data_in[7:0]; //byte
            else if (wstrb == 4'b0011)
                data_mem[address][15:0] <= data_in[15:0]; //half
            else if (wstrb == 4'b1111)
                data_mem[address] <= data_in; //word
            else
                data_mem[address] <= data_in; 
        end
     end
       
     always @(*) begin
          if(wstrb_load == 4'b0001)
              data_out = {{24{data_mem[address][31]}},data_mem[address][7:0]};
          if(wstrb_load == 4'b0011)
              data_out = {{16{data_mem[address][31]}},data_mem[address][15:0]};
          if(wstrb_load == 4'b1111)
              data_out = data_mem[address];
          if(wstrb_load == 4'b1001)
              data_out = {24'd0,data_mem[address][7:0]};
          if(wstrb_load == 4'b1011)
              data_out = {16'd0,data_mem[address][15:0]};
     end

endmodule

*/

module data_mem  #(parameter w = 32, d = 2056, d_bit = $clog2(d))(
    input clk,
    input [31:0] data_in,
    input [31:0] addr_in,
    input we,
    input [3:0] wstrb,
    input [3:0] wstrb_load,
    output reg [31:0] data_out,
    output reg mem_valid_out
    );

reg [w-1:0] data_mem [0:d];
    
genvar i;
generate
    for (i = 0 ; i < d ; i = i +1) begin
        initial data_mem[i] = 32'b0;
    end
endgenerate
    
wire [d_bit-1:0] address_read;
assign address_read = {addr_in[d_bit+1:2]}; 


reg [31:0] read_data_ff0, read_data_ff1, read_data_ff2, read_data_ff3, read_data_ff4;

reg we_ff0, we_ff1, we_ff2, we_ff3, we_ff4;
reg [3:0] wstrb_ff0, wstrb_ff1, wstrb_ff2, wstrb_ff3, wstrb_ff4;
reg [31:0] addr_in_ff0, addr_in_ff1, addr_in_ff2, addr_in_ff3, addr_in_ff4;
reg [31:0] data_in_ff0, data_in_ff1, data_in_ff2, data_in_ff3, data_in_ff4;

reg valid_ff0, valid_ff1, valid_ff2, valid_ff3, valid_ff4;

wire [d_bit-1:0] address_write;
assign address_write = {addr_in_ff4[d_bit+1:2]}; 

reg [31:0] read_data_immediate; 
always @(*) begin
    if(wstrb_load == 4'b0001)
        read_data_immediate = {{24{data_mem[address_read][31]}},data_mem[address_read][7:0]};
    else if(wstrb_load == 4'b0011)
        read_data_immediate = {{16{data_mem[address_read][31]}},data_mem[address_read][15:0]};
    else if(wstrb_load == 4'b1111)
        read_data_immediate = data_mem[address_read];
    else if(wstrb_load == 4'b1001)
        read_data_immediate = {24'd0,data_mem[address_read][7:0]};
    else if(wstrb_load == 4'b1011)
        read_data_immediate = {16'd0,data_mem[address_read][15:0]};
    else
        read_data_immediate = 32'd0; 
end


reg start_valid;
always @(posedge clk) begin
    
    start_valid = (wstrb_load != 4'b0000) | we; 
    
    read_data_ff0 <= read_data_immediate;
    
    // Write Command Path
    we_ff0 <= we;
    wstrb_ff0 <= wstrb;
    addr_in_ff0 <= addr_in;
    data_in_ff0 <= data_in;
    
    // Valid Path
    valid_ff0 <= start_valid;

    // --------- AŞAMA 1 - 4: Kaydırma Zincirleri ---------
    // Read Path
    read_data_ff1 <= read_data_ff0;
    read_data_ff2 <= read_data_ff1;
    read_data_ff3 <= read_data_ff2;
    read_data_ff4 <= read_data_ff3;

    // Write Command Path
    we_ff1 <= we_ff0;
    we_ff2 <= we_ff1;
    we_ff3 <= we_ff2;
    we_ff4 <= we_ff3;

    wstrb_ff1 <= wstrb_ff0;
    wstrb_ff2 <= wstrb_ff1;
    wstrb_ff3 <= wstrb_ff2;
    wstrb_ff4 <= wstrb_ff3;

    addr_in_ff1 <= addr_in_ff0;
    addr_in_ff2 <= addr_in_ff1;
    addr_in_ff3 <= addr_in_ff2;
    addr_in_ff4 <= addr_in_ff3;

    data_in_ff1 <= data_in_ff0;
    data_in_ff2 <= data_in_ff1;
    data_in_ff3 <= data_in_ff2;
    data_in_ff4 <= data_in_ff3;

    // Valid Path
    valid_ff1 <= valid_ff0;
    valid_ff2 <= valid_ff1;
    valid_ff3 <= valid_ff2;
    valid_ff4 <= valid_ff3;


    // --------- AŞAMA 5: Gecikmeli Hafızaya Yazma (Write-Back) ---------
    // Hafızaya yazma işlemi 5 çevrim sonra (we_ff4 aktif olduğunda) gerçekleşir.
    if (we_ff4) begin
        if (wstrb_ff4 == 4'b0001)
            data_mem[address_write][7:0] <= data_in_ff4[7:0]; // byte
        else if (wstrb_ff4 == 4'b0011)
            data_mem[address_write][15:0] <= data_in_ff4[15:0]; // half
        else if (wstrb_ff4 == 4'b1111)
            data_mem[address_write] <= data_in_ff4; // word
        else
            data_mem[address_write] <= data_in_ff4;
    end

    data_out <= read_data_ff4;
    mem_valid_out <= valid_ff4;
end

endmodule


