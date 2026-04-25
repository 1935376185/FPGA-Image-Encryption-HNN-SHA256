`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/24 22:16:25
// Design Name: 
// Module Name: W_mem
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module W_mem (
    input  wire signed [31:0] a,
    input  wire signed [31:0] b,
    output wire signed [31:0] y
);
    localparam signed [31:0] one = 32'h0100_0000;
    wire signed [63:0] m = a * b;
    assign y = (m >>> 24)+one;
endmodule
