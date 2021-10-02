`include "defines.v"

// Access permissions
`define AXI_PROT_UNPRIVILEGED_ACCESS                        3'b000
`define AXI_PROT_PRIVILEGED_ACCESS                          3'b001
`define AXI_PROT_SECURE_ACCESS                              3'b000
`define AXI_PROT_NON_SECURE_ACCESS                          3'b010
`define AXI_PROT_DATA_ACCESS                                3'b000
`define AXI_PROT_INSTRUCTION_ACCESS                         3'b100

// Memory types (AR)
`define AXI_ARCACHE_DEVICE_NON_BUFFERABLE                   4'b0000
`define AXI_ARCACHE_DEVICE_BUFFERABLE                       4'b0001
`define AXI_ARCACHE_NORMAL_NON_CACHEABLE_NON_BUFFERABLE     4'b0010
`define AXI_ARCACHE_NORMAL_NON_CACHEABLE_BUFFERABLE         4'b0011
`define AXI_ARCACHE_WRITE_THROUGH_NO_ALLOCATE               4'b1010
`define AXI_ARCACHE_WRITE_THROUGH_READ_ALLOCATE             4'b1110
`define AXI_ARCACHE_WRITE_THROUGH_WRITE_ALLOCATE            4'b1010
`define AXI_ARCACHE_WRITE_THROUGH_READ_AND_WRITE_ALLOCATE   4'b1110
`define AXI_ARCACHE_WRITE_BACK_NO_ALLOCATE                  4'b1011
`define AXI_ARCACHE_WRITE_BACK_READ_ALLOCATE                4'b1111
`define AXI_ARCACHE_WRITE_BACK_WRITE_ALLOCATE               4'b1011
`define AXI_ARCACHE_WRITE_BACK_READ_AND_WRITE_ALLOCATE      4'b1111

// Memory types (AW)
`define AXI_AWCACHE_DEVICE_NON_BUFFERABLE                   4'b0000
`define AXI_AWCACHE_DEVICE_BUFFERABLE                       4'b0001
`define AXI_AWCACHE_NORMAL_NON_CACHEABLE_NON_BUFFERABLE     4'b0010
`define AXI_AWCACHE_NORMAL_NON_CACHEABLE_BUFFERABLE         4'b0011
`define AXI_AWCACHE_WRITE_THROUGH_NO_ALLOCATE               4'b0110
`define AXI_AWCACHE_WRITE_THROUGH_READ_ALLOCATE             4'b0110
`define AXI_AWCACHE_WRITE_THROUGH_WRITE_ALLOCATE            4'b1110
`define AXI_AWCACHE_WRITE_THROUGH_READ_AND_WRITE_ALLOCATE   4'b1110
`define AXI_AWCACHE_WRITE_BACK_NO_ALLOCATE                  4'b0111
`define AXI_AWCACHE_WRITE_BACK_READ_ALLOCATE                4'b0111
`define AXI_AWCACHE_WRITE_BACK_WRITE_ALLOCATE               4'b1111
`define AXI_AWCACHE_WRITE_BACK_READ_AND_WRITE_ALLOCATE      4'b1111

module biu (
    
    // Global AXI Signals
    input wire aclk,
    input wire aresetn,

    //---------- CPU Interface Signals ----------
    // signals from if module
    input wire [`InstAddrBus]  if_inst_addr,
    input wire                 if_inst_ena,
    input wire                 if_inst_ready,

    output wire                if_inst_valid,
    output wire [`InstBus]     if_inst,

    // signals from mem module
    input wire [`DataAddrBus]  mem_data_addr,

    input wire [7:0]           mem_wmask,
    input wire [`DataBus]      mem_wdata,
    input wire                 mem_we,
    output wire                mem_wfinish,

    output wire [`DataBus]     mem_rdata,
    input wire                 mem_re,
    output wire                mem_rfinish,
    

    //----------- AXI Interface Signals ----------
    // write address channel
    output wire [`AXI_AxID_BUS]      axi_aw_id,
    output wire [`AXI_AxADDR_BUS]    axi_aw_addr,
    output wire [`AXI_AxLEN_BUS]     axi_aw_len,
    output wire [`AXI_AxSIZE_BUS]    axi_aw_size,
    output wire [`AXI_AxBURST_BUS]   axi_aw_burst,
    //output wire                      axi_aw_lock,
    output wire [`AXI_AxCACHE_BUS]   axi_aw_cache,
    output wire [`AXI_AxPROT_BUS]    axi_aw_prot,
    output wire [`AXI_AxQOS_BUS]     axi_aw_qos,
    //output wire [`AXI_AxREGION_BUS]  axi_aw_region,
    //output wire                      axi_aw_user    
    output wire                      axi_aw_valid,
    input  wire                      axi_aw_ready,

    // write data channel
    output wire [`AXI_xDATA_BUS]     axi_w_data,
    output wire [`AXI_WSTRB_BUS]     axi_w_strb,
    output wire                      axi_w_last,
    //output wire                    axi_w_user
    output wire                      axi_w_valid,
    input  wire                      axi_w_ready,

    // write response channel
    input wire [`AXI_xID_BUS]        axi_b_id,
    input wire [`AXI_xRESP_BUS]      axi_b_resp,
    //input wire                     axi_b_user
    input  wire                      axi_b_valid,
    output wire                      axi_b_ready,

    // read address channel
    output wire [`AXI_AxID_BUS]      axi_ar_id,
    output wire [`AXI_AxADDR_BUS]    axi_ar_addr,
    output wire [`AXI_AxLEN_BUS]     axi_ar_len,
    output wire [`AXI_AxSIZE_BUS]    axi_ar_size,
    output wire [`AXI_AxBURST_BUS]   axi_ar_burst,
    //output wire                    axi_ar_lock,
    output wire [`AXI_AxCACHE_BUS]   axi_ar_cache,
    output wire [`AXI_AxPROT_BUS]    axi_ar_prot,
    output wire [`AXI_AxQOS_BUS]     axi_ar_qos,
    //output wire [`AXI_AxREGION_BUS]  axi_ar_region,
    //output wire                    axi_aw_user    
    output wire                      axi_ar_valid,
    input  wire                      axi_ar_ready,

    // read data channel
    input wire [`AXI_xID_BUS]        axi_r_id,
    input wire [`AXI_xDATA_BUS]      axi_r_data,
    input wire [`AXI_xRESP_BUS]      axi_r_resp,
    input wire                       axi_r_last,
    //input wire                     axi_r_user
    input wire                       axi_r_valid,
    output wire                      axi_r_ready

    );

    //-------------------- MMIO Address Recognition --------------------
    wire if_access_uart, if_access_spi_ctrl, if_access_spi_flash;
    wire mem_access_uart, mem_access_spi_ctrl, mem_access_spi_flash;

    assign if_access_uart       = (if_inst_addr >= `UART_ADDR_START) && (if_inst_addr <= `UART_ADDR_END);
    assign if_access_spi_ctrl   = (if_inst_addr >= `SPI_CTRL_START ) && (if_inst_addr <= `SPI_CTRL_END );
    assign if_access_spi_flash  = (if_inst_addr >= `SPI_FLASH_START) && (if_inst_addr <= `SPI_FLASH_END);

    assign mem_access_uart      = (mem_data_addr >= `UART_ADDR_START) && (mem_data_addr <= `UART_ADDR_END);
    assign mem_access_spi_ctrl  = (mem_data_addr >= `SPI_CTRL_START ) && (mem_data_addr <= `SPI_CTRL_END );
    assign mem_access_spi_flash = (mem_data_addr >= `SPI_FLASH_START) && (mem_data_addr <= `SPI_FLASH_END);

    wire if_access_apb  = (if_access_spi_ctrl  | if_access_spi_flash  | if_access_uart );
    wire mem_access_apb = (mem_access_spi_ctrl | mem_access_spi_flash | mem_access_uart);

    //-------------------- Write Transaction Control --------------------

    parameter [1:0] W_STATE_IDLE = 2'b00, W_STATE_INFO = 2'b01, W_STATE_RESP = 2'b11;
    reg [1:0] wtrans_state, wtrans_nxt_state;

    wire aw_handshake = axi_aw_valid && axi_aw_ready;
    wire w_handshake  = axi_w_valid  && axi_w_ready;
    wire b_handshake  = axi_b_valid  && axi_b_ready && (axi_b_id == 4'b0000);
    wire b_success    = b_handshake  && (axi_b_resp == 2'b00);

    // generate next state
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

    // state transition
    always @(posedge aclk) begin
        if(~aresetn) begin
            wtrans_state <= W_STATE_IDLE;
        end
        else begin
            wtrans_state <= wtrans_nxt_state;
        end
    end

    // generate output signals

    assign axi_aw_id     =  4'b0000;
    assign axi_aw_len    =  7'd0;
    assign axi_aw_size   =  mem_access_apb ? `AXI_SIZE_BYTES_4 : `AXI_SIZE_BYTES_8;  
    assign axi_aw_burst  =  `AXI_BURST_TYPE_INCR;
    assign axi_aw_cache  =  `AXI_AWCACHE_NORMAL_NON_CACHEABLE_NON_BUFFERABLE;
    assign axi_aw_prot   =  `AXI_PROT_UNPRIVILEGED_ACCESS | `AXI_PROT_SECURE_ACCESS | `AXI_PROT_DATA_ACCESS;
    assign axi_aw_qos    =  4'h0;

    wire [63:0] aw_addr_temp = mem_access_apb ? {mem_data_addr[63:0]}:{mem_data_addr[63:3],3'b000};
    assign axi_aw_valid  = (wtrans_state == W_STATE_IDLE|wtrans_state==W_STATE_INFO) ? mem_we: 1'b0;
    assign axi_aw_addr   = (wtrans_state == W_STATE_IDLE|wtrans_state==W_STATE_INFO) ? aw_addr_temp:`ZeroWord;


    assign axi_w_last    = 1'b1;
    //assign axi_w_user  = 0;
    assign axi_w_valid   = (wtrans_state == W_STATE_IDLE|wtrans_state==W_STATE_INFO) ? mem_we: 1'b0;
    assign axi_w_data    = (wtrans_state == W_STATE_IDLE|wtrans_state==W_STATE_INFO) ? mem_wdata:`ZeroWord;

    assign axi_w_strb    = (wtrans_state == W_STATE_IDLE|wtrans_state == W_STATE_INFO) ? mem_wmask : 8'h00;

    assign axi_b_ready   = 1'b1;

    // mem_wfinish signal to mem
    assign mem_wfinish   = (wtrans_state == W_STATE_RESP) && b_handshake;



    //-------------------- Read Transaction Control --------------------


    parameter R_STATE_IDLE = 2'b00, R_STATE_ADDR = 2'b01, R_STATE_DATA = 2'b10 ;
    reg [1:0] mem_rtrans_state, mem_rtrans_nxt_state;
    reg [1:0] if_rtrans_state,if_rtrans_nxt_state;

    wire mem_ar_handshake = mem_ar_valid && axi_ar_ready;
    wire if_ar_handshake  = if_ar_valid  && axi_ar_ready;

    wire r_handshake = axi_r_valid && axi_r_ready;
    wire mem_r_handshake;
    assign mem_r_handshake = axi_r_valid  && axi_r_ready && (axi_r_id == 4'b0001);
    wire mem_r_success = mem_r_handshake && (axi_r_resp == 2'b00);

    wire if_r_handshake;
    assign if_r_handshake = r_handshake && (axi_r_id == 4'b0000);
    wire if_r_success = if_r_handshake  && (axi_r_resp == 2'b00);
    

    //generate mem_rtrans_nxt_state
    always @(*) begin
        case (mem_rtrans_state)
            R_STATE_IDLE: begin
                if(mem_ar_handshake)      begin mem_rtrans_nxt_state = R_STATE_DATA; end
                else if(mem_ar_valid)     begin mem_rtrans_nxt_state = R_STATE_ADDR; end
                else                      begin mem_rtrans_nxt_state = R_STATE_IDLE; end
            end 
            R_STATE_ADDR: begin
                if(mem_ar_handshake)      begin mem_rtrans_nxt_state = R_STATE_DATA; end
                else                      begin mem_rtrans_nxt_state = R_STATE_ADDR; end
                
            end
            R_STATE_DATA: begin
                if(mem_r_handshake && axi_r_last) begin
                    mem_rtrans_nxt_state = R_STATE_IDLE;
                end
                else begin
                    mem_rtrans_nxt_state = R_STATE_DATA;
                end
            end
            default: mem_rtrans_nxt_state = R_STATE_IDLE;
        endcase        
    end
    //generate if_rtrans_nxt_state
    always @(*) begin
        case (if_rtrans_state)
            R_STATE_IDLE: begin
                if(if_ar_handshake)      begin if_rtrans_nxt_state = R_STATE_DATA; end
                else if(if_ar_valid)     begin if_rtrans_nxt_state = R_STATE_ADDR; end
                else                     begin if_rtrans_nxt_state = R_STATE_IDLE; end
            end 
            R_STATE_ADDR: begin
                if(if_ar_handshake)      begin if_rtrans_nxt_state = R_STATE_DATA;  end
                else                     begin if_rtrans_nxt_state = R_STATE_ADDR;  end
            end
            R_STATE_DATA: begin
                if(if_r_handshake && axi_r_last) begin
                    if_rtrans_nxt_state = R_STATE_IDLE;
                end
                else begin
                    if_rtrans_nxt_state = R_STATE_DATA;
                end
            end
            default: begin if_rtrans_nxt_state = R_STATE_IDLE; end
        endcase        
    end

    // state transition
    always @(posedge aclk) begin
        if(~aresetn) begin
            mem_rtrans_state <= R_STATE_IDLE;
        end
        else begin
            mem_rtrans_state <= mem_rtrans_nxt_state;
        end   
    end

    always @(posedge aclk) begin
        if(~aresetn) begin
            if_rtrans_state <= R_STATE_IDLE;
        end
        else begin
            if_rtrans_state <= if_rtrans_nxt_state;
        end 
    end


    // generate output signals

    wire mem_ar_valid   = (if_rtrans_state != R_STATE_ADDR) && (mem_rtrans_state != R_STATE_DATA) && mem_re;
    wire if_ar_valid    = ~mem_ar_valid && (if_rtrans_state != R_STATE_DATA) && if_inst_ena && ~if_inst_valid_reg;
    assign axi_ar_valid = mem_ar_valid | if_ar_valid;

    // read address channel output
    assign axi_ar_id    = mem_ar_valid ? 4'b0001 : (if_ar_valid ? 4'b0000 : 4'b0000);

    wire [63:0] data_addr_temp = mem_access_apb ? {mem_data_addr[63:0]} : {mem_data_addr[63:3],3'b000};
    wire [63:0] inst_addr_temp =  if_access_apb ? { if_inst_addr[63:0]} : { if_inst_addr[63:3],3'b000};

    assign axi_ar_addr  = mem_ar_valid ? data_addr_temp : (if_ar_valid ? inst_addr_temp : 64'd0);
    assign axi_ar_len   = 7'd0;
    assign axi_ar_size  = ( (mem_ar_valid & mem_access_apb)|(if_ar_valid & if_access_apb) ) ? `AXI_SIZE_BYTES_4: `AXI_SIZE_BYTES_8;
    assign axi_ar_burst = `AXI_BURST_TYPE_INCR;

    assign axi_ar_cache = `AXI_ARCACHE_NORMAL_NON_CACHEABLE_NON_BUFFERABLE;
    assign axi_ar_prot  = `AXI_PROT_UNPRIVILEGED_ACCESS | `AXI_PROT_SECURE_ACCESS | `AXI_PROT_DATA_ACCESS;
    assign axi_ar_qos   = 4'h0;

    // read data channel output
    assign axi_r_ready = 1'b1;


    // signals to mem and if
    assign mem_rfinish = mem_r_handshake ;
    assign mem_rdata   = axi_r_data ;


    wire [`InstBus] if_inst_temp;
    wire if_inst_valid_temp;
    assign if_inst_temp = if_inst_addr[2] ? axi_r_data[63:32]:axi_r_data[31:0];
    assign if_inst_valid_temp = if_r_handshake;

    reg [31:0] if_inst_reg;
    reg if_inst_valid_reg;
    always @(posedge aclk) begin
        if(if_inst_valid_temp && ~if_inst_ready) begin
            if_inst_reg        <= if_inst_temp;
            if_inst_valid_reg  <= if_inst_valid_temp;
        end
        else if(if_inst_ready && if_inst_valid) begin
            if_inst_reg        <= 32'd0;
            if_inst_valid_reg  <= 1'b0;
        end
        else begin
            if_inst_reg        <= if_inst_reg;
            if_inst_valid_reg  <= if_inst_valid_reg;
        end
    end

    assign if_inst = if_inst_valid_temp ? if_inst_temp :
                     if_inst_valid_reg  ? if_inst_reg  :
                                                32'd0  ;
    assign if_inst_valid = if_inst_valid_reg | if_inst_valid_temp;

endmodule

