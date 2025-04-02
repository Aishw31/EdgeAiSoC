`timescale 1ns / 1ns

module SOC_tb;
    // Testbench signals
    reg clk;
    reg resetn;
    wire [3:0] led;

    reg ser_rx;
    wire ser_tx;
    // Simulation parameters
    parameter CLK_PERIOD = 10; // 10ns = 100MHz

    // Instantiate the SOC with debug signals
    SOC uut (
        .clk(clk),
        .resetn(resetn),
        .led(led),
        .ser_rx(ser_rx),
        .ser_tx(ser_tx)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Reset stimulus
    initial begin
        // Initialize signals
        #100;
        clk = 0;
        resetn = 0;
        ser_rx = 1 ;
        // Apply Reset
        #100;   // Wait 100ns
        resetn = 1;  // Release reset

        // Run simulation for some time
        #1000;

        $finish;
    end

endmodule
