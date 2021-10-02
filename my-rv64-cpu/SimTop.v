`include "defines.v"
`include "rvcpu.v"
`include "biu.v"
`include "clint.v"
`include "axi_splt.v"
`include "sim_uart.v"
`define AXI_TOP_INTERFACE(name) io_memAXI_0_``name

module SimTop (
    input         clock,
    input         reset,

    input  [63:0] io_logCtrl_log_begin,
    input  [63:0] io_logCtrl_log_end,
    input  [63:0] io_logCtrl_log_level,
    input         io_perfInfo_clean,
    input         io_perfInfo_dump,

    output        io_uart_out_valid,
    output [7:0]  io_uart_out_ch,
    output        io_uart_in_valid,
    input  [7:0]  io_uart_in_ch,

    // write address channel
    input                               `AXI_TOP_INTERFACE(aw_ready),
    output                              `AXI_TOP_INTERFACE(aw_valid),
    output [`AXI_AxADDR_BUS]            `AXI_TOP_INTERFACE(aw_bits_addr),
    output [2:0]                        `AXI_TOP_INTERFACE(aw_bits_prot),
    output [`AXI_AxID_BUS]              `AXI_TOP_INTERFACE(aw_bits_id),
    output                              `AXI_TOP_INTERFACE(aw_bits_user),
    output [7:0]                        `AXI_TOP_INTERFACE(aw_bits_len),
    output [2:0]                        `AXI_TOP_INTERFACE(aw_bits_size),
    output [1:0]                        `AXI_TOP_INTERFACE(aw_bits_burst),
    output                              `AXI_TOP_INTERFACE(aw_bits_lock),
    output [3:0]                        `AXI_TOP_INTERFACE(aw_bits_cache),
    output [3:0]                        `AXI_TOP_INTERFACE(aw_bits_qos),
    // write data channel
    input                               `AXI_TOP_INTERFACE(w_ready),
    output                              `AXI_TOP_INTERFACE(w_valid),
    output [`AXI_xDATA_BUS]             `AXI_TOP_INTERFACE(w_bits_data)         [3:0],
    output [`AXI_WSTRB_BUS]             `AXI_TOP_INTERFACE(w_bits_strb),
    output                              `AXI_TOP_INTERFACE(w_bits_last),
    // write response channel
    output                              `AXI_TOP_INTERFACE(b_ready),
    input                               `AXI_TOP_INTERFACE(b_valid),
    input  [1:0]                        `AXI_TOP_INTERFACE(b_bits_resp),
    input  [`AXI_xID_BUS]               `AXI_TOP_INTERFACE(b_bits_id),
    input                               `AXI_TOP_INTERFACE(b_bits_user),
    // read address channel
    input                               `AXI_TOP_INTERFACE(ar_ready),
    output                              `AXI_TOP_INTERFACE(ar_valid),
    output [`AXI_AxADDR_BUS]            `AXI_TOP_INTERFACE(ar_bits_addr),
    output [2:0]                        `AXI_TOP_INTERFACE(ar_bits_prot),
    output [`AXI_AxID_BUS]              `AXI_TOP_INTERFACE(ar_bits_id),
    output                              `AXI_TOP_INTERFACE(ar_bits_user),
    output [7:0]                        `AXI_TOP_INTERFACE(ar_bits_len),
    output [2:0]                        `AXI_TOP_INTERFACE(ar_bits_size),
    output [1:0]                        `AXI_TOP_INTERFACE(ar_bits_burst),
    output                              `AXI_TOP_INTERFACE(ar_bits_lock),
    output [3:0]                        `AXI_TOP_INTERFACE(ar_bits_cache),
    output [3:0]                        `AXI_TOP_INTERFACE(ar_bits_qos),

    //read data channel 
    output                              `AXI_TOP_INTERFACE(r_ready),
    input                               `AXI_TOP_INTERFACE(r_valid),
    input  [1:0]                        `AXI_TOP_INTERFACE(r_bits_resp),
    input  [`AXI_xDATA_BUS]             `AXI_TOP_INTERFACE(r_bits_data)         [3:0],
    input                               `AXI_TOP_INTERFACE(r_bits_last),
    input  [`AXI_xID_BUS]               `AXI_TOP_INTERFACE(r_bits_id),
    input                               `AXI_TOP_INTERFACE(r_bits_user)
    );

    // if bus
    wire [`InstAddrBus]  inst_addr;
    wire [`InstBus]      inst;
    wire                 inst_ena;
    wire                 inst_valid;
    wire                 inst_ready;

    // mem bus
    wire [`DataAddrBus]  data_addr;
    wire [`DataBus]      rdata;
    wire [`DataBus]      wdata;
    wire [7:0]           wmask;
    wire                 re;
    wire                 we;
    wire                 mem_rfinish;
    wire                 mem_wfinish;

//
    rvcpu rvcpu0(
        .clk(clock),
        .rst(reset),

        //inst bus
        .inst(inst),
        .inst_addr(inst_addr),
        .inst_ena(inst_ena),
        .inst_ready(inst_ready),
        .biu_inst_valid(inst_valid),

        //data bus
        .data_addr(data_addr),
        .wmask(wmask),
        .data_o(wdata),
        .data_i(rdata),
        .we(we),
        .re(re),
        .mem_finish(mem_rfinish|mem_wfinish),

        //interrupt signal
        .timer_intr(timer_intr)
    );
//

//
    biu biu0 (
    // Global core Signals
        .aclk(clock),
        .aresetn(~reset),

    //---------- CPU Interface Signals ----------
    // signals from if module
        .if_inst_addr(inst_addr),
        .if_inst_ena(inst_ena),
        .if_inst_ready(inst_ready),

        .if_inst_valid(inst_valid),
        .if_inst(inst),

    // signals from mem module
        .mem_data_addr(data_addr),

        .mem_wmask(wmask),
        .mem_wdata(wdata),
        .mem_we(we),
        .mem_wfinish(mem_wfinish),

        .mem_rdata(rdata),
        .mem_re(re),
        .mem_rfinish(mem_rfinish),
    

    //----------- AXI Interface Signals ----------
    // write address channel        
        .axi_aw_valid(core_aw_valid),
        .axi_aw_ready(core_aw_ready),
        .axi_aw_id(core_aw_id),
        .axi_aw_addr(core_aw_addr),
        .axi_aw_len(core_aw_len),
        .axi_aw_size(core_aw_size),
        .axi_aw_burst(core_aw_burst),
        .axi_aw_cache(core_aw_cache),
        .axi_aw_prot(core_aw_prot),
        .axi_aw_qos(core_aw_qos),

    // write data channel
        .axi_w_data(core_w_data),
        .axi_w_strb(core_w_strb),
        .axi_w_last(core_w_last),
        .axi_w_valid(core_w_valid),
        .axi_w_ready(core_w_ready),

    // write response channel
        .axi_b_id(core_b_id),
        .axi_b_resp(core_b_resp),
        .axi_b_valid(core_b_valid),
        .axi_b_ready(core_b_ready),

    // read address channel
        .axi_ar_valid(core_ar_valid),
        .axi_ar_ready(core_ar_ready),
        .axi_ar_id(core_ar_id),
        .axi_ar_addr(core_ar_addr),
        .axi_ar_len(core_ar_len),
        .axi_ar_size(core_ar_size),
        .axi_ar_burst(core_ar_burst),

        .axi_ar_cache(core_ar_cache),
        .axi_ar_prot(core_ar_prot),
        .axi_ar_qos(core_ar_qos),

    // read data channel
        .axi_r_id(core_r_id),
        .axi_r_data(core_r_data),
        .axi_r_resp(core_r_resp),
        .axi_r_last(core_r_last),
        .axi_r_valid(core_r_valid),
        .axi_r_ready(core_r_ready)

    );
//


    wire [`AXI_AxID_BUS]        clint_aw_id;
    wire [`AXI_AxADDR_BUS]      clint_aw_addr;
    wire [`AXI_AxLEN_BUS]       clint_aw_len;
    wire [`AXI_AxSIZE_BUS]      clint_aw_size;
    wire [`AXI_AxBURST_BUS]     clint_aw_burst;
    wire [`AXI_AxCACHE_BUS]     clint_aw_cache;
    wire [`AXI_AxPROT_BUS]      clint_aw_prot;
    wire [`AXI_AxQOS_BUS]       clint_aw_qos;
    wire                        clint_aw_valid;
    wire                        clint_aw_ready;
    // write data channel   
    wire [`AXI_xDATA_BUS]       clint_w_data;
    wire [`AXI_WSTRB_BUS]       clint_w_strb;
    wire                        clint_w_last;
    wire                        clint_w_valid;
    wire                        clint_w_ready;
    // write response channel 
    wire [`AXI_xID_BUS]         clint_b_id;
    wire [`AXI_xRESP_BUS]       clint_b_resp;
    wire                        clint_b_valid;
    wire                        clint_b_ready;
    // read address channel  
    wire [`AXI_AxID_BUS]        clint_ar_id;
    wire [`AXI_AxADDR_BUS]      clint_ar_addr;
    wire [`AXI_AxLEN_BUS]       clint_ar_len;
    wire [`AXI_AxSIZE_BUS]      clint_ar_size;
    wire [`AXI_AxBURST_BUS]     clint_ar_burst;
    wire [`AXI_AxCACHE_BUS]     clint_ar_cache;
    wire [`AXI_AxPROT_BUS]      clint_ar_prot;
    wire [`AXI_AxQOS_BUS]       clint_ar_qos;
    wire                        clint_ar_valid;
    wire                        clint_ar_ready;
    // read data channel  
    wire [`AXI_xID_BUS]         clint_r_id;
    wire [`AXI_xDATA_BUS]       clint_r_data;
    wire [`AXI_xRESP_BUS]       clint_r_resp;
    wire                        clint_r_last;
    wire                        clint_r_valid;
    wire                        clint_r_ready;
    //--------------- Interrupt Signals ---------------
    wire                        timer_intr;

// clint instantiation
    clint clint0 (
        .clk(clock),
        .rst(reset),
    //----------- AXI Interface Signals ----------
    // write address channel (slave)
        .axi_aw_id   (clint_aw_id   ),
        .axi_aw_addr (clint_aw_addr ),
        .axi_aw_len  (clint_aw_len  ),
        .axi_aw_size (clint_aw_size ),
        .axi_aw_burst(clint_aw_burst),
        .axi_aw_cache(clint_aw_cache),
        .axi_aw_prot (clint_aw_prot ),
        .axi_aw_qos  (clint_aw_qos  ),
        .axi_aw_valid(clint_aw_valid),
        .axi_aw_ready(clint_aw_ready),

    // write data channel   (slave)
        .axi_w_data  (clint_w_data),
        .axi_w_strb  (clint_w_strb),
        .axi_w_last  (clint_w_last),
        .axi_w_valid (clint_w_valid),
        .axi_w_ready (clint_w_ready),

    // write response channel (slave)
        .axi_b_id    (clint_b_id),
        .axi_b_resp  (clint_b_resp),
        .axi_b_valid (clint_b_valid),
        .axi_b_ready (clint_b_ready),

    // read address channel  (slave)
        .axi_ar_id   (clint_ar_id   ),
        .axi_ar_addr (clint_ar_addr ),
        .axi_ar_len  (clint_ar_len  ),
        .axi_ar_size (clint_ar_size ),
        .axi_ar_burst(clint_ar_burst),
        .axi_ar_cache(clint_ar_cache),
        .axi_ar_prot (clint_ar_prot ),
        .axi_ar_qos  (clint_ar_qos  ),
        .axi_ar_valid(clint_ar_valid),
        .axi_ar_ready(clint_ar_ready),

    // read data channel  (slave)
        .axi_r_id    (clint_r_id    ),
        .axi_r_data  (clint_r_data  ),
        .axi_r_resp  (clint_r_resp  ),
        .axi_r_last  (clint_r_last  ),
        .axi_r_valid (clint_r_valid ),
        .axi_r_ready (clint_r_ready ),
    
    //--------------- Interrupt Signals ---------------
        .timer_intr  (timer_intr    )
    );
//


// connections between core and splitter
    // write address channel
    wire [`AXI_AxID_BUS]        core_aw_id;
    wire [`AXI_AxADDR_BUS]      core_aw_addr;
    wire [`AXI_AxLEN_BUS]       core_aw_len;
    wire [`AXI_AxSIZE_BUS]      core_aw_size;
    wire [`AXI_AxBURST_BUS]     core_aw_burst;
    wire [`AXI_AxCACHE_BUS]     core_aw_cache;
    wire [`AXI_AxPROT_BUS]      core_aw_prot;
    wire [`AXI_AxQOS_BUS]       core_aw_qos;
    wire                        core_aw_valid;
    wire                        core_aw_ready;
    // write data channel  
    wire [`AXI_xDATA_BUS]       core_w_data;
    wire [`AXI_WSTRB_BUS]       core_w_strb;
    wire                        core_w_last;
    wire                        core_w_valid;
    wire                        core_w_ready;
    // write response channel 
    wire [`AXI_xID_BUS]         core_b_id;
    wire [`AXI_xRESP_BUS]       core_b_resp;
    wire                        core_b_valid;
    wire                        core_b_ready;
    // read address channel  
    wire [`AXI_AxID_BUS]        core_ar_id;
    wire [`AXI_AxADDR_BUS]      core_ar_addr;
    wire [`AXI_AxLEN_BUS]       core_ar_len;
    wire [`AXI_AxSIZE_BUS]      core_ar_size;
    wire [`AXI_AxBURST_BUS]     core_ar_burst;
    wire [`AXI_AxCACHE_BUS]     core_ar_cache;
    wire [`AXI_AxPROT_BUS]      core_ar_prot;
    wire [`AXI_AxQOS_BUS]       core_ar_qos;
    wire                        core_ar_valid;
    wire                        core_ar_ready;
    // read data channel  
    wire [`AXI_xID_BUS]         core_r_id;
    wire [`AXI_xDATA_BUS]       core_r_data;
    wire [`AXI_xRESP_BUS]       core_r_resp;
    wire                        core_r_last;
    wire                        core_r_valid;
    wire                        core_r_ready;
//


// connections between splitter and perips
    // write address channel
    wire [2:0] w_splt_indic, r_splt_indic;

    wire [ 4*3-1   :0]   s_aw_id_bus;
    wire [64*3-1   :0]   s_aw_addr_bus;
    wire [ 8*3-1   :0]   s_aw_len_bus;
    wire [ 3*3-1   :0]   s_aw_size_bus;
    wire [ 2*3-1   :0]   s_aw_burst_bus;
    wire [ 4*3-1   :0]   s_aw_cache_bus;
    wire [ 3*3-1   :0]   s_aw_prot_bus;
    wire [ 4*3-1   :0]   s_aw_qos_bus;
    wire [ 1*3-1   :0]   s_aw_valid_bus;
    wire [ 1*3-1   :0]   s_aw_ready_bus;
                                       
                                       
    // write data channel              
    wire [    64*3-1   :0]   s_w_data_bus;
    wire [(64/8)*3-1   :0]   s_w_strb_bus;
    wire [     1*3-1   :0]   s_w_last_bus;
    wire [     1*3-1   :0]   s_w_valid_bus;
    wire [     1*3-1   :0]   s_w_ready_bus;
                                    
    // write response channel 
    wire [4*3-1    :0]   s_b_id_bus;
    wire [2*3-1    :0]   s_b_resp_bus;
    wire [1*3-1    :0]   s_b_valid_bus;
    wire [1*3-1    :0]   s_b_ready_bus;
                                       
    // read address channel            
    wire [ 4*3-1   :0]   s_ar_id_bus;
    wire [64*3-1   :0]   s_ar_addr_bus;
    wire [ 8*3-1   :0]   s_ar_len_bus;
    wire [ 3*3-1   :0]   s_ar_size_bus;
    wire [ 2*3-1   :0]   s_ar_burst_bus;
    wire [ 4*3-1   :0]   s_ar_cache_bus;
    wire [ 3*3-1   :0]   s_ar_prot_bus;
    wire [ 4*3-1   :0]   s_ar_qos_bus;
    wire [ 1*3-1   :0]   s_ar_valid_bus;
    wire [ 1*3-1   :0]   s_ar_ready_bus;

    // read data channel  
    wire [ 4*3-1   :0]   s_r_id_bus;
    wire [64*3-1   :0]   s_r_data_bus;
    wire [ 2*3-1   :0]   s_r_resp_bus;
    wire [ 1*3-1   :0]   s_r_last_bus;
    wire [ 1*3-1   :0]   s_r_valid_bus;
    wire [ 1*3-1   :0]   s_r_ready_bus;

    assign {uart_aw_id   , clint_aw_id   , axi_aw_id   } = s_aw_id_bus   ;
    assign {uart_aw_addr , clint_aw_addr , axi_aw_addr } = s_aw_addr_bus ;
    assign {uart_aw_len  , clint_aw_len  , axi_aw_len  } = s_aw_len_bus  ;
    assign {uart_aw_size , clint_aw_size , axi_aw_size } = s_aw_size_bus ;
    assign {uart_aw_burst, clint_aw_burst, axi_aw_burst} = s_aw_burst_bus;
    assign {uart_aw_cache, clint_aw_cache, axi_aw_cache} = s_aw_cache_bus;
    assign {uart_aw_prot , clint_aw_prot , axi_aw_prot } = s_aw_prot_bus ;
    assign {uart_aw_qos  , clint_aw_qos  , axi_aw_qos  } = s_aw_qos_bus  ;
    assign {uart_aw_valid, clint_aw_valid, axi_aw_valid} = s_aw_valid_bus;
    assign s_aw_ready_bus = {uart_aw_ready, clint_aw_ready, axi_aw_ready};
                                       
                                       
    // write data channel              
    assign {uart_w_data , clint_w_data  , axi_w_data } = s_w_data_bus ;
    assign {uart_w_strb , clint_w_strb  , axi_w_strb } = s_w_strb_bus ;
    assign {uart_w_last , clint_w_last  , axi_w_last } = s_w_last_bus ;
    assign {uart_w_valid, clint_w_valid , axi_w_valid} = s_w_valid_bus;
    assign s_w_ready_bus = {uart_w_ready, clint_w_ready , axi_w_ready};
                                    
    // write response channel 
    assign s_b_id_bus    = {uart_b_id   , clint_b_id   , axi_b_id   };
    assign s_b_resp_bus  = {uart_b_resp , clint_b_resp , axi_b_resp };
    assign s_b_valid_bus = {uart_b_valid, clint_b_valid, axi_b_valid};
    assign {uart_b_ready, clint_b_ready, axi_b_ready} = s_b_ready_bus;
                                       
    // read address channel            
    assign {uart_ar_id    , clint_ar_id   , axi_ar_id   } = s_ar_id_bus   ;
    assign {uart_ar_addr  , clint_ar_addr , axi_ar_addr } = s_ar_addr_bus ;
    assign {uart_ar_len   , clint_ar_len  , axi_ar_len  } = s_ar_len_bus  ;
    assign {uart_ar_size  , clint_ar_size , axi_ar_size } = s_ar_size_bus ;
    assign {uart_ar_burst , clint_ar_burst, axi_ar_burst} = s_ar_burst_bus;
    assign {uart_ar_cache , clint_ar_cache, axi_ar_cache} = s_ar_cache_bus;
    assign {uart_ar_prot  , clint_ar_prot , axi_ar_prot } = s_ar_prot_bus ;
    assign {uart_ar_qos   , clint_ar_qos  , axi_ar_qos  } = s_ar_qos_bus  ;
    assign {uart_ar_valid , clint_ar_valid, axi_ar_valid} = s_ar_valid_bus;
    assign s_ar_ready_bus =  {uart_ar_ready, clint_ar_ready, axi_ar_ready};

    // read data channel  
    assign s_r_id_bus    = {uart_r_id   , clint_r_id   , axi_r_id} ;
    assign s_r_data_bus  = {uart_r_data , clint_r_data , axi_r_data} ;
    assign s_r_resp_bus  = {uart_r_resp , clint_r_resp , axi_r_resp} ;
    assign s_r_last_bus  = {uart_r_last , clint_r_last , axi_r_last} ;
    assign s_r_valid_bus = {uart_r_valid, clint_r_valid, axi_r_valid};
    assign {uart_r_ready, clint_r_ready, axi_r_ready} = s_r_ready_bus;

    assign w_splt_indic[2] = ({core_aw_addr[63:3],3'b000} == `UART_ADDR_START);
    assign w_splt_indic[1] = (core_aw_addr == `MTIMECMP_ADDR) | (core_aw_addr == `MTIME_ADDR);
    assign w_splt_indic[0] = (core_aw_addr != `MTIMECMP_ADDR)  & (core_aw_addr != `MTIME_ADDR) &
                             ({core_aw_addr[63:3],3'b000} != `UART_ADDR_START);


    assign r_splt_indic[2] = ({core_aw_addr[63:3],3'b000} == `UART_ADDR_START);
    assign r_splt_indic[1] = (core_ar_addr == `MTIMECMP_ADDR) | (core_ar_addr == `MTIME_ADDR);
    assign r_splt_indic[0] = (core_ar_addr != `MTIMECMP_ADDR) & (core_ar_addr != `MTIME_ADDR) &
                             ({core_aw_addr[63:3],3'b000} != `UART_ADDR_START);
//


// axi splitter instantiation
    axi_splt#(
        .AW       (64),
        .DW       (64),
        .ID_W     (4),
        .SPLT_NUM (3),
        .SPLT_PTR_W(2)
    )axi_splt0(
        .clk(clock),
        .rst(reset),

        .w_splt_indic(w_splt_indic),
        .r_splt_indic(r_splt_indic),
    //----------- AXI Interface Signals To Or From Master ----------
    // write address channel 
        .m_aw_id   (core_aw_id   ),
        .m_aw_addr (core_aw_addr ),
        .m_aw_len  (core_aw_len  ),
        .m_aw_size (core_aw_size ),
        .m_aw_burst(core_aw_burst),
        .m_aw_cache(core_aw_cache),
        .m_aw_prot (core_aw_prot ),
        .m_aw_qos  (core_aw_qos  ),
        .m_aw_valid(core_aw_valid),
        .m_aw_ready(core_aw_ready),
                                                      
    // write data channel   
        .m_w_data (core_w_data ),
        .m_w_strb (core_w_strb ),
        .m_w_last (core_w_last ),
        .m_w_valid(core_w_valid),
        .m_w_ready(core_w_ready),
                          
    // write response channel 
        .m_b_id   (core_b_id   ),
        .m_b_resp (core_b_resp ),
        .m_b_valid(core_b_valid),
        .m_b_ready(core_b_ready),
                                  
    // read address channel  
        .m_ar_id   (core_ar_id   ),
        .m_ar_addr (core_ar_addr ),
        .m_ar_len  (core_ar_len  ),
        .m_ar_size (core_ar_size ),
        .m_ar_burst(core_ar_burst),
        .m_ar_cache(core_ar_cache),
        .m_ar_prot (core_ar_prot ),
        .m_ar_qos  (core_ar_qos  ),
        .m_ar_valid(core_ar_valid),
        .m_ar_ready(core_ar_ready),

    // read data channel  
        .m_r_id   (core_r_id   ),
        .m_r_data (core_r_data ),
        .m_r_resp (core_r_resp ),
        .m_r_last (core_r_last ),
        .m_r_valid(core_r_valid),
        .m_r_ready(core_r_ready),

    //----------- AXI Interface Signals To Or From Slave ----------
    // write address channel 
        .s_aw_id_bus   (s_aw_id_bus   ),
        .s_aw_addr_bus (s_aw_addr_bus ),
        .s_aw_len_bus  (s_aw_len_bus  ),
        .s_aw_size_bus (s_aw_size_bus ),
        .s_aw_burst_bus(s_aw_burst_bus),
        .s_aw_cache_bus(s_aw_cache_bus),
        .s_aw_prot_bus (s_aw_prot_bus ),
        .s_aw_qos_bus  (s_aw_qos_bus  ),
        .s_aw_valid_bus(s_aw_valid_bus),
        .s_aw_ready_bus(s_aw_ready_bus),
                                       
                                       
    // write data channel              
        .s_w_data_bus (s_w_data_bus),
        .s_w_strb_bus (s_w_strb_bus),
        .s_w_last_bus (s_w_last_bus),
        .s_w_valid_bus(s_w_valid_bus),
        .s_w_ready_bus(s_w_ready_bus),
                                    
    // write response channel 
        .s_b_id_bus   (s_b_id_bus   ),
        .s_b_resp_bus (s_b_resp_bus ),
        .s_b_valid_bus(s_b_valid_bus),
        .s_b_ready_bus(s_b_ready_bus),
                                       
    // read address channel            
        .s_ar_id_bus   (s_ar_id_bus   ),
        .s_ar_addr_bus (s_ar_addr_bus ),
        .s_ar_len_bus  (s_ar_len_bus  ),
        .s_ar_size_bus (s_ar_size_bus ),
        .s_ar_burst_bus(s_ar_burst_bus),
        .s_ar_cache_bus(s_ar_cache_bus),
        .s_ar_prot_bus (s_ar_prot_bus ),
        .s_ar_qos_bus  (s_ar_qos_bus  ),
        .s_ar_valid_bus(s_ar_valid_bus),
        .s_ar_ready_bus(s_ar_ready_bus),

    // read data channel  
        .s_r_id_bus   (s_r_id_bus   ),
        .s_r_data_bus (s_r_data_bus ),
        .s_r_resp_bus (s_r_resp_bus ),
        .s_r_last_bus (s_r_last_bus ),
        .s_r_valid_bus(s_r_valid_bus),
        .s_r_ready_bus(s_r_ready_bus)
    );

//

// instantiate sim_uart
    wire [`AXI_AxID_BUS]        uart_aw_id;
    wire [`AXI_AxADDR_BUS]      uart_aw_addr;
    wire [`AXI_AxLEN_BUS]       uart_aw_len;
    wire [`AXI_AxSIZE_BUS]      uart_aw_size;
    wire [`AXI_AxBURST_BUS]     uart_aw_burst;
    wire [`AXI_AxCACHE_BUS]     uart_aw_cache;
    wire [`AXI_AxPROT_BUS]      uart_aw_prot;
    wire [`AXI_AxQOS_BUS]       uart_aw_qos;
    wire                        uart_aw_valid;
    wire                        uart_aw_ready;
    // write data channel  
    wire [`AXI_xDATA_BUS]       uart_w_data;
    wire [`AXI_WSTRB_BUS]       uart_w_strb;
    wire                        uart_w_last;
    wire                        uart_w_valid;
    wire                        uart_w_ready;
    // write response channel 
    wire [`AXI_xID_BUS]         uart_b_id;
    wire [`AXI_xRESP_BUS]       uart_b_resp;
    wire                        uart_b_valid;
    wire                        uart_b_ready;
    // read address channel  
    wire [`AXI_AxID_BUS]        uart_ar_id;
    wire [`AXI_AxADDR_BUS]      uart_ar_addr;
    wire [`AXI_AxLEN_BUS]       uart_ar_len;
    wire [`AXI_AxSIZE_BUS]      uart_ar_size;
    wire [`AXI_AxBURST_BUS]     uart_ar_burst;
    wire [`AXI_AxCACHE_BUS]     uart_ar_cache;
    wire [`AXI_AxPROT_BUS]      uart_ar_prot;
    wire [`AXI_AxQOS_BUS]       uart_ar_qos;
    wire                        uart_ar_valid;
    wire                        uart_ar_ready;
    // read data channel  
    wire [`AXI_xID_BUS]         uart_r_id;
    wire [`AXI_xDATA_BUS]       uart_r_data;
    wire [`AXI_xRESP_BUS]       uart_r_resp;
    wire                        uart_r_last;
    wire                        uart_r_valid;
    wire                        uart_r_ready;

sim_uart sim_uart0(
    .clk(clock),
    .rst(reset),

    //----------- AXI Interface Signals ----------
    // write address channel (slave)
    .axi_aw_id    (uart_aw_id   ),
    .axi_aw_addr  (uart_aw_addr ),
    .axi_aw_len   (uart_aw_len  ),
    .axi_aw_size  (uart_aw_size ),
    .axi_aw_burst (uart_aw_burst),
    .axi_aw_cache (uart_aw_cache),
    .axi_aw_prot  (uart_aw_prot ),
    .axi_aw_qos   (uart_aw_qos  ),
    .axi_aw_valid (uart_aw_valid),
    .axi_aw_ready (uart_aw_ready),

    // write data channel   (slave)
    .axi_w_data   (uart_w_data ),
    .axi_w_strb   (uart_w_strb ),
    .axi_w_last   (uart_w_last ),
    .axi_w_valid  (uart_w_valid),
    .axi_w_ready  (uart_w_ready),

    // write response channel (slave)
    .axi_b_id     (uart_b_id   ),
    .axi_b_resp   (uart_b_resp ),
    .axi_b_valid  (uart_b_valid),
    .axi_b_ready  (uart_b_ready),

    // read address channel  (slave)
    .axi_ar_id    (uart_ar_id   ),
    .axi_ar_addr  (uart_ar_addr ),
    .axi_ar_len   (uart_ar_len  ),
    .axi_ar_size  (uart_ar_size ),
    .axi_ar_burst (uart_ar_burst),
    .axi_ar_cache (uart_ar_cache),
    .axi_ar_prot  (uart_ar_prot ),
    .axi_ar_qos   (uart_ar_qos  ),
    .axi_ar_valid (uart_ar_valid),
    .axi_ar_ready (uart_ar_ready),
                                      
    // read data channel  (slave)
    .axi_r_id     (uart_r_id    ),
    .axi_r_data   (uart_r_data  ),
    .axi_r_resp   (uart_r_resp  ),
    .axi_r_last   (uart_r_last  ),
    .axi_r_valid  (uart_r_valid ),
    .axi_r_ready  (uart_r_ready )
    );
//
assign io_uart_in_valid = 1'b1;


// connection between simtop ports and splitter
    // write address channel connections
    wire [`AXI_AxID_BUS]      axi_aw_id;
    wire [`AXI_AxADDR_BUS]    axi_aw_addr;
    wire [`AXI_AxLEN_BUS]     axi_aw_len;
    wire [`AXI_AxSIZE_BUS]    axi_aw_size;
    wire [`AXI_AxBURST_BUS]   axi_aw_burst;
    wire [`AXI_AxCACHE_BUS]   axi_aw_cache;
    wire [`AXI_AxPROT_BUS]    axi_aw_prot;
    wire [`AXI_AxQOS_BUS]     axi_aw_qos;
    wire axi_aw_valid;
    wire axi_aw_ready;

    assign axi_aw_ready = `AXI_TOP_INTERFACE(aw_ready);
    assign `AXI_TOP_INTERFACE(aw_valid)      = axi_aw_valid;
    assign `AXI_TOP_INTERFACE(aw_bits_addr)  = axi_aw_addr;
    assign `AXI_TOP_INTERFACE(aw_bits_len)   = axi_aw_len;
    assign `AXI_TOP_INTERFACE(aw_bits_size)  = axi_aw_size;
    assign `AXI_TOP_INTERFACE(aw_bits_burst) = axi_aw_burst;
    assign `AXI_TOP_INTERFACE(aw_bits_id)    = axi_aw_id;
    assign `AXI_TOP_INTERFACE(aw_bits_prot)  = axi_aw_prot;
    assign `AXI_TOP_INTERFACE(aw_bits_cache) = axi_aw_cache;
    assign `AXI_TOP_INTERFACE(aw_bits_qos)   = axi_aw_qos;
    assign `AXI_TOP_INTERFACE(aw_bits_user)  = 0;
    assign `AXI_TOP_INTERFACE(aw_bits_lock)  = 0;


    // write data channel connections
    wire [`AXI_xDATA_BUS]     axi_w_data;
    wire [`AXI_WSTRB_BUS]     axi_w_strb;
    wire                      axi_w_last;
    wire                      axi_w_valid;
    wire                      axi_w_ready;

    assign axi_w_ready = `AXI_TOP_INTERFACE(w_ready);
    assign `AXI_TOP_INTERFACE(w_valid)        = axi_w_valid;
    assign `AXI_TOP_INTERFACE(w_bits_data)[0] = axi_w_data;
    assign `AXI_TOP_INTERFACE(w_bits_strb)    = axi_w_strb;
    assign `AXI_TOP_INTERFACE(w_bits_last)    = axi_w_last;


    // write response channel response
    wire [`AXI_xID_BUS]        axi_b_id;
    wire [`AXI_xRESP_BUS]      axi_b_resp;
    wire                       axi_b_valid;
    wire                       axi_b_ready;

    assign `AXI_TOP_INTERFACE(b_ready) = axi_b_ready;
    assign axi_b_valid = `AXI_TOP_INTERFACE(b_valid);
    assign axi_b_resp  = `AXI_TOP_INTERFACE(b_bits_resp);
    assign axi_b_id    = `AXI_TOP_INTERFACE(b_bits_id);




    // read address channel connections
    wire [`AXI_AxID_BUS]      axi_ar_id;
    wire [`AXI_AxADDR_BUS]    axi_ar_addr;
    wire [`AXI_AxLEN_BUS]     axi_ar_len;
    wire [`AXI_AxSIZE_BUS]    axi_ar_size;
    wire [`AXI_AxBURST_BUS]   axi_ar_burst;
    wire [`AXI_AxCACHE_BUS]   axi_ar_cache;
    wire [`AXI_AxPROT_BUS]    axi_ar_prot;
    wire [`AXI_AxQOS_BUS]     axi_ar_qos;
    wire                      axi_ar_valid;
    wire                      axi_ar_ready;

    assign axi_ar_ready =  `AXI_TOP_INTERFACE(ar_ready);
    assign `AXI_TOP_INTERFACE(ar_valid)      = axi_ar_valid;
    assign `AXI_TOP_INTERFACE(ar_bits_addr)  = axi_ar_addr;
    assign `AXI_TOP_INTERFACE(ar_bits_len)   = axi_ar_len;
    assign `AXI_TOP_INTERFACE(ar_bits_size)  = axi_ar_size;
    assign `AXI_TOP_INTERFACE(ar_bits_burst) = axi_ar_burst;
    
    assign `AXI_TOP_INTERFACE(ar_bits_prot)  = axi_ar_prot;
    assign `AXI_TOP_INTERFACE(ar_bits_id)    = axi_ar_id;
    assign `AXI_TOP_INTERFACE(ar_bits_cache) = axi_ar_cache;
    assign `AXI_TOP_INTERFACE(ar_bits_qos)   = axi_ar_qos;
    assign `AXI_TOP_INTERFACE(ar_bits_user)  = 0;
    assign `AXI_TOP_INTERFACE(ar_bits_lock)  = 0;

    //read data channel connections
    wire [`AXI_xID_BUS]        axi_r_id;
    wire [`AXI_xDATA_BUS]      axi_r_data;
    wire [`AXI_xRESP_BUS]      axi_r_resp;
    wire                       axi_r_last;
    wire                       axi_r_valid;
    wire                       axi_r_ready;
    assign `AXI_TOP_INTERFACE(r_ready) = axi_r_ready;
    assign axi_r_valid = `AXI_TOP_INTERFACE(r_valid);
    assign axi_r_resp  = `AXI_TOP_INTERFACE(r_bits_resp);
    assign axi_r_data  = `AXI_TOP_INTERFACE(r_bits_data)[0];
    assign axi_r_last  = `AXI_TOP_INTERFACE(r_bits_last);
    assign axi_r_id    = `AXI_TOP_INTERFACE(r_bits_id);

//
endmodule

