`timescale 1ns / 1ns
module systolic_array_2x2 #(
    parameter integer WIDTH = 16 
) (
    input clk,
    input [7:0] shift_n_flow, // to control shifting of data
    input [7:0] start,                  // 8-bit start vector for PEs and buffers
    input [7:0] reset,                  // 8-bit reset vector for PEs and buffers
    input [WIDTH-1:0] inp_west0_buf,    // Buffered west input 0
    input [WIDTH-1:0] inp_west1_buf,    // Buffered west input 1
    input [WIDTH-1:0] inp_north0_buf,   // Buffered north input 0
    input [WIDTH-1:0] inp_north1_buf,   // Buffered north input 1
    output reg done,                    // Computation done signal
    output [WIDTH-1:0] result0,       // Result from P0 (C[0][0])
    output [WIDTH-1:0] result1,       // Result from P1 (C[0][1])
    output [WIDTH-1:0] result2,       // Result from P2 (C[1][0])
    output [WIDTH-1:0] result3        // Result from P3 (C[1][1])
);

    reg [3:0] count; // Counter for timing control
    
    // Internal signals for buffered inputs
    wire [WIDTH-1:0] inp_west0, inp_west1;    // Outputs from west buffers
    wire [WIDTH-1:0] inp_north0, inp_north1;  // Outputs from north buffers (corrected typo)
    
    
    wire [WIDTH-1:0] outp_south0, outp_south1; // Outputs moving downward
    wire [WIDTH-1:0] outp_east0, outp_east1;   // Outputs moving right

    // Four pipeline buffers for all inputs
    pipeline_buffer #(
        .WIDTH(WIDTH)
    ) west0_buffer (
        .clk(clk),
        .rst(reset[7]),         // Use reset[4] for west0 buffer
        .en_fill(shift_n_flow[0]),             // Always enabled to shift data
        .en_flow(shift_n_flow[4]),
        .data_in(inp_west0_buf),
        .data_out(inp_west0)
    );

    pipeline_buffer #(
        .WIDTH(WIDTH)
    ) west1_buffer (
        .clk(clk),
        .rst(reset[6]),         // Use reset[5] for west1 buffer
        .en_fill(shift_n_flow[1]),              // Always enabled to shift data
        .en_flow(shift_n_flow[5]),
        .data_in(inp_west1_buf),
        .data_out(inp_west1)
    );

    pipeline_buffer #(
        .WIDTH(WIDTH)
    ) north0_buffer (
        .clk(clk),
        .rst(reset[5]),         // Use reset[6] for north0 buffer
        .en_fill(shift_n_flow[2]),              // Always enabled to shift data
        .en_flow(shift_n_flow[6]),
        .data_in(inp_north0_buf),
        .data_out(inp_north0)
    );

    pipeline_buffer #(
        .WIDTH(WIDTH)
    ) north1_buffer (
        .clk(clk),
        .rst(reset[4]),         // Use reset[7] for north1 buffer
        .en_fill(shift_n_flow[3]),              // Always enabled to shift data
        .en_flow(shift_n_flow[7]),
        .data_in(inp_north1_buf),
        .data_out(inp_north1)
    );

    // First row of the systolic array
    block # (
        .WIDTH(WIDTH)
    ) P00 (
        .inp_north(inp_north0),
        .inp_west(inp_west0),
        .clk(clk),
        .start(start[3]),
        .rst(reset[3]),
        .outp_south(outp_south0),
        .outp_east(outp_east0),
        .result(result0)
    );

    block # (
        .WIDTH(WIDTH)
    ) P01 (
        .inp_north(inp_north1),
        .inp_west(outp_east0),
        .clk(clk),
        .start(start[2]),
        .rst(reset[2]),
        .outp_south(outp_south1),
        .outp_east(),
        .result(result1)
    );

    // Second row of the systolic array
    block # (
        .WIDTH(WIDTH)
    ) P10 (
        .inp_north(outp_south0),
        .inp_west(inp_west1),
        .clk(clk),
        .start(start[1]),
        .rst(reset[1]),
        .outp_south(),  // No further south connections in a 2x2 array
        .outp_east(outp_east1),
        .result(result2)
    );

    block # (
        .WIDTH(WIDTH)
    ) P11 (
        .inp_north(outp_south1),
        .inp_west(outp_east1),
        .clk(clk),
        .start(start[0]),
        .rst(reset[0]),
        .outp_south(),
        .outp_east(),
        .result(result3)
    );

    // Start signal aggregation
    wire strt = |start;  // OR reduction of start vector

    // Control logic for computation timing
    always @(posedge clk) begin  // Use reset[0] for control logic
        if (|reset) begin
            done <= 0;
            count <= 0;
        end else if (strt) begin
            if (count == 5) begin
                done <= 1;
            end else begin
                done <= 0;
                count <= count + 1;
            end
        end
    end

endmodule

module pipeline_buffer #(
    parameter WIDTH = 16  // Width of the data to be buffered
) (
    input wire clk,                  // Clock signal
    input wire rst,                  // Active-high reset
    input wire en_fill,                   // Enable signal to shift data during loading
    input wire en_flow,             // let the data flow
    input wire [WIDTH-1:0] data_in,  // Input data to the buffer
    output wire [WIDTH-1:0] data_out  // Output data from the buffer (last stage)
);

    reg [WIDTH-1:0] buffer [0:3];  // Four pipeline stages
    reg en_d; // Delayed version of 'en' to detect posedge

    always @(posedge clk) begin
        if (rst) begin
            buffer[0] <= 0;
            buffer[1] <= 0;
            buffer[2] <= 0;
            buffer[3] <= 0;
            en_d      <= 0; // Reset delayed enable
        end else begin
            en_d <= en_fill; // Store previous value of `en` for edge detection
            
            if ((~en_d & en_fill) || (en_flow)  ) begin // Detect rising edge of `en`
                buffer[3] <= buffer[2];
                buffer[2] <= buffer[1];
                buffer[1] <= buffer[0];
                buffer[0] <= data_in;
            end
        end
    end
    
    assign data_out = buffer[3]; // Directly assign buffer[3] to data_out

endmodule


