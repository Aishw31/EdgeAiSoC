`timescale 1ns / 1ns

module tb_MatrixMulUnit;

    // Parameters
    parameter integer WIDTH = 16;
    parameter integer BASE_ADDRESS = 32'h1000_0040;

    // Testbench signals
    reg clk;
    reg wen;
    reg [21:0] addr;
    reg [WIDTH-1:0] wdata;
    wire [(WIDTH*2)-1:0] rdata;

    // Instantiate the MatrixMulUnit
    MatrixMulUnit #(
        .WIDTH(WIDTH),
        .BASE_ADDRESS(BASE_ADDRESS)
    ) uut (
        .clk(clk),
        .wen(wen),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata)
    );

    // Clock generation
    initial begin
        clk = 0 ;
    forever #5 clk = ~ clk ;
    end

    // Test procedure
    initial begin
        $dumpfile("tb_MatrixMulUnit.vcd");
        $dumpvars(0, tb_MatrixMulUnit);
        
        // Initialize signals
        clk = 0;
        wen = 0;
        addr = 0;
        wdata = 0;
        
        // Apply Reset
        #10;
        
        // Write input values
        wen = 1;
        addr = BASE_ADDRESS;       wdata = 16'h0003; #10; // A[0][0] = 3
        addr = BASE_ADDRESS + 4;   wdata = 16'h0002; #10; // A[0][1] = 2
        addr = BASE_ADDRESS + 8;   wdata = 16'h0001; #10; // B[0][0] = 1
        addr = BASE_ADDRESS + 12;  wdata = 16'h0004; #10; // B[1][0] = 4
        addr = BASE_ADDRESS + 16;  wdata = 8'hFF;    #10; // Control (Trigger computation)
        
        wen = 0; // Stop writing

        // Wait for computation to complete
        #50;
        
        // Read result values
        addr = BASE_ADDRESS;       #10; $display("Result0: %d", rdata);
        addr = BASE_ADDRESS + 4;   #10; $display("Result1: %d", rdata);
        addr = BASE_ADDRESS + 8;   #10; $display("Result2: %d", rdata);
        addr = BASE_ADDRESS + 12;  #10; $display("Result3: %d", rdata);
        
        // Finish simulation
        #20;
        $finish;
    end

endmodule
