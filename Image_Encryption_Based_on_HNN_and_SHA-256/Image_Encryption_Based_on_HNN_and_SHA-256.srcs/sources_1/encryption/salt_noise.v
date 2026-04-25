`timescale 1ns / 1ps
// ============================================================================
// Module: salt_noise
// Description:
//   Salt-and-pepper noise injection module.
//   - Each RGB channel independently controlled
//   - Noise pattern generated via ROM
// ============================================================================
module salt_noise(
    input               clk,
    input       [15:0]  addr,
    input       [23:0]  img_in,
    input       [23:0]  chaos_in,
    output      [23:0]  snoise_out
);

    // ------------------------------------------------------------------------
    // Noise selector: 2 bits per channel
    // 00 → normal (encrypted)
    // 01 → black (0x00)
    // 10 → white (0xFF)
    // ------------------------------------------------------------------------
    wire [5:0] snoise_case;

    salt_noise_rom u_s_noise_rom(
        .clka  (clk),
        .addra (img_in),
        .douta (snoise_case)
    );

    // ------------------------------------------------------------------------
    // Channel-wise noise injection
    // ------------------------------------------------------------------------
    wire [7:0] snoise_r, snoise_g, snoise_b;

    assign snoise_r = (snoise_case[1:0] == 2'b00) ? (img_in[23:16] ^ chaos_in[23:16]) :
                      (snoise_case[1:0] == 2'b01) ? 8'h00 :
                                                    8'hFF;

    assign snoise_g = (snoise_case[3:2] == 2'b00) ? (img_in[15:8] ^ chaos_in[15:8]) :
                      (snoise_case[3:2] == 2'b01) ? 8'h00 :
                                                    8'hFF;

    assign snoise_b = (snoise_case[5:4] == 2'b00) ? (img_in[7:0] ^ chaos_in[7:0]) :
                      (snoise_case[5:4] == 2'b01) ? 8'h00 :
                                                    8'hFF;

    assign snoise_out = {snoise_r, snoise_g, snoise_b};

endmodule
