`include "defines.v"

module pipeline_ctrl(

    input wire rst,
    //input: stall request from id, ex and mem
    input wire if_stall_req,
    input wire id_stall_req,
    input wire ex_stall_req,
    input wire mem_stall_req,

    //output: stall control signals
    //stall_ctrl[0] --> pc
    //stall_ctrl[1] --> if
    //stall_ctrl[2] --> id
    //stall_ctrl[3] --> ex
    //stall_ctrl[4] --> mem
    //stall_ctrl[5] --> wb
    output reg [4:0] stall_ctrl
    );



    always @(*) begin
        if(rst == `RstEnable)          begin stall_ctrl = 5'b00000; end
        else if(mem_stall_req== `Stop) begin stall_ctrl = 5'b11111; end
        else if(ex_stall_req == `Stop) begin stall_ctrl = 5'b01111; end
        else if(id_stall_req == `Stop) begin stall_ctrl = 5'b00111; end
        else if(if_stall_req == `Stop) begin stall_ctrl = 5'b00011; end
        else                           begin stall_ctrl = 5'b00000; end
    end
    
endmodule