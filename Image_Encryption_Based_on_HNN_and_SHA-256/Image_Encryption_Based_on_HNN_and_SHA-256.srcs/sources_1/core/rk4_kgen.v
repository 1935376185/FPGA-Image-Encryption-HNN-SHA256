// ============================================================
// Submodule 1: RK4 core (your original mHNN FSM, cleaner I/O)
// ============================================================
// WAIT_CYC = 8 cycles for stable values; if different, it matches SHA256 latency.
module rk4_kgen #(
    parameter integer WAIT_CYC = 8  
)(
    input  wire clk,
    input  wire rst_n,

    // current state (from x-update registers)
    input  wire signed [31:0] x1,
    input  wire signed [31:0] x2,
    input  wire signed [31:0] x3,
    input  wire signed [31:0] s,
    input  wire signed [31:0] w,
    input  wire signed [31:0] v,

    // derivative outputs from func (corresponding to current x_t)
    input  wire signed [31:0] dx1,
    input  wire signed [31:0] dx2,
    input  wire signed [31:0] dx3,
    input  wire signed [31:0] ds,
    input  wire signed [31:0] dw,
    input  wire signed [31:0] dv,

    // evaluation point to func (x_t)
    output reg  signed [31:0] xt1,
    output reg  signed [31:0] xt2,
    output reg  signed [31:0] xt3,
    output reg  signed [31:0] st,
    output reg  signed [31:0] wt,
    output reg  signed [31:0] vt,

    // output four k values
    output reg  signed [31:0] k1_x1,k1_x2,k1_x3,k1_s,k1_w,k1_v,  
    output reg  signed [31:0] k2_x1,k2_x2,k2_x3,k2_s,k2_w,k2_v,  
    output reg  signed [31:0] k3_x1,k3_x2,k3_x3,k3_s,k3_w,k3_v,  
    output reg  signed [31:0] k4_x1,k4_x2,k4_x3,k4_s,k4_w,k4_v,  

    // pulse indicating all four k are ready (single cycle)
    output reg x_start,
    output reg  k_valid
);

    localparam signed [31:0] h_step = 32'h0002_8f5c;

    reg [3:0] state;
    reg [6:0] cnt;

    localparam [3:0] S_SET_K1  = 4'd0;
    localparam [3:0] S_WAIT_K1 = 4'd1;
    localparam [3:0] S_SET_K2  = 4'd2;
    localparam [3:0] S_WAIT_K2 = 4'd3;
    localparam [3:0] S_SET_K3  = 4'd4;
    localparam [3:0] S_WAIT_K3 = 4'd5;
    localparam [3:0] S_SET_K4  = 4'd6;
    localparam [3:0] S_WAIT_K4 = 4'd7;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= S_SET_K1;
            cnt <= 0;
            k_valid <= 1'b0;
            xt1 <= 0; xt2 <= 0; xt3 <= 0; st<=0; wt<=0; vt<=0;
            k1_x1<=0;k1_x2<=0;k1_x3<=0;k1_s<=0;k1_w<=0;k1_v<=0; 
            k2_x1<=0;k2_x2<=0;k2_x3<=0;k2_s<=0;k2_w<=0;k2_v<=0; 
            k3_x1<=0;k3_x2<=0;k3_x3<=0;k3_s<=0;k3_w<=0;k3_v<=0; 
            k4_x1<=0;k4_x2<=0;k4_x3<=0;k4_s<=0;k4_w<=0;k4_v<=0; 
            x_start <= 1'b0;
        end else begin
            k_valid <= 1'b0;
            x_start <= 1'b0;
            
            case(state)
                // ---- K1: xt = x ----
                S_SET_K1: begin
                    xt1 <= x1; xt2 <= x2; xt3 <= x3; st <= s; wt <= w; vt <= v;
                    cnt <= 0;
                    state <= S_WAIT_K1;
                    x_start <= 1'b1;
                end

                S_WAIT_K1: begin
                    if(cnt == WAIT_CYC-1) begin
                        k1_x1 <= dx1; k1_x2 <= dx2; k1_x3 <= dx3; k1_s <= ds; k1_w <= dw; k1_v <= dv; 
                        cnt <= 0;
                        state <= S_SET_K2;
                    end else begin
                        cnt <= cnt + 1;
                    end
                end

                // ---- K2: xt = x + h/2*k1 (original uses >>>25) ----
                S_SET_K2: begin
                    xt1 <= x1 + (k1_x1*h_step >>> 25);
                    xt2 <= x2 + (k1_x2*h_step >>> 25);
                    xt3 <= x3 + (k1_x3*h_step >>> 25);
                    st <= s + (k1_s*h_step >>> 25);
                    wt <= w + (k1_w*h_step >>> 25);
                    vt <= v + (k1_v*h_step >>> 25);
                    cnt <= 0;
                    state <= S_WAIT_K2;
                end

                S_WAIT_K2: begin
                    if(cnt == WAIT_CYC-1) begin
                        k2_x1 <= dx1; k2_x2 <= dx2; k2_x3 <= dx3; k2_s <= ds; k2_w <= dw; k2_v <= dv;
                        cnt <= 0;
                        state <= S_SET_K3;
                    end else begin
                        cnt <= cnt + 1;
                    end
                end

                // ---- K3: xt = x + h/2*k2 (original uses >>>25) ----
                S_SET_K3: begin
                    xt1 <= x1 + (k2_x1*h_step >>> 25);
                    xt2 <= x2 + (k2_x2*h_step >>> 25);
                    xt3 <= x3 + (k2_x3*h_step >>> 25);
                    st <= s + (k2_s*h_step >>> 25);
                    wt <= w + (k2_w*h_step >>> 25);
                    vt <= v + (k2_v*h_step >>> 25);
                    cnt <= 0;
                    state <= S_WAIT_K3;
                end

                S_WAIT_K3: begin
                    if(cnt == WAIT_CYC-1) begin
                        k3_x1 <= dx1; k3_x2 <= dx2; k3_x3 <= dx3; k3_s <= ds; k3_w <= dw; k3_v <= dv;
                        cnt <= 0;
                        state <= S_SET_K4;
                    end else begin
                        cnt <= cnt + 1;
                    end
                end

                // ---- K4: xt = x + h*k3 (original uses >>>24) ----
                S_SET_K4: begin
                    xt1 <= x1 + (k3_x1*h_step >>> 24);
                    xt2 <= x2 + (k3_x2*h_step >>> 24);
                    xt3 <= x3 + (k3_x3*h_step >>> 24);
                    st <= s + (k3_s*h_step >>> 24);
                    wt <= w + (k3_w*h_step >>> 24);
                    vt <= v + (k3_v*h_step >>> 24);
                    cnt <= 0;
                    state <= S_WAIT_K4;
                end

                S_WAIT_K4: begin
                    if(cnt == WAIT_CYC-1) begin //68
                        k4_x1 <= dx1; k4_x2 <= dx2; k4_x3 <= dx3; k4_s <= ds; k4_w <= dw; k4_v <= dv;
                        k_valid <= 1'b1;      // all four k ready
                        cnt <= 0;
                        state <= S_SET_K1;    // next iteration
                    end else begin
                        cnt <= cnt + 1;
                    end
                end

                default: state <= S_SET_K1;
            endcase
        end
    end

endmodule