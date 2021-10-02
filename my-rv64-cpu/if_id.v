`include "defines.v"

module if_id (
    input wire clk,
    input wire rst,
    
    input wire [`InstAddrBus] if_pc,
    input wire [`InstBus] if_inst,
    input wire if_id_flush,
    input wire if_id_bubble,

    input wire if_inst_valid,
    output wire if_inst_ready,
    //stall control and req signal
    input wire [4:0] stall_ctrl,
    output wire if_stall_req,

    output reg [`InstAddrBus] id_pc,
    output reg [`InstBus] id_inst
    );

    always@(posedge clk) begin
        if(rst == `RstEnable|if_id_flush) begin
            id_pc   <= `ZeroWord;
            id_inst <= 32'h0000_0000;
        end
        else if((stall_ctrl[1] == `Stop) && (stall_ctrl[2] == `NoStop) && (stall_ctrl[4:3]==2'b00)) begin
            id_pc   <= `ZeroWord;
            id_inst <= 32'h0000_0000;
        end
        else if((stall_ctrl[0]==`Stop) && (stall_ctrl[1] == `Stop) && (stall_ctrl[2] == `Stop)) begin
            id_pc   <= id_pc;
            id_inst <= id_inst;
        end
        else begin
            if(if_id_bubble) begin
                id_pc   <= `ZeroWord;
                id_inst <= 32'h0000_0000;
            end
            else begin
                id_pc   <= if_pc;
                id_inst <= if_inst;
            end
        end
    end

    assign if_stall_req = (rst == `RstEnable) ? 1'b0:(if_inst_valid == 1'b0);

    assign if_inst_ready = (stall_ctrl[1] == `NoStop);

endmodule





