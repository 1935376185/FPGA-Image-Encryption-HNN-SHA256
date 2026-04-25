
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Module name: J_MHHNN
// Description: Top-level memristive Hopfield neural network with RK4 integration
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module J_MHHNN (
    input  wire clk,
    input  wire rst_n,
    
    input wire [31:0] s0,
    input wire [31:0] w0,
    input wire [31:0] v0,
    
    output wire signed [31:0] x1,
    output wire signed [31:0] x2,
    output wire signed [31:0] x3,
    output wire signed [31:0] s,
    output wire signed [31:0] w,
    output wire signed [31:0] v,
    output wire x_start,
    output wire x_valid
);

    // VIO: initial values + run/reset control
    wire signed [31:0] x10, x20,x30,s0,w0,v0;
    assign x10 = 32'h0010_0000;
    assign x20 = 32'h0000_0000;
    assign x30 = 32'h0000_0000;
   reg reset_n_run, reset_n_run_d1,reset_n_run_d2; // 0=run, 1=reload init
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            reset_n_run <= 1;
            reset_n_run_d1 <= 1;
            reset_n_run_d2 <= 1;
        end else begin
            reset_n_run_d2 <=0;
            reset_n_run_d1 <= reset_n_run_d2;
            reset_n_run <= reset_n_run_d1;
        end
    end


    // ---- State registers (from update module) ----
    wire signed [31:0] x1_r, x2_r, x3_r, s_r, w_r, v_r;

    // ---- RK4 evaluation point (to func) ----
    wire signed [31:0] xt1, xt2, xt3, st, wt, vt;

    // ---- Derivatives from func ----
    wire signed [31:0] dx1, dx2, dx3, ds, dw, dv;

    // ---- K values ----
    wire signed [31:0] k1_x1,k1_x2,k1_x3,k1_s, k1_w, k1_v;
    wire signed [31:0] k2_x1,k2_x2,k2_x3,k2_s, k2_w, k2_v;
    wire signed [31:0] k3_x1,k3_x2,k3_x3,k3_s, k3_w, k3_v;
    wire signed [31:0] k4_x1,k4_x2,k4_x3,k4_s, k4_w, k4_v;
    wire k_valid;


    // ---- Top outputs ----
    assign x1 = x1_r;
    assign x2 = x2_r;
    assign x3 = x3_r;
    assign s = s_r;
    assign w = w_r;
    assign v = v_r;

    // 1) K generator: produces xt, captures k1..k4, outputs k_valid
    rk4_kgen #(.WAIT_CYC(8)) u_kgen (
        .clk(clk),
        .rst_n(rst_n),

        .x1(x1_r), .x2(x2_r), .x3(x3_r), .s(s_r), .w(w_r), .v(v_r),

        .dx1(dx1), .dx2(dx2), .dx3(dx3), .ds(ds), .dw(dw), .dv(dv),

        .xt1(xt1), .xt2(xt2), .xt3(xt3), .st(st), .wt(wt), .vt(vt),

        .k1_x1(k1_x1),.k1_x2(k1_x2),.k1_x3(k1_x3),.k1_s(k1_s),.k1_w(k1_w),.k1_v(k1_v),
        .k2_x1(k2_x1),.k2_x2(k2_x2),.k2_x3(k2_x3),.k2_s(k2_s),.k2_w(k2_w),.k2_v(k2_v),
        .k3_x1(k3_x1),.k3_x2(k3_x2),.k3_x3(k3_x3),.k3_s(k3_s),.k3_w(k3_w),.k3_v(k3_v),
        .k4_x1(k4_x1),.k4_x2(k4_x2),.k4_x3(k4_x3),.k4_s(k4_s),.k4_w(k4_w),.k4_v(k4_v),
              
        .x_start(x_start),
        .k_valid(k_valid)
    );

    // 2) Function: uses xt to compute dx
    hnn_func u_func (
        .clk(clk),
        .rst_n(rst_n),
        .x1(xt1), .x2(xt2), .x3(xt3), .s(st), .w(wt), .v(vt),
        .dx1(dx1), .dx2(dx2), .dx3(dx3), .ds(ds), .dw(dw), .dv(dv)
    );

    // 3) Update: uses k_valid and k1..k4 to update x
    rk4_update u_upd (
        .clk(clk),
        .rst_n(rst_n),

        .init_x1(x10),
        .init_x2(x20),
        .init_x3(x30),
        .init_s(s0),
        .init_w(w0),
        .init_v(v0),
        .run_reset_n(reset_n_run),

        .k_valid(k_valid),

        .k1_x1(k1_x1),.k1_x2(k1_x2),.k1_x3(k1_x3),.k1_s(k1_s),.k1_w(k1_w),.k1_v(k1_v),
        .k2_x1(k2_x1),.k2_x2(k2_x2),.k2_x3(k2_x3),.k2_s(k2_s),.k2_w(k2_w),.k2_v(k2_v),
        .k3_x1(k3_x1),.k3_x2(k3_x2),.k3_x3(k3_x3),.k3_s(k3_s),.k3_w(k3_w),.k3_v(k3_v),
        .k4_x1(k4_x1),.k4_x2(k4_x2),.k4_x3(k4_x3),.k4_s(k4_s),.k4_w(k4_w),.k4_v(k4_v),
                                                             
        .x1(x1_r), .x2(x2_r), .x3(x3_r), .s(s_r), .w(w_r), .v(v_r),

        .x_valid(x_valid) // optional
    );
    
endmodule
































////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

