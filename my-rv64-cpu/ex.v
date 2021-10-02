`include "defines.v"
`include "csr.v"
module ex (
    input wire clk,
    input wire rst,
    input wire [`InstAddrBus]pc_i,
    //input ports
    input wire [7:0] inst_type_i,
    input wire [7:0] inst_opcode_i,
    input wire [`RegBus] op1_i,
    input wire [`RegBus] op2_i,
    input wire rd_ena_i,
    input wire [`RegAddrBus] rd_addr_i,

    input wire [2 :0] ls_sel_i,
    input wire [11:0] addr_offset_i,
    

    //output ports
    output wire [7:0] inst_type_o,
    output wire rd_ena_o,
    output wire [`RegBus] rd_data_o,
    output wire [`RegAddrBus] rd_addr_o,

    output wire [2 :0] ls_sel_o,
    output wire [`DataAddrBus] ls_addr_o,

    output wire  ex_flush,
    output wire branch_pc_ena,
    output wire [`InstAddrBus] branch_pc,

    // signals about ex_stall_req
    input  wire if_stall_req,
    output wire ex_stall_req,

    // interrupt signal
    input  wire timer_intr,
    input  wire ex_stall,

    //for difftest
    output wire tmr_trap_ena_o 
    );

    reg [`RegBus] exe_res;


    //********** execute the INST_SLTI INST_SLT **********
    wire [`RegBus] op2_i_mux = ~op2_i + 64'd1; // one's complement of op2_i
    wire [`RegBus] op1_sub_op2 = op1_i + op2_i_mux;


    //********** execute ADDXX **********
    wire [`RegBus] op1_add_op2   = op1_i +op2_i;
    wire [`RegBus] op1_addw_op2 = {{32{op1_add_op2[31]}},op1_add_op2[31:0]};

    //********** execute SLT SLTI **********
    //op1_ls_op2: op1 is less than op2 (signed)
    wire op1_ls_op2 = (op1_i[63] && ~op2_i[63])||(~op1_i[63] && ~op2_i[63] && op1_sub_op2[63])
                      ||(op1_i[63] && op2_i[63] && op1_sub_op2[63]);
    
    //********** execute SRAI SRA **********
    wire [`RegBus] shift_res = ( { 64{op1_i[63]} }<<(7'd64-{1'b0,op2_i[5:0]}) )|( op1_i>>op2_i[5:0] );
    
    //********** execute SLLW SLLIW **********
    wire [31:0]    op1_sllw_op2 = op1_i[31:0] << op2_i[4:0];
    wire [`RegBus] sllw_res     = {{32{op1_sllw_op2[31]}},op1_sllw_op2};

    //********** execute SRLIW SRLW **********
    wire [31:0]    op1_srlw_op2 = op1_i[31:0] >> op2_i[4:0];
    wire [`RegBus] srlw_res     = {{32{op1_srlw_op2[31]}},op1_srlw_op2};

    //********** execute SRAIW SRAW **********
    wire [31:0]    op1_sraw_op2 = ( {32{op1_i[31]}}<<(6'd32-{1'b0,op2_i[4:0]}) )|( op1_i[31:0]>>op2_i[4:0] );
    wire [`RegBus] sraw_res     = {{32{op1_sraw_op2[31]}},op1_sraw_op2};

    //********** execute SUBW       **********
    wire [31:0]    op1_subw_op2 = op1_i[31:0] - op2_i[31:0];
    wire [`RegBus] subw_res     = {{32{op1_subw_op2[31]}},op1_subw_op2};

    assign rd_data_o    =  inst_type_i[0] ? op2_i :(inst_type_i[7] ? read_csr_data : exe_res);
    // when trap don't execute the instruction
    assign inst_type_o  =  inst_type_i & {8{~tmr_trap_ena}};
    assign rd_ena_o     =  rd_ena_i    & (~tmr_trap_ena); 
    assign rd_addr_o    =  rd_addr_i;

    //load and store info
    assign ls_addr_o    = (inst_type_i[1]|inst_type_i[0]) ? (op1_i + {{52{addr_offset_i[11]}},addr_offset_i}) : `ZeroWord;
    assign ls_sel_o     = ls_sel_i;

    //lui and auipc offset
    wire [`RegBus] upper_imm = {{32{op2_i[19]}},op2_i[19:0],12'd0};

    always @(*) begin
        if(rst == `RstEnable) begin exe_res = `ZeroWord; end
        else begin
            case (inst_opcode_i)
                `INST_ADDI, `INST_ADD:  begin exe_res = op1_add_op2;              end 
                `INST_SLTI, `INST_SLT:  begin exe_res = {63'd0,op1_ls_op2};       end
                `INST_SLTIU,`INST_SLTU: begin exe_res = {63'd0,(op1_i < op2_i)};  end
                `INST_XORI, `INST_XOR:  begin exe_res = op1_i  ^  op2_i;          end
                `INST_ORI , `INST_OR :  begin exe_res = op1_i  |  op2_i;          end
                `INST_ANDI, `INST_AND:  begin exe_res = op1_i  &  op2_i;          end
                `INST_SLLI, `INST_SLL:  begin exe_res = op1_i <<  op2_i[5:0];     end
                `INST_SRLI, `INST_SRL:  begin exe_res = op1_i >>  op2_i[5:0];     end
                `INST_SRAI, `INST_SRA:  begin exe_res = shift_res;                end
                `INST_SUB            :  begin exe_res = op1_sub_op2;              end
                `INST_LUI,`INST_AUIPC:  begin exe_res = op1_i + upper_imm;        end
                `INST_JAL,`INST_JALR:   begin exe_res = op2_i + 64'd4;            end
                `INST_ADDIW,`INST_ADDW: begin exe_res = op1_addw_op2;             end
                `INST_SLLIW,`INST_SLLW: begin exe_res = sllw_res;                 end
                `INST_SRLIW,`INST_SRLW: begin exe_res = srlw_res;                 end                     
                `INST_SRAIW,`INST_SRAW: begin exe_res = sraw_res;                 end
                `INST_SUBW            : begin exe_res = subw_res;                 end
                default               : begin exe_res = `ZeroWord;                end
            endcase
        end
    end


    //Conditional Branch
    reg ex_flush_branch;
    always @(*) begin
        if(~inst_type_i[2]) begin ex_flush_branch = `FlushDisable;  end
        else begin
            case (inst_opcode_i)
                `INST_BEQ  : begin ex_flush_branch = (op1_i == op2_i)  ? `FlushDisable:`FlushEnable; end 
                `INST_BNE  : begin ex_flush_branch = (op1_i != op2_i)  ? `FlushDisable:`FlushEnable; end 
                `INST_BLTU : begin ex_flush_branch = (op1_i <  op2_i)  ? `FlushDisable:`FlushEnable; end 
                `INST_BGEU : begin ex_flush_branch = (op1_i >=  op2_i) ? `FlushDisable:`FlushEnable; end 
                `INST_BLT  : begin ex_flush_branch = (  op1_ls_op2  )  ? `FlushDisable:`FlushEnable; end 
                `INST_BGE  : begin ex_flush_branch = ( ~op1_ls_op2  )  ? `FlushDisable:`FlushEnable; end 
                default:     begin ex_flush_branch = `FlushDisable;  end
            endcase
        end        
    end


    assign branch_pc_ena = (ex_flush_branch == `FlushEnable) | trap_ena | cmt_mret_ena;
    assign branch_pc     =    (trap_ena  | cmt_mret_ena) ? read_csr_data :
                       (ex_flush_branch == `FlushEnable) ? pc_i+64'd4    :
                                                               `ZeroWord ;

    assign ex_stall_req = branch_pc_ena && if_stall_req;
    assign ex_flush     = branch_pc_ena;

    // CSR Instructions and Priviledge Instructions

    wire tmr_trap_ena; 
    reg ecall_trap_ena,cmt_mret_ena;
    reg  csr_wr_en, csr_rd_en;
    wire [11:0] csr_idx = inst_type_i[7] ? op2_i[11:0] : 12'd0;
    wire [`RegBus] read_csr_data ;
    reg  [`RegBus] wbck_csr_data ;
    reg  [`RegBus] trap_mcause_value;

    wire trap_ena = ecall_trap_ena | (tmr_trap_ena);
    
    // for difftest
    assign tmr_trap_ena_o = tmr_trap_ena;
    /////////////////////////////////////

    // Mask Set And Clear Result
    wire [`RegBus] mask_set_res   = read_csr_data | op1_i ;
    wire [`RegBus] mask_clear_res = read_csr_data & (~op1_i);
    csr csr0(
        .clk(clk),
        .rst(rst),
        .pc_i(pc_i),

        .csr_wr_en(csr_wr_en ),   
        .csr_rd_en(csr_rd_en ),
        .csr_idx(csr_idx),

        .cmt_mret_ena(cmt_mret_ena ),
        .ecall_trap_ena(ecall_trap_ena ),
        .trap_mcause_value(trap_mcause_value),

        .tmr_intr_ena(timer_intr),
        .tmr_trap_ena(tmr_trap_ena),

        .read_csr_data(read_csr_data),
        .wbck_csr_data(wbck_csr_data),
        .ex_stall(ex_stall)
    );

    always @(*) begin
        if(~inst_type_i[7]) begin
            csr_wr_en         = `WriteDisable;
            csr_rd_en         = `ReadDisable ;
            cmt_mret_ena      = 1'b0         ;
            ecall_trap_ena    = 1'b0         ;
            wbck_csr_data     = `ZeroWord    ;
            trap_mcause_value = `ZeroWord    ;

        end
        else begin
            csr_wr_en         = `WriteDisable;
            csr_rd_en         = `ReadDisable ;
            cmt_mret_ena      = 1'b0         ;
            ecall_trap_ena    = 1'b0         ;
            wbck_csr_data     = `ZeroWord    ;
            trap_mcause_value = `ZeroWord    ;
            case (inst_opcode_i)
                `INST_CSRRW,`INST_CSRRWI: begin
                    csr_wr_en     = `WriteEnable;
                    csr_rd_en     = (rd_addr_o == 5'b0) ? `ReadDisable : `ReadEnable;
                    wbck_csr_data = op1_i;
                end
                `INST_CSRRS,`INST_CSRRSI: begin
                    csr_wr_en     = (op1_i == `ZeroWord) ? `WriteDisable:`WriteEnable;
                    csr_rd_en     = `ReadEnable;
                    wbck_csr_data = mask_set_res;
                end
                `INST_CSRRC,`INST_CSRRCI: begin
                    csr_wr_en     = (op1_i == `ZeroWord) ? `WriteDisable:`WriteEnable;
                    csr_rd_en     = `ReadEnable;
                    wbck_csr_data = mask_clear_res;
                end
                `INST_ECALL:              begin
                    ecall_trap_ena    = 1'b1;
                    wbck_csr_data     = pc_i; //MEPC
                    trap_mcause_value = 64'd11;
                end
                `INST_MRET:              begin
                    cmt_mret_ena  = 1'b1;
                end
                default: begin
                    csr_wr_en         = `WriteDisable;
                    csr_rd_en         = `ReadDisable ;
                    cmt_mret_ena      = 1'b0         ;
                    ecall_trap_ena    = 1'b0         ;
                end
            endcase
        end
        if(tmr_trap_ena) begin 
            csr_wr_en         = `WriteDisable;
            csr_rd_en         = `ReadDisable ;
            cmt_mret_ena      = 1'b0         ;
            ecall_trap_ena    = 1'b0         ;
            wbck_csr_data     = pc_i         ;
            trap_mcause_value = 64'h8000_0000_0000_0007;
        end
    end

endmodule


