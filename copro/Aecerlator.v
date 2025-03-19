`timescale 1ns / 1ns
// startaddrss oX2000_0000
module MatrixMulUnit #(
    parameter integer WIDTH = 16,
    parameter integer BASE_ADDRESS = 32'h1000_0040
)
(
    input clk,
    input wen,
    input [21:0] addr,
    input [WIDTH-1:0] wdata,
    output reg [(WIDTH*2)-1:0] rdata
);

    // Input buffers for systolic
    reg [WIDTH-1:0] bufa, bufb, bufc, bufd;

    // Output buffers for systolic
    reg [(WIDTH*2)-1:0] resa, resb, resc, resd;

    // Control and status registers
    reg [7:0] status;
    reg [7:0] control;
    wire reset = (control == 8'b11111111);
    wire done ;
    always @(posedge clk) begin
        if (wen) begin
            case (addr)
                BASE_ADDRESS      : bufa   <= wdata;
                BASE_ADDRESS + 4  : bufb   <= wdata;
                BASE_ADDRESS + 8  : bufc   <= wdata;
                BASE_ADDRESS + 12 : bufd   <= wdata;
                BASE_ADDRESS + 16 : control <= wdata[7:0];
                default: status <= 8'b11111111;
            endcase
        end else begin  
            case (addr)
                BASE_ADDRESS      : rdata <= resa;
                BASE_ADDRESS + 4  : rdata <= resb;
                BASE_ADDRESS + 8  : rdata <= resc;
                BASE_ADDRESS + 12 : rdata <= resd;
                BASE_ADDRESS + 16 : rdata <= { {(WIDTH*2-8){1'b0}}, status };
                default: status <= 8'b11110000;
            endcase
        end
    end
    systolic_array_2x2  # (
        .WIDTH(WIDTH)
    ) unit (
        .clk (clk) ,
        .rst(reset),
        .inp_west0(bufa),
        .inp_west1(bufb),
        .inp_north0(bufc),
        .inp_north1(bufd),
        .result0(resa),
        .result1(resc),
        .result2(resb),
        .result3(resd),
        .done(done)
    );
endmodule

    
