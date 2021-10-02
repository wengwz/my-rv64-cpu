`include "defines.v"

module ex_mem (
    input wire clk,
    input wire rst,
    input wire [4:0] stall_ctrl,
    // input signals
    input wire [7:0]          ex_inst_type,
    input wire                ex_rd_ena,
    input wire [`RegBus]      ex_rd_data,
    input wire [`RegAddrBus]  ex_rd_addr,

    input wire [2:0]          ex_ls_sel,
    input wire [`DataAddrBus] ex_ls_addr,
    //output signals
    output reg [7:0]          mem_inst_type,
    output reg                mem_rd_ena,
    output reg [`RegBus]      mem_rd_data,
    output reg [`RegAddrBus]  mem_rd_addr,

    output reg [2:0]          mem_ls_sel,
    output reg [`DataAddrBus] mem_ls_addr
    );

    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            mem_inst_type <= 8'd0;
            mem_rd_ena    <= 1'b0;
            mem_rd_data   <= `ZeroWord;
            mem_rd_addr   <= 5'd0;
            mem_ls_sel    <= 3'd0;
            mem_ls_addr   <= `ZeroWord;
        end
        else begin
            if(stall_ctrl[3] == `NoStop && stall_ctrl[4]==`NoStop) begin
                mem_inst_type <= ex_inst_type;
                mem_rd_ena    <= ex_rd_ena;
                mem_rd_data   <= ex_rd_data;
                mem_rd_addr   <= ex_rd_addr;
                mem_ls_sel    <= ex_ls_sel;
                mem_ls_addr   <= ex_ls_addr;
            end
            else if((stall_ctrl[2:0]==3'b111) && (stall_ctrl[3] == `Stop) && (stall_ctrl[4] == `NoStop)) begin
                mem_inst_type <= 8'd0;
                mem_rd_ena    <= 1'b0;
                mem_rd_data   <= `ZeroWord;
                mem_rd_addr   <= 5'd0;
                mem_ls_sel    <= 3'd0;
                mem_ls_addr   <= `ZeroWord;
            end
            else begin
                mem_inst_type <= mem_inst_type;
                mem_rd_ena    <= mem_rd_ena;
                mem_rd_data   <= mem_rd_data;
                mem_rd_addr   <= mem_rd_addr ;
                mem_ls_sel    <= mem_ls_sel;
                mem_ls_addr   <= mem_ls_addr;
            end
        end
    end

endmodule