`include "defines.v"
module csr (
    input wire clk,
    input wire rst,
    input [`InstAddrBus] pc_i,

    input wire csr_wr_en,
    input wire csr_rd_en,
    input wire [11:0] csr_idx,

    input wire cmt_mret_ena,
    input wire ecall_trap_ena,
    input wire [`RegBus]trap_mcause_value,

    input wire tmr_intr_ena,
    output wire tmr_trap_ena,

    output wire [`RegBus] read_csr_data,
    input  wire [`RegBus] wbck_csr_data,

    input  wire ex_stall
    );


    //-------------------- 0xB00 MRW mcycle --------------------
    wire sel_mcycle = (csr_idx == 12'hb00);
    wire rd_mcycle  = csr_rd_en && sel_mcycle;
    wire wr_mcycle  = csr_wr_en && sel_mcycle;
    reg [`RegBus] csr_mcycle;
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            csr_mcycle <= `ZeroWord;
        end
        else if(wr_mcycle) begin
            csr_mcycle <= wbck_csr_data;
        end
        else begin
            csr_mcycle <= csr_mcycle + 64'd1;
        end
    end

    //-------------------- 0x300 MRW mstatus --------------------
    wire sel_mstatus = (csr_idx == 12'h300);
    wire rd_mstatus  = sel_mstatus && csr_rd_en;
    wire wr_mstatus  = sel_mstatus && csr_wr_en;

    // Implement MPIE field
    wire mstatus_mpie_ena = 
                 // The CSR is written by CSR instruction
                 wr_mstatus   | 
                 // The MRET instruction commited
                 cmt_mret_ena | 
                 // The trap is taken
                 (ecall_trap_ena | tmr_trap_ena) ;
    
    wire mstatus_mpie_nxt = (ecall_trap_ena|tmr_trap_ena) ? csr_mstatus_mie :
                                             cmt_mret_ena ? 1'b1            :
                                               wr_mstatus ? wbck_csr_data[7]:
                                                            csr_mstatus_mpie;

    reg csr_mstatus_mpie;
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            csr_mstatus_mpie <= 1'b0;
        end
        else if(mstatus_mpie_ena & ~ex_stall) begin //when ex is stall,don't change mpie
            csr_mstatus_mpie <= mstatus_mpie_nxt;
        end
        else begin
            csr_mstatus_mpie <= csr_mstatus_mpie;
        end
    end

    // Implement MIE field
    wire mstatus_mie_ena = mstatus_mpie_ena;

    wire mstatus_mie_nxt = (ecall_trap_ena|tmr_trap_ena) ? 1'b0            :
                                            cmt_mret_ena ? csr_mstatus_mpie:
                                              wr_mstatus ? wbck_csr_data[3]:
                                                           csr_mstatus_mie ;

    reg csr_mstatus_mie;
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            csr_mstatus_mie <= 1'b0;
        end 
        else if(mstatus_mie_ena & ~ex_stall) begin // when ex is stall,don't change mie
            csr_mstatus_mie <= mstatus_mie_nxt;
        end 
        else begin
            csr_mstatus_mie <= csr_mstatus_mie;
        end      
    end

    // Implement MPP Field
    wire mstatus_mpp_ena = mstatus_mpie_ena;
    wire [1:0] mstatus_mpp_nxt = (ecall_trap_ena|tmr_trap_ena) ? 2'b11               :
                                                  cmt_mret_ena ? 2'b00               :
                                                    wr_mstatus ? wbck_csr_data[12:11]:
                                                                 csr_mstatus_mpp     ;
                                                     
    reg [1:0] csr_mstatus_mpp;
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            csr_mstatus_mpp <= 2'b00;
        end
        else if(mstatus_mpp_ena) begin
            csr_mstatus_mpp <= mstatus_mpp_nxt;
        end
        else begin
            csr_mstatus_mpp <= csr_mstatus_mpp;
        end
    end

    // Implement XS field
    wire [1:0] csr_mstatus_xs;
    // If no EAI coprocessor interface configured, the XS is just hardwired to 0
    assign csr_mstatus_xs = 2'b00;

    // Implement FS field
    reg [1:0] csr_mstatus_fs;
    // If no FPU configured, the FS is just hardwired to 0
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            csr_mstatus_fs <= 2'b00;
        end
        else if(wr_mstatus) begin
            csr_mstatus_fs <= wbck_csr_data[14:13];
        end
        else begin
            csr_mstatus_fs <= csr_mstatus_fs;
        end
    end

    // Implement SD field
    wire csr_mstatus_sd = (csr_mstatus_xs == 2'b11) | (csr_mstatus_fs == 2'b11);
    

    // Pack the full mstatus register
    wire [`RegBus] csr_mstatus;
    assign csr_mstatus[63]    = csr_mstatus_sd  ;   //SD
    assign csr_mstatus[62:36] = 27'd0           ;   //Reserved
    assign csr_mstatus[35:34] = 2'b00           ;   //SXL
    assign csr_mstatus[33:32] = 2'b00           ;   //UXL
    assign csr_mstatus[31:23] = 9'd0            ;   //Reserved
    assign csr_mstatus[22:17] = 6'd0            ;   //TSR--MPRV
    assign csr_mstatus[16:15] = csr_mstatus_xs  ;   //XS
    assign csr_mstatus[14:13] = csr_mstatus_fs  ;   //FS
    assign csr_mstatus[12:11] = csr_mstatus_mpp ;   //MPP
    assign csr_mstatus[10: 9] = 2'b00           ;   //Reserved
    assign csr_mstatus[8]     = 1'b0            ;   //SPP
    assign csr_mstatus[7]     = csr_mstatus_mpie;   //MPIE
    assign csr_mstatus[6]     = 1'b0            ;   //Reserved
    assign csr_mstatus[5]     = 1'b0            ;   //SPIE
    assign csr_mstatus[4]     = 1'b0            ;   //UPIE
    assign csr_mstatus[3]     = csr_mstatus_mie ;   //MIE
    assign csr_mstatus[2]     = 1'b0            ;   //Reserved
    assign csr_mstatus[1]     = 1'b0            ;   //SIE
    assign csr_mstatus[0]     = 1'b0            ;   //UIE


    //-------------------- 0x305 MRW mtvec --------------------
    wire sel_mtvec = (csr_idx == 12'h305);
    wire rd_mtvec  = (sel_mtvec && csr_rd_en) | ecall_trap_ena | tmr_trap_ena;
    wire wr_mtvec  = sel_mtvec && csr_wr_en;
    // implement base field
    reg [63:2] csr_mtvec_base;
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            csr_mtvec_base <= 62'd0;
        end
        else if(wr_mtvec) begin
            csr_mtvec_base <= wbck_csr_data[63:2];
        end
        else begin
            csr_mtvec_base <= csr_mtvec_base;
        end
    end

    // implement mode field
    wire [1:0] csr_mtvec_mode;
    assign csr_mtvec_mode = 2'b00;
    // pack the full mtvec register 
    wire [`RegBus] csr_mtvec;
    assign csr_mtvec = {csr_mtvec_base,csr_mtvec_mode};


    //-------------------- 0x341 MRW MEPC --------------------
    wire sel_mepc = (csr_idx == 12'h341);
    wire rd_mepc  = (sel_mepc && csr_rd_en)  | cmt_mret_ena;
    wire wr_mepc  = (sel_mepc && csr_wr_en)  | ecall_trap_ena | tmr_trap_ena;
    
    // implement base field
    reg [`RegBus] csr_mepc;
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            csr_mepc <= `ZeroWord;
        end
        else if(wr_mepc) begin
            csr_mepc <= {wbck_csr_data[63:2],2'b00};
        end
        else begin
            csr_mepc <= csr_mepc;
        end
    end

    //-------------------- 0x342 MRW MCAUSE --------------------

    wire sel_mcause = (csr_idx == 12'h342);
    wire rd_mcause  = sel_mcause && csr_rd_en;
    wire wr_mcause  = sel_mcause && csr_wr_en;
    wire csr_mcause_ena = wr_mcause | ecall_trap_ena | tmr_trap_ena;
    wire [`RegBus]  csr_mcause_nxt = (ecall_trap_ena | tmr_trap_ena) ? trap_mcause_value:
                                                           wr_mcause ? wbck_csr_data    : 
                                                                       csr_mcause ;

    reg [`RegBus] csr_mcause;
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            csr_mcause <= `ZeroWord;
        end
        else if(csr_mcause_ena)begin
            csr_mcause <= csr_mcause_nxt;            
        end
        else begin
            csr_mcause <= csr_mcause;
        end
    end


    //-------------------- 0x304 MRW MIE --------------------
    wire sel_mie = (csr_idx == 12'h304);
    wire rd_mie  = sel_mie && csr_rd_en;
    wire wr_mie  = sel_mie && csr_wr_en;

    // implement mtie field
    reg csr_mie_mtie;
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            csr_mie_mtie <= 1'b0;
        end
        else if(wr_mie) begin
            csr_mie_mtie <= wbck_csr_data[7];
        end
        else begin
            csr_mie_mtie <= csr_mie_mtie;
        end
    end

    // pack the full mie register
    wire [`RegBus] csr_mie;
    assign csr_mie[6:0]  = 7'd0;
    assign csr_mie[7]    = csr_mie_mtie;
    assign csr_mie[63:8] = 56'd0;

    //-------------------- 0x344 MRW MIP --------------------
    wire sel_mip = (csr_idx == 12'h344);
    wire rd_mip  = sel_mip && csr_rd_en;

    // implement mtip field
    reg csr_mip_mtip;
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            csr_mip_mtip <= 1'b0;
        end
        else begin
            csr_mip_mtip <= tmr_intr_ena;
        end
    end

    // pack the full mie register
    wire [`RegBus] csr_mip;
    assign csr_mip[6:0]  = 7'd0;
    assign csr_mip[7]    = csr_mip_mtip;
    assign csr_mip[63:8] = 56'd0;

    // generate tmr_trap_ena
    assign tmr_trap_ena = csr_mip_mtip & csr_mstatus_mie & csr_mie_mtie && (pc_i != 64'd0);


    //-------------------- 0x340 MRW MSCRATCH  --------------------
    wire sel_mscratch = (csr_idx == 12'h340);
    wire rd_mscratch  = sel_mscratch && csr_rd_en;
    wire wr_mscratch  = sel_mscratch && csr_wr_en;
    reg [`RegBus] csr_mscratch;

    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            csr_mscratch <= 64'd0;
        end
        else if(wr_mscratch) begin
            csr_mscratch <= wbck_csr_data;
        end
        else begin
            csr_mscratch <= csr_mscratch;
        end
    end


    //-------------------- 0x100 SRW SSTATUS --------------------
    wire [`RegBus] csr_sstatus;
    assign csr_sstatus[63]    = (csr_mstatus_fs == 2'b11);
    assign csr_sstatus[62:15] = 48'd0;
    assign csr_sstatus[14:13] = csr_mstatus_fs;
    assign csr_sstatus[12: 0] = 13'd0;
    


    //-------------------- generate the Read path --------------------

    assign read_csr_data = 64'd0 | ({64{rd_mcycle}}  & csr_mcycle  )
                                 | ({64{rd_mstatus}} & csr_mstatus )
                                 | ({64{rd_mtvec}}   & csr_mtvec   )
                                 | ({64{rd_mepc}}    & csr_mepc    )
                                 | ({64{rd_mcause}}  & csr_mcause  )
                                 | ({64{rd_mie}}     & csr_mie     )
                                 //| ({64{rd_mip}}     & csr_mip     )
                                 | ({64{rd_mscratch}}& csr_mscratch);



    //----------------- difftest interface --------------------

    reg [`RegBus] mem_wb_mstatus , mstatus_cmt;
    reg [`RegBus] mem_wb_mepc    , mepc_cmt   ;
    reg [`RegBus] mem_wb_mtvec   , mtvec_cmt  ;
    reg [`RegBus] mem_wb_mcause  , mcause_cmt ;
    reg [`RegBus] mem_wb_mie     , mie_cmt    ;
    reg [`RegBus] mem_wb_mip     , mip_cmt    ;
    reg [`RegBus] mem_wb_mscratch, mscratch_cmt;
    reg ex_mem_tmr_trap_ena, mem_wb_tmr_trap_ena, tmr_trap_ena_cmt,temp_tmr_trap_ena;
    reg [63:0]    ex_mem_pc, mem_wb_pc, pc_cmt, temp_pc; 


    /*always @(posedge clk) begin
        if(rst == `RstEnable) begin
            temp_tmr_trap_ena <= 1'b0;
            temp_pc           <= 0;
        end
        else begin
            if(tmr_trap_ena) begin
                temp_tmr_trap_ena <= tmr_trap_ena;
                temp_pc           <= pc_i;
            end
        end
    end*/

    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            ex_mem_tmr_trap_ena <= 1'b0;
            ex_mem_pc           <= 0;
        end
        else begin
            if(~ex_stall) begin
                ex_mem_tmr_trap_ena <= tmr_trap_ena;
                ex_mem_pc           <= pc_i;
            end
            else begin
                ex_mem_tmr_trap_ena <= 0;
                ex_mem_pc           <= 0;
            end
        end
    end

    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            mem_wb_mstatus <= 0;
            mem_wb_mepc    <= 0; 
            mem_wb_mtvec   <= 0;
            mem_wb_mcause  <= 0;
            mem_wb_mie     <= 0;
            mem_wb_mip     <= 0;
            mem_wb_tmr_trap_ena <= 0;
            mem_wb_pc      <= 0;
            mem_wb_mscratch <= 0;
        end
        else begin
            mem_wb_mstatus  <= csr_mstatus;
            mem_wb_mepc     <= csr_mepc; 
            mem_wb_mtvec    <= csr_mtvec;
            mem_wb_mcause   <= csr_mcause;
            mem_wb_mie      <= csr_mie;
            mem_wb_mip      <= csr_mip;
            mem_wb_mscratch <= csr_mscratch;
            mem_wb_tmr_trap_ena <= ex_mem_tmr_trap_ena;
            mem_wb_pc      <= ex_mem_pc;
        end
    end
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            mstatus_cmt <= 0;
            mepc_cmt    <= 0; 
            mtvec_cmt   <= 0;
            mcause_cmt  <= 0;
            mie_cmt     <= 0;
            mip_cmt     <= 0;
            tmr_trap_ena_cmt <= 0;
            pc_cmt      <= 0;
            mscratch_cmt <= 0;
        end
        else begin
            mstatus_cmt <= mem_wb_mstatus;
            mepc_cmt    <= mem_wb_mepc   ; 
            mtvec_cmt   <= mem_wb_mtvec  ;
            mcause_cmt  <= mem_wb_mcause ;
            mie_cmt     <= mem_wb_mie    ;
            mip_cmt     <= mem_wb_mip    ;
            mscratch_cmt<= mem_wb_mscratch;
            tmr_trap_ena_cmt <= mem_wb_tmr_trap_ena;
            pc_cmt      <= mem_wb_pc     ;
        end
    end

    //
    DifftestCSRState DifftestCSRState(
        .clock              (clk),
        .coreid             (0),
        .priviledgeMode     (3),
        .mstatus            (mstatus_cmt),
        .sstatus            (csr_sstatus),
        .mepc               (mepc_cmt),
        .sepc               (0),
        .mtval              (0),
        .stval              (0),
        .mtvec              (mtvec_cmt),
        .stvec              (0),
        .mcause             (mcause_cmt),
        .scause             (0),
        .satp               (0),
        .mip                (0),
        .mie                (mie_cmt),
        .mscratch           (mscratch_cmt),
        .sscratch           (0),
        .mideleg            (0),
        .medeleg            (0)
        );

    wire [31:0] intrNO = {29'd0,{3{tmr_trap_ena_cmt}}};
    //
    DifftestArchEvent DifftestArchEvent(
        .clock(clk),
        .coreid(0),
        .intrNO(intrNO),
        .cause(0),
        .exceptionPC(pc_cmt)
    );

endmodule

