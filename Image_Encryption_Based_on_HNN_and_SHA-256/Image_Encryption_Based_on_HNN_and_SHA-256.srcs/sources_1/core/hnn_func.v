`timescale 1ns / 1ps
// ============================================================
// Submodule 2: hnn_func (outputs 32-bit dx cleanly)
// ============================================================
module hnn_func (
    input  wire clk,
    input  wire rst_n,
    input  wire signed [31:0] x1,
    input  wire signed [31:0] x2,
    input  wire signed [31:0] x3,
    input  wire signed [31:0] s,
    input  wire signed [31:0] w,
    input  wire signed [31:0] v,
    output reg  signed [31:0] dx1,
    output reg  signed [31:0] dx2,
    output reg  signed [31:0] dx3,
    output reg  signed [31:0] ds,
    output reg  signed [31:0] dw,
    output reg  signed [31:0] dv
);

    // Pdf and abs
    wire signed [31:0] Tanh_x1,Pdf_x1, Pdf_x2, Pdf_x3;
    wire signed [31:0] Pdf_s, Pdf_w, Pdf_v;
    wire signed [31:0] Sn_s, Sn_w, Sn_v;
    
    Tanh u_tanh1(.clk(clk), .rst_n(rst_n), .x(x1), .Tanh_x(Tanh_x1));
    Pdf u_pdf1(.clk(clk), .rst_n(rst_n), .x(x1), .Pdf_x(Pdf_x1));
    Pdf u_pdf2(.clk(clk), .rst_n(rst_n), .x(x2), .Pdf_x(Pdf_x2));
    Pdf u_pdf3(.clk(clk), .rst_n(rst_n), .x(x3), .Pdf_x(Pdf_x3));
    
    Pdf u_pdf4(.clk(clk), .rst_n(rst_n), .x(s), .Pdf_x(Pdf_s));
    Pdf u_pdf5(.clk(clk), .rst_n(rst_n), .x(w), .Pdf_x(Pdf_w));
    Pdf u_pdf6(.clk(clk), .rst_n(rst_n), .x(v), .Pdf_x(Pdf_v));

    Sn Sns(.clk(clk), .rst_n(rst_n),.x(s),.Sn_x(Sn_s));
    Sn Snw(.clk(clk), .rst_n(rst_n),.x(w),.Sn_x(Sn_w));
    Sn Snv(.clk(clk), .rst_n(rst_n),.x(v),.Sn_x(Sn_v));

// ============================================================================
// Weight matrix parameters (Q8.24 fixed-point format)
// Q8.24 format: 8-bit integer part + 24-bit fractional part
// Conversion: decimal = hex / 2^24 = hex / 16777216
// ============================================================================

// ---------- First row weights (x1 equation) ----------
localparam signed [31:0] w11 = 32'h01CC_CCCD;  // +1.8       (1.800000)
localparam signed [31:0] w12 = -32'h0199_999A; // -1.6       (-1.600000)
localparam signed [31:0] w13 = 32'h014C_CCCD;  // +1.3       (1.300000)

// ---------- Second row weights (x2 equation) ----------
localparam signed [31:0] w21 = 32'h0C00_0000;  // +12.0      (12.000000)
localparam signed [31:0] w22 = 32'h0280_0000;  // +2.5       (2.500000)
localparam signed [31:0] w23 = 32'h0300_0000;  // +3.0       (3.000000)

// ---------- Third row weights (x3 equation) ----------
localparam signed [31:0] w31 = -32'h0300_0000; // -3.0       (-3.000000)
localparam signed [31:0] w32 = 32'h0400_0000;  // +4.0       (4.000000)
localparam signed [31:0] w33 = 32'h00CC_CCCD;  // +0.8       (0.800000)

// ---------- Auxiliary variable parameters (s equation) ----------
localparam signed [31:0] c1 = 32'h0300_0000;   // +3.0       (3.000000)
localparam signed [31:0] c2 = 32'h0280_0000;   // +2.5       (2.500000)
localparam signed [31:0] c3 = 32'h0233_3333;   // +2.2       (2.200000)
localparam signed [31:0] d  = 32'h0166_6666;   // +1.4       (1.400000)

localparam signed [31:0] b1  = 32'h0007_AE14;  // 0.03
localparam signed [31:0] b2  = 32'h0007_AE14;  // 0.03
localparam signed [31:0] b3  = 32'h0007_AE14;  // 0.03


    // Q-multiply blocks (>>>24)
    wire signed [31:0] w11tanh1, w12p2, w13p3;
    wire signed [31:0] w21tanh1, w22p2, w23p3;
    wire signed [31:0] w31tanh1, w32p2, w33p3;
    wire signed [31:0] c1tanh1, c2p2, c3p3;
    wire signed [31:0] d_Sn_s, d_Sn_w, d_Sn_v;
    wire signed [31:0] W1, W2, W3;
    wire signed [31:0] w11W1tanh1, w22W2p2, w33W3p3;
    
    qmul_s24 u1 (.a(w11), .b(Tanh_x1), .y(w11tanh1));
    qmul_s24 u2 (.a(w12), .b(Pdf_x2), .y(w12p2));
    qmul_s24 u3 (.a(w13), .b(Pdf_x3), .y(w13p3));

    qmul_s24 u4 (.a(w21), .b(Tanh_x1), .y(w21tanh1));
    qmul_s24 u5 (.a(w22), .b(Pdf_x2), .y(w22p2));
    qmul_s24 u6 (.a(w23), .b(Pdf_x3), .y(w23p3));
    
    qmul_s24 u7 (.a(w31), .b(Tanh_x1), .y(w31tanh1));
    qmul_s24 u8 (.a(w32), .b(Pdf_x2), .y(w32p2));
    qmul_s24 u9 (.a(w33), .b(Pdf_x3), .y(w33p3));
    
    qmul_s24 u10(.a(c1), .b(Tanh_x1), .y(c1tanh1));
    qmul_s24 u11(.a(c2), .b(Pdf_x2), .y(c2p2));
    qmul_s24 u12(.a(c3), .b(Pdf_x3), .y(c3p3));
    
    qmul_s24 u13(.a(d), .b(Sn_s), .y(d_Sn_s));
    qmul_s24 u14(.a(d), .b(Sn_w), .y(d_Sn_w));
    qmul_s24 u15(.a(d), .b(Sn_v), .y(d_Sn_v));
    
    W_mem mem1(.a(b1), .b(Pdf_s), .y(W1));
    W_mem mem2(.a(b2), .b(Pdf_w), .y(W2));
    W_mem mem3(.a(b3), .b(Pdf_v), .y(W3));
    
    
    qmul_s24_reg2 u1_reg2(.clk(clk),.rst_n(rst_n),.a(W1), .b(w11tanh1), .y(w11W1tanh1)); // requires 2 clock cycles
    qmul_s24_reg2 u2_reg2(.clk(clk),.rst_n(rst_n),.a(W2), .b(w22p2), .y(w22W2p2));
    qmul_s24_reg2 u3_reg2(.clk(clk),.rst_n(rst_n),.a(W3), .b(w33p3), .y(w33W3p3));
    
    
    
    // Derivatives (registered)
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            dx1 <= 32'sd0;
            dx2 <= 32'sd0;
            dx3 <= 32'sd0;
            ds <= 32'sd0;
            dw <= 32'sd0;
            dv <= 32'sd0;
        end else begin
            dx1 <= (-x1) + w11W1tanh1 + w12p2 + w13p3;
            dx2 <= (-x2) + w21tanh1 + w22W2p2 + w23p3;
            dx3 <= (-x3) + w31tanh1 + w32p2 + w33W3p3;
            ds  <= c1tanh1-d_Sn_s;
            dw  <= c2p2-d_Sn_w;
            dv  <= c3p3-d_Sn_v;
        end
    end

endmodule
