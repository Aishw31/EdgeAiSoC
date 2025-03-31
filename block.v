`timescale 1ns / 1ns
module block # (
    parameter integer WIDTH = 16
)
    (
    input clk,
    input rst,
    input start,
    input [WIDTH-1:0] inp_north,
    input [WIDTH-1:0] inp_west,
    output reg [WIDTH-1:0] outp_south,
    output reg [WIDTH-1:0] outp_east,
    output reg [WIDTH-1:0] result
);
    wire [WIDTH-1:0] multi;
    always @(posedge rst or posedge clk) begin
        if (rst) begin
            result <= 0;
            outp_east <= 0;
            outp_south <= 0;
       end else if (start) begin
            result <= result + multi;
            outp_east <= inp_west;
            outp_south <= inp_north;
        end 
    end
    assign multi = inp_north * inp_west;
endmodule