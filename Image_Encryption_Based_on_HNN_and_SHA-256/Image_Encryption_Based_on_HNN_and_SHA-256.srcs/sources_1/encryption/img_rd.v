`timescale 1ns / 1ps

// ============================================================================
// Module Name: img_rd
// Description:
//   Image read controller with pipeline delay.
//   - Generates BRAM address
//   - Aligns address and valid signals (1-cycle delay)
// ============================================================================

module img_rd(
    input               clk,
    input               rst_n,

    input               chaos_valid,
    input               wr_enc_en,

    output      [15:0]  img_addra,
    output reg  [15:0]  img_addr,
    output reg          img_valid
);

    reg [15:0] img_addr_d0;
    reg        img_valid_d0;

    assign img_addra = img_addr_d0;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            img_addr     <= 16'd65535;
            img_addr_d0  <= 16'd65535;
            img_valid    <= 1'b0;
            img_valid_d0 <= 1'b0;
        end else begin
            img_valid <= 1'b0;

            if (chaos_valid | ~wr_enc_en) begin
                img_addr_d0  <= img_addr_d0 + 1'b1;
                img_valid_d0 <= 1'b1;
            end else begin
                img_valid_d0 <= 1'b0;
            end

            // 1-cycle pipeline alignment
            img_addr  <= img_addr_d0;
            img_valid <= img_valid_d0;
        end
    end

endmodule
