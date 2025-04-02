`timescale 1ns / 1ps

module SYSTOLIC (
    input wire          clk,
    input wire          reset,
    input wire [3:0]    wen,
    input wire [31:0]   wdata,
    output reg [31:0]   rdata
);

// INSTRUCTION ENCODING
localparam NO_OP       = 16'h0000;
localparam RESET       = 16'h0001;
localparam WRITE_WEST_0   = 16'h0002;
localparam WRITE_WEST_1   = 16'h0003;
localparam WRITE_NORTH_0   = 16'h0004;
localparam WRITE_NORTH_1   = 16'h0005;
localparam STATUS      = 16'h0006;
localparam READ_R00    = 16'h0007;
localparam READ_R01    = 16'h0008;
localparam READ_R10    = 16'h0009;
localparam READ_R11    = 16'h000A;
localparam START       = 16'h000B;

// Split memory bus data to instruction and data
reg [15:0] instruction;
reg [15:0] data_in;
reg [15:0] data_out;

// Internal signals
wire status;
reg [3:0] temp_start;
reg [3:0] temp_reset;
reg start_pulse; 
reg reset_pulse;
reg instruction_pulse;
// Input registers
reg [15:0] inp_west0, inp_west1;
reg [15:0] inp_north0, inp_north1;

// Result registers
wire [15:0] result_00, result_01, result_10, result_11;   

// Systolic 2x2 Instance
systolic_2x2 systolic_inst (
    .clk(clk),
    .start(temp_start),
    .reset(temp_reset),
    .inp_west0(inp_west0),
    .inp_west1(inp_west1),
    .inp_north0(inp_north0),
    .inp_north1(inp_north1),
    .done(status),
    .result_00(result_00),
    .result_01(result_01),
    .result_10(result_10),
    .result_11(result_11)
);

// Initialize with zeros
always @(posedge clk) begin
    if (!reset) begin
        instruction <= 16'h0000;
        data_in     <= 16'h0000;
    end else if (|wen) begin
        instruction <= wdata[31:16];
        instruction_pulse <= 1'b1;
        data_in     <= wdata[15:0];
    end
    if (instruction_pulse) begin
        instruction <= 16'h0;
        instruction_pulse <= 1'b0;
    end
    if (instruction == START) begin
         temp_start <= 4'hF;
         start_pulse <= 1'b1;
    end
    
    if (start_pulse) begin
         temp_start  <= 4'h0;
         start_pulse <= 1'b0;
    end  
    
     if (instruction == RESET) begin
         temp_reset <= 4'hF;
         reset_pulse <= 1'b1;
    end
    
      if (reset_pulse) begin
         temp_reset  <= 4'h0;
         reset_pulse <= 1'b0;
    end  
             
        
end

// Instruction Execution
always @(posedge clk) begin
    case (instruction)
        RESET: begin
//            temp_reset  <= 4'hF;
//            reset_pulse <= 1'h1;
            inp_west0   <= 16'h0000;
            inp_west1   <= 16'h0000;
            inp_north0  <= 16'h0000;
            inp_north1  <= 16'h0000;
            data_out    <= 32'h00000000;
            
        end
        WRITE_WEST_0: inp_west0 <= data_in;
        WRITE_WEST_1: inp_west1 <= data_in;
        WRITE_NORTH_0: inp_north0 <= data_in;
        WRITE_NORTH_1: inp_north1 <= data_in;
        
//        START : begin
//            temp_start <= 4'hF;
//            start_pulse <= 1'b1;    
//        end
        STATUS  :   data_out <= {31'h0,status};
        READ_R00: data_out <= result_00;
        READ_R01: data_out <= result_01;
        READ_R10: data_out <= result_10;
        READ_R11: data_out <= result_11;
    endcase
end

//// Reset temp_start after one cycle
//always @(posedge clk) begin
//    if (start_pulse) begin
//        temp_start  <= 4'h0;
//        start_pulse <= 1'b0;
//    end
//end

// Reset temp_reset after one cycle
//always @(posedge clk) begin
//    if (reset_pulse) begin
//        temp_reset  <= 4'h0;
//        reset_pulse <= 1'b0;
//    end
//end
//always @(posedge clk) begin
//    if (instruction_pulse) begin
//        instruction <= 16'h0;
//        instruction_pulse <= 1'b0;
//    end
//end

// Output data
always@(posedge clk)
    rdata <= data_out;

endmodule


module systolic_2x2 #(
    parameter integer WIDTH = 16 
) (
    input clk,
    input [3:0] start,                 
    input [3:0] reset,              
    input [WIDTH-1:0] inp_west0,   
    input [WIDTH-1:0] inp_west1,    
    input [WIDTH-1:0] inp_north0,   
    input [WIDTH-1:0] inp_north1,
    output reg done,                    // Computation done signal
    output [WIDTH-1:0] result_00,       // Result from P0 (C[0][0])
    output [WIDTH-1:0] result_01,       // Result from P1 (C[0][1])
    output [WIDTH-1:0] result_10,       // Result from P2 (C[1][0])
    output [WIDTH-1:0] result_11        // Result from P3 (C[1][1])
);

    reg [3:0] count; // Counter for timing control
    
    wire [WIDTH-1:0] outp_south0, outp_south1; // Outputs moving downward
    wire [WIDTH-1:0] outp_east0, outp_east1;   // Outputs moving right

  
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
        .result(result_00)
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
        .result(result_01)
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
        .result(result_10)
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
        .result(result_11)
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
