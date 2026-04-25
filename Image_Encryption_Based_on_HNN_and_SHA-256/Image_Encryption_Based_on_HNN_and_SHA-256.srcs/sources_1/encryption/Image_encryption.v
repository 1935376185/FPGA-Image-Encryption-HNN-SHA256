`timescale 1ns / 1ps

// ============================================================================
// Module Name: Image_encryption
// Description:
//   Top-level module for image encryption system.
//   Integrates key generation, chaotic diffusion, memory read/write control.
//
// Features:
//   - Supports encryption / decryption switching (denc)
//   - Uses SHA256-based key initialization
//   - Modular design for scalability and clarity
// ============================================================================

module Image_encryption(
    input               clk,
    input               rst_n,
    input               soft_reset,
    input               denc,

    output              enc_img_valid,
    output      [15:0]  img_addra,
    input       [23:0]  img_out,

    output              wr_enc_ena,
    output      [15:0]  enc_img_addra,
    output      [23:0]  enc_din,
    input       [23:0]  enc_dout
);

    // ------------------------------------------------------------------------
    // Internal signals
    // ------------------------------------------------------------------------
    wire [15:0] img_addr;
    wire        img_valid;

    wire signed [31:0] s0, w0, v0;
    wire [255:0]       key_sha;

    wire [23:0] chaos_out;
    wire        chaos_valid;

    // ------------------------------------------------------------------------
    // SHA256-based key generation
    // ------------------------------------------------------------------------
    KEY_SHA256 u_KEY_SHA256(
        .clka   (clk),
        .addra  (0),
        .douta  (key_sha)
    );

    assign s0 = key_sha[95:64];
    assign w0 = key_sha[63:32];
    assign v0 = key_sha[31:0];

    // ------------------------------------------------------------------------
    // Image read controller
    // ------------------------------------------------------------------------
    img_rd u_img_rd(
        .clk        (clk),
        .rst_n      (rst_n && soft_reset),
        .chaos_valid(chaos_valid),
        .wr_enc_en  (wr_enc_ena),

        .img_addra  (img_addra),
        .img_addr   (img_addr),
        .img_valid  (img_valid)
    );

    // ------------------------------------------------------------------------
    // Chaotic diffusion core
    // ------------------------------------------------------------------------
    diffusion_top u_diffusion_top(
        .clk        (clk),
        .rst_n      (rst_n && soft_reset),

        .s0         (s0),
        .w0         (w0),
        .v0         (v0),

        .img_valid  (img_valid),
        .img_out    (img_out),

        .chaos_out  (chaos_out),
        .chaos_valid(chaos_valid)
    );

    // ------------------------------------------------------------------------
    // Write-back controller
    // ------------------------------------------------------------------------
    enc_img_we u_enc_img_we(
        .clk          (clk),
        .rst_n        (rst_n && soft_reset),
        .denc         (denc),

        .chaos_valid  (chaos_valid),
        .chaos_in     (chaos_out),

        .img_addr     (img_addr),
        .img_out      (img_out),

        .enc_img_valid(enc_img_valid),

        .wr_enc_ena   (wr_enc_ena),
        .enc_img_addra(enc_img_addra),
        .enc_din      (enc_din)
    );

endmodule
