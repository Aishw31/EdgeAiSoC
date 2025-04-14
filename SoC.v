`timescale 1ns / 1ns

module SOC
(
    input clk,
    input resetn,

    
	output ser_tx,
	input  ser_rx,
	
    output [3:0] led,
    output reset_led
   
    
);  
    parameter MEM_WORDS = 8192;
    parameter [ 0:0] ENABLE_COUNTERS = 1;
    parameter [ 0:0] ENABLE_COUNTERS64 = 1;
    parameter [ 0:0] ENABLE_REGS_16_31 = 1;
    parameter [ 0:0] ENABLE_REGS_DUALPORT = 1;
    parameter [ 0:0] LATCHED_MEM_RDATA = 0;  // Changed to 0 to match PicoSoC
    parameter [ 0:0] TWO_STAGE_SHIFT = 0;
    parameter [ 0:0] BARREL_SHIFTER = 1;
    parameter [ 0:0] TWO_CYCLE_COMPARE = 0;
    parameter [ 0:0] TWO_CYCLE_ALU = 0;
    parameter [ 0:0] COMPRESSED_ISA = 1;
    parameter [ 0:0] CATCH_MISALIGN = 1;
    parameter [ 0:0] CATCH_ILLINSN = 1;
    parameter [ 0:0] ENABLE_PCPI = 0;
    parameter [ 0:0] ENABLE_MUL = 1;
    parameter [ 0:0] ENABLE_FAST_MUL = 0;
    parameter [ 0:0] ENABLE_DIV = 1;
    parameter [ 0:0] ENABLE_IRQ = 0;
    parameter [ 0:0] ENABLE_IRQ_QREGS = 0;
    parameter [ 0:0] ENABLE_IRQ_TIMER = 0;
    parameter [ 0:0] ENABLE_TRACE = 0;
    parameter [ 0:0] REGS_INIT_ZERO = 0;
    parameter [31:0] MASKED_IRQ = 32'h 0000_0000;
    parameter [31:0] LATCHED_IRQ = 32'h ffff_ffff;
    parameter [31:0] PROGADDR_RESET = 32'h 0000_0000;
    parameter [31:0] PROGADDR_IRQ = 32'h 0000_0000;
    parameter [31:0] STACKADDR = 32'd 8000;
    
    wire mem_valid;
    wire mem_instr;
    wire mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0] mem_wstrb;
    wire [31:0] mem_rdata;
    
   
    // RAM signals
    reg ram_ready;
    wire [31:0] ram_rdata;
    
    // led Signals
    wire [31:0] led_rdata;
    
    wire led_sel = mem_valid && (mem_addr == 32'h 0200_0000);
    wire        simpleuart_reg_div_sel = mem_valid && (mem_addr == 32'h 0200_0004);
	wire [31:0] simpleuart_reg_div_do;

	wire        simpleuart_reg_dat_sel = mem_valid && (mem_addr == 32'h 0200_0008);
	wire [31:0] simpleuart_reg_dat_do;
	wire        simpleuart_reg_dat_wait;


    // matrix mul
    wire mm_sel = mem_valid && (mem_addr == 32'h 0300_0000);
    wire [31:0] mm_do ;
    
 
    assign mem_ready = ram_ready || led_sel || mm_sel ||
			simpleuart_reg_div_sel || (simpleuart_reg_dat_sel && !simpleuart_reg_dat_wait);

	assign mem_rdata =  ram_ready ? ram_rdata : simpleuart_reg_div_sel ? simpleuart_reg_div_do :
			simpleuart_reg_dat_sel ? simpleuart_reg_dat_do : led_sel ? led_rdata : mm_sel ? mm_do : 32'h 0000_0000;

   
                   
    always @(posedge clk)
        ram_ready <= mem_valid && !mem_ready && mem_addr < 4*MEM_WORDS;
   
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
        .clk(clk),
        .resetn(resetn),
        .mem_valid(mem_valid),
        .mem_instr(mem_instr),
        .mem_ready(mem_ready),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata),
        .mem_wstrb(mem_wstrb),
        
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

    simpleuart simpleuart (
		.clk         (clk         ),
		.resetn      (resetn      ),

		.ser_tx      (ser_tx      ),
		.ser_rx      (ser_rx      ),

		.reg_div_we  (simpleuart_reg_div_sel ? mem_wstrb : 4'b 0000),
		.reg_div_di  (mem_wdata),
		.reg_div_do  (simpleuart_reg_div_do),

		.reg_dat_we  (simpleuart_reg_dat_sel ? mem_wstrb[0] : 1'b 0),
		.reg_dat_re  (simpleuart_reg_dat_sel && !mem_wstrb),
		.reg_dat_di  (mem_wdata),
		.reg_dat_do  (simpleuart_reg_dat_do),
		.reg_dat_wait(simpleuart_reg_dat_wait)
	);
	
    // RAM module with the same timing as PicoSoC
    SRAM_v2 #(
        .WORDS(MEM_WORDS)
    ) memory (
        .clk(clk),
        .wen((mem_valid && !mem_ready && mem_addr < 4*MEM_WORDS) ? mem_wstrb : 4'b0),
        .addr(mem_addr[23:2]),
        .wdata(mem_wdata),
        .rdata(ram_rdata)
    );

    // LED device with simpler interface
    led_module device (
        .clk(clk),
        .resetn(resetn),
        .wen(led_sel ? mem_wstrb : 4'b0),
        .wdata(mem_wdata),
        .rdata(led_rdata)
    );
    
    // Matrix mul unit
    
//    MMSystolicArray #(
    
//        ) MatrixMul (
//        .clk(clk),
//        .wen(mm_sel ? mem_wstrb : 4'b0),
//        .addr(mem_addr[23:2]),
//        .wdata(mem_wdata),
//        .rdata(mm_do)
//        );
    
    SYSTOLIC #(
) new_module(
    .clk(clk),
    .reset(resetn),
    .wen(mm_sel ? mem_wstrb :4'b0),
    .wdata(mem_wdata),
    .rdata(mm_do)
);

    
    assign led = led_rdata[3:0];
    assign reset_led = resetn;
endmodule

module SRAM_v2 #(
    parameter integer WORDS = 8192
)
(
    input clk,
    input [3:0] wen,
    input [21:0] addr,
    input [31:0] wdata,
    output reg [31:0] rdata 
);
    reg [31:0] mem [0:WORDS-1];
    
    initial begin
        $readmemh("main.mem", mem);
    end
    
    always @(posedge clk) begin
        rdata <= mem[addr];  // Read data is registered
        if (wen[0]) mem[addr][ 7: 0] <= wdata[ 7: 0];
        if (wen[1]) mem[addr][15: 8] <= wdata[15: 8];
        if (wen[2]) mem[addr][23:16] <= wdata[23:16];
        if (wen[3]) mem[addr][31:24] <= wdata[31:24];
    end
endmodule

module led_module (
    input clk,
    input resetn,
    input [3:0] wen,
    input [31:0] wdata,
    output reg [31:0] rdata
);
    (* syn_keep *) reg [31:0] device_reg;
    always @(posedge clk) begin
        if (!resetn) 
            device_reg <= 32'h0;
        else if (|wen) begin 
            if (wen[0]) device_reg[7:0]   <= wdata[7:0];
            if (wen[1]) device_reg[15:8]  <= wdata[15:8];
            if (wen[2]) device_reg[23:16] <= wdata[23:16];
            if (wen[3]) device_reg[31:24] <= wdata[31:24];
        end
    end
    

    always @(*) begin
        rdata = device_reg;
    end
endmodule


