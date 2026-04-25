`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/24 22:11:43
// Design Name: 
// Module Name: rk4_update
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


module rk4_update (
    input  wire clk,
    input  wire rst_n,

    input  wire signed [31:0] init_x1,
    input  wire signed [31:0] init_x2,
    input  wire signed [31:0] init_x3,
    input  wire signed [31:0] init_s,
    input  wire signed [31:0] init_w,
    input  wire signed [31:0] init_v,
    input  wire run_reset_n,

    input  wire k_valid,

    input  wire signed [31:0] k1_x1, k1_x2, k1_x3,k1_s,k1_w,k1_v,
    input  wire signed [31:0] k2_x1, k2_x2, k2_x3,k2_s,k2_w,k2_v,
    input  wire signed [31:0] k3_x1, k3_x2, k3_x3,k3_s,k3_w,k3_v,
    input  wire signed [31:0] k4_x1, k4_x2, k4_x3,k4_s,k4_w,k4_v,

    output reg  signed [31:0] x1,
    output reg  signed [31:0] x2,
    output reg  signed [31:0] x3,
    output reg  signed [31:0] s,
    output reg  signed [31:0] w,
    output reg  signed [31:0] v,

    output reg  x_valid
);

    // Constants
    localparam signed [31:0] h_step = 32'h0002_8f5c;
    localparam signed [31:0] c = 32'h2A_AAAAAB;

    //========================================
    // Pipeline Stage 1: sum
    //========================================
    reg signed [31:0] sum_x1, sum_x2, sum_x3, sum_s, sum_w, sum_v;
    reg pipe_valid_1;

    //========================================
    // Pipeline Stage 2: h_step * sum
    //========================================
    reg signed [63:0] mul1_x1, mul1_x2, mul1_x3, mul1_s, mul1_w, mul1_v;
    reg pipe_valid_2;

    //========================================
    // Pipeline Stage 3: mul1 * c
    //========================================
    reg signed [95:0] mul2_x1, mul2_x2, mul2_x3, mul2_s, mul2_w, mul2_v;
    reg pipe_valid_3;
    
    reg [10:0] start;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset
            x1 <= init_x1;
            x2 <= init_x2;
            x3 <= 32'sd0;
            s <= 32'sd0;
            w <= 32'sd0;
            v <= 32'sd0;
            
            sum_x1 <= 0; sum_x2 <= 0; sum_x3 <= 0;    sum_s <= 0;   sum_w <= 0;  sum_v <= 0;  
            mul1_x1 <= 0; mul1_x2 <= 0; mul1_x3 <= 0; mul1_s <= 0;  mul1_w <= 0; mul1_v <= 0; 
            mul2_x1 <= 0; mul2_x2 <= 0; mul2_x3 <= 0; mul2_s <= 0;  mul2_w <= 0; mul2_v <= 0; 
            
            pipe_valid_1 <= 1'b0;
            pipe_valid_2 <= 1'b0;
            pipe_valid_3 <= 1'b0;
            x_valid <= 1'b0;
            
            start <= 11'b0;
            
        end else begin
            // Default values
            x_valid <= 1'b0;

            if (run_reset_n) begin
                // VIO reset
                x1 <= init_x1;
                x2 <= init_x2;
                x3 <= init_x3;
                s <=  init_s;
                w <=  init_w;
                v <=  init_v;
                
                pipe_valid_1 <= 1'b0;
                pipe_valid_2 <= 1'b0;
                pipe_valid_3 <= 1'b0;
                
            end else begin
                //========================================
                // Stage 1: compute sum (delay ~3-4ns)
                //========================================
                pipe_valid_1 <= k_valid;
                
                sum_x1 <= k1_x1 + (k2_x1 <<< 1) + (k3_x1 <<< 1) + k4_x1;
                sum_x2 <= k1_x2 + (k2_x2 <<< 1) + (k3_x2 <<< 1) + k4_x2;
                sum_x3 <= k1_x3 + (k2_x3 <<< 1) + (k3_x3 <<< 1) + k4_x3;
                sum_s <= k1_s + (k2_s <<< 1) + (k3_s <<< 1) + k4_s;
                sum_w <= k1_w + (k2_w <<< 1) + (k3_w <<< 1) + k4_w;
                sum_v <= k1_v + (k2_v <<< 1) + (k3_v <<< 1) + k4_v;

                //========================================
                // Stage 2: h_step * sum (delay ~4-5ns)
                //========================================
                pipe_valid_2 <= pipe_valid_1;
                
                mul1_x1 <= h_step * sum_x1;
                mul1_x2 <= h_step * sum_x2;
                mul1_x3 <= h_step * sum_x3;
                mul1_s <= h_step * sum_s;
                mul1_w <= h_step * sum_w;
                mul1_v <= h_step * sum_v;

                //========================================
                // Stage 3: * c (delay ~4-5ns)
                //========================================
                pipe_valid_3 <= pipe_valid_2;
                
                mul2_x1 <= mul1_x1 * c;
                mul2_x2 <= mul1_x2 * c;
                mul2_x3 <= mul1_x3 * c;
                mul2_s <= mul1_s * c;
                mul2_w <= mul1_w * c;
                mul2_v <= mul1_v * c;

                //========================================
                // Stage 4: shift + update x (delay ~2-3ns)
                //========================================
                if (pipe_valid_3) begin
                    x1 <= x1 + mul2_x1[87:56];
                    x2 <= x2 + mul2_x2[87:56];
                    x3 <= x3 + mul2_x3[87:56];
                    s <= s + mul2_s[87:56];
                    w <= w + mul2_w[87:56];
                    v <= v + mul2_v[87:56];
                    if(start<=11'd32)begin
                         x_valid <= 1'b0;
                         start <= start+1;
                    end else begin
                        x_valid <= 1'b1;
                    end
                   
                end
            end
        end
    end

endmodule
