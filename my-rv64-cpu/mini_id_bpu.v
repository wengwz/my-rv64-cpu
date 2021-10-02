`include "defines.v"

module mini_id_bpu (
    input wire rst,

    input wire [`InstBus]     inst_i,
    input wire [`InstAddrBus] pc_i,

    //x1 data
    output wire x1_read_ena,
    input  wire [`RegBus]     x1_data,

    // predict pc 
    output wire [`InstAddrBus] prdt_pc_o

    );

    wire [`InstAddrBus] prdt_pc_add_op1, prdt_pc_add_op2, prdt_pc_temp;

    wire [6 :0] opcode  = inst_i[6:0];
    //J-type imm
    wire [20:1] j_imm;
    assign {j_imm[20],j_imm[10:1],j_imm[11],j_imm[19:12]} = inst_i[31:12];

    //I-type imm
    wire [11:0] i_imm   = inst_i[31:20];

    //B-type imm
    wire [12:1] b_imm;
    assign {b_imm[12],b_imm[10:5],b_imm[4:1],b_imm[11]} = {inst_i[31:25],inst_i[11:7]};


    //decode
    wire inst_jal,inst_jalr,inst_bxx;
    assign inst_jal     = (opcode[6:2] == `JUMP_JAL) && (opcode[1:0] == 2'b11);
    assign inst_jalr    = (opcode[6:2] == `JUMP_JALR)&& (opcode[1:0] == 2'b11);
    assign inst_bxx     = (opcode[6:2] == `BRANCH) && (opcode[1:0] == 2'b11);

    assign x1_read_ena  = (rst == `RstEnable) ? 0 : inst_jalr;

    //generate prdt_pc_add_opx
    assign prdt_pc_add_op1 = inst_jalr ? x1_data : pc_i;

    assign prdt_pc_add_op2 = inst_jal ? {{44{j_imm[20]}},j_imm[20:1]<<1}:
                             inst_bxx ? {{52{b_imm[12]}},b_imm[12:1]<<1}:
                            inst_jalr ?    {{52{i_imm[11]}},i_imm[11:0]}:
                                                                   64'd4;

    assign prdt_pc_temp = prdt_pc_add_op1 + prdt_pc_add_op2;
    assign prdt_pc_o    = (rst == `RstEnable)? `ZeroWord:(inst_jalr ? {prdt_pc_temp[63:1],1'b0}: prdt_pc_temp);

endmodule


