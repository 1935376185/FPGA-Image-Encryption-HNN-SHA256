`timescale 1ns / 1ps
// ============================================================================
// Module: gaussian_noise
// Description:
//   Gaussian noise injection module.
//   - Generates pseudo-Gaussian noise from ROM
//   - Applies encryption (XOR) + additive noise
// ============================================================================
module gaussian_noise(
    input               clk,
    input       [15:0]  addr,
    input       [23:0]  img_in,
    input       [23:0]  chaos_in,
    output      [23:0]  gnoise_out
);

    // ------------------------------------------------------------------------
    // Noise source (ROM-based)
    // ------------------------------------------------------------------------
    wire [7:0] gnoise;

    gaussian_noise_rom u_gn_noise_rom(
        .clka  (clk),
        .addra (addr),
        .douta (gnoise)
    );

    // ------------------------------------------------------------------------
    // Gaussian noise model
    // Formula: (Image XOR Chaos) + Noise
    // ------------------------------------------------------------------------
    assign gnoise_out = (img_in ^ chaos_in) + {gnoise, gnoise, gnoise};

endmodule
