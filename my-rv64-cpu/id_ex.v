`include "defines.v"

module id_ex (
    input wire clk,
    input wire rst,
    input wire id_ex_bubble,

    // stall control signals
    input wire [4:0] stall_ctrl,

    //input 
    input wire [`InstAddrBus] id_pc,
    input wire [7:0] id_inst_type,
    input wire [7:0] id_inst_opcode,
    input wire [`RegBus] id_op1,
    input wire [`RegBus] id_op2,
    input wire id_rd_ena,
    input wire [`RegAddrBus] id_rd_addr,

    input wire [11:0] id_addr_offset,
    input wire [2 :0] id_ls_sel,
    
    //output
    output reg [`InstAddrBus] ex_pc,
    output reg [7:0] ex_inst_type,
    output reg [7:0] ex_inst_opcode,
    output reg [`RegBus] ex_op1,
    output reg [`RegBus] ex_op2,
    output reg ex_rd_ena,
    output reg [`RegAddrBus] ex_rd_addr,

    output reg [11:0] ex_addr_offset,
    output reg [2 :0] ex_ls_sel

    );

    always @(posedge clk) begin

        if(rst == `RstEnable) begin
            ex_pc                <= `ZeroWord;
            ex_inst_type         <= 8'd0;
            ex_inst_opcode       <= 8'd0;
            ex_op1               <= 64'd0;
            ex_op2               <= 64'd0;
            ex_rd_ena            <= 1'b0;
            ex_rd_addr           <= 5'd0;
            ex_addr_offset       <= 12'd0;
            ex_ls_sel            <= 3'd0;
        end
        else if((stall_ctrl[2] == `NoStop) && (stall_ctrl[4:3]==2'b00)) begin
            
            if(id_ex_bubble) begin
                ex_pc                <= `ZeroWord;
                ex_inst_type         <= 8'd0;
                ex_inst_opcode       <= 8'd0;
                ex_op1               <= 64'd0;
                ex_op2               <= 64'd0;
                ex_rd_ena            <= 1'b0;
                ex_rd_addr           <= 5'd0;
                ex_addr_offset       <= 12'd0;
                ex_ls_sel            <= 3'd0;
            end
            else begin
                ex_pc          <= id_pc;
                ex_inst_type   <= id_inst_type;
                ex_inst_opcode <= id_inst_opcode;
                ex_op1         <= id_op1;
                ex_op2         <= id_op2;
                ex_rd_ena      <= id_rd_ena;
                ex_rd_addr     <= id_rd_addr;
                ex_addr_offset <= id_addr_offset;
                ex_ls_sel      <= id_ls_sel;            
            end

        end
        else if((stall_ctrl[1:0]==2'b11)&&(stall_ctrl[2] == `Stop) && (stall_ctrl[3]==`NoStop) ) begin
            ex_pc                <= `ZeroWord;
            ex_inst_type         <= 8'd0;
            ex_inst_opcode       <= 8'd0;
            ex_op1               <= 64'd0;
            ex_op2               <= 64'd0;
            ex_rd_ena            <= 1'b0;
            ex_rd_addr           <= 5'd0;
            ex_addr_offset       <= 12'd0;
            ex_ls_sel            <= 3'd0;
        end
        else begin
            ex_pc                <= ex_pc;
            ex_inst_type         <= ex_inst_type;
            ex_inst_opcode       <= ex_inst_opcode;
            ex_op1               <= ex_op1;
            ex_op2               <= ex_op2;
            ex_rd_ena            <= ex_rd_ena;
            ex_rd_addr           <= ex_rd_addr;
            ex_addr_offset       <= ex_addr_offset;
            ex_ls_sel            <= ex_ls_sel;
        end
    end

endmodule