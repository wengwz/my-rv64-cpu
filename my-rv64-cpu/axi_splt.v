`include "defines.v"
module axi_splt #(
    parameter AW = 64,
    parameter DW = 64,
    parameter ID_W = 4,
    parameter SPLT_NUM = 2,
    parameter SPLT_PTR_W = 1 

)(
    input wire clk,
    input wire rst,

    input wire [SPLT_NUM-1:0]     w_splt_indic,
    input wire [SPLT_NUM-1:0]     r_splt_indic,
    //----------- AXI Interface Signals To Or From Master ----------
    // write address channel 
    input  wire [ID_W-1:0]        m_aw_id,
    input  wire [AW-1  :0]        m_aw_addr,
    input  wire [7:0]             m_aw_len,
    input  wire [2:0]             m_aw_size,
    input  wire [1:0]             m_aw_burst,
    input  wire [3:0]             m_aw_cache,
    input  wire [2:0]             m_aw_prot,
    input  wire [3:0]             m_aw_qos,
    input  wire                   m_aw_valid,
    output wire                   m_aw_ready,
                                  
                                   
    // write data channel   
    input  wire [DW-1  :0]        m_w_data,
    input  wire [DW/8-1:0]        m_w_strb,
    input  wire                   m_w_last,
    input  wire                   m_w_valid,
    output wire                   m_w_ready,
                          
    // write response channel 
    output wire [ID_W-1:0]        m_b_id,
    output wire [1:0]             m_b_resp,
    output wire                   m_b_valid,
    input  wire                   m_b_ready,
                                  
    // read address channel  
    input wire [ID_W-1:0]         m_ar_id,
    input wire [AW-1  :0]         m_ar_addr,
    input wire [7:0]              m_ar_len,
    input wire [2:0]              m_ar_size,
    input wire [1:0]              m_ar_burst,
    input wire [3:0]              m_ar_cache,
    input wire [2:0]              m_ar_prot,
    input wire [3:0]              m_ar_qos,
    input wire                    m_ar_valid,
    output  wire                  m_ar_ready,

    // read data channel  
    output wire [ID_W-1:0]        m_r_id,
    output wire [DW-1  :0]        m_r_data,
    output wire [1:0]             m_r_resp,
    output wire                   m_r_last,
    output wire                   m_r_valid,
    input wire                    m_r_ready,

    //----------- AXI Interface Signals To Or From Slave ----------
    // write address channel 
    output  wire [ID_W*SPLT_NUM-1:0]   s_aw_id_bus,
    output  wire [AW*SPLT_NUM-1  :0]   s_aw_addr_bus,
    output  wire [8*SPLT_NUM-1   :0]   s_aw_len_bus,
    output  wire [3*SPLT_NUM-1   :0]   s_aw_size_bus,
    output  wire [2*SPLT_NUM-1   :0]   s_aw_burst_bus,
    output  wire [4*SPLT_NUM-1   :0]   s_aw_cache_bus,
    output  wire [3*SPLT_NUM-1   :0]   s_aw_prot_bus,
    output  wire [4*SPLT_NUM-1   :0]   s_aw_qos_bus,
    output  wire [1*SPLT_NUM-1   :0]   s_aw_valid_bus,
    input   wire [1*SPLT_NUM-1   :0]   s_aw_ready_bus,
                                       
                                       
    // write data channel              
    output  wire [DW*SPLT_NUM-1  :0]   s_w_data_bus,
    output  wire [(DW/8)*SPLT_NUM-1:0] s_w_strb_bus,
    output  wire [1*SPLT_NUM-1   :0]   s_w_last_bus,
    output  wire [1*SPLT_NUM-1   :0]   s_w_valid_bus,
    input   wire [1*SPLT_NUM-1   :0]   s_w_ready_bus,
                                    
    // write response channel 
    input   wire [ID_W*SPLT_NUM-1:0]   s_b_id_bus,
    input   wire [2*SPLT_NUM-1   :0]   s_b_resp_bus,
    input   wire [1*SPLT_NUM-1   :0]   s_b_valid_bus,
    output  wire [1*SPLT_NUM-1   :0]   s_b_ready_bus,
                                       
    // read address channel            
    output  wire [ID_W*SPLT_NUM-1:0]   s_ar_id_bus,
    output  wire [AW*SPLT_NUM-1  :0]   s_ar_addr_bus,
    output  wire [8*SPLT_NUM-1   :0]   s_ar_len_bus,
    output  wire [3*SPLT_NUM-1   :0]   s_ar_size_bus,
    output  wire [2*SPLT_NUM-1   :0]   s_ar_burst_bus,
    output  wire [4*SPLT_NUM-1   :0]   s_ar_cache_bus,
    output  wire [3*SPLT_NUM-1   :0]   s_ar_prot_bus,
    output  wire [4*SPLT_NUM-1   :0]   s_ar_qos_bus,
    output  wire [1*SPLT_NUM-1   :0]   s_ar_valid_bus,
    input   wire [1*SPLT_NUM-1   :0]   s_ar_ready_bus,

    // read data channel  
    input  wire [ID_W*SPLT_NUM-1  :0]   s_r_id_bus,
    input  wire [DW*SPLT_NUM-1    :0]   s_r_data_bus,
    input  wire [2*SPLT_NUM-1     :0]   s_r_resp_bus,
    input  wire [1*SPLT_NUM-1     :0]   s_r_last_bus,
    input  wire [1*SPLT_NUM-1     :0]   s_r_valid_bus,
    output wire [1*SPLT_NUM-1     :0]   s_r_ready_bus

    );


    // write address channel
    wire [ID_W-1:0]        s_aw_id   [SPLT_NUM-1:0];
    wire [AW-1  :0]        s_aw_addr [SPLT_NUM-1:0];
    wire [7:0]             s_aw_len  [SPLT_NUM-1:0];
    wire [2:0]             s_aw_size [SPLT_NUM-1:0];
    wire [1:0]             s_aw_burst[SPLT_NUM-1:0];
    wire [3:0]             s_aw_cache[SPLT_NUM-1:0];
    wire [2:0]             s_aw_prot [SPLT_NUM-1:0];
    wire [3:0]             s_aw_qos  [SPLT_NUM-1:0];
    wire [SPLT_NUM-1:0]    s_aw_valid;
    wire [SPLT_NUM-1:0]    s_aw_ready;                              
    // write data channel   
    wire [DW-1  :0]        s_w_data [SPLT_NUM-1:0];
    wire [DW/8-1:0]        s_w_strb [SPLT_NUM-1:0];
    wire                   s_w_last [SPLT_NUM-1:0];
    wire                   s_w_valid[SPLT_NUM-1:0];
    wire                   s_w_ready[SPLT_NUM-1:0];
                          
    // write response channel 
    wire [ID_W-1:0]        s_b_id   [SPLT_NUM-1:0];
    wire [1:0]             s_b_resp [SPLT_NUM-1:0];
    wire                   s_b_valid[SPLT_NUM-1:0];
    wire                   s_b_ready[SPLT_NUM-1:0];
                                  
    // read address channel  
    wire [ID_W-1:0]        s_ar_id   [SPLT_NUM-1:0];
    wire [AW-1  :0]        s_ar_addr [SPLT_NUM-1:0];
    wire [7:0]             s_ar_len  [SPLT_NUM-1:0];
    wire [2:0]             s_ar_size [SPLT_NUM-1:0];
    wire [1:0]             s_ar_burst[SPLT_NUM-1:0];
    wire [3:0]             s_ar_cache[SPLT_NUM-1:0];
    wire [2:0]             s_ar_prot [SPLT_NUM-1:0];
    wire [3:0]             s_ar_qos  [SPLT_NUM-1:0];
    wire                   s_ar_valid[SPLT_NUM-1:0];
    wire                   s_ar_ready[SPLT_NUM-1:0];

    // read data channel  
    wire [ID_W-1:0]        s_r_id   [SPLT_NUM-1:0];
    wire [DW-1  :0]        s_r_data [SPLT_NUM-1:0];
    wire [1:0]             s_r_resp [SPLT_NUM-1:0];
    wire                   s_r_last [SPLT_NUM-1:0];
    wire                   s_r_valid[SPLT_NUM-1:0];
    wire                   s_r_ready[SPLT_NUM-1:0];

    reg m_aw_ready_pre;
    reg m_w_ready_pre;
    reg m_ar_ready_pre;

    reg [SPLT_PTR_W-1:0] w_resp_ptr;
    reg [SPLT_PTR_W-1:0] r_resp_ptr;
    

    integer j;
    genvar  i;
    generate
        if(SPLT_NUM == 1) begin: splt_num_eq_1_gen
            // write address
            assign s_aw_id_bus      = m_aw_id;
            assign s_aw_addr_bus    = m_aw_addr;
            assign s_aw_len_bus     = m_aw_len;
            assign s_aw_size_bus    = m_aw_size;
            assign s_aw_burst_bus   = m_aw_burst;
            assign s_aw_cache_bus   = m_aw_cache;
            assign s_aw_prot_bus    = m_aw_prot;
            assign s_aw_qos_bus     = m_aw_qos;
            assign s_aw_valid_bus   = m_aw_valid;
            //
            assign m_aw_ready       = s_aw_ready_bus;


            // write data
            assign s_w_data_bus     = m_w_data;
            assign s_w_strb_bus     = m_w_strb;
            assign s_w_last_bus     = m_w_last;
            assign s_w_valid_bus    = m_w_valid;
            //
            assign m_w_ready        = s_w_ready_bus;

            // write response
            assign m_b_id           = s_b_id_bus;
            assign m_b_resp         = s_b_resp_bus;
            assign m_b_valid        = s_b_valid_bus;
            //
            assign s_b_ready_bus    = m_b_ready;

            // read address
            assign s_ar_id_bus      = m_ar_id;
            assign s_ar_addr_bus    = m_ar_addr;
            assign s_ar_len_bus     = m_ar_len;
            assign s_ar_size_bus    = m_ar_size;
            assign s_ar_burst_bus   = m_ar_burst;
            assign s_ar_cache_bus   = m_ar_cache;
            assign s_ar_prot_bus    = m_ar_prot;
            assign s_ar_qos_bus     = m_ar_qos;
            assign s_ar_valid_bus   = m_ar_valid;
            //
            assign m_ar_ready       = s_ar_ready_bus;

            // read data
            assign m_r_id           = s_r_id_bus;
            assign m_r_data         = s_r_data_bus;
            assign m_r_resp         = s_r_resp_bus;
            assign m_r_last         = s_r_last_bus;
            assign m_r_valid        = s_r_valid_bus;
            //
            assign s_r_ready_bus    = m_r_ready;
        end
        else begin :splt_num_gt_1_gen
            for(i = 0; i < SPLT_NUM; i=i+1) begin
                assign s_aw_id_bus   [ID_W *(i+1)-1 : i*ID_W]  = s_aw_id   [i];
                assign s_aw_addr_bus [AW   *(i+1)-1 : i*AW  ]  = s_aw_addr [i];
                assign s_aw_len_bus  [8    *(i+1)-1 : i*8   ]  = s_aw_len  [i];
                assign s_aw_size_bus [3    *(i+1)-1 : i*3   ]  = s_aw_size [i];
                assign s_aw_burst_bus[2    *(i+1)-1 : i*2   ]  = s_aw_burst[i];
                assign s_aw_cache_bus[4    *(i+1)-1 : i*4   ]  = s_aw_cache[i];
                assign s_aw_prot_bus [3    *(i+1)-1 : i*3   ]  = s_aw_prot [i];
                assign s_aw_qos_bus  [4    *(i+1)-1 : i*4   ]  = s_aw_qos  [i];
                assign s_aw_valid_bus[i]                       = s_aw_valid[i];
                assign s_aw_ready[i]                           = s_aw_ready_bus[i];
                                                             
                assign s_w_data_bus  [DW   *(i+1)-1 : i*DW   ] = s_w_data  [i];
                assign s_w_strb_bus  [(DW/8)*(i+1)-1:i*(DW/8)] = s_w_strb  [i];
                assign s_w_last_bus  [i]                       = s_w_last  [i];      
                assign s_w_valid_bus [i]                       = s_w_valid [i];
                assign s_w_ready     [i]                       = s_w_ready_bus [i];

                assign s_b_id[i]        = s_b_id_bus   [ID_W*(i+1)-1 :i*ID_W];   
                assign s_b_resp[i]      = s_b_resp_bus [2*(i+1)-1    :i*2   ];
                assign s_b_valid[i]     = s_b_valid_bus[i];
                assign s_b_ready_bus[i] = s_b_ready    [i];



                assign s_ar_id_bus   [ID_W *(i+1)-1 : i*ID_W]  = s_ar_id   [i];
                assign s_ar_addr_bus [AW   *(i+1)-1 : i*AW  ]  = s_ar_addr [i];
                assign s_ar_len_bus  [8    *(i+1)-1 : i*8   ]  = s_ar_len  [i];
                assign s_ar_size_bus [3    *(i+1)-1 : i*3   ]  = s_ar_size [i];
                assign s_ar_burst_bus[2    *(i+1)-1 : i*2   ]  = s_ar_burst[i];
                assign s_ar_cache_bus[4    *(i+1)-1 : i*4   ]  = s_ar_cache[i];
                assign s_ar_prot_bus [3    *(i+1)-1 : i*3   ]  = s_ar_prot [i];
                assign s_ar_qos_bus  [4    *(i+1)-1 : i*4   ]  = s_ar_qos  [i];
                assign s_ar_valid_bus[i]                       = s_ar_valid[i];
                assign s_ar_ready    [i]                       = s_ar_ready_bus[i];

                assign s_r_id[i]        = s_r_id_bus   [ID_W*(i+1)-1 :i*ID_W]; 
                assign s_r_data[i]      = s_r_data_bus [DW  *(i+1)-1 :i*DW  ];  
                assign s_r_resp[i]      = s_r_resp_bus [2*(i+1)-1    :i*2   ];
                assign s_r_last[i]      = s_r_last_bus [i];
                assign s_r_valid[i]     = s_r_valid_bus[i];
                assign s_r_ready_bus[i] = s_r_ready    [i];
            end

            //---------------------  Write Transaction Mux  --------------------
            // Write Address Channel
            always @(*) begin
                m_aw_ready_pre = 0;
                for(j=0; j<SPLT_NUM; j=j+1) begin
                    m_aw_ready_pre = m_aw_ready_pre | (w_splt_indic[j] & s_aw_ready[j]);
                end
            end
            assign m_aw_ready = m_aw_ready_pre;

            for (i=0 ;i < SPLT_NUM ;i=i+1 ) begin
                assign s_aw_valid[i] = m_aw_valid && w_splt_indic[i];

                assign s_aw_id   [i]   = {ID_W{s_aw_valid[i]}} & m_aw_id;
                assign s_aw_addr [i]   = {AW  {s_aw_valid[i]}} & m_aw_addr;
                assign s_aw_len  [i]   = {8   {s_aw_valid[i]}} & m_aw_len;
                assign s_aw_size [i]   = {3   {s_aw_valid[i]}} & m_aw_size;
                assign s_aw_burst[i]   = {2   {s_aw_valid[i]}} & m_aw_burst;
                assign s_aw_cache[i]   = {4   {s_aw_valid[i]}} & m_aw_cache;
                assign s_aw_prot [i]   = {3   {s_aw_valid[i]}} & m_aw_prot;
                assign s_aw_qos  [i]   = {4   {s_aw_valid[i]}} & m_aw_qos;
            end

            // Write Data Channel
            always @(*) begin
                m_w_ready_pre = 0;
                for(j=0; j<SPLT_NUM; j=j+1) begin
                    m_w_ready_pre = m_w_ready_pre | (w_splt_indic[j] & s_w_ready[j]);
                end
            end
            assign m_w_ready = m_w_ready_pre;

            for (i=0 ;i < SPLT_NUM ;i=i+1 ) begin
                assign s_w_valid[i] = m_w_valid && w_splt_indic[i];

                assign s_w_data [i]   = {DW     {s_w_valid[i]}} & m_w_data;
                assign s_w_strb [i]   = {(DW/8) {s_w_valid[i]}} & m_w_strb;
                assign s_w_last [i]   = {1      {s_w_valid[i]}} & m_w_last;
            end

            // Write Response Channel
            always @(*) begin
                w_resp_ptr = 0;
                for(j = 0; j < SPLT_NUM; j=j+1) begin
                    if(s_b_valid[j]) begin w_resp_ptr = j[SPLT_PTR_W-1:0]; end
                end
            end

            assign m_b_valid = s_b_valid[w_resp_ptr];
            assign m_b_id    = s_b_id   [w_resp_ptr];
            assign m_b_resp  = s_b_resp [w_resp_ptr];

            for (i = 0; i<SPLT_NUM; i=i+1 ) begin
                assign s_b_ready[i] = (w_resp_ptr==i) && m_b_ready;
            end

            //---------------------  Read Transaction Mux  ---------------------

            // Read Address Channel
            always @(*) begin
                m_ar_ready_pre = 1'b0;
                for(j=0; j < SPLT_NUM; j=j+1) begin
                    m_ar_ready_pre = m_ar_ready_pre | (r_splt_indic[j] & s_ar_ready[j]);
                end
            end
            assign m_ar_ready = m_ar_ready_pre;

            for (i=0; i < SPLT_NUM; i=i+1 ) begin
                assign s_ar_valid[i] = m_ar_valid && r_splt_indic[i];

                assign s_ar_id   [i]   = {ID_W{s_ar_valid[i]}} & m_ar_id;
                assign s_ar_addr [i]   = {AW  {s_ar_valid[i]}} & m_ar_addr;
                assign s_ar_len  [i]   = {8   {s_ar_valid[i]}} & m_ar_len;
                assign s_ar_size [i]   = {3   {s_ar_valid[i]}} & m_ar_size;
                assign s_ar_burst[i]   = {2   {s_ar_valid[i]}} & m_ar_burst;
                assign s_ar_cache[i]   = {4   {s_ar_valid[i]}} & m_ar_cache;
                assign s_ar_prot [i]   = {3   {s_ar_valid[i]}} & m_ar_prot;
                assign s_ar_qos  [i]   = {4   {s_ar_valid[i]}} & m_ar_qos;
            end

            // Read Data Response
            always @(*) begin
                r_resp_ptr = 0;
                for(j = 0; j < SPLT_NUM; j=j+1) begin
                    if(s_r_valid[j]) begin r_resp_ptr = j[SPLT_PTR_W-1:0]; end
                end
            end

            assign m_r_valid = s_r_valid[r_resp_ptr];

            assign m_r_id    = s_r_id   [r_resp_ptr];
            assign m_r_data  = s_r_data [r_resp_ptr];
            assign m_r_resp  = s_r_resp [r_resp_ptr];
            assign m_r_last  = s_r_last [r_resp_ptr];

            for (i = 0; i<SPLT_NUM; i=i+1 ) begin
                assign s_r_ready[i] = (r_resp_ptr==i) && m_r_ready;
            end
        end
    
    endgenerate

endmodule











