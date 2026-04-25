`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/24 22:17:13
// Design Name: 
// Module Name: Tanh
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


module Tanh(
   clk,
   rst_n,
   x,
   Tanh_x
);
input clk,rst_n;
input wire signed [31:0] x;
output reg signed [31:0] Tanh_x;

reg [9:0] addr;
wire [31:0] dout;
tanh tanh_rom(
    clk,
    addr,
    dout
    );
   
 
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        Tanh_x <= 32'h0;
        addr <= 10'h0;
    end else begin
       addr <= (x[31]) ? ~x[25:16] : x[25:16]; // 10-bit address width: bits [25:16] / 14-bit: [25:12]
       Tanh_x <= (x[31]) ? -dout: dout; // 4 clock cycles!
    end
 end
    
endmodule

