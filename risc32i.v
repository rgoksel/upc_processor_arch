`timescale 1ns / 1ps

module pipe_risc32i(
    input clk,
    input reset_ni
    //output [31:0] Result
    );
    
    wire [31:0] data_out_instr;
    wire [6:0] op_code = data_out_instr[6:0];
    wire [2:0] func3 = data_out_instr[14:12];
    wire [6:0] func7 = data_out_instr[31:25];
    
    wire [31:0] PC;
    wire [31:0] pc_next;
    
    wire [31:0] Result;
    wire [4:0] addr1_r = data_out_instr[19:15];
    wire [4:0] addr2_r = data_out_instr[24:20];
    wire [4:0] addr3_w = data_out_instr[11:7];
    wire [31:0] rd1, rd2, Src_B;
    
    wire zero, PC_src, we, u_s, reg_write;
    wire [1:0] Res_src;
    wire [3:0] ALU_Control;
    wire ALU_src;
    wire [3:0] wstrb, wstrb_load;
    wire [2:0] Imm_src;
    
    wire [31:0] ALU_res;
    
    wire [31:0] Read_Data;
    
    wire [31:0] PC_plus4, PC_target;
    
    wire [31:0] Imm_Ext;
    
    wire [31:0] PC_in;
    wire pc_in_sel;
    
    wire branch, jump;
    
    //  Data memory completion valid pulse
    wire mem_valid;
    // Register to pass we_mem to WB stage (Store completion check için gerekli)
    reg we_wb_reg; 
    //Global stall for memory latency
    wire global_mem_stall;
    
    
    
    /*pipe wiressss*/
    //
    wire [31:0] data_out_instr_d;
    wire [31:0] PC_d;
    wire [31:0] PC_plus4_d;
    
    
    //2
    wire [31:0] rd1_ex;
    wire [31:0] rd2_ex;
    wire [31:0] pc_ex;
    wire [4:0] addr3_ex;
    wire [31:0] Imm_Ext_ex;
    wire [31:0] PC_plus4_ex;
    wire [4:0] rs1_D = data_out_instr_d[19:15];
    wire [4:0] rs2_D = data_out_instr_d[24:20];
    wire [4:0] rs1E;
    wire [4:0] rs2E;
    
    //2 control pl1
    wire reg_write_ex;
    wire [1:0] Res_src_ex;
    wire we_ex;
    wire jump_ex;
    wire branch_ex;
    wire [3:0] ALU_Control_ex;
    wire ALU_src_ex;
    wire u_s_ex;
    wire [3:0] wstrb_ex;
    wire [3:0] wstrb_load_ex;
    
    //// 3
    wire [31:0] ALU_res_mem;
    wire [31:0] rd2_mem;
    wire [4:0] addr3_mem;
    wire [31:0] PC_plus4_mem;
    wire [31:0] PC_target_mem;
    
    //3 control
    wire reg_write_mem;
    wire [1:0 ]Res_src_mem;
    wire we_mem;
    wire [3:0] wstrb_mem;
    wire [3:0] wstrb_load_mem;
    ///////////////////
    //4
    wire [31:0] Read_Data_wb;
    wire [31:0] ALU_res_wb;
    wire [4:0] addr3_wb;
    wire [31:0] PC_plus4_wb;
    wire [31:0] PC_target_wb;
    
    
    ///4 cntrl
    wire reg_write_wb;
    wire [1:0] Res_src_wb;
    
    //////
    wire stallF;
    wire stallD;
    wire flushD;
    wire flushE;
    wire [1:0] forwardAE;
    wire [1:0] forwardBE;
    
    hazard_unit1 hazard_unit1(
    .reset_ni(reset_ni),
    .rs1D(rs1_D), // rs1_d yerine rs1_D kullanýldý
    .rs2D(rs2_D), // rs2_d yerine rs2_D kullanýldý
    .rdE(addr3_ex),
    .rs1E(rs1E),
    .rs2E(rs2E),
    .PC_srcE(PC_src),
    .res_srcE(Res_src_mem[0]),
    .rdM(addr3_mem),
    .reg_writeM(reg_write_mem),
    .rdW(addr3_wb),
    .reg_writeW(reg_write_wb),
    
    .global_mem_stall(global_mem_stall), // new
    
    .stallF(stallF),
    .stallD(stallD), 
    .flushD(flushD),
    .flushE(flushE),
    .forwardAE(forwardAE),
    .forwardBE(forwardBE)
    );
    
    mux_pcnext mux_pcnexttt(
        .reset_ni(reset_ni),
        .PC_Src(PC_src),
        .PC_plus4(PC_plus4), 
        .PC_target(PC_target),
        .PC_next(pc_next)
    ); 
    
    PC pc(
        .clk(clk),
        .en(stallF),
        .reset_ni(reset_ni),
        .pc_next(pc_next),
        .PC(PC)
    );
    
    instr_mem #(.w(32), .d(2000)) i_mem(
        .addr_instr(PC),
        .data_out_instr(data_out_instr)
    );
    
    plus_four plusfour(
        .reset_ni(reset_ni),
        .PC(PC),
        .PC_plus4(PC_plus4)
    );
    
    /* ------ first stage ----*/
    
    //pipe
    pipe_if_id pl_if_id(
    .clk(clk),
    .en(stallD),
    .clr(flushD),
    .reset_ni(reset_ni),
    .in_1(data_out_instr),
    .in_2(PC),
    .in_3(PC_plus4),
    .out_1(data_out_instr_d),
    .out_2(PC_d),
    .out_3(PC_plus4_d)
    );
    
    //ok
    ///pipe sonu
    
    RF rf(
        .clk(clk), 
        .rst_ni(reset_ni),
        .we(reg_write_wb), //boxuk
        .data_in(Result), 
        .addr1_r(data_out_instr_d[19:15]), 
        .addr2_r(data_out_instr_d[24:20]), 
        .addr3_w(addr3_wb), //bozuk
        .data_out_1(rd1), 
        .data_out_2(rd2)
    );
    
    control_unit cont_unit(
        .op_code(data_out_instr_d[6:0]),
        .func3(data_out_instr_d[14:12]),
        .func7(data_out_instr_d[31:25]),
        .reset_ni(reset_ni),
        //.zero(zero),
        //.PC_src(PC_src),
        .Res_src(Res_src),
        .mem_write(we),
        .ALU_Control(ALU_Control),
        .u_s(u_s),
        .ALU_src(ALU_src),
        .wstrb(wstrb), //bu yok pipe
        .wstrb_load(wstrb_load), //bu yok pipe
        .Imm_src(Imm_src),
        .reg_write(reg_write),
        .pc_in_sel(pc_in_sel),
        .jump(jump),
        .branch(branch)
    );
    
    extend extenddd(
        .reset_ni(reset_ni),
        .Instr(data_out_instr_d),
        .imm_src(Imm_src),
        .Imm_Ext(Imm_Ext)
    );
    
    mux_jalr mux_j(
    .reset_ni(reset_ni),
    .rs1(rd1), 
    .pc(PC_d),
    .pc_in_sel(pc_in_sel),
    .PC_in(PC_in)
    );
    
    ///second stage
    ////pipe 2 
    
    pipe_id_ex p2_id_ex(
    .clk(clk),
    .en(1'b1), // en=0 ise boru hattý reg'leri hiç çalýþmaz
    .clr(flushE),
    .reset_ni(reset_ni),
    .in_1(rd1),
    .in_2(rd2),
    .in_3(PC_in),
    .in_4(data_out_instr_d[11:7]),
    .in_5(Imm_Ext),
    .in_6(PC_plus4_d),
    .in_7(rs1_D), // rs1_D kullanýldý
    .in_8(rs2_D), // rs2_D kullanýldý
    .out_1(rd1_ex),
    .out_2(rd2_ex),
    .out_3(pc_ex),
    .out_4(addr3_ex),
    .out_5(Imm_Ext_ex),
    .out_6(PC_plus4_ex),
    .out_7(rs1E),
    .out_8(rs2E)
    );
    
    
    pipe_id_ex_control pl_id_ex_c(
    .clk(clk),
    .en(1'b1), // en=0 ise boru hattý reg'leri hiç çalýþmaz
    .clr(flushE),
    .reset_ni(reset_ni),
    .in_1(reg_write),
    .in_2(Res_src),
    .in_3(we),
    .in_4(jump),
    .in_5(branch),
    .in_6(ALU_Control),
    .in_7(ALU_src),
    .in_8(u_s),
    .in_9(wstrb),
    .in_10(wstrb_load),
    .out_1(reg_write_ex),
    .out_2(Res_src_ex),
    .out_3(we_ex),
    .out_4(jump_ex),
    .out_5(branch_ex),
    .out_6(ALU_Control_ex),
    .out_7(ALU_src_ex),
    .out_8(u_s_ex),
    .out_9(wstrb_ex),
    .out_10(wstrb_load_ex)
    );
    
    ///pipeline2 sonu
    
    wire [31:0] srcAE ;
    wire [31:0] srcBE ;
    
    mux_srcA muxA(
    .forwardAE(forwardAE),
    .reset_ni(reset_ni),
    .rd1E(rd1_ex),
    .result(Result),
    .Alu_Result(ALU_res_mem),
    .srcA(srcAE)
    );
    
    mux_srcB mux_B(
    .forwardBE(forwardBE),
    .reset_ni(reset_ni),
    .rd2E(rd2_ex),
    .result(Result),
    .Alu_Result(ALU_res_mem),
    .srcB(srcBE)
    );
    
    mux_Bin mux_b_in(
        .reset_ni(reset_ni),
        .ALU_Src(ALU_src_ex),
        .RD_2(srcBE),
        .Imm_Ext(Imm_Ext_ex),
        .Src_B(Src_B)
    );
    
    ALU alu(
        .A(srcAE),
        .reset_ni(reset_ni), 
        .B(Src_B),
        .op(ALU_Control_ex),
        .u_s(u_s_ex),
        .FU(ALU_res),
        .zero(zero)
    );
    
    plus_imm_ext1 plus_imm_nextt(
        .reset_ni(reset_ni),
        .PC(pc_ex),
        .Imm_Ext(Imm_Ext_ex),
        .PC_Target(PC_target)
    );
    
    assign PC_src = ((zero & branch_ex) | jump_ex) ;
    
    ///pl3
    pipe_ex_mem p3_ex_mem(
    .clk(clk),
    .en(1'b1), // en=0 ise boru hattý reg'leri hiç çalýþmaz
    .clr(1'b0),
    .reset_ni(reset_ni),
    .in_1(ALU_res),
    .in_2(srcBE),
    .in_3(addr3_ex),
    .in_4(PC_plus4_ex),
    .in_5(PC_target),
    .out_1(ALU_res_mem),
    .out_2(rd2_mem),
    .out_3(addr3_mem),
    .out_4(PC_plus4_mem),
    .out_5(PC_target_mem)
    );
    
    pipe_control_ex_mem p_c_ex_mem(
    .clk(clk),
    .en(1'b1), // en=0 ise boru hattý reg'leri hiç çalýþmaz
    .clr(1'b0),
    .reset_ni(reset_ni),
    .in_1(reg_write_ex),
    .in_2(Res_src_ex),
    .in_3(we_ex),
    .in_4(wstrb_ex),
    .in_5(wstrb_load_ex),
    .out_1(reg_write_mem),
    .out_2(Res_src_mem),
    .out_3(we_mem),
    .out_4(wstrb_mem),
    .out_5(wstrb_load_mem)
    );
    
    
    
data_mem #(.w(32), .d(256)) d_mem(
        .clk(clk),
        .data_in(rd2_mem),
        .addr_in(ALU_res_mem),
        .we(we_mem),
        .wstrb(wstrb_mem),
        .wstrb_load(wstrb_load_mem),
        .data_out(Read_Data),
        .mem_valid_out(mem_valid) // new
    );
    
    //pp4
    pipe_mem_wb p4_mem_wb(
    .clk(clk),
    .en(1'b1), // en=0 ise boru hattý reg'leri hiç çalýþmaz
    .clr(1'b0),
    .reset_ni(reset_ni),
    .in_1(Read_Data),
    .in_2(ALU_res_mem),
    .in_3(addr3_mem),
    .in_4(PC_plus4_mem),
    .in_5(PC_target_mem),
    .out_1(Read_Data_wb),
    .out_2(ALU_res_wb),
    .out_3(addr3_wb),
    .out_4(PC_plus4_wb),
    .out_5(PC_target_wb)
    );
    
    pipe_control_mem_wb p4_c_mem_wb(
    .clk(clk),
    .reset_ni(reset_ni),
    .en(1'b1), // en=0 ise boru hattý reg'leri hiç çalýþmaz
    .clr(1'b0),
    .in_1(reg_write_mem),
    .in_2(Res_src_mem),
    .out_1(reg_write_wb),
    .out_2(Res_src_wb)
    );
    
    always @(posedge clk) begin
        if (!reset_ni)
            we_wb_reg <= 1'b0;
        else
            we_wb_reg <= we_mem; // we_mem'i bir çevrim geciktirir
    end
    
    wire is_mem_op_W = (Res_src_wb == 2'b01) | we_wb_reg;
    
    reg waiting_for_mem; 

    always @(posedge clk) begin
        if (!reset_ni)
            waiting_for_mem <= 1'b0;
        else if (mem_valid)
            // Memory operation completed (pulse arrived): Stop waiting.
            waiting_for_mem <= 1'b0;
        else if (is_mem_op_W)
            // Memory op entered WB stage: Start waiting (until mem_valid pulse).
            waiting_for_mem <= 1'b1; 
    end

    // 4. Global stall signal for Hazard Unit
    assign global_mem_stall = waiting_for_mem;
    
    
    mux_result mux_res(
        .reset_ni(reset_ni),
        .Res_Src(Res_src_wb),
        .ALU_res(ALU_res_wb),
        .read_data(Read_Data_wb),
        .PC_plus4(PC_plus4_wb),
        .PC_target(PC_target_wb),
        .Result(Result)
    ); 
    
    reg [31:0] pc_1, pc_2 , pc_3, pc_4;
    reg [31:0] data_out_instr_1, data_out_instr_2, data_out_instr_3 , data_out_instr_4;
    reg [4:0] addr3_w_1, addr3_w_2, addr3_w_3 ,addr3_w_4;
    
    
    always @(posedge clk) begin
        if(!reset_ni) begin
            pc_1 <= 32'd0;
            pc_2 <= 32'd0;
            pc_3 <= 32'd0;
            pc_4 <= 32'd0;
            
            data_out_instr_1 <= 32'd0;
            data_out_instr_2 <= 32'd0;
            data_out_instr_3 <= 32'd0;
            data_out_instr_4 <= 32'd0;
            
            addr3_w_1 <= 5'd0; // 32'd0 yerine 5'd0
            addr3_w_2 <= 5'd0;
            addr3_w_3 <= 5'd0;
            addr3_w_4 <= 5'd0;
        end else begin
            pc_1 <= PC;
            pc_2 <= pc_1;
            pc_3 <= pc_2;
            pc_4 <= pc_3; 
            
            data_out_instr_1 <= data_out_instr;
            data_out_instr_2 <= data_out_instr_1 ;
            data_out_instr_3 <= data_out_instr_2 ;
            data_out_instr_4 <= data_out_instr_3 ;
            
            // Boru hattý reg'lerindeki data sinyallerini kullan
            addr3_w_1 <= data_out_instr_d[11:7]; // IF/ID çýkýþýndaki rd
            addr3_w_2 <= addr3_ex; // ID/EX çýkýþýndaki rd
            addr3_w_3 <= addr3_mem; // EX/MEM çýkýþýndaki rd
            addr3_w_4 <= addr3_wb; // MEM/WB çýkýþýndaki rd (Zaten WB'ye ulaþan rd)
            
        end 
    end
    
// pipeline valid flags aligned with pipeline registers
reg valid_if;
reg valid_id;
reg valid_ex;
reg valid_mem;
reg valid_wb;

always @(posedge clk or negedge reset_ni) begin
    if (!reset_ni) begin
        valid_if  <= 1'b0;
        valid_id  <= 1'b0;
        valid_ex  <= 1'b0;
        valid_mem <= 1'b0;
        valid_wb  <= 1'b0;
    end else begin
        // IF stage: fetch new instruction only if PC is not stalled
        // assume stallF==1 means "stall", or if your stall convention is opposite, invert accordingly
        // (If your PC module uses en=stallF earlier, adjust condition: use !stallF to allow fetch)
        valid_if <= (stallF) ? valid_if : 1'b1; 
            // Explanation: if fetch is stalled, keep previous valid_if,
            // otherwise a new fetch occurs -> mark as valid.
            // If you prefer: valid_if <= ~stallF; both work but this keeps previous when stall keeps IF valid.

        // ID stage uses stallD (enable on pipe_if_id was stallD in your code)
        // and clear on flushD (pipe_if_id.clr(flushD))
        if (flushD)
            valid_id <= 1'b0;
        else if (stallD)
            valid_id <= valid_id; // hold
        else
            valid_id <= valid_if;

        // EX stage: clear on flushE (pipe_id_ex.clr(flushE))
        // assume there is no dedicated stallE in your current design; if there is, use it similarly
        if (flushE)
            valid_ex <= 1'b0;
        else
            valid_ex <= valid_id;

        // MEM stage: no flush for EX/MEM in your instantiation (clr(0)) -> just shift
        valid_mem <= valid_ex;

        // WB stage:
        valid_wb <= valid_mem;
    end
end

    integer f;
    initial begin
        f = $fopen("rtl.log");
    end
    
    integer i = 0;
      // Talimat deðeri
    localparam NOP_INSTR = 32'h00000013;
    localparam FLUSHED_INSTR = 32'h00000000;
    localparam ZERO_REG = 5'd0; // Register x0

// risc32i_modified.v içinden loglama bloðu
// ----------------------------------------------------

// Loglama için kullanýlan parametreler
// localparam NOP_INSTR = 32'h00000013;
// localparam FLUSHED_INSTR = 32'h00000000;
// localparam ZERO_REG = 5'd0;
// wire is_mem_op_W = (Res_src_wb == 2'b01) | we_wb_reg; 

always @(posedge clk) begin
    i = i + 1;

    if (valid_wb && data_out_instr_4 != FLUSHED_INSTR) begin
        // store (we_wb_reg) ve mem_valid pulse gerekiyorsa
        if (we_wb_reg == 1'b1 && mem_valid == 1'b1) begin
            $fwrite(f, "core   0: 3 0x%08x (0x%08x) mem 0x%08x 0x%08x\n",
                    pc_4, data_out_instr_4, ALU_res_wb, Read_Data_wb);
        end
        // register write (x0 dýþýnda) -> eðer memory-op ise mem_valid==1 bekle (is_mem_op_W)
        else if (reg_write_wb == 1'b1 && addr3_wb != ZERO_REG &&
                 (!is_mem_op_W || (is_mem_op_W && mem_valid == 1'b1))) begin
                 if (addr3_wb < 10) begin
                    $fwrite(f, "core   0: 3 0x%08x (0x%08x) x%1d  0x%08x\n", pc_4, data_out_instr_4, addr3_wb, Result);
                 end else begin
                    $fwrite(f, "core   0: 3 0x%08x (0x%08x) x%d 0x%08x\n", pc_4, data_out_instr_4, addr3_wb, Result);
                 end
        end
        // other instructions (branch/jump/nop vs. mem-op completed)
        else if ((!is_mem_op_W) || (is_mem_op_W && mem_valid == 1'b1)) begin
            $fwrite(f, "core   0: 3 0x%08x (0x%08x)\n",
                    pc_4, data_out_instr_4);
        end
    end

    // $display versiyonu (ayný mantýk)
    if (valid_wb && data_out_instr_4 != FLUSHED_INSTR) begin
        if (reg_write_wb == 1'b1 && addr3_wb != ZERO_REG && mem_valid == 1'b1) begin
            $display("%d 0x%08x (0x%08x) x%2d 0x%08x",
                     i, pc_4, data_out_instr_4, addr3_wb, Result);
        end else if ((!is_mem_op_W) || (is_mem_op_W && mem_valid == 1'b1)) begin
            $display("%d 0x%08x (0x%08x)",
                     i, pc_4, data_out_instr_4);
        end
    end
end


    
endmodule