`include "defines.v"

module pc (
    input wire clk,
    input wire rst,

    input wire [`InstAddrBus] prdt_pc_i,

    input wire [`InstAddrBus] id_pc_i,
    input wire id_pc_ena,

    input wire [`InstAddrBus] ex_pc_i,
    input wire ex_pc_ena,

    //pc stall signal
    input wire pc_stall,

    output reg [`InstAddrBus] pc,
    output wire ce
    );

    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            pc <= `ADDR_START;
        end
        else begin
            if      (ex_pc_ena) pc <= ex_pc_i;
            else if (id_pc_ena) pc <= id_pc_i;
            else if (pc_stall == `Stop) begin 
                pc <= pc;
            end
            else begin
                pc <= prdt_pc_i;              
            end
        end
    end
    
    assign ce = (rst == `RstEnable)?`ChipDisable:`ChipEnable;
endmodule