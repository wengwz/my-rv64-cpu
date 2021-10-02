`include "defines.v"

module id (
    input wire rst,
    input wire [`InstBus] inst_i,
    input wire [`InstAddrBus] pc_i,

    // fetch data from regfile
    input wire [`RegBus] op1_data_i,
    input wire [`RegBus] op2_data_i,
    output wire [`RegAddrBus] op1_addr_o,
    output wire [`RegAddrBus] op2_addr_o,
    output wire op1_read_o,
    output wire op2_read_o,

    //signals from ex module
    input wire [`RegBus] ex_rd_data,
    input wire [`RegAddrBus] ex_rd_addr,
    input wire ex_rd_ena,
    input wire [7:0]ex_inst_type, // load related data hazard

    //signals from mem module
    input wire [`RegBus] mem_rd_data,
    input wire [`RegAddrBus] mem_rd_addr,
    input wire mem_rd_ena,
    //signals from regfile
    input wire wb_rd_ena,
    input wire [`RegAddrBus] wb_rd_addr,
    
    //signal to pipeline_ctrl
    output wire id_stall_req,
    input wire if_stall_req,

    //output to id_exe
    output wire [7:0] inst_type,
    output wire [7:0] inst_opcode,
    output reg [`RegBus] op1_o,
    output reg [`RegBus] op2_o,
    output wire rd_w_ena,
    output wire [`RegAddrBus] rd_w_addr,
    output wire [`InstAddrBus] pc_o,
   
    output wire [11:0] store_addr_offset,
    output wire [2 :0] mem_op_sel,


    //output to pc and if_id(branch instruction)
    output wire jalr_pc_ena,
    output wire [`InstAddrBus]jalr_pc,
    output wire id_flush
    );

    //I-type
    wire [6:0]   opcode;
    wire [4:0]   rd;
    wire [2:0]   funct3;
    wire [4:0]   rs1;
    wire [11:0]  imm;
    assign opcode   = inst_i[6:0];
    assign rd       = inst_i[11:7];
    assign funct3   = inst_i[14:12];
    assign rs1      = inst_i[19:15];
    assign imm      = inst_i[31:20];

    // R-type addition
    wire [6:0]   funct7;
    wire [4:0]   rs2;
    assign funct7   = inst_i[31:25];
    assign rs2      = inst_i[24:20];
    // U-type addition
    wire [19:0]  u_imm;
    assign u_imm    = inst_i[31:12];

    // J-type addition
    //wire [20:1] j_imm;
    //assign {j_imm[20],j_imm[10:1],j_imm[11],j_imm[19:12]} = inst_i[31:12];

    // B-type addition
    //wire [12:1] b_imm;
    //assign {b_imm[12],b_imm[10:5],b_imm[4:1],b_imm[11]} = {inst_i[31:25],inst_i[11:7]};

    // S-type addition
    wire [11:0] s_imm;
    assign s_imm = {inst_i[31:25], inst_i[11:7]};


    //*************** decode opcode ***************
    assign inst_type[7]   = (rst == `RstEnable) ? 0:(opcode[6:2] == `SYSTEM);
    assign inst_type[6]   = (rst == `RstEnable) ? 0:(opcode[6:2] == `INT_REG_REG_W);
    assign inst_type[5]   = (rst == `RstEnable) ? 0:(opcode[6:2] == `INT_REG_IMM_W); 
    assign inst_type[4]   = (rst == `RstEnable) ? 0:(opcode[6:2] == `INT_REG_IMM); 
    assign inst_type[3]   = (rst == `RstEnable) ? 0:(opcode[6:2] == `INT_REG_REG);
    assign inst_type[2]   = (rst == `RstEnable) ? 0:(opcode[6:2] == `BRANCH);
    assign inst_type[1]   = (rst == `RstEnable) ? 0:(opcode[6:2] == `LOAD) && (opcode[1:0]==2'b11);
    assign inst_type[0]   = (rst == `RstEnable) ? 0:(opcode[6:2] == `STORE);

    wire inst_lui         = (rst == `RstEnable) ? 0:(opcode[6:2] == `INT_LUI);
    wire inst_auipc       = (rst == `RstEnable) ? 0:(opcode[6:2] == `INT_AUIPC);
    wire inst_jal         = (rst == `RstEnable) ? 0:(opcode[6:2] == `JUMP_JAL);
    wire inst_jalr        = (rst == `RstEnable) ? 0:(opcode[6:2] == `JUMP_JALR);
    wire inst_jump        = inst_jal|inst_jalr;

    //Integer Computational Instructions
    wire inst_addi  = inst_type[4] & ~funct3[2] & ~funct3[1] & ~funct3[0];
    wire inst_slti  = inst_type[4] & ~funct3[2] &  funct3[1] & ~funct3[0];
    wire inst_sltiu = inst_type[4] & ~funct3[2] &  funct3[1] &  funct3[0];
    wire inst_xori  = inst_type[4] &  funct3[2] & ~funct3[1] & ~funct3[0];
    wire inst_ori   = inst_type[4] &  funct3[2] &  funct3[1] & ~funct3[0];
    wire inst_andi  = inst_type[4] &  funct3[2] &  funct3[1] &  funct3[0];
    wire inst_slli  = inst_type[4] & ~funct3[2] & ~funct3[1] &  funct3[0];
    wire inst_srli  = inst_type[4] &  funct3[2] & ~funct3[1] &  funct3[0] & ~imm[10];
    wire inst_srai  = inst_type[4] &  funct3[2] & ~funct3[1] &  funct3[0] &  imm[10];
   
    wire inst_addiw = inst_type[5] & ~funct3[2] & ~funct3[1] & ~funct3[0];
    wire inst_slliw = inst_type[5] & ~funct3[2] & ~funct3[1] &  funct3[0];
    wire inst_srliw = inst_type[5] &  funct3[2] & ~funct3[1] &  funct3[0] & ~imm[10];
    wire inst_sraiw = inst_type[5] &  funct3[2] & ~funct3[1] &  funct3[0] &  imm[10];

    wire inst_add   = inst_type[3]  & ~funct3[2] & ~funct3[1] & ~funct3[0] & ~funct7[5];
    wire inst_sub   = inst_type[3]  & ~funct3[2] & ~funct3[1] & ~funct3[0] &  funct7[5];
    wire inst_sll   = inst_type[3]  & ~funct3[2] & ~funct3[1] &  funct3[0] ;
    wire inst_slt   = inst_type[3]  & ~funct3[2] &  funct3[1] & ~funct3[0] ;
    wire inst_sltu  = inst_type[3]  & ~funct3[2] &  funct3[1] &  funct3[0] ;
    wire inst_xor   = inst_type[3]  &  funct3[2] & ~funct3[1] & ~funct3[0] ;
    wire inst_srl   = inst_type[3]  &  funct3[2] & ~funct3[1] &  funct3[0] & ~funct7[5];
    wire inst_sra   = inst_type[3]  &  funct3[2] & ~funct3[1] &  funct3[0] &  funct7[5];
    wire inst_or    = inst_type[3]  &  funct3[2] &  funct3[1] & ~funct3[0] ;
    wire inst_and   = inst_type[3]  &  funct3[2] &  funct3[1] &  funct3[0] ;
  
    wire inst_addw = inst_type[6] & ~funct3[2] & ~funct3[1] & ~funct3[0] & ~imm[10];
    wire inst_subw = inst_type[6] & ~funct3[2] & ~funct3[1] & ~funct3[0] &  imm[10];
    wire inst_sllw = inst_type[6] & ~funct3[2] & ~funct3[1] &  funct3[0];
    wire inst_srlw = inst_type[6] &  funct3[2] & ~funct3[1] &  funct3[0] & ~imm[10];
    wire inst_sraw = inst_type[6] &  funct3[2] & ~funct3[1] &  funct3[0] &  imm[10];


    // Branch Instructions 
    wire inst_beq   = inst_type[2]  & ~funct3[2] & ~funct3[1] & ~funct3[0] ;
    wire inst_bne   = inst_type[2]  & ~funct3[2] & ~funct3[1] &  funct3[0] ;
    wire inst_blt   = inst_type[2]  &  funct3[2] & ~funct3[1] & ~funct3[0] ;
    wire inst_bge   = inst_type[2]  &  funct3[2] & ~funct3[1] &  funct3[0] ;
    wire inst_bltu  = inst_type[2]  &  funct3[2] &  funct3[1] & ~funct3[0] ;
    wire inst_bgeu  = inst_type[2]  &  funct3[2] &  funct3[1] &  funct3[0] ;

    // CSR Instructions
    wire inst_csrrw = inst_type[7]  & ~funct3[2] & ~funct3[1] &  funct3[0] ;
    wire inst_csrrs = inst_type[7]  & ~funct3[2] &  funct3[1] & ~funct3[0] ;
    wire inst_csrrc = inst_type[7]  & ~funct3[2] &  funct3[1] &  funct3[0] ;
    wire inst_csrrwi= inst_type[7]  &  funct3[2] & ~funct3[1] &  funct3[0] ;
    wire inst_csrrsi= inst_type[7]  &  funct3[2] &  funct3[1] & ~funct3[0] ;
    wire inst_csrrci= inst_type[7]  &  funct3[2] &  funct3[1] &  funct3[0] ;

    wire inst_csr_rs1 = inst_csrrw | inst_csrrs | inst_csrrc;
    wire inst_csr_imm = inst_csrrwi | inst_csrrsi |inst_csrrci;

    // Privileged Instructions
    wire inst_ecall   = inst_type[7]  & ~funct3[2] & ~funct3[1] & ~funct3[0] && (imm == 12'd0);
    wire inst_mret    = inst_type[7]  & ~funct3[2] & ~funct3[1] & ~funct3[0] && (funct7 == 7'b0011000);

    
    //specify the instruction
    assign inst_opcode[0] = (  rst == 1'b1 ) ? 0 : inst_csrrc |inst_beq  |inst_addi | inst_srai|inst_slt |inst_sra|inst_auipc|inst_slliw|inst_subw;
    assign inst_opcode[1] = (  rst == 1'b1 ) ? 0 : inst_csrrwi|inst_bne  |inst_slti | inst_srai|inst_sltu|inst_or |inst_jal  |inst_sraiw|inst_sllw;
    assign inst_opcode[2] = (  rst == 1'b1 ) ? 0 : inst_csrrsi|inst_blt  |inst_sltiu| inst_add |inst_slt |inst_and|inst_jalr |inst_sraiw|inst_srlw;
    assign inst_opcode[3] = (  rst == 1'b1 ) ? 0 : inst_csrrci|inst_bge  |inst_xori | inst_add |inst_sltu|inst_lui|inst_addiw|inst_slliw|inst_sraw;
    assign inst_opcode[4] = (  rst == 1'b1 ) ? 0 : inst_ecall |inst_bltu |inst_ori  | inst_sub |inst_xor |inst_sra|inst_addiw|inst_srliw|inst_sllw;
    assign inst_opcode[5] = (  rst == 1'b1 ) ? 0 : inst_mret  |inst_bgeu |inst_andi | inst_sub |inst_srl |inst_or |inst_jalr |inst_addw |inst_subw;
    assign inst_opcode[6] = (  rst == 1'b1 ) ? 0 :            |inst_csrrw|inst_slli | inst_sll |inst_xor |inst_and|inst_jal  |inst_addw |inst_sraw;
    assign inst_opcode[7] = (  rst == 1'b1 ) ? 0 :            |inst_csrrs|inst_srli | inst_sll |inst_srl |inst_lui|inst_auipc|inst_srliw|inst_srlw;

    //output signal: 
    wire   op1_load_relate,op2_load_relate;
    assign op1_load_relate = (rst == `RstEnable) ? 0 : op1_read_o && (ex_inst_type == 8'b0000_0010) && (op1_addr_o == ex_rd_addr);
    assign op2_load_relate = (rst == `RstEnable) ? 0 : op2_read_o && (ex_inst_type == 8'b0000_0010) && (op2_addr_o == ex_rd_addr);
    assign id_stall_req    = (rst == `RstEnable) ? 0 : op1_load_relate | op2_load_relate | (id_flush && if_stall_req);

    assign pc_o = (rst == `RstEnable) ? `ZeroWord : pc_i;

    assign op1_read_o = 1'b0 | inst_type[6]|inst_type[5]|inst_type[4]|inst_type[3]|inst_jalr|inst_type[2]|inst_type[1]|inst_type[0]|inst_csr_rs1;
    assign op1_addr_o = op1_read_o ? rs1 : 5'd0;

    assign op2_read_o = 1'b0 | inst_type[3] | inst_type[2] | inst_type[0]|inst_type[6];
    assign op2_addr_o = op2_read_o ? rs2 : 0;

    assign rd_w_ena   = (rd != 5'd0)&&(inst_type[6]|inst_type[5]|inst_type[4] |inst_type[3]|inst_lui|inst_auipc|inst_jump|inst_type[1]|inst_type[7]);
    assign rd_w_addr  = rd_w_ena   ? rd  : 0;

    assign store_addr_offset = inst_type[1] ?   imm:
                               inst_type[0] ? s_imm:
                                              12'd0;
    
    assign mem_op_sel = (rst == `RstEnable) ? 3'b000 : funct3;


    //***** check ex,mem and wb to solve the data hazard in pipeline ******
    wire ex_op1,mem_op1;
    assign ex_op1  =  (ex_rd_addr == op1_addr_o)  && ex_rd_ena;
    assign mem_op1 =  (mem_rd_addr == op1_addr_o) && mem_rd_ena;

    always @(*) begin
        if(rst == `RstEnable ) begin op1_o = `ZeroWord;    end
        else if (op1_read_o) 
        begin 
            if(ex_op1)       begin op1_o = ex_rd_data ;  end
            else if(mem_op1) begin op1_o = mem_rd_data;  end
            else             begin op1_o = op1_data_i ;  end
        end
        else if(inst_auipc|inst_jal) begin op1_o = pc_i;             end
        else if(inst_csr_imm)        begin op1_o = {{59{1'b0}},rs1}; end
        else                         begin op1_o = `ZeroWord;        end
    end


    wire ex_op2, mem_op2;
    assign ex_op2  = (ex_rd_addr  == op2_addr_o)  &&  ex_rd_ena;
    assign mem_op2 = (mem_rd_addr == op2_addr_o) && mem_rd_ena;
    always @(*) begin
        if(rst == `RstEnable) begin op2_o = `ZeroWord; end
        else if(op2_read_o)
        begin 
            if      (ex_op2)  begin op2_o = ex_rd_data ;  end
            else if(mem_op2)  begin op2_o = mem_rd_data;  end
            else              begin op2_o = op2_data_i;   end
        end
        else if (inst_type[4]|inst_type[5]|inst_type[7]) begin op2_o = {{52{imm[11]}},imm};    end
        else if (inst_lui|inst_auipc)                    begin op2_o = {{44{u_imm[19]}},u_imm};end
        else if (inst_jump)                              begin op2_o = pc_i;                   end
        else                                             begin op2_o = `ZeroWord;              end
    end



    //jalr: signals to pc and if_id 
    wire wb_op1;
    assign wb_op1 = (wb_rd_addr == op1_addr_o) && wb_rd_ena;

    wire [`InstAddrBus] jalr_pc_temp = {{52{imm[11]}},imm}+op1_o;
    wire   predict_success = ~ex_op1 & ~mem_op1 & ~wb_op1 & (op1_addr_o == 5'd1);

    assign jalr_pc_ena = (rst == `RstEnable) ? 0 : inst_jalr && ~predict_success;
    assign jalr_pc     = inst_jalr ? {jalr_pc_temp[63:1], 1'b0 & jalr_pc_temp[0]} : `ZeroWord;

    assign id_flush = (rst == `RstEnable) ? `FlushDisable : 
                              jalr_pc_ena ?  `FlushEnable :
                                             `FlushDisable;

endmodule





