`timescale 1ns / 1ps
// ============================================================================
// qmul_s24_reg2 - 2-stage pipelined Q8.24 multiplier
// 
// Function: compute (a * b) >>> 24, where a, b are Q8.24 signed 32-bit
// Output: y = (a*b) >>> 24 (Q8.24 signed 32-bit)
//
// Timing:
//   - Pipeline latency: 2 clock cycles
//   - Stage1: input register
//   - Stage2: multiplication + shift + output register
// ============================================================================

module qmul_s24_reg2 (
    input  wire clk,
    input  wire rst_n,
    input  wire signed [31:0] a,
    input  wire signed [31:0] b,
    output reg  signed [31:0] y
);

    // ========================================================================
    // Stage 1: Input register
    // ========================================================================
    reg signed [31:0] a_d1;
    reg signed [31:0] b_d1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_d1 <= 32'sd0;
            b_d1 <= 32'sd0;
        end else begin
            a_d1 <= a;
            b_d1 <= b;
        end
    end
    
    // ========================================================================
    // Stage 2: Multiplication + shift + output register
    // ========================================================================
    wire signed [63:0] product = a_d1 * b_d1;
    wire signed [31:0] result = product[55:24];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 32'sd0;
        end else begin
            y <= result;
        end
    end

endmodule

