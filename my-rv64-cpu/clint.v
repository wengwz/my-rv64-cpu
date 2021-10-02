`include "defines.v"
module clint (
    input wire clk,
    input wire rst,
    //----------- AXI Interface Signals ----------
    // write address channel (slave)
    input  wire [`AXI_AxID_BUS]        axi_aw_id,
    input  wire [`AXI_AxADDR_BUS]      axi_aw_addr,
    input  wire [`AXI_AxLEN_BUS]       axi_aw_len,
    input  wire [`AXI_AxSIZE_BUS]      axi_aw_size,
    input  wire [`AXI_AxBURST_BUS]     axi_aw_burst,
    input  wire [`AXI_AxCACHE_BUS]     axi_aw_cache,
    input  wire [`AXI_AxPROT_BUS]      axi_aw_prot,
    input  wire [`AXI_AxQOS_BUS]       axi_aw_qos,
    input  wire                        axi_aw_valid,
    output wire                        axi_aw_ready,

    // write data channel   (slave)
    input  wire [`AXI_xDATA_BUS]       axi_w_data,
    input  wire [`AXI_WSTRB_BUS]       axi_w_strb,
    input  wire                        axi_w_last,
    input  wire                        axi_w_valid,
    output wire                        axi_w_ready,

    // write response channel (slave)
    output wire [`AXI_xID_BUS]        axi_b_id,
    output wire [`AXI_xRESP_BUS]      axi_b_resp,
    output wire                       axi_b_valid,
    input  wire                       axi_b_ready,

    // read address channel  (slave)
    input wire [`AXI_AxID_BUS]        axi_ar_id,
    input wire [`AXI_AxADDR_BUS]      axi_ar_addr,
    input wire [`AXI_AxLEN_BUS]       axi_ar_len,
    input wire [`AXI_AxSIZE_BUS]      axi_ar_size,
    input wire [`AXI_AxBURST_BUS]     axi_ar_burst,
    input wire [`AXI_AxCACHE_BUS]     axi_ar_cache,
    input wire [`AXI_AxPROT_BUS]      axi_ar_prot,
    input wire [`AXI_AxQOS_BUS]       axi_ar_qos,
    input wire                        axi_ar_valid,
    output wire                       axi_ar_ready,
                                      
    // read data channel  (slave)
    output wire [`AXI_xID_BUS]        axi_r_id,
    output wire [`AXI_xDATA_BUS]      axi_r_data,
    output wire [`AXI_xRESP_BUS]      axi_r_resp,
    output wire                       axi_r_last,
    output wire                       axi_r_valid,
    input wire                        axi_r_ready,
    
    //--------------- Interrupt Signals ---------------
    output wire                       timer_intr
    );

    reg [`RegBus] csr_mtime, csr_mtimecmp;
    wire csr_mtime_ena, csr_mtimecmp_ena;
    wire [`RegBus] mtime_nxt_value, mtimecmp_nxt_value;

    wire [`RegBus] wmask = { {8{axi_w_strb[7]}}, {8{axi_w_strb[6]}}, {8{axi_w_strb[5]}},
                             {8{axi_w_strb[4]}}, {8{axi_w_strb[3]}}, {8{axi_w_strb[2]}},
                             {8{axi_w_strb[1]}}, {8{axi_w_strb[0]}} };


    assign mtime_nxt_value    = csr_mtime_ena    ? (wmask & axi_w_data) : csr_mtime +64'd1;
    assign mtimecmp_nxt_value = csr_mtimecmp_ena ? (wmask & axi_w_data) : csr_mtimecmp;

    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            csr_mtime <= `ZeroWord;
        end
        else begin
            csr_mtime <= mtime_nxt_value;
        end
    end

    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            csr_mtimecmp <= `ZeroWord;
        end
        else begin
            csr_mtimecmp <= mtimecmp_nxt_value;
        end
    end


    //------------------  Write Transaction Control ------------------

    parameter [1:0] W_STATE_IDLE = 2'b00, W_STATE_INFO = 2'b01, W_STATE_RESP = 2'b10;
    reg [1:0] wtrans_state, wtrans_nxt_state;

    // State Transition
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            wtrans_state <= W_STATE_IDLE;
        end
        else begin
            wtrans_state <= wtrans_nxt_state;
        end 
    end

    // Generate Next State

    wire aw_handshake = axi_aw_ready && axi_aw_valid;
    wire w_handshake  = axi_w_ready  && axi_w_valid ; 
    wire b_handshake  = axi_b_ready  && axi_b_valid ;

    assign csr_mtime_ena    = aw_handshake && w_handshake && (axi_aw_addr == `MTIME_ADDR   );
    assign csr_mtimecmp_ena = aw_handshake && w_handshake && (axi_aw_addr == `MTIMECMP_ADDR);


    always @(*) begin
        case(wtrans_state) 
            W_STATE_IDLE:begin
                if(aw_handshake && w_handshake)   begin wtrans_nxt_state = W_STATE_RESP; end
                else if(axi_aw_valid|axi_w_valid) begin wtrans_nxt_state = W_STATE_INFO; end
                else                              begin wtrans_nxt_state = W_STATE_IDLE; end
            end
            W_STATE_INFO: begin
                if(aw_handshake && w_handshake)   begin wtrans_nxt_state = W_STATE_RESP; end
                else                              begin wtrans_nxt_state = W_STATE_INFO; end
            end
            W_STATE_RESP:begin
                if(b_handshake)                   begin wtrans_nxt_state = W_STATE_IDLE; end
                else                              begin wtrans_nxt_state = W_STATE_RESP; end
            end
            default:                              begin wtrans_nxt_state = W_STATE_IDLE; end
        endcase 
    end


    // Generate Output Signals
    assign axi_aw_ready = axi_w_valid && axi_aw_valid && (axi_aw_len == 8'd0) && (axi_aw_size == 3'b011) && (axi_aw_burst == 2'b01);
    assign axi_w_ready  = axi_w_valid && axi_aw_valid && axi_w_last;

    reg [`AXI_xID_BUS] b_id_reg;
    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            b_id_reg    <= 4'd0;
        end
        else if (csr_mtimecmp_ena|csr_mtime_ena) begin
            b_id_reg    <= axi_aw_id;
        end
    end

    assign axi_b_id    = (wtrans_state == W_STATE_RESP) ? b_id_reg : 4'd0;
    assign axi_b_valid = (wtrans_state == W_STATE_RESP);
    assign axi_b_resp  = 2'b00;


                                       
    //-------------------  Read Transaction Control  -------------------
    parameter [1:0] R_STATE_IDLE = 2'b00, R_STATE_ADDR = 2'b01, R_STATE_DATA = 2'b10;
    reg [1:0] rtrans_state, rtrans_nxt_state;

    // State Transition
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            rtrans_state <= R_STATE_IDLE;
        end
        else begin
            rtrans_state <= rtrans_nxt_state;
        end 
    end

    // Generate Next State

    wire ar_handshake = axi_ar_ready && axi_ar_valid && (axi_ar_len == 8'd0) && (axi_ar_size == 3'b011) && (axi_ar_burst == 2'b01);
    wire r_handshake  = axi_r_ready  && axi_r_valid;
    always @(*) begin
        case (rtrans_state)
            R_STATE_IDLE: begin
                if(ar_handshake)      begin rtrans_nxt_state = R_STATE_DATA; end
                else if(axi_ar_valid) begin rtrans_nxt_state = R_STATE_ADDR; end
                else                  begin rtrans_nxt_state = R_STATE_IDLE; end
            end                       
                                      
            R_STATE_ADDR: begin       
                if(ar_handshake)      begin rtrans_nxt_state = R_STATE_DATA; end
                else                  begin rtrans_nxt_state = R_STATE_ADDR; end
            end
            R_STATE_DATA: begin
                if(r_handshake)       begin rtrans_nxt_state = R_STATE_IDLE; end
                else                  begin rtrans_nxt_state = R_STATE_DATA; end
            end
            default:                  begin rtrans_nxt_state = R_STATE_IDLE; end
        endcase       
    end

    wire mtime_rd_ena = ar_handshake && ( axi_ar_addr == `MTIME_ADDR );
    wire mtimecmp_rd_ena = ar_handshake && ( axi_ar_addr == `MTIMECMP_ADDR );

    reg [`RegBus] r_data_reg;
    reg [3:0] r_id_reg;
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            r_data_reg    <= 64'd0;
            r_id_reg      <= 4'b0000;
        end
        else if(mtime_rd_ena | mtimecmp_rd_ena)begin
            r_data_reg    <= mtime_rd_ena ? csr_mtime : csr_mtimecmp;
            r_id_reg      <= axi_ar_id;
        end
    end

    // Generate Output Signals
    assign axi_ar_ready = (rtrans_state == R_STATE_ADDR) | (rtrans_state == R_STATE_IDLE);

    assign axi_r_valid  = (rtrans_state == R_STATE_DATA);                    
    assign axi_r_id     = (rtrans_state == R_STATE_DATA) ? r_id_reg   : 4'd0;
    assign axi_r_data   = (rtrans_state == R_STATE_DATA) ? r_data_reg : 64'd0;
    assign axi_r_resp   = 2'b00;
    assign axi_r_last   = (rtrans_state == R_STATE_DATA) ? 1'b1       : 1'b0;

    //---------------  Timer Interrupt Signal    ---------------
    assign timer_intr  = (csr_mtime >= csr_mtimecmp);

endmodule




