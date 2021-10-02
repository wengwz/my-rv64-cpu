`define RstEnable       1'b1
`define RstDisable      1'b0

`define ZeroWord        64'h0000_0000_0000_0000

`define WriteEnable     1'b1
`define WriteDisable    1'b0

`define ReadEnable      1'b1
`define ReadDisable     1'b0

`define InstValid       1'b0
`define InstInvalid     1'b1

`define ChipEnable      1'b1
`define ChipDisable     1'b0

`define FlushEnable     1'b1
`define FlushDisable    1'b0

`define Stop            1'b1
`define NoStop          1'b0

`define ADDR_START   64'h00000000_80000000

//*************** defines about inst bus ***************
`define InstAddrBus     63:0
`define InstBus         31:0

//*************** defines about data bus ***************
`define DataAddrBus     63:0
`define DataBus         63:0


//*************** defines about regfile ***************
`define RegAddrBus      4 :0
`define RegBus          63:0

//*************** defines about instructions ***************

// Integer Computational Instructions
`define INST_ADDI      8'b0000_0001
`define INST_SLTI      8'b0000_0010
`define INST_SLTIU     8'b0000_0100
`define INST_XORI      8'b0000_1000
`define INST_ORI       8'b0001_0000
`define INST_ANDI      8'b0010_0000
`define INST_SLLI      8'b0100_0000
`define INST_SRLI      8'b1000_0000
`define INST_SRAI      8'b0000_0011

`define INST_ADD       8'b0000_1100
`define INST_SUB       8'b0011_0000
`define INST_SLL       8'b1100_0000
`define INST_SLT       8'b0000_0101
`define INST_SLTU      8'b0000_1010
`define INST_XOR       8'b0101_0000
`define INST_SRL       8'b1010_0000      
`define INST_SRA       8'b0001_0001
`define INST_OR        8'b0010_0010
`define INST_AND       8'b0100_0100

`define INST_LUI       8'b1000_1000
`define INST_AUIPC     8'b1000_0001

`define INST_ADDIW     8'b0001_1000
`define INST_SLLIW     8'b0000_1001
`define INST_SRLIW     8'b1001_0000
`define INST_SRAIW     8'b0000_0110

`define INST_ADDW     8'b0110_0000
`define INST_SUBW     8'b0010_0001
`define INST_SLLW     8'b0001_0010
`define INST_SRLW     8'b1000_0100
`define INST_SRAW     8'b0100_1000


// Control Transfer Instructions
`define INST_JAL       8'b0100_0010
`define INST_JALR      8'b0010_0100

`define INST_BEQ       8'b0000_0001
`define INST_BNE       8'b0000_0010
`define INST_BLT       8'b0000_0100
`define INST_BGE       8'b0000_1000
`define INST_BLTU      8'b0001_0000
`define INST_BGEU      8'b0010_0000

// CSR Instructions
`define INST_CSRRW     8'b0100_0000
`define INST_CSRRS     8'b1000_0000
`define INST_CSRRC     8'b0000_0001
`define INST_CSRRWI    8'b0000_0010
`define INST_CSRRSI    8'b0000_0100
`define INST_CSRRCI    8'b0000_1000

// Priviledge Instructions
`define INST_ECALL     8'b0001_0000
`define INST_MRET      8'b0010_0000


//*************** defines about opcode ***************
// Integer Computational Instructions
`define INT_REG_IMM    5'b00100
`define INT_REG_IMM_W  5'b00110

`define INT_REG_REG    5'b01100
`define INT_REG_REG_W  5'b01110
`define INT_REG_REG_W  5'b01110
`define INT_LUI        5'b01101
`define INT_AUIPC      5'b00101
// Control Transfer Instructions
`define JUMP_JAL       5'b11011
`define JUMP_JALR      5'b11001
`define BRANCH         5'b11000

// Load and Store Instructions
`define LOAD           5'b00000
`define STORE          5'b01000

// CSR Instructions
`define SYSTEM         5'b11100

// Fence Instructions
`define FENCE          5'b00011

//*************** defines about funct3 ***************
`define LB_SEL         3'b000
`define LH_SEL         3'b001
`define LW_SEL         3'b010
`define LBU_SEL        3'b100
`define LHU_SEL        3'b101
`define LWU_SEL        3'b110
`define LD_SEL         3'b011

`define SB_SEL         3'b000
`define SH_SEL         3'b001
`define SW_SEL         3'b010
`define SD_SEL         3'b011


//********** defines about memory mapped address **********
`define MTIMECMP_ADDR       64'h0000_0000_0200_4000
`define MTIME_ADDR          64'h0000_0000_0200_BFF8

`define UART_ADDR_START     64'h0000_0000_1000_0000
`define UART_ADDR_END       64'h0000_0000_1000_0FFF

`define SPI_CTRL_START      64'h0000_0000_1000_1000
`define SPI_CTRL_END        64'h0000_0000_1000_1FFF

`define SPI_FLASH_START     64'h0000_0000_3000_0000
`define SPI_FLASH_END       64'h0000_0000_3FFF_FFFF


//*************** defines about AXI4 ***************
// axi burst types
`define AXI_BURST_TYPE_FIXED               2'b00
`define AXI_BURST_TYPE_INCR                2'b01
`define AXI_BURST_TYPE_WRAP                2'b10

// axi burst size
`define AXI_SIZE_BYTES_1                   3'b000
`define AXI_SIZE_BYTES_2                   3'b001
`define AXI_SIZE_BYTES_4                   3'b010
`define AXI_SIZE_BYTES_8                   3'b011
`define AXI_SIZE_BYTES_16                  3'b100
`define AXI_SIZE_BYTES_32                  3'b101
`define AXI_SIZE_BYTES_64                  3'b110
`define AXI_SIZE_BYTES_128                 3'b111

//axi signals bus 
`define AXI_AxID_BUS                       3:0
`define AXI_AxADDR_BUS                     63:0
`define AXI_AxLEN_BUS                      7:0
`define AXI_AxSIZE_BUS                     2:0
`define AXI_AxBURST_BUS                    1:0
`define AXI_AxCACHE_BUS                    3:0  
`define AXI_AxPROT_BUS                     2:0
`define AXI_AxQOS_BUS                      3:0
`define AXI_AxREGION_BUS                   3:0

`define AXI_xID_BUS                        3:0
`define AXI_xDATA_BUS                      63:0
`define AXI_WSTRB_BUS                      7:0
`define AXI_xRESP_BUS                      1:0



