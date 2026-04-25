`timescale 1ns / 1ps
// ============================================================================
// Module Name: enc_img_we
// Description:
//   Write-back controller for encrypted image data.
//   - Handles chaos delay (2 cycles)
//   - Controls write enable, address, and data
//   - Supports encryption / noise injection modes
// ============================================================================

module enc_img_we(
    input               clk,
    input               rst_n,
    input               denc,

    input               chaos_valid,
    input       [23:0]  chaos_in,

    input       [15:0]  img_addr,
    input       [23:0]  img_out,

    output              enc_img_valid,

    output              wr_enc_ena,
    output      [15:0]  enc_img_addra,
    output      [23:0]  enc_din
);

    // ------------------------------------------------------------------------
    // Registers
    // ------------------------------------------------------------------------
    reg         wr_enc_en;
    reg [15:0]  enc_img_addr;
    reg [23:0]  wr_enc_data;

    assign wr_enc_ena     = wr_enc_en;
    assign enc_img_addra  = enc_img_addr;
    assign enc_din        = wr_enc_data;

    // ------------------------------------------------------------------------
    // Write control logic
    // ------------------------------------------------------------------------
    reg [16:0] write_cnt;
    reg        write_done;

    wire write_request = ~write_done;

    // ------------------------------------------------------------------------
    // Chaos signal pipeline (2-cycle delay)
    // ------------------------------------------------------------------------
    reg [23:0] chaos_out_d0, chaos_out_d1;
    reg        chaos_valid_d0, chaos_valid_d1;

    wire [23:0] chaos_out;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            chaos_valid_d0 <= 1'b0;
            chaos_valid_d1 <= 1'b0;
            chaos_out_d0   <= 24'd0;
            chaos_out_d1   <= 24'd0;
        end else begin
            chaos_valid_d0 <= chaos_valid;
            chaos_valid_d1 <= chaos_valid_d0;

            chaos_out_d1   <= chaos_in;
            chaos_out_d0   <= chaos_out_d1;
        end
    end

    assign enc_img_valid = chaos_valid_d1;
    assign chaos_out     = chaos_out_d0;

    // ------------------------------------------------------------------------
    // Write counter
    // ------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_cnt  <= 17'd0;
            write_done <= 1'b0;
        end else if (write_request & (chaos_valid | ~wr_enc_en)) begin
            write_cnt <= write_cnt + 1'b1;

            if (write_cnt == 17'd65536)
                write_done <= 1'b1;
        end
    end

    // ------------------------------------------------------------------------
    // Mode selection (via VIO)
    // ------------------------------------------------------------------------
    wire [1:0] caseTest;

    vio_SecurityTest u_vio_SecurityTest(
        .clk(clk),
        .probe_out0(caseTest)
    );

    // ------------------------------------------------------------------------
    // Encryption / Noise selection
    // ------------------------------------------------------------------------
    wire [23:0] encrypt_out, gnoise_out, snoise_out;

    assign ciphertext =
        (caseTest == 2'b00) ? img_out :
        (caseTest == 2'b01) ? encrypt_out :
        (caseTest == 2'b10) ? gnoise_out :
                             snoise_out;

    wire [23:0] ciphertext;

    // ------------------------------------------------------------------------
    // Write operation
    // ------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_enc_en    <= 1'b1;
            wr_enc_data  <= 24'd0;
            enc_img_addr <= 16'd65535;
        end else begin
            if (write_request & chaos_valid) begin
                wr_enc_en    <= 1'b1;
                enc_img_addr <= img_addr;
                wr_enc_data  <= ciphertext;
            end
            else if (!write_request) begin
                wr_enc_en    <= 1'b0;
                wr_enc_data  <= 24'd0;
                enc_img_addr <= img_addr;
            end
        end
    end

    // ------------------------------------------------------------------------
    // Submodules
    // ------------------------------------------------------------------------
    encryption u_encryption(
        .img_in(img_out),
        .chaos_in(chaos_out),
        .encrypt_out(encrypt_out)
    );

    gaussian_noise u_gaussian_noise(
        .clk(clk),
        .addr(img_addr),
        .img_in(img_out),
        .chaos_in(chaos_out),
        .gnoise_out(gnoise_out)
    );

    salt_noise u_salt_noise(
        .clk(clk),
        .addr(img_addr),
        .img_in(img_out),
        .chaos_in(chaos_out),
        .snoise_out(snoise_out)
    );

endmodule
