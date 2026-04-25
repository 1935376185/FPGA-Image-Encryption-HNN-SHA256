`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/24 22:24:15
// Design Name: 
// Module Name: Sn
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


module Sn(
    input  wire clk,
    input  wire rst_n,
    input  wire signed [31:0] x,
    output reg  signed [31:0] Sn_x
);

// ============================================================================
// Parameters and constants
// ============================================================================
localparam [2:0] SCROLLS = 3'd3;                        // n = 3
localparam signed [31:0] ONE = 32'h01000000;            // 1.0 in Q8.24
localparam signed [31:0] HALF = 32'h00800000;           // 0.5 in Q8.24
wire signed [31:0] POS_THRESHOLD;
wire signed [31:0] NEG_THRESHOLD;

assign POS_THRESHOLD = (SCROLLS << 24) - HALF;  // n - 0.5 = 2.5
assign NEG_THRESHOLD = -(POS_THRESHOLD);        // -(n - 0.5) = -2.5

// ============================================================================
// Internal signals
// ============================================================================
reg [9:0] addr;
wire [31:0] dout;
reg flip_d1, flip_d2, flip_d3;

// Saturation detection signals
reg saturate_pos_d1, saturate_pos_d2, saturate_pos_d3;  // positive saturation delay chain
reg saturate_neg_d1, saturate_neg_d2, saturate_neg_d3;  // negative saturation delay chain

// ============================================================================
// ROM instance
// ============================================================================
sn sn_rom(
    .clka(clk),
    .addra(addr),
    .douta(dout)
);

// ============================================================================
// Main logic
// ============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr <= 10'd0;
        flip_d1 <= 1'b0;
        flip_d2 <= 1'b0;
        flip_d3 <= 1'b0;
        saturate_pos_d1 <= 1'b0;
        saturate_pos_d2 <= 1'b0;
        saturate_pos_d3 <= 1'b0;
        saturate_neg_d1 <= 1'b0;
        saturate_neg_d2 <= 1'b0;
        saturate_neg_d3 <= 1'b0;
        Sn_x <= 32'd0;
    end else begin
        // ====================================================================
        // Stage 1: Sample input and detect saturation
        // ====================================================================
        addr <= x[23:14];
        flip_d1 <= x[24];
        
        // Saturation detection
        saturate_pos_d1 <= (x >= POS_THRESHOLD);  // x >= 2.5
        saturate_neg_d1 <= (x <= NEG_THRESHOLD);  // x <= -2.5
        
        // ====================================================================
        // Stage 2: Delay to match ROM
        // ====================================================================
        flip_d2 <= flip_d1;
        saturate_pos_d2 <= saturate_pos_d1;
        saturate_neg_d2 <= saturate_neg_d1;
        
        // ====================================================================
        // Stage 3: Continue delay
        // ====================================================================
        flip_d3 <= flip_d2;
        saturate_pos_d3 <= saturate_pos_d2;
        saturate_neg_d3 <= saturate_neg_d2;
        
        // ====================================================================
        // Stage 4: Output selection (saturation or normal)
        // ====================================================================
        if (saturate_pos_d3) begin
            Sn_x <= ONE;           // saturate to +1.0
        end else if (saturate_neg_d3) begin
            Sn_x <= -ONE;          // saturate to -1.0
        end else begin
            // Normal table lookup + sign flip
            Sn_x <= (flip_d3^SCROLLS[0]) ? dout : (~dout + 1'b1) ; // SCROLLS is odd

        end
    end
end

endmodule