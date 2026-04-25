

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/14 20:00:00
// Design Name: 
// Module Name: diffusion_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//     Top-level wrapper for diffusion module, integrating all submodules
//     using only wire connections (no additional logic).
// 
// Dependencies: 
//     - dGHNN_top
//     - sha256_wrapper
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//     All submodules are connected purely through wires.
// 
//////////////////////////////////////////////////////////////////////////////////

module diffusion_top(
    input  wire        clk,
    input  wire        rst_n,
    
    // Initial parameters for dGHNN
    input  wire signed [31:0] s0,
    input  wire signed [31:0] w0,
    input  wire signed [31:0] v0,
    
    // Image input
    input  wire               img_valid,
    input  wire        [23:0]  img_out,
    
    // Chaos output
    output wire [23:0]  chaos_out,
    output wire        chaos_valid
);

//=============================================================================
// Internal wire declarations for dGHNN_top outputs
//=============================================================================
wire signed [31:0] x1;
wire signed [31:0] x2;
wire signed [31:0] x3;
wire signed [31:0] s;
wire signed [31:0] w;
wire signed [31:0] v;
wire               x_start;
wire               x_valid;

//=============================================================================
// Internal wire declarations for SHA256 wrapper
//=============================================================================
wire [255:0] sha_data_in;
wire [255:0] sha_hash_out;
wire         sha_hash_valid;
wire         sha_busy;

//=============================================================================
// Internal wire declarations for diffusion pipeline
//=============================================================================
wire [255:0] hash_out_reg;
wire [31:0]  sum_sw_v;
wire [31:0]  prod32;

wire         x_valid_d1;
wire         x_valid_d2;
wire         x_valid_d3;
wire         x_valid_d4;
wire         x_valid_d5;
wire         x_valid_d6;
wire         x_valid_d7;
wire         x_valid_d8;
wire         x_valid_d9;
wire         x_valid_d10;
wire         x_valid_d11;

wire         hash_valid_d1;
wire         hash_valid_d2;
wire         hash_valid_d3;

//=============================================================================
// Submodule Instantiation: dGHNN_top
//=============================================================================




J_MHHNN J_MHHNN_inst (
    .clk      (clk),
    .rst_n    (rst_n),
    .s0       (s0),
    .w0       (w0),
    .v0       (v0),
    .x1       (x1),
    .x2       (x2),
    .x3       (x3),
    .s        (s),
    .w        (w),
    .v        (v),
    .x_start  (x_start),
    .x_valid  (x_valid)
);

//=============================================================================
// SHA256 data input assignment: concatenate x1, x2, x3
// Assumes each is 32 bits, total 96 bits. Pad remaining bits to 256.
//=============================================================================
assign sha_data_in = {{160{1'b0}}, x1, x2, x3};  // Zero-padding upper 160 bits

//=============================================================================
// Submodule Instantiation: sha256_wrapper
//=============================================================================
sha256_wrapper sha_inst (
    .clk      (clk),
    .reset_n  (rst_n),
    .data_in  (sha_data_in),
    .start    (x_valid),
    .hash_out (sha_hash_out),
    .valid    (sha_hash_valid),
    .busy     (sha_busy)
);

//=============================================================================
// Submodule Instantiation: diffusion_datapath
// This module implements the pipeline logic previously in the always block
//=============================================================================
diffusion_datapath datapath_inst (
    .clk            (clk),
    .rst_n          (rst_n),
    
    // Inputs from dGHNN
    .s              (s),
    .w              (w),
    .v              (v),
    .x_valid        (x_valid),
    
    // Inputs from SHA256
    .hash_out       (sha_hash_out),
    .hash_valid     (sha_hash_valid),
    
    // Outputs
    .chaos_out      (chaos_out),
    .chaos_valid    (chaos_valid)
);

endmodule





module diffusion_datapath(
    input  wire        clk,
    input  wire        rst_n,
    
    // Inputs from dGHNN
    input  wire signed [31:0] s,
    input  wire signed [31:0] w,
    input  wire signed [31:0] v,
    input  wire               x_valid,
    
    // Inputs from SHA256
    input  wire [255:0] hash_out,
    input  wire         hash_valid,
    
    // Outputs
    output reg  [23:0]   chaos_out,
    output reg          chaos_valid
);

//=============================================================================
// Pipeline registers
//=============================================================================
reg [255:0] hash_out_r;
reg signed [31:0] sum_sw_v;
reg signed [31:0] prod32;

// Valid signal delay chain
reg x_valid_d1, x_valid_d2, x_valid_d3, x_valid_d4, x_valid_d5;
reg x_valid_d6, x_valid_d7, x_valid_d8, x_valid_d9, x_valid_d10, x_valid_d11;

reg hash_valid_d1, hash_valid_d2, hash_valid_d3;

//=============================================================================
// Pipeline Logic
//=============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        hash_out_r     <= 256'd0;
        sum_sw_v       <= 32'sd0;
        prod32         <= 32'sd0;
        chaos_out      <= 8'd0;
        chaos_valid    <= 1'b0;
        
        // Reset valid delay chain
        x_valid_d1     <= 1'b0;
        x_valid_d2     <= 1'b0;
        x_valid_d3     <= 1'b0;
        x_valid_d4     <= 1'b0;
        x_valid_d5     <= 1'b0;
        x_valid_d6     <= 1'b0;
        x_valid_d7     <= 1'b0;
        x_valid_d8     <= 1'b0;
        x_valid_d9     <= 1'b0;
        x_valid_d10    <= 1'b0;
        x_valid_d11    <= 1'b0;
        
        hash_valid_d1  <= 1'b0;
        hash_valid_d2  <= 1'b0;
        hash_valid_d3  <= 1'b0;
        
    end else begin
        // Default: clear chaos_valid
        chaos_valid <= 1'b0;
        
        //---------------------------------------------------------------------
        // Valid signal delay chains
        //---------------------------------------------------------------------
        x_valid_d1  <= x_valid;
        x_valid_d2  <= x_valid_d1;
        x_valid_d3  <= x_valid_d2;
        x_valid_d4  <= x_valid_d3;
        x_valid_d5  <= x_valid_d4;
        x_valid_d6  <= x_valid_d5;
        x_valid_d7  <= x_valid_d6;
        x_valid_d8  <= x_valid_d7;
        x_valid_d9  <= x_valid_d8;
        x_valid_d10 <= x_valid_d9;
        x_valid_d11 <= x_valid_d10;
        
        hash_valid_d1 <= hash_valid;
        hash_valid_d2 <= hash_valid_d1;
        hash_valid_d3 <= hash_valid_d2;
        
        //---------------------------------------------------------------------
        // Stage 0: Register hash output
        //---------------------------------------------------------------------
        if (hash_valid) begin
            hash_out_r <= hash_out;
        end
        
        //---------------------------------------------------------------------
        // Stage 1: Compute sum of s + w + v
        //---------------------------------------------------------------------
        if (hash_valid_d1) begin
            sum_sw_v <= $signed(s) + $signed(w) + $signed(v);
        end
        
        //---------------------------------------------------------------------
        // Stage 2: Multiply sum by hash_out_r
        //---------------------------------------------------------------------
        if (hash_valid_d2) begin
            prod32 <= $signed(sum_sw_v) * $signed(hash_out_r[31:0]);  
            // Note: Using lower 32 bits of hash for multiplication
        end
        
        //---------------------------------------------------------------------
        // Stage 3: Extract mod 256 and output
        //---------------------------------------------------------------------
        if (hash_valid_d3) begin
            chaos_out   <= prod32[23:0];  // Take lower 8 bits (mod 256)
            chaos_valid <= 1'b1;
        end
    end
end

endmodule


