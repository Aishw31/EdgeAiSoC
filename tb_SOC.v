`timescale 1ns / 1ns

module SOC_tb;
    // Testbench signals
    reg clk;
    reg resetn;

    // Simulation parameters
    parameter CLK_PERIOD = 10; // 10ns = 100MHz

    // Instantiate the SOC
    SOC uut (
        .clk(clk),
        .resetn(resetn)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Reset stimulus
    initial begin
        // Apply reset
        resetn = 0;
        repeat(5) @(posedge clk); // Hold reset for 5 clock cycles (50 ns)

        // Release reset and run for 500 ns
        resetn = 1;
        #500;

        // End simulation
        $finish;
    end
endmodule