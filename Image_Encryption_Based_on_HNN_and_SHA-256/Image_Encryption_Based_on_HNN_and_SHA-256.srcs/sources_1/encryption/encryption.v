`timescale 1ns / 1ps
// ============================================================================
// Module: encryption
// Description:
//   Core encryption module using XOR diffusion.
//   - Lightweight and hardware-efficient
//   - Combined with chaotic sequence for randomness
// ============================================================================
module encryption(
    input       [23:0] img_in,
    input       [23:0] chaos_in,
    output      [23:0] encrypt_out
);

    // ------------------------------------------------------------------------
    // XOR-based diffusion
    // ------------------------------------------------------------------------
    assign encrypt_out = img_in ^ chaos_in;

endmodule
