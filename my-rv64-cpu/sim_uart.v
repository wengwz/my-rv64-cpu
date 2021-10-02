`include "defines.v"
`define THR_ADDR 32'h1000_0000
`define RHR_ADDR 32'h1000_0000
`define LSR_ADDR 32'h1000_0005
module sim_uart (
    input clk,
    input rst,

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
    input wire                        axi_r_ready
    );


    // transmitter hold register
    reg  [7:0] transmitter_hold_reg;
    wire [7:0] thr_nxt_value;
    wire thr_ena;

    assign thr_nxt_value = thr_ena ? axi_w_data[7:0] : 8'd0;
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            transmitter_hold_reg <= 8'd0;
        end
        else begin
            transmitter_hold_reg <= thr_nxt_value;
        end
    end
    
    // line state register
    wire [7:0] line_status_reg;

    reg lsr_thre;
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            lsr_thre <=  1'b1;
        end
        else begin
            if(aw_handshake && w_handshake) begin
                lsr_thre <=  1'b0;
            end
            else begin
                lsr_thre <= 1'b1;
            end
        end
    end

    wire lsr_dr;
    assign lsr_dr = 1'b0;

    assign line_status_reg[0]   = lsr_dr;
    assign line_status_reg[4:1] = 4'b0000;
    assign line_status_reg[5]   = lsr_thre;
    assign line_status_reg[7:6] = 2'b00;

    // receiver hold register
    reg [7:0] receiver_hold_reg;
    always @(posedge clk) begin
        receiver_hold_reg <= 0;
    end


    //-------------------- Write Transaction --------------------
    // Wtrans State Machine
    parameter [1:0] W_STATE_IDLE = 2'b00, W_STATE_INFO = 2'b01, W_STATE_RESP = 2'b10;
    reg [1:0] wtrans_state, wtrans_nxt_state;

    // state transition
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            wtrans_state <= W_STATE_IDLE;
        end
        else begin
            wtrans_state <= wtrans_nxt_state;
        end 
    end
    // generate nxt state
    wire aw_handshake = axi_aw_ready && axi_aw_valid;
    wire w_handshake  = axi_w_ready  && axi_w_valid;
    wire b_handshake  = axi_b_valid  && axi_b_ready;
    assign thr_ena    = aw_handshake && w_handshake && axi_w_strb[0];


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


    // generate output signals   
    assign axi_aw_ready = axi_aw_valid && axi_w_valid;
    assign axi_w_ready  = axi_aw_ready;

    reg [`AXI_xID_BUS] wtrans_id;
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            wtrans_id <= 0;
        end
        else if(aw_handshake) begin
            wtrans_id <= axi_aw_id;
        end
    end
    assign axi_b_id = (wtrans_state == W_STATE_RESP) ? wtrans_id : 4'b0000;
    assign axi_b_valid = (wtrans_state == W_STATE_RESP );
    assign axi_b_resp  = 2'b00;


    //-------------------- Read Transaction ---------------
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

    wire ar_handshake = axi_ar_ready && axi_ar_valid;
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

    wire [`RegBus] r_data_temp;
    assign r_data_temp [7 : 0] = receiver_hold_reg;
    assign r_data_temp [15: 8] = 0;
    assign r_data_temp [23:16] = 0;
    assign r_data_temp [31:24] = 0;
    assign r_data_temp [39:32] = 0;
    assign r_data_temp [47:40] = line_status_reg;
    assign r_data_temp [55:48] = 0;
    assign r_data_temp [63:56] = 0;


    reg  [`RegBus] r_data_reg;
    reg [3:0] r_id_reg;
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            r_data_reg    <= 64'd0;
            r_id_reg      <= 4'b0000;
        end
        else if(ar_handshake)begin
            r_data_reg    <= r_data_temp;
            r_id_reg      <= axi_ar_id  ;
        end
    end

    // Generate Output Signals
    assign axi_ar_ready = (rtrans_state == R_STATE_ADDR) | (rtrans_state == R_STATE_IDLE);

    assign axi_r_valid  = (rtrans_state == R_STATE_DATA);                    
    assign axi_r_id     = (rtrans_state == R_STATE_DATA) ? r_id_reg   : 4'd0;
    assign axi_r_data   = (rtrans_state == R_STATE_DATA) ? r_data_reg : 64'd0;
    assign axi_r_resp   = 2'b00;
    assign axi_r_last   = (rtrans_state == R_STATE_DATA) ? 1'b1       : 1'b0;

    //-------------------- Implement UART Function --------------------


    // output function
    always @(posedge clk) begin
        if(lsr_thre == 1'b0) begin
            $write("%c",transmitter_hold_reg);
        end
    end
    // input function
endmodule