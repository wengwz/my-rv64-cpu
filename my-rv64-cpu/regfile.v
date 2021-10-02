`include "defines.v"

module regfile (
    input wire clk,
    input wire rst,

    //one write port
    input wire  [`RegAddrBus] waddr,
    input wire  [`RegBus] wdata,
    input wire  we,
    
    //two read ports
    input  wire  [`RegAddrBus] raddr1,
    output wire  [`RegBus] rdata1,
    input  wire  re1,

    input  wire [`RegAddrBus] raddr2,
    output wire [`RegBus] rdata2,
    input  wire re2,

    //shortcut to x1
    input  wire  x1_read_ena,
    output wire [`RegBus] x1_data,

    //difftest ports
    output wire [7:0] trap_code,

    //reg a0 for $write
    output wire [`RegBus] reg_a0

    );

    
    reg [`RegBus] regs [31:0];
    integer i;

    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            for (i = 0;i<32 ;i=i+1 ) begin 
                regs[i] <= `ZeroWord;
            end
        end
        else begin
            if(we == `WriteEnable && waddr!=5'h0) begin
                regs[waddr] <= wdata;
            end
        end
    end


    //********** output signals **********
    assign rdata1  = ((rst == `RstDisable)&&(re1 == `ReadEnable))?
      ((waddr==raddr1)&&(we==`WriteEnable) ? wdata:regs[raddr1] ):
                                                        `ZeroWord;

    assign rdata2  = ((rst == `RstDisable)&&(re2 == `ReadEnable))?
      ((waddr==raddr2)&&(we==`WriteEnable) ? wdata:regs[raddr2] ):
                                                        `ZeroWord;

    assign x1_data = ((rst == `RstDisable)&&(x1_read_ena==`ReadEnable))?
              ((waddr == 5'b00001)&&(we==`WriteEnable) ? wdata:regs[1]):
                                                              `ZeroWord;

    //**********reg a0 output for $write **********
    assign reg_a0 = regs[10];

    DifftestArchIntRegState DifftestArchIntRegState (
        .clock              (clk),
        .coreid             (0),
        .gpr_0              (regs[0]),
        .gpr_1              (regs[1]),
        .gpr_2              (regs[2]),
        .gpr_3              (regs[3]),
        .gpr_4              (regs[4]),
        .gpr_5              (regs[5]),
        .gpr_6              (regs[6]),
        .gpr_7              (regs[7]),
        .gpr_8              (regs[8]),
        .gpr_9              (regs[9]),
        .gpr_10             (regs[10]),
        .gpr_11             (regs[11]),
        .gpr_12             (regs[12]),
        .gpr_13             (regs[13]),
        .gpr_14             (regs[14]),
        .gpr_15             (regs[15]),
        .gpr_16             (regs[16]),
        .gpr_17             (regs[17]),
        .gpr_18             (regs[18]),
        .gpr_19             (regs[19]),
        .gpr_20             (regs[20]),
        .gpr_21             (regs[21]),
        .gpr_22             (regs[22]),
        .gpr_23             (regs[23]),
        .gpr_24             (regs[24]),
        .gpr_25             (regs[25]),
        .gpr_26             (regs[26]),
        .gpr_27             (regs[27]),
        .gpr_28             (regs[28]),
        .gpr_29             (regs[29]),
        .gpr_30             (regs[30]),
        .gpr_31             (regs[31])
        );
    assign trap_code = regs[10][7:0];


endmodule

