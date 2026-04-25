`timescale 1ns / 1ps
// ============================================================
// Utility: qmul_s24  (signed (a*b) >>> 24  -> 32-bit)
// ============================================================
module qmul_s24 (
    input  wire signed [31:0] a,
    input  wire signed [31:0] b,
    output wire signed [31:0] y
);
    wire signed [63:0] m = a * b;
    assign y = (m >>> 24);
endmodule
