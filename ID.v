`include "lib/defines.vh"
module ID(
    input wire clk,
    input wire rst,
    // input wire flush,
    input wire [`StallBus-1:0] stall,
    
    output wire stallreq,

    input wire [`IF_TO_ID_WD-1:0] if_to_id_bus,

    input wire [31:0] inst_sram_rdata,

    input wire [`WB_TO_RF_WD-1:0] wb_to_rf_bus,

    output wire [`ID_TO_EX_WD-1:0] id_to_ex_bus,

    output wire [`BR_WD-1:0] br_bus ,
    
    input wire [37:0] wb_to_id,//
    
    input wire [37:0] ex_to_id,//
    
    input wire [37:0] mem_to_id,//
    
    input wire ex_is_load ,
    
    output wire stall_from_id
);

    reg [`IF_TO_ID_WD-1:0] if_to_id_bus_r;
    wire [31:0] inst;
    wire [31:0] id_pc;
    wire ce;

    wire wb_rf_we;
    wire [4:0] wb_rf_waddr;
    wire [31:0] wb_rf_wdata;
    
    wire wb_id_we;
    wire [4:0] wb_id_waddr;
    wire [31:0] wb_id_wdata;
    
    wire mem_id_we;
    wire [4:0] mem_id_waddr;
    wire [31:0] mem_id_wdata;
    
    reg q;
    wire ex_id_we;
    wire [4:0] ex_id_waddr;
    wire [31:0] ex_id_wdata;

    always @ (posedge clk) begin
        if (rst) begin
            if_to_id_bus_r <= `IF_TO_ID_WD'b0;        
        end
        // else if (flush) begin
        //     ic_to_id_bus <= `IC_TO_ID_WD'b0;
        // end
        else if (stall[1]==`Stop && stall[2]==`NoStop) begin
            if_to_id_bus_r <= `IF_TO_ID_WD'b0;
        end
        else if (stall[1]==`NoStop) begin
            if_to_id_bus_r <= if_to_id_bus;
        end
    end
    
    always @(posedge clk) begin
        if (stall[1]==`Stop) begin
            q <= 1'b1;
        end
        else begin
            q <= 1'b0;
        end
    end
    
    assign inst = (q) ?inst: inst_sram_rdata;
    
    //assign inst = inst_sram_rdata;
    assign {
        ce,
        id_pc
    } = if_to_id_bus_r;
    assign {
        wb_rf_we,
        wb_rf_waddr,
        wb_rf_wdata
    } = wb_to_rf_bus;

    assign {
        wb_id_we,
        wb_id_waddr,
        wb_id_wdata
    } = wb_to_id;

    assign {
        mem_id_we,
        mem_id_waddr,
        mem_id_wdata
    } = mem_to_id;

    assign {
        ex_id_we,
        ex_id_waddr,
        ex_id_wdata
    } = ex_to_id;
    
    wire [5:0] opcode;
    wire [4:0] rs,rt,rd,sa;
    wire [5:0] func;
    wire [15:0] imm;
    wire [25:0] instr_index;
    wire [19:0] code;
    wire [4:0] base;
    wire [15:0] offset;
    wire [2:0] sel;

    wire [63:0] op_d, func_d;
    wire [31:0] rs_d, rt_d, rd_d, sa_d;

    wire [2:0] sel_alu_src1;
    wire [3:0] sel_alu_src2;
    wire [11:0] alu_op;

    wire data_ram_en;
    wire [3:0] data_ram_wen;
    wire [3:0] data_ram_readen;
    wire rf_we;
    wire [4:0] rf_waddr;
    wire sel_rf_res;
    wire [2:0] sel_rf_dst;

    wire [31:0] rdata1, rdata2;
    wire [31:0] rdata11, rdata22;
    regfile u_regfile(
    	.clk    (clk    ),
        .raddr1 (rs ),
        .rdata1 (rdata1 ),
        .raddr2 (rt ),
        .rdata2 (rdata2 ),
        .we     (wb_rf_we     ),
        .waddr  (wb_rf_waddr  ),
        .wdata  (wb_rf_wdata  )
    );



    
  
    assign rdata11 = (ex_id_we &(ex_id_waddr==rs))?ex_id_wdata
                   : (mem_id_we &(mem_id_waddr==rs)) ? mem_id_wdata
                   : rdata1;
    assign rdata22 =  (ex_id_we &(ex_id_waddr==rt))?ex_id_wdata
                   : (mem_id_we &(mem_id_waddr==rt)) ? mem_id_wdata
                   : rdata2;
                   
    assign opcode = inst[31:26];
    assign rs = inst[25:21];
    assign rt = inst[20:16];
    assign rd = inst[15:11];
    assign sa = inst[10:6];
    assign func = inst[5:0];
    assign imm = inst[15:0];
    assign instr_index = inst[25:0];
    assign code = inst[25:6];
    assign base = inst[25:21];
    assign offset = inst[15:0];
    assign sel = inst[2:0];

    wire inst_ori, inst_lui, inst_addiu, inst_beq,
    inst_subu,
    inst_jr,
    inst_jal,
    inst_lw,
    inst_or, 
    inst_sll,   
    inst_addu, 
    inst_bne,        
    inst_xor,
    inst_xori,
    inst_nor,
    inst_sw,
    inst_sltu,
    inst_slt,
    inst_slti,
    inst_sltiu,
    inst_j,
    inst_add,
    inst_addi,
    inst_sub,
    inst_and,
    inst_andi,
    inst_sllv,
    inst_sra,
    inst_srav,
    inst_srl,
    inst_srlv,
    inst_bgez,
    inst_bgtz,
    inst_blez,
    inst_bltz,
    inst_bltzal,
    inst_bgezal,inst_jalr,inst_div,inst_divu,
    inst_mflo,
    inst_mfhi,
    inst_mult,inst_multu,inst_mthi,inst_mtlo,inst_lb,
    inst_lbu,
    inst_lh,       
    inst_lhu,      
    inst_sb, 
    inst_lsa,
    inst_sh; 
    wire op_add, op_sub, op_slt, op_sltu;
    wire op_and, op_nor, op_or, op_xor;
    wire op_sll, op_srl, op_sra, op_lui;

    decoder_6_64 u0_decoder_6_64(
    	.in  (opcode  ),
        .out (op_d )
    );

    decoder_6_64 u1_decoder_6_64(
    	.in  (func  ),
        .out (func_d )
    );
    
    decoder_5_32 u0_decoder_5_32(
    	.in  (rs  ),
        .out (rs_d )
    );

    decoder_5_32 u1_decoder_5_32(
    	.in  (rt  ),
        .out (rt_d )
    );

    
    assign inst_ori     = op_d[6'b00_1101];
    assign inst_lui     = op_d[6'b00_1111];
    assign inst_addiu   = op_d[6'b00_1001];
    assign inst_beq     = op_d[6'b00_0100];
    assign inst_subu    = op_d[6'b00_0000] && func_d[6'b10_0011];
    assign inst_jr      = op_d[6'b00_0000] && func_d[6'b00_1000];
    assign inst_jal     = op_d[6'b00_0011];
    assign inst_lw      = op_d[6'b10_0011];
    assign inst_addu    = op_d[6'b00_0000] && func_d[6'b10_0001];
    assign inst_or      = op_d[6'b00_0000] && func_d[6'b10_0101];
    assign inst_sll     = op_d[6'b00_0000] && func_d[6'b00_0000];
    assign inst_bne     = op_d[6'b00_0101];
    assign inst_xor     = op_d[6'b00_0000] && func_d[6'b10_0110];
    assign inst_xori    = op_d[6'b00_1110];
    assign inst_nor     = op_d[6'b00_0000] && func_d[6'b10_0111];
    assign inst_sw      = op_d[6'b10_1011]; 
    assign inst_sltu    = op_d[6'b00_0000] && func_d[6'b10_1011];
    assign inst_slt     = op_d[6'b00_0000] && func_d[6'b10_1010];
    assign inst_slti    = op_d[6'b00_1010];
    assign inst_sltiu   = op_d[6'b00_1011];
    assign inst_j       = op_d[6'b00_0010]; 
    assign inst_add     = op_d[6'b00_0000] && func_d[6'b10_0000];
    assign inst_addi    = op_d[6'b00_1000];
    assign inst_sub     = op_d[6'b00_0000] && func_d[6'b10_0010];
    assign inst_and     = op_d[6'b00_0000] && func_d[6'b10_0100];
    assign inst_andi    = op_d[6'b00_1100];
    assign inst_sllv    = op_d[6'b00_0000] && func_d[6'b00_0100];
    assign inst_sra     = op_d[6'b00_0000] && func_d[6'b00_0011];
    assign inst_srav    = op_d[6'b00_0000] && func_d[6'b00_0111];
    assign inst_srl     = op_d[6'b00_0000] && func_d[6'b00_0010];
    assign inst_srlv    = op_d[6'b00_0000] && func_d[6'b00_0110];
    assign inst_bgez    = op_d[6'b00_0001] && rt_d[5'b00001];
    assign inst_bgtz    = op_d[6'b00_0111] && rt_d[5'b00000];
    assign inst_blez    = op_d[6'b00_0110] && rt_d[5'b00000];
    assign inst_bltz    = op_d[6'b00_0001] && rt_d[5'b00000];
    assign inst_bltzal  = op_d[6'b00_0001] && rt_d[5'b10000];
    assign inst_bgezal  = op_d[6'b00_0001] && rt_d[5'b10001];
    assign inst_jalr    = op_d[6'b00_0000] && func_d[6'b00_1001];
    assign inst_div     = op_d[6'b00_0000] && func_d[6'b01_1010];
    assign inst_divu    = op_d[6'b00_0000] && func_d[6'b01_1011];
    assign inst_mflo    = op_d[6'b00_0000] && func_d[6'b01_0010];
    assign inst_mfhi    = op_d[6'b00_0000] && func_d[6'b01_0000];
    assign inst_mult    = op_d[6'b00_0000] && func_d[6'b01_1000];
    assign inst_multu   = op_d[6'b00_0000] && func_d[6'b01_1001];
    assign inst_mthi    = op_d[6'b00_0000] && func_d[6'b01_0001];
    assign inst_mtlo    = op_d[6'b00_0000] && func_d[6'b01_0011];
    assign inst_lb      = op_d[6'b10_0000];
    assign inst_lbu     = op_d[6'b10_0100];
    assign inst_lh      = op_d[6'b10_0001];
    assign inst_lhu     = op_d[6'b10_0101];
    assign inst_sb      = op_d[6'b10_1000];
    assign inst_sh      = op_d[6'b10_1001];
    assign inst_lsa     = op_d[6'b01_1100] && func_d[6'b11_0111];
    // rs to reg1
    assign sel_alu_src1[0] =inst_sh | inst_sb | inst_lhu | inst_lh | inst_lbu | inst_bgez | inst_srlv | inst_srav | inst_sllv | inst_andi | inst_and | inst_sub | inst_addi | inst_add | inst_sltiu | inst_slti | inst_slt | inst_sltu | inst_sw | inst_nor | inst_xori | inst_xor | inst_ori | inst_addiu | inst_subu | inst_jr | inst_lw | inst_addu | 
                            inst_or   | inst_mflo  |inst_mfhi | inst_lb |inst_lsa;

    // pc to reg1
    assign sel_alu_src1[1] =  inst_jal | inst_bltzal | inst_bgezal |inst_jalr;

    // sa_zero_extend to reg1
    assign sel_alu_src1[2] =inst_srl |inst_sra | inst_sll;

    
    // rt to reg2
    assign sel_alu_src2[0] =inst_lsa|inst_mfhi|inst_mflo | inst_srl | inst_srlv | inst_srav | inst_sra | inst_sllv | inst_and | inst_sub | inst_add | inst_slt | inst_sltu | inst_nor | inst_xor  | inst_subu | inst_addu | inst_or | inst_sll |inst_div | inst_divu;
    
    // imm_sign_extend to reg2
    assign sel_alu_src2[1] =inst_sh | inst_sb | inst_lhu | inst_lh | inst_lbu | inst_addi | inst_sltiu | inst_slti | inst_sw | inst_lui | inst_addiu | inst_lw |inst_lb;

    // 32'b8 to reg2
    assign sel_alu_src2[2] = inst_jal | inst_bltzal | inst_bgezal |inst_jalr;

    // imm_zero_extend to reg2
    assign sel_alu_src2[3] = inst_andi | inst_xori | inst_ori;



    assign op_add =inst_lsa|inst_sh | inst_sb | inst_lhu | inst_lh | inst_lbu |  inst_lb | inst_addi | inst_add | inst_addiu | inst_lw | inst_addu | inst_jal | inst_sw | inst_bltzal |inst_bgezal|inst_jalr;
    assign op_sub =inst_sub | inst_subu;
    assign op_slt = inst_slt | inst_slti; //	&÷Ô
    assign op_sltu = inst_sltu|inst_sltiu;  //à&÷Ô
    assign op_and = inst_andi | inst_and | inst_mflo |inst_mfhi;
    assign op_nor = inst_nor;
    assign op_or = inst_ori | inst_or;
    assign op_xor = inst_xori |inst_xor;
    assign op_sll = inst_sllv | inst_sll;//;æû
    assign op_srl = inst_srl | inst_srlv;//;óû
    assign op_sra = inst_srav | inst_sra;///óû
    assign op_lui = inst_lui;

    assign alu_op = {op_add, op_sub, op_slt, op_sltu,
                     op_and, op_nor, op_or, op_xor,
                     op_sll, op_srl, op_sra, op_lui};
    // mem load and store enable
    assign data_ram_en =inst_sh | inst_sb | inst_lhu | inst_lh | inst_lbu | inst_lw | inst_sw | inst_lb;

    // mem write enable
    assign data_ram_wen = inst_sw ? 4'b1111 : 4'b0000;

    //mem read enable
    assign data_ram_readen =  inst_lw  ? 4'b1111 
                             :inst_lb  ? 4'b0001 
                             :inst_lbu ? 4'b0010
                             :inst_lh  ? 4'b0011
                             :inst_lhu ? 4'b0100
                             :inst_sb  ? 4'b0101
                             :inst_sh  ? 4'b0111
                             :4'b0000;


    // regfile sotre enable
    assign rf_we =inst_lsa|inst_lhu | inst_lh | inst_lbu | inst_lb| inst_mfhi | inst_mflo | inst_jalr |inst_bgezal | inst_bltzal|inst_srl | inst_srlv | inst_srav | inst_sra | inst_sllv | inst_andi | inst_and | inst_sub | inst_addi | inst_add | inst_sltiu | inst_slti | inst_slt | inst_sltu | inst_nor |inst_xori | inst_xor | inst_sll | inst_ori | inst_lui | inst_addiu | inst_subu | inst_jal | inst_lw | inst_addu | inst_or;



    // store in [rd]
    assign sel_rf_dst[0] = inst_lsa|inst_mfhi | inst_mflo | inst_jalr |inst_srl | inst_srlv | inst_srav | inst_sra | inst_sllv | inst_and | inst_sub | inst_add | inst_slt | inst_sltu | inst_nor | inst_xor | inst_subu | inst_addu | inst_or | inst_sll;
    // store in [rt] 
    assign sel_rf_dst[1] = inst_lhu | inst_lh | inst_lbu | inst_lb |inst_andi | inst_addi | inst_sltiu | inst_slti | inst_xori | inst_ori | inst_lui | inst_addiu | inst_lw;
    // store in [31]
    assign sel_rf_dst[2] = inst_jal | inst_bltzal | inst_bgezal;

    // sel for regfile address
    assign rf_waddr = {5{sel_rf_dst[0]}} & rd 
                    | {5{sel_rf_dst[1]}} & rt
                    | {5{sel_rf_dst[2]}} & 32'd31;
    
    // 0 from alu_res ; 1 from ld_res
    assign sel_rf_res = 1'b0; 


    wire [31:0] rdata111;
    assign rdata111 = (inst_lsa &inst[7:6]==2'b11) ? {rdata11[27:0] ,4'b0}
                    :(inst_lsa & inst[7:6]==2'b10) ? {rdata11[28:0] ,3'b0}
                    :(inst_lsa & inst[7:6]==2'b01) ? {rdata11[29:0] ,2'b0}
                    :(inst_lsa & inst[7:6]==2'b00) ? {rdata11[30:0] ,1'b0}
                    :rdata11;

    assign id_to_ex_bus = {
        id_pc,          // 158:127
        inst,           // 126:95
        alu_op,         // 94:83
        sel_alu_src1,   // 82:80
        sel_alu_src2,   // 79:76
        data_ram_en,    // 75
        data_ram_wen,   // 74:71
        rf_we,          // 70
        rf_waddr,       // 69:65
        sel_rf_res,     // 64
        rdata111,         // 63:32
        rdata22         // 31:0
    };


    wire br_e;
    wire [31:0] br_addr;
    wire rs_eq_rt;
    wire rs_ge_z;
    wire rs_gt_z;
    wire rs_le_z;
    wire rs_lt_z;
    wire [31:0] pc_plus_4;
    wire br_e;
    wire [31:0] br_addr;
    wire rs_eq_rt;
    wire rs_ge_z;
    wire rs_gt_z;
    wire rs_le_z;
    wire rs_lt_z;
    wire [31:0] pc_plus_4;
    assign pc_plus_4 = id_pc + 32'h4;
    assign rs_ge_z  = (rdata11[31] == 1'b0); //
    assign rs_gt_z  = (rdata11[31] == 1'b0 & rdata11 != 32'b0  );  //
    assign rs_le_z  = (rdata11[31] == 1'b1 | rdata11 == 32'b0  );  //
    assign rs_lt_z  = (rdata11[31] == 1'b1);  //
    assign rs_eq_rt = (rdata11 == rdata22);
    
    assign br_e =  inst_jalr | (inst_bgezal & rs_ge_z ) | ( inst_bltzal & rs_lt_z) | (inst_bgtz & rs_gt_z  ) | (inst_bltz & rs_lt_z) | (inst_blez & rs_le_z) | (inst_bgez & rs_ge_z ) | (inst_beq & rs_eq_rt) | inst_jr | inst_jal | (inst_bne & !rs_eq_rt) | inst_j ;
    assign br_addr = inst_beq ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}) 
                    :(inst_jr |inst_jalr)  ? (rdata11)  
                    : inst_jal ? ({pc_plus_4[31:28],inst[25:0],2'b0}) 
                    : inst_j ? ({pc_plus_4[31:28],inst[25:0],2'b0}) 
                    :(inst_bgezal|inst_bltzal |inst_blez | inst_bltz |inst_bgez |inst_bgtz ) ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b00})
                    :inst_bne ? (pc_plus_4 + {{14{inst[15]}},{inst[15:0],2'b00}}) : 32'b0;

    assign br_bus = {
        br_e,
        br_addr
    };
    assign stallreq_from_id = (ex_is_load  & ex_id_waddr == rs) | (ex_is_load & ex_id_waddr == rt) ;


endmodule