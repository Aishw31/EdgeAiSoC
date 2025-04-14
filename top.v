`timescale 1ns / 1ns
module Top
(
    input clk,         // Input reference clock (e.g., 100MHz)
    input resetn,         // Global reset (active low)

    output ser_tx,        
    input  ser_rx,

    output [3:0] led,
    output reset_led
);


wire clk_soc;


divide_by_2 divider (
    .clk(clk),
    .clk_out(clk_soc)
);

// SoC Instance (Uses PLL Clock)
SOC soc_inst (
    .clk(clk_soc),        // Use PLL-generated clock
    .resetn(resetn),  // Only start SoC when PLL is locked

    .ser_tx(ser_tx),
    .ser_rx(ser_rx),
    .led(led),
    .reset_led(reset_led)
);

endmodule


module divide_by_2 (
    input clk,        // Input clock (100MHz)
    output reg clk_out // Output divided clock (50MHz)
);

initial clk_out = 0; // Ensure known starting value

always @(posedge clk) begin
    clk_out <= ~clk_out;  // Toggle every clock cycle
end

endmodule


