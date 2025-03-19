`timescale 1ns / 1ns

module SOC
(
    input clk,
    input resetn,
    output  [3:0] led,
    output [31:0] m_addr
);  
    parameter MEM_WORDS = 4096;
    parameter [ 0:0] ENABLE_COUNTERS = 1;
	parameter [ 0:0] ENABLE_COUNTERS64 = 1;
	parameter [ 0:0] ENABLE_REGS_16_31 = 1;
	parameter [ 0:0] ENABLE_REGS_DUALPORT = 1;
	parameter [ 0:0] LATCHED_MEM_RDATA = 1 ;
	parameter [ 0:0] TWO_STAGE_SHIFT = 1 ;
	parameter [ 0:0] BARREL_SHIFTER = 1;
	parameter [ 0:0] TWO_CYCLE_COMPARE = 1 ;
	parameter [ 0:0] TWO_CYCLE_ALU = 1;
	parameter [ 0:0] COMPRESSED_ISA = 1;
	parameter [ 0:0] CATCH_MISALIGN = 1;
	parameter [ 0:0] CATCH_ILLINSN = 1;
	parameter [ 0:0] ENABLE_PCPI = 1;
	parameter [ 0:0] ENABLE_MUL = 1;
	parameter [ 0:0] ENABLE_FAST_MUL = 1;
	parameter [ 0:0] ENABLE_DIV = 1;
	parameter [ 0:0] ENABLE_IRQ = 1;
	parameter [ 0:0] ENABLE_IRQ_QREGS = 1;
	parameter [ 0:0] ENABLE_IRQ_TIMER = 1;
	parameter [ 0:0] ENABLE_TRACE = 1;
	parameter [ 0:0] REGS_INIT_ZERO = 1;
	parameter [31:0] MASKED_IRQ = 32'h 0000_0000;
	parameter [31:0] LATCHED_IRQ = 32'h ffff_ffff;
	parameter [31:0] PROGADDR_RESET = 32'h 0000_0000;
	parameter [31:0] PROGADDR_IRQ = 32'h 0000_0100;
	parameter [31:0] STACKADDR = 32'h ffff_ffff;


    wire mem_valid;
    wire mem_instr;
    reg mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0] mem_wstrb;
    reg [31:0] mem_rdata;
   
    // SRAM signals
    wire sram_ready ;
    wire [31:0] sram_rdata;
    
    // Memory mapped Device Signals
    wire device_ready;
    wire [31:0] device_rdata;

    picorv32 #(
        .ENABLE_COUNTERS(ENABLE_COUNTERS),
        .ENABLE_COUNTERS64(ENABLE_COUNTERS64),
        .ENABLE_REGS_16_31(ENABLE_REGS_16_31),
        .ENABLE_REGS_DUALPORT(ENABLE_REGS_DUALPORT),
        .LATCHED_MEM_RDATA(LATCHED_MEM_RDATA),
        .TWO_STAGE_SHIFT(TWO_STAGE_SHIFT),
        .BARREL_SHIFTER(BARREL_SHIFTER),
        .TWO_CYCLE_COMPARE(TWO_CYCLE_COMPARE),
        .TWO_CYCLE_ALU(TWO_CYCLE_ALU),
        .COMPRESSED_ISA(COMPRESSED_ISA),
        .CATCH_MISALIGN(CATCH_MISALIGN),
        .CATCH_ILLINSN(CATCH_ILLINSN),
        .ENABLE_PCPI(ENABLE_PCPI),
        .ENABLE_MUL(ENABLE_MUL),
        .ENABLE_FAST_MUL(ENABLE_FAST_MUL),
        .ENABLE_DIV(ENABLE_DIV),
        .ENABLE_IRQ(ENABLE_IRQ),
        .ENABLE_IRQ_QREGS(ENABLE_IRQ_QREGS),
        .ENABLE_IRQ_TIMER(ENABLE_IRQ_TIMER),
        .ENABLE_TRACE(ENABLE_TRACE),
        .REGS_INIT_ZERO(REGS_INIT_ZERO),
        .MASKED_IRQ(MASKED_IRQ),
        .LATCHED_IRQ(LATCHED_IRQ),
        .PROGADDR_RESET(PROGADDR_RESET),
        .PROGADDR_IRQ(PROGADDR_IRQ),
        .STACKADDR(STACKADDR)
        
    ) cpu (
        .clk (clk),
        .resetn (resetn),
        .mem_valid (mem_valid),
        .mem_instr (mem_instr),
        .mem_ready (mem_ready),
        .mem_addr (mem_addr),
        .mem_wdata (mem_wdata),
        .mem_rdata (mem_rdata),
        .mem_wstrb (mem_wstrb),

    .trap(),
         // Look-Ahead Interface (Unused)
    .mem_la_read(),        
    .mem_la_write(),       
    .mem_la_addr(),        
    .mem_la_wdata(),       
    .mem_la_wstrb(),       

    // Pico Co-Processor Interface (Unused)
    .pcpi_valid(),         
    .pcpi_insn(),          
    .pcpi_rs1(),          
    .pcpi_rs2(),          
    .pcpi_wr(),           
    .pcpi_rd(),           
    .pcpi_wait(),         
    .pcpi_ready(),        

    // IRQ Interface (Explicitly tied to 0)
    .irq(32'b0),           
    .eoi(),           

    // Debug/Trace Interface (Unused)
    .trace_valid(),       
    .trace_data() 
    );

    // Address Decoding
    wire is_ram = (mem_addr < 4 * MEM_WORDS );
    wire is_device = (mem_addr == 32'h1000_0000);

    always @(posedge clk) begin
        if (!resetn)
            mem_ready <= 0 ;
        else
            mem_ready <= mem_valid && (is_ram || is_device);
    end

    always @(*) begin
        case (1'b1)
            is_ram:     mem_rdata = sram_rdata ;
            is_device:  mem_rdata = device_rdata ;
            default:    mem_rdata = 32'h0000_0000;
        endcase
    end

    SRAM_v2 # (
        .WORDS(MEM_WORDS)
    ) boot (
        .clk (clk),
        .addr (mem_addr[23:2]),
        .wdata (mem_wdata),
        .wen ((mem_valid && is_ram ) ? mem_wstrb : 4'b0),
        .rdata (sram_rdata)
    );

    MappedDevice device (
        .clk (clk ),
        .wen((mem_valid && is_device) ? mem_wstrb : 4'b0),
        .wdata(mem_wdata),
        .rdata(device_rdata)
    );
    assign led = mem_rdata[3:0];
    assign m_addr = mem_addr;
endmodule

// module SRAM_v1 #(
//     parameter integer WORDS = 256 
// )
// (
//     input clk,
//     input mem_valid,
//     input mem_instr,
//     output mem_ready,

//     input [21:0] mem_addr,
//     input [31:0] mem_wdata,
//     input [3:0] mem_wstrb,
//     output reg [31:0] mem_rdata
// );

//     reg [31:0] mem [0:WORDS-1] ;

//     initial begin
//         $readmemh("test.mem",mem);
//     end
//     assign mem_ready = mem_valid ? 1'b1 : 1'b0;
    
//     always@(posedge clk) begin
//         if (mem_ready) begin
//             if (mem_wstrb == 4'b0000) mem_rdata <= mem[mem_addr];
//             if (mem_wstrb[0]) mem[mem_addr][7:0] <= mem_wdata[7:0];
//             if (mem_wstrb[1]) mem[mem_addr][15:8] <= mem_wdata[15:8];
//             if (mem_wstrb[2]) mem[mem_addr][23:16] <= mem_wdata[23:16];
//             if (mem_wstrb[3]) mem[mem_addr][31:24] <= mem_wdata[31:24];
//         end
//     end
//  endmodule  

module SRAM_v2 #(
    parameter integer WORDS = 256
)
(
    input clk ,
    input [3:0] wen ,
    input [21:0] addr,
    input [31:0] wdata,
    output reg [31:0] rdata 
);
    reg [31:0] mem [0:WORDS-1];
     initial begin
        $readmemh("testmmio.mem", mem);
    end
    always@(posedge clk ) begin
        rdata <= mem[addr];
		if (wen[0]) mem[addr][ 7: 0] <= wdata[ 7: 0];
		if (wen[1]) mem[addr][15: 8] <= wdata[15: 8];
		if (wen[2]) mem[addr][23:16] <= wdata[23:16];
		if (wen[3]) mem[addr][31:24] <= wdata[31:24];
    end
endmodule

module MappedDevice (
    input clk,
    input [3:0] wen,
    input [31:0] wdata,
    output reg [31:0] rdata
);
    (* syn_keep *) reg [31:0] device_reg;
   

    always @(posedge clk) begin
        if (wen[0]) device_reg[7:0]   <= wdata[7:0];
        if (wen[1]) device_reg[15:8]  <= wdata[15:8];
        if (wen[2]) device_reg[23:16] <= wdata[23:16];
        if (wen[3]) device_reg[31:24] <= wdata[31:24];
    end

    always @(*) begin
        rdata = device_reg[31:0];
    end
endmodule



            



