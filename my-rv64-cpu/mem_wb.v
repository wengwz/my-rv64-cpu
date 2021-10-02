`include "defines.v"
module mem_wb (
    input wire clk,
    input wire rst,

    // stall control signal
    input wire [4:0] stall_ctrl,

    input wire [`RegBus]     mem_rd_data,
    input wire [`RegAddrBus] mem_rd_addr,
    input wire               mem_rd_ena,

    output reg [`RegBus]     wb_rd_data,
    output reg [`RegAddrBus] wb_rd_addr,
    output reg               wb_rd_ena
    );

    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            wb_rd_data  <= `ZeroWord;
            wb_rd_addr  <= 5'd0;
            wb_rd_ena   <= 1'b0;
        end
        else begin
            if(stall_ctrl[4]==`NoStop) begin
                wb_rd_data  <= mem_rd_data;
                wb_rd_addr  <= mem_rd_addr;
                wb_rd_ena   <= mem_rd_ena;
            end
            else if((stall_ctrl[3:0] == 4'b1111) && (stall_ctrl[4]==`Stop))begin
                wb_rd_data  <= `ZeroWord;
                wb_rd_addr  <= 5'd0;
                wb_rd_ena   <= 1'b0;
            end
            else begin
                wb_rd_data  <= wb_rd_data;
                wb_rd_addr  <= wb_rd_addr;
                wb_rd_ena   <= wb_rd_ena ;
            end
        end
    end
    
endmodule