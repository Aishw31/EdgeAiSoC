`timescale 1ns / 1ns
module MMSystolicArray #(
    parameter integer WIDTH = 32,
    parameter  BASE_ADDRESS = 32'h0300_0000
)
(
    input clk,
    input [3:0] wen,
    input [21:0] addr,
    input [31:0] wdata,
    output reg [31:0] rdata 
);
    // Control And Status Registers
    localparam CONTROL_REG = 8'h00;
    localparam STATUS_REG  = 8'h01;

    // Input Registers
    localparam NORTH_0 = 8'h02;
    localparam NORTH_1 = 8'h03;
    localparam WEST_0  = 8'h04;
    localparam WEST_1  = 8'h05;

    // Output Registers
    localparam RESULT_00 = 8'h06;
    localparam RESULT_01 = 8'h07;
    localparam RESULT_10 = 8'h08;
    localparam RESULT_11 = 8'h09;

    // Internal Signals
    reg [31:0] control;
    reg [31:0] status;
    
    wire return_code ; 
    
    reg [WIDTH-1:0] in_buffers[3:0];
    wire [31:0] out_buffers[3:0];

  
    // Register Write Operations
    always @(posedge clk) begin
        if (|wen) begin
            case (addr[7:0])
                CONTROL_REG: begin
                    control <= wdata[31:0];
                end
                NORTH_0: begin
                    in_buffers[0] <= wdata[31:0];
                end
                NORTH_1: begin
                    in_buffers[1] <= wdata[31:0];
                end
                WEST_0: begin
                    in_buffers[2] <= wdata[31:0];
                end
                WEST_1: begin
                    in_buffers[3] <= wdata[31:0];
                end
            endcase
        end
     end
    // **Register Read Operations (Fixed)**
    always @(posedge clk) begin
        case (addr[7:0])
            CONTROL_REG: rdata <= control;  // ✅ Correctly updates rdata
            STATUS_REG:  rdata <= status;
            NORTH_0:     rdata <= in_buffers[0];
            NORTH_1:     rdata <= in_buffers[1];
            WEST_0:      rdata <= in_buffers[2];
            WEST_1:      rdata <= in_buffers[3];
            RESULT_00:   rdata <= out_buffers[0];
            RESULT_01:   rdata <= out_buffers[1];
            RESULT_10:   rdata <= out_buffers[2];
            RESULT_11:   rdata <= out_buffers[3];
            default:     rdata <= 32'hABCD;  // ✅ Prevents stale values
        endcase
    end
      // Instantiate the Systolic Array Module
    systolic_array_2x2 #(
        .WIDTH(WIDTH)
    ) duw (
        .clk(clk),
        .reset(control[7:0]),
        .start(control[15:8]),
        .shift_n_flow(control[23:16]),
        .inp_west0_buf(in_buffers[2]),
        .inp_west1_buf(in_buffers[3]),
        .inp_north0_buf(in_buffers[0]),
        .inp_north1_buf(in_buffers[1]),
        .done(return_code),
        .result0(out_buffers[0]),
        .result1(out_buffers[1]),
        .result2(out_buffers[2]),
        .result3(out_buffers[3])
    );

    always@(posedge clk) begin
        status <= {31'h0,return_code};
    end
    
endmodule
