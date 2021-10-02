`include "defines.v"
module mem (
    input wire rst,
    input wire [7:0]          inst_type_i,
    input wire                rd_ena_i,
    input wire [`RegBus]      rd_data_i,
    input wire [`RegAddrBus]  rd_addr_i,


    input wire [`DataAddrBus] ls_addr_i,
    input wire [2:0]          ls_sel_i,

    //to memory
    output wire [`DataAddrBus] data_addr_o,
    output wire [7:0]          wmask_o,
    input  wire [`DataBus]     data_i,
    output wire [`DataBus]     data_o,
    output wire                we,
    output wire                re,
    input  wire                mem_finish,

    //to mem_wb
    output wire                rd_ena_o,
    output wire [`RegBus]      rd_data_o,
    output wire [`RegAddrBus]  rd_addr_o,

    //to pipelinectrl
    output wire                mem_stall_req
    );
    //*************** signals to pipelinectrl ***************
    assign mem_stall_req = (rst == `RstEnable) ? 1'b0 : ((re|we) && (mem_finish == 1'b0)); 

    //*************** signal to mem_wb ***************
    assign rd_addr_o = rd_addr_i;
    assign rd_data_o = inst_type_i[1] ? load_data :rd_data_i;
    assign rd_ena_o =  rd_ena_i;


    //*************** signals to ram *****************
    assign we          = (rst == `RstEnable) ? 1'b0 : inst_type_i[0];
    assign re          = (rst == `RstEnable) ? 1'b0 : inst_type_i[1];
    assign data_addr_o = (rst == `RstEnable) ? `ZeroWord : ls_addr_i;

    // load data part:
    reg [`DataBus] load_data;

    wire [2:0] byte_sel        = ls_addr_i[2:0];
    wire [1:0] half_byte_sel   = ls_addr_i[2:1];
    wire       word_sel        = ls_addr_i[2];

    reg  [7:0]  data_byte;
    reg  [15:0] data_half_byte;
    wire [31:0] data_word;

    always @(*) begin
        case (byte_sel)
            3'b000:  data_byte = data_i[ 7: 0];
            3'b001:  data_byte = data_i[15: 8];
            3'b010:  data_byte = data_i[23:16];
            3'b011:  data_byte = data_i[31:24];
            3'b100:  data_byte = data_i[39:32];
            3'b101:  data_byte = data_i[47:40];
            3'b110:  data_byte = data_i[55:48];
            default: data_byte = data_i[63:56];
        endcase
    end

    always @(*) begin
        case (half_byte_sel)
            2'b00:   data_half_byte = data_i[15: 0];
            2'b01:   data_half_byte = data_i[31:16];
            2'b10:   data_half_byte = data_i[47:32];
            default: data_half_byte = data_i[63:48];
        endcase
    end

    assign data_word = word_sel ? data_i[63:32] : data_i[31:0];

    always @(*) begin
        if(inst_type_i == 8'b0000_0010) begin
            case (ls_sel_i)
                `LB_SEL :begin load_data = {{56{data_byte[7]}}, data_byte};            end
                `LH_SEL :begin load_data = {{48{data_half_byte[15]}}, data_half_byte}; end                                 
                `LW_SEL :begin load_data = {{32{data_word[31]}}, data_word};           end
                `LBU_SEL:begin load_data = {{56{1'b0}}, data_byte};                    end
                `LHU_SEL:begin load_data = {{48{1'b0}}, data_half_byte};               end
                `LWU_SEL:begin load_data = {{32{1'b0}}, data_word};                    end
                `LD_SEL :begin load_data = data_i;                                     end
                default :begin load_data = `ZeroWord;                                  end
            endcase
        end
        else begin load_data = `ZeroWord;  end
    end

    // store data part: 

    reg [`DataBus] store_data;
    reg [7:0] store_mask;

    reg [`DataBus] sb_data, sh_data, sw_data;
    reg [7:0]      sb_mask, sh_mask, sw_mask;
    always @(*) begin
        if(rst == `RstEnable) begin
            sb_data = 64'd0;
            sb_mask =  8'd0;
        end
        else begin
            case (byte_sel)
                3'b000:begin 
                    sb_data = {56'd0,rd_data_i[7:0]};
                    sb_mask = 8'b0000_0001;
                end
                3'b001:begin
                    sb_data = {48'd0,rd_data_i[7:0],8'd0};
                    sb_mask = 8'b0000_0010;
                end
                3'b010:begin 
                    sb_data = {40'd0,rd_data_i[7:0],16'd0};
                    sb_mask = 8'b0000_0100;
                end
                3'b011:begin
                    sb_data = {32'd0,rd_data_i[7:0],24'd0};
                    sb_mask = 8'b0000_1000;
                end
                3'b100:begin
                    sb_data = {24'd0,rd_data_i[7:0],32'd0};
                    sb_mask = 8'b0001_0000;
                end
                3'b101: begin
                    sb_data = {16'd0,rd_data_i[7:0],40'd0};
                    sb_mask = 8'b0010_0000;
                end
                3'b110: begin
                    sb_data = {8'd0 ,rd_data_i[7:0],48'd0};
                    sb_mask = 8'b0100_0000;
                end
                default:begin
                    sb_data = {rd_data_i[7:0],56'd0};
                    sb_mask = 8'b1000_0000;
                end
            endcase
        end
    end

    always @(*) begin
        if(rst == `RstEnable) begin
            sh_data = 64'd0;
            sh_mask =  8'd0;
        end
        else begin
            case (half_byte_sel)
                2'b00: begin
                    sh_data = {48'd0,rd_data_i[15:0]};
                    sh_mask = 8'b0000_0011;
                end
                2'b01: begin
                    sh_data = {32'd0,rd_data_i[15:0],16'd0};
                    sh_mask = 8'b0000_1100;
                end
                2'b10: begin
                    sh_data = {16'd0,rd_data_i[15:0],32'd0};
                    sh_mask = 8'b0011_0000;
                end
                default: begin
                    sh_data = {rd_data_i[15:0],48'd0};
                    sh_mask = 8'b1100_0000;
                end
            endcase
        end
    end

    always @(*) begin
        if(rst == `RstEnable) begin
            sw_data = 64'd0;
            sw_mask =  8'd0;
        end
        else begin
            case (word_sel)
                1'b0: begin
                    sw_data = {32'd0, rd_data_i[31:0]};
                    sw_mask = 8'b0000_1111;
                end
                default: begin
                    sw_data = {rd_data_i[31:0],32'd0};
                    sw_mask = 8'b1111_0000;
                end
            endcase
        end
    end

    always @(*) begin
        if(rst == `RstEnable) begin
            store_data  = 64'd0;
            store_mask  =  8'd0;
        end
        else begin
            case (ls_sel_i)
                `SB_SEL: begin
                    store_data = sb_data;
                    store_mask = sb_mask;
                end
                `SH_SEL: begin
                    store_data = sh_data;
                    store_mask = sh_mask;
                end
                `SW_SEL: begin
                    store_data = sw_data;
                    store_mask = sw_mask;                
                end
                `SD_SEL: begin
                    store_data = rd_data_i;
                    store_mask = 8'b1111_1111;
                end
                default: begin
                    store_data = 64'd0;
                    store_mask = 8'b0000_0000;
                end
            endcase
        end
    end

    assign data_o   = (rst == `RstEnable|~inst_type_i[0]) ? 64'd0:store_data;
    assign wmask_o  = (rst == `RstEnable|~inst_type_i[0]) ?  8'd0:store_mask; 


endmodule
