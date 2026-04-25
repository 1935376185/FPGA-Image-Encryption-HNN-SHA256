`timescale 1ns / 1ps

// ============================================================
// Pdf ROM wrapper
// ============================================================
module Pdf(
   clk,
   rst_n,
   x,
   Pdf_x
);
input clk,rst_n;
input wire signed [31:0] x;
output reg signed [31:0] Pdf_x;

reg [9:0] addr;
wire [31:0] dout;
pdf pdf_rom(
    clk,
    addr,
    dout
    );
   
 
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        Pdf_x <= 32'h0;
        addr <= 10'h0;
    end else begin
       addr <= (x[31]) ? ~x[26:17] : x[26:17]; // 10-bit address width: bits [25:16] / 14-bit: [25:12]
       Pdf_x <= (x[31]) ? -dout: dout; // 4 clock cycles!
    end
 end
    
endmodule

