`include "defines.v"
`include "regfile.v"
`include "if_id.v"
`include "pc.v"
`include "id.v"
`include "id_ex.v"
`include "ex.v"
`include "ex_mem.v"
`include "mem.v"
`include "mem_wb.v"
`include "mini_id_bpu.v"
`include "pipeline_ctrl.v"

module rvcpu (
    input wire                 clk,
    input wire                 rst,
    
    // instruction bus
    output wire [`InstAddrBus] inst_addr,
    output wire                inst_ena,

    output wire                inst_ready,
    input wire [`InstBus]      inst,
    input wire                 biu_inst_valid,

    // data bus
    output wire [`DataAddrBus] data_addr,
    output wire [7:0]          wmask,
    output wire [`DataBus]     data_o,
    input  wire [`DataBus]     data_i,
    output wire                we,
    output wire                re,
    input  wire                mem_finish,
                               
    // interrupt signals       
    input  wire                timer_intr

    );

    //********** define connections **********
    wire [`InstAddrBus]       pc;
    assign inst_addr = pc;


    //between pc and id/ex
    wire [`InstAddrBus]       jalr_pc;
    wire                      jalr_pc_ena; 
    wire [`InstAddrBus]       branch_pc;
    wire                      branch_pc_ena; 

    //between mini_id_bpuand pc
    wire [`InstAddrBus]       prdt_pc;
    //between mini_id_bpu and regfile
    wire                      x1_read_ena;
    wire [`RegBus]            x1_data;

     
    // between if_id and id
    wire                      id_flush; //flush signal
    wire [`InstAddrBus]       pc_id;
    wire [`InstBus]           inst_id;

    // between id and regfile 
    wire [`RegAddrBus]   raddr1,raddr2;
    wire                 re1,re2;
    wire [`RegBus]       rdata1,rdata2;


    // between id and id_ex
    wire [`InstAddrBus] id_pc;
    wire [7:0]          id_inst_type;
    wire [7:0]          id_inst_opcode;
    wire [`RegBus]      id_op1;
    wire [`RegBus]      id_op2;
    wire                id_rd_ena;
    wire [`RegAddrBus]  id_rd_addr;

    wire [11:0]         id_addr_offset;
    wire [2 :0]         id_ls_sel;    

    //between id_ex and ex
    wire [`InstAddrBus] pc_ex;
    wire [7:0]          inst_type_ex;
    wire [7:0]          inst_opcode_ex;
    wire [`RegBus]      op1_ex;
    wire [`RegBus]      op2_ex;
    wire                rd_ena_ex;
    wire [`RegAddrBus]  rd_addr_ex;

    wire [11:0]         addr_offset_ex;
    wire [ 2:0]         ls_sel_ex;  

    //between ex and ex_mem
    wire ex_flush;
    wire [7:0]          ex_inst_type;
    wire                ex_rd_ena;
    wire [`RegBus]      ex_rd_data;
    wire [`RegAddrBus]  ex_rd_addr;

    wire [`DataAddrBus] ex_ls_addr;
    wire [2:0]          ex_ls_sel;

    //between ex_mem to mem
    wire [7:0]          inst_type_mem;
    wire                rd_ena_mem;
    wire [`RegBus]      rd_data_mem;
    wire [`RegAddrBus]  rd_addr_mem;

    wire [`DataAddrBus] ls_addr_mem;
    wire [2:0]          ls_sel_mem;

    //between mem and mem_wb
    wire                mem_rd_ena;
    wire [`RegBus]      mem_rd_data;
    wire [`RegAddrBus]  mem_rd_addr;
    //between mem_wb and regfile
    wire                rd_ena_wb;
    wire [`RegBus]      rd_data_wb;
    wire [`RegAddrBus]  rd_addr_wb;

    // signals related to pipeline_ctrl 
    wire [4:0]          stall_ctrl;
    wire                id_stall_req;
    wire                if_stall_req;
    wire                ex_stall_req;
    wire                mem_stall_req;
    

    //********** fetch instructions **********
    //instantiate pc module
    pc pc0(
        .clk(clk),
        .rst(rst),
        .prdt_pc_i(prdt_pc),

        .id_pc_i(jalr_pc),
        .id_pc_ena(jalr_pc_ena),
        .ex_pc_i(branch_pc),
        .ex_pc_ena(branch_pc_ena),

        .pc_stall(stall_ctrl[0]),

        .pc(pc),
        .ce(inst_ena)
    );

    //instantiate mini_id_bpu module
    mini_id_bpu mini_id_bpu0(
        .rst(rst),
        
        .inst_i(inst),
        .pc_i(pc),

        //x1 data
        .x1_read_ena(x1_read_ena),
        .x1_data(x1_data),

        // predict pc 
        .prdt_pc_o(prdt_pc)
    );


    //instantiate if_id module
    if_id if_id0(
        .clk(clk),
        .rst(rst),
        .if_pc(pc),
        .if_inst(inst),
        .if_inst_ready(inst_ready),
        .if_inst_valid(biu_inst_valid),

        .id_pc(pc_id),
        .id_inst(inst_id),
        .if_id_flush(ex_flush),
        .if_id_bubble(id_flush),
        .stall_ctrl(stall_ctrl),
        .if_stall_req(if_stall_req)
    );


    //********** decode instructions **********

    //instantiate regfile
    regfile regfile0(
        .clk(clk),
        .rst(rst),

        //one write port
        .waddr(rd_addr_wb),
        .wdata(rd_data_wb),
        .we(rd_ena_wb),
    
        //two read ports
        .raddr1(raddr1),
        .rdata1(rdata1),
        .re1(re1),

        .raddr2(raddr2),
        .rdata2(rdata2),
        .re2(re2),

        //shortcut between x1 and mini_id_bpu
        .x1_read_ena(x1_read_ena),
        .x1_data(x1_data),
        .trap_code(trap_code),

        //reg a0 for write 
        .reg_a0(reg_a0) 
    );

    id id0(
        .rst(rst),
        .inst_i(inst_id),
        .pc_i(pc_id),

        // fetch data from regfile
        .op1_data_i(rdata1),
        .op2_data_i(rdata2),
        .op1_addr_o(raddr1),
        .op2_addr_o(raddr2),
        .op1_read_o(re1),
        .op2_read_o(re2),
        // signal from ex stage
        .ex_rd_data(ex_rd_data),
        .ex_rd_addr(ex_rd_addr),
        .ex_rd_ena(ex_rd_ena),
        .ex_inst_type(ex_inst_type),

        //signals from mem stage
        .mem_rd_data(mem_rd_data),
        .mem_rd_addr(mem_rd_addr),
        .mem_rd_ena(mem_rd_ena),

        //signals from wb stage
        .wb_rd_ena (rd_ena_wb),
        .wb_rd_addr(rd_addr_wb),

        //signal to pipeline_ctrl
        .id_stall_req(id_stall_req),
        .if_stall_req(if_stall_req),

        //output to id_exe
        .inst_type(id_inst_type),
        .inst_opcode(id_inst_opcode),
        .op1_o(id_op1),
        .op2_o(id_op2),
        .rd_w_ena(id_rd_ena),
        .rd_w_addr(id_rd_addr),
        .pc_o(id_pc),

        .store_addr_offset(id_addr_offset),
        .mem_op_sel(id_ls_sel),

        //output to pc and if_id 
        .jalr_pc_ena(jalr_pc_ena),
        .jalr_pc(jalr_pc),
        .id_flush(id_flush)
    );

    id_ex id_ex0(
        .clk(clk),
        .rst(rst),
        .id_ex_bubble(ex_flush),

        //input 
        .id_pc(id_pc),
        .id_inst_type(id_inst_type),
        .id_inst_opcode(id_inst_opcode),
        .id_op1(id_op1),
        .id_op2(id_op2),
        .id_rd_ena(id_rd_ena),
        .id_rd_addr(id_rd_addr),

        .id_addr_offset(id_addr_offset),
        .id_ls_sel(id_ls_sel),

        .stall_ctrl(stall_ctrl),
    
        //output
        .ex_pc(pc_ex),
        .ex_inst_type(inst_type_ex),
        .ex_inst_opcode(inst_opcode_ex),
        .ex_op1(op1_ex),
        .ex_op2(op2_ex),
        .ex_rd_ena(rd_ena_ex),
        .ex_rd_addr(rd_addr_ex),

        .ex_addr_offset(addr_offset_ex),
        .ex_ls_sel(ls_sel_ex)
    );

    //********** execute instructions **********
    ex ex0(
        .clk(clk),
        .rst(rst),
        //input ports
        .pc_i(pc_ex),
        .inst_type_i(inst_type_ex),
        .inst_opcode_i(inst_opcode_ex),
        .op1_i(op1_ex),
        .op2_i(op2_ex),
        .rd_ena_i(rd_ena_ex),
        .rd_addr_i(rd_addr_ex),

        .ls_sel_i(ls_sel_ex),
        .addr_offset_i(addr_offset_ex),

        //output ports
        .inst_type_o(ex_inst_type),
        .rd_ena_o(ex_rd_ena),
        .rd_data_o(ex_rd_data),
        .rd_addr_o(ex_rd_addr),
        .ls_sel_o(ex_ls_sel),
        .ls_addr_o(ex_ls_addr),

        .ex_flush(ex_flush),
        .branch_pc_ena(branch_pc_ena),
        .branch_pc(branch_pc),

        .if_stall_req(if_stall_req),
        .ex_stall_req(ex_stall_req),

        //interrupt
        .timer_intr(timer_intr),

        .ex_stall(stall_ctrl[3]),

        //for difftest
        .tmr_trap_ena_o(tmr_trap_ena)
        //////////////
    );

    ex_mem ex_mem0(
        .clk(clk),
        .rst(rst),
        // input signals
        .ex_inst_type(ex_inst_type),
        .ex_rd_ena(ex_rd_ena),
        .ex_rd_data(ex_rd_data),
        .ex_rd_addr(ex_rd_addr),

        .ex_ls_sel(ex_ls_sel),
        .ex_ls_addr(ex_ls_addr),

        .stall_ctrl(stall_ctrl),
        // output signals
        .mem_inst_type(inst_type_mem),
        .mem_rd_ena(rd_ena_mem),
        .mem_rd_data(rd_data_mem),
        .mem_rd_addr(rd_addr_mem),

        .mem_ls_sel(ls_sel_mem),
        .mem_ls_addr(ls_addr_mem)
    );

    //********** access memory **********
    mem mem0(
        .rst(rst),
        .inst_type_i(inst_type_mem),
        .rd_ena_i(rd_ena_mem),
        .rd_data_i(rd_data_mem),
        .rd_addr_i(rd_addr_mem),

        .ls_sel_i(ls_sel_mem),
        .ls_addr_i(ls_addr_mem),
        // to memory
        .data_addr_o(data_addr),
        .wmask_o(wmask),
        .data_i(data_i),
        .data_o(data_o),
        .we(we),
        .re(re),
        .mem_finish(mem_finish),
        // to mem_wb
        .rd_ena_o(mem_rd_ena),
        .rd_data_o(mem_rd_data),
        .rd_addr_o(mem_rd_addr),

        // to pipelinectrl
        .mem_stall_req(mem_stall_req)
    );

    mem_wb mem_wb0(
        .clk(clk),
        .rst(rst),

        .mem_rd_data(mem_rd_data),
        .mem_rd_addr(mem_rd_addr),
        .mem_rd_ena(mem_rd_ena),

        .stall_ctrl(stall_ctrl),

        .wb_rd_data(rd_data_wb),
        .wb_rd_addr(rd_addr_wb),
        .wb_rd_ena(rd_ena_wb)
    );

    pipeline_ctrl pipeline_ctrl0(
        .rst(rst),
        //input: stall request from id, ex and mem
        .if_stall_req(if_stall_req),
        .id_stall_req(id_stall_req),
        .ex_stall_req(ex_stall_req),
        .mem_stall_req(mem_stall_req),

        //output: stall control signals
        //stall_ctrl[0] --> pc
        //stall_ctrl[1] --> if
        //stall_ctrl[2] --> id
        //stall_ctrl[3] --> ex
        //stall_ctrl[4] --> mem
        //stall_ctrl[5] --> wb
        .stall_ctrl(stall_ctrl)
    );


    //*************** difftest interface ***************
    reg                cmt_wen;
    reg[7:0]           cmt_wdest;
    reg [`RegBus]      cmt_wdata;
    reg [`InstAddrBus] cmt_pc;
    reg [`InstBus]     cmt_inst;
    reg                cmt_valid;
    reg                trap;
    reg                skip;
    wire[7:0]          trap_code;
    reg [63:0]         cycleCnt;
    reg [63:0]         instrCnt;

    // delay the pc and inst
    reg [`InstBus]     id_ex_inst, ex_mem_inst, mem_wb_inst;
    reg [`InstAddrBus] ex_mem_pc;
    reg [`InstAddrBus] mem_wb_pc;

    reg mem_wb_re, mem_wb_we;
    reg [63:0] mem_wb_data_addr;

    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            id_ex_inst <= 32'd0;
        end
        else begin
            if(stall_ctrl[2] == `NoStop) begin
                if(ex_flush) begin
                    id_ex_inst <= 32'd0;
                end
                else begin
                    id_ex_inst <= inst_id;
                end
            end
            else if(stall_ctrl[2] == `Stop&&stall_ctrl[3] == `NoStop) begin
                id_ex_inst <= 32'd0;
            end
            else begin
                id_ex_inst <= id_ex_inst;
            end
        end
    end
    
    wire tmr_trap_ena;
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            ex_mem_pc   <= 64'd0;
            ex_mem_inst <= 32'd0;
        end
        else begin
            if(stall_ctrl[3] == `NoStop) begin
                ex_mem_pc <= pc_ex & {64{~tmr_trap_ena}};
                ex_mem_inst <= id_ex_inst;
            end
            else if(stall_ctrl[3] == `Stop&&stall_ctrl[4] == `NoStop) begin
                ex_mem_pc <= 64'd0;
                ex_mem_inst <= 32'd0;
            end
            else begin
                ex_mem_pc <= ex_mem_pc;
                ex_mem_inst <= ex_mem_inst;
            end
        end
    end
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            mem_wb_pc        <= 64'd0;
            mem_wb_inst      <= 32'd0;
            mem_wb_re        <= 0;
            mem_wb_data_addr <= 0; 
            mem_wb_we        <= 0;
        end
        else begin
            if(stall_ctrl[4]==`NoStop) begin
             	mem_wb_inst <= ex_mem_inst;
                mem_wb_pc   <= ex_mem_pc;
                mem_wb_re   <= re;
                mem_wb_data_addr <= data_addr;
                mem_wb_we   <= we;
            end
            else if(stall_ctrl[4]==`Stop)begin
                mem_wb_pc        <= `ZeroWord;
                mem_wb_inst      <= 32'd0;
                mem_wb_re        <= 0;
                mem_wb_data_addr <= 0;
                mem_wb_we        <= 0;
            end
            else begin
                mem_wb_pc        <= mem_wb_pc;
                mem_wb_inst      <= mem_wb_inst;
                mem_wb_re        <= mem_wb_re;
                mem_wb_data_addr <= mem_wb_data_addr;
                mem_wb_we        <= mem_wb_we;
            end
        end
    end



    wire inst_valid;
    assign inst_valid = (mem_wb_inst != 32'd0) && (mem_wb_pc!=64'd0);
    wire inst_skip;
    wire skip_addr_ena = (mem_wb_data_addr == `MTIME_ADDR) | (mem_wb_data_addr == `MTIMECMP_ADDR) |({mem_wb_data_addr[63:3],3'd0} == `UART_ADDR_START);
    assign inst_skip   = (mem_wb_inst == 32'hb00027f3) | (mem_wb_inst == 32'h0006b783) | (mem_wb_inst == 32'h00f6b023)|(mem_wb_inst == 32'h00a78023)
                           |((mem_wb_re|mem_wb_we) & skip_addr_ena)|(mem_wb_inst == 32'h00078023)|(mem_wb_inst == 32'h0000_007b);

    always @(posedge clk) begin
        if(rst) begin
            cmt_wen   <= 1'b0;
            cmt_wdest <= 8'd0;
            cmt_wdata <= 64'd0;
            cmt_pc    <= 64'd0;
            cmt_inst  <= 32'd0;
            cmt_valid <= 1'b0;
            trap      <= 1'b0;
            cycleCnt  <= 64'd0;
            instrCnt  <= 64'd0;
        end
        else begin
            cmt_wen   <= rd_ena_wb;
            cmt_wdest <= {3'b000,rd_addr_wb};
            cmt_wdata <= rd_data_wb;
            cmt_pc    <= mem_wb_pc;
            cmt_inst  <= mem_wb_inst;
            cmt_valid <= inst_valid;
            trap      <= mem_wb_inst[6:0] == 7'h6b;
            skip      <= inst_skip;
            cycleCnt  <= cycleCnt + 1;
            instrCnt  <= instrCnt + inst_valid;
        end
        
    end

    // Implement The Custom Instruction for Output: ADDI x0,rs1,0 (rs1: output char)
    wire is_output = id_ex_inst == 32'h8005_0013;
    always @(posedge clk) begin
        if(is_output) begin
            $write("%c",op1_ex);
        end
    end

    // Implement The Custom Instruction For Output: 0x0000_007b
    wire [`RegBus] reg_a0;
    always @(posedge clk) begin
        if(mem_wb_inst == 32'h0000_007b) begin
            $write("%c",reg_a0);
        end       
    end


    DifftestInstrCommit DifftestInstrCommit(
        .clock              (clk      ),
        .coreid             (0        ),    
        .index              (0        ),
        .valid              (cmt_valid),
        .pc                 (cmt_pc   ),
        .instr              (cmt_inst ),
        .skip               (skip     ),
        .isRVC              (0        ),
        .scFailed           (0        ),
        .wen                (cmt_wen  ),
        .wdest              (cmt_wdest),
        .wdata              (cmt_wdata)
        );


    DifftestTrapEvent DifftestTrapEvent(
        .clock              (clk      ),
        .coreid             (0        ),
        .valid              (trap     ),
        .code               (trap_code),
        .pc                 (cmt_pc   ),
        .cycleCnt           (cycleCnt ),
        .instrCnt           (instrCnt )
        );
    
    DifftestArchFpRegState DifftestArchFpRegState(
        .clock              (clk),
        .coreid             (0),
        .fpr_0              (0),
        .fpr_1              (0),
        .fpr_2              (0),
        .fpr_3              (0),
        .fpr_4              (0),
        .fpr_5              (0),
        .fpr_6              (0),
        .fpr_7              (0),
        .fpr_8              (0),
        .fpr_9              (0),
        .fpr_10             (0),
        .fpr_11             (0),
        .fpr_12             (0),
        .fpr_13             (0),
        .fpr_14             (0),
        .fpr_15             (0),
        .fpr_16             (0),
        .fpr_17             (0),
        .fpr_18             (0),
        .fpr_19             (0),
        .fpr_20             (0),
        .fpr_21             (0),
        .fpr_22             (0),
        .fpr_23             (0),
        .fpr_24             (0),
        .fpr_25             (0),
        .fpr_26             (0),
        .fpr_27             (0),
        .fpr_28             (0),
        .fpr_29             (0),
        .fpr_30             (0),
        .fpr_31             (0)
        );


endmodule


