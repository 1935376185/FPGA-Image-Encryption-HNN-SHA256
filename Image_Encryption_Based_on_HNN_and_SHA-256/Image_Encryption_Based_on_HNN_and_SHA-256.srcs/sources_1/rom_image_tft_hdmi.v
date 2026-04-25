
// ============================================================================
// Top Module: rom_image_tft_hdmi
// Description:
//   - Image encryption + decryption system
//   - Dual image display on TFT (original + encrypted)
//   - HDMI initialization via SiI9022
// ============================================================================

module rom_image_tft_hdmi (
    input         sys_clk,        // System clock input (50 MHz)
    input         reset_n,        // Active-low reset
    
    // TFT interface
    output [15:0] TFT_rgb,        // RGB output
    output        TFT_hs,         // Horizontal sync
    output        TFT_vs,         // Vertical sync
    output        TFT_clk,        // Pixel clock
    output        TFT_de,         // Data enable
    output        TFT_pwm,        // Backlight control
    
    // HDMI (SiI9022)
    output        SiI9022_sclk,   // I2C clock
    inout         SiI9022_sdat,   // I2C data
    output        led             // Init done indicator
);

// ============================================================================
// Internal Signals
// ============================================================================

wire enc_img_valid;
wire wr_enc_ena;
wire soft_reset;
wire denc;  // 0: encryption, 1: decryption

wire [15:0] img_addr, disp_img_addr;
wire [15:0] img_addr1, img_addr2;
wire [15:0] enc_img_addra, disp_enc_img_addra;

wire [23:0] img_din, img_out, enc_din, enc_dout;
wire [23:0] img_out1, img_out2;
wire [23:0] disp_img_out, disp_enc_dout;

// ============================================================================
// Memory Blocks
// ============================================================================

// Original image storage (dual-port RAM)
image256x256 image_inst (
    .addra(img_addr1),
    .clka(clk80M),
    .dina(enc_din),
    .douta(img_out1),
    .wea(wr_enc_ena && denc),

    .addrb(disp_img_addr),
    .clkb(loc_clk33M),
    .dinb(),
    .doutb(disp_img_out),
    .web(1'b0)
);

// Encrypted image storage
Encrypted_image Enc_img (
    .clka(clk80M),
    .wea(wr_enc_ena && !denc),
    .addra(img_addr2),
    .dina(enc_din),
    .douta(img_out2),

    .clkb(loc_clk33M),
    .web(1'b0),
    .addrb(disp_enc_img_addra),
    .dinb(),
    .doutb(disp_enc_dout)
);

// ============================================================================
// Control via VIO (for debugging)
// ============================================================================

vio_denc u_vio_denc (
    .clk(clk80M),
    .probe_out0(soft_reset),
    .probe_out1(denc)
);

// Address/data switching between encryption & decryption
assign img_addr1 = (!denc) ? img_addr : enc_img_addra;
assign img_addr2 = (!denc) ? enc_img_addra : img_addr;

assign img_out  = (!denc) ? img_out1 : img_out2;
assign enc_dout = (!denc) ? img_out2 : img_out1;

// ============================================================================
// Image Encryption Core
// ============================================================================

Image_encryption u_Image_encryption (
    .clk(clk80M),
    .rst_n(reset_n),
    .soft_reset(soft_reset),
    .denc(denc),

    .enc_img_valid(enc_img_valid),

    .img_addra(img_addr),
    .img_out(img_out),

    .wr_enc_ena(wr_enc_ena),
    .enc_img_addra(enc_img_addra),
    .enc_din(enc_din),
    .enc_dout(enc_dout)
);

// ============================================================================
// Display Parameters
// ============================================================================

parameter DISP_IMAGE_W    = 256;
parameter DISP_IMAGE_H    = 256;
parameter ROM_ADDR_WIDTH  = 16;
parameter DISP_BACK_COLOR = 16'hFFFF; // White background

parameter TFT_WIDTH  = 800;
parameter TFT_HEIGHT = 480;

// Image positions
parameter IMG1_HBEGIN = 80;
parameter IMG1_VBEGIN = (TFT_HEIGHT - DISP_IMAGE_H) / 2;

parameter IMG2_HBEGIN = 464;
parameter IMG2_VBEGIN = (TFT_HEIGHT - DISP_IMAGE_H) / 2;

// ============================================================================
// Clock Generation
// ============================================================================

wire pll_locked;
wire loc_clk33M, clk80M;  

//pll pll (
//    .clk_out1(loc_clk33M),
//    .resetn(reset_n),
//    .locked(pll_locked),
//    .clk_in1(clk80M)
//);

clk_wiz_0 u_clk (
    .clk_in1   (sys_clk),   // 50 MHz
    .clk_out1  (loc_clk33M),   // 33 MHz
    .clk_out2  (clk80M),   // 80 MHz
    .resetn(reset_n),
    .locked(pll_locked)
);

// ============================================================================
// Image Extraction (Original + Encrypted)
// ============================================================================

wire [11:0] visible_hcount, visible_vcount;
wire disp_data_req, Frame_Begin;

wire [15:0] disp_data_1, disp_data_2, final_disp_data;

// Encrypted image display
image_extract #(
    .H_Visible_area(TFT_WIDTH),
    .V_Visible_area(TFT_HEIGHT),
    .IMG_WIDTH(DISP_IMAGE_W),
    .IMG_HEIGHT(DISP_IMAGE_W),
    .IMG_DATA_WIDTH(24),
    .ROM_ADDR_WIDTH(ROM_ADDR_WIDTH)
) image_extract1 (
    .clk_ctrl(loc_clk33M),
    .reset_n(pll_locked),
    .img_disp_hbegin(IMG1_HBEGIN),
    .img_disp_vbegin(IMG1_VBEGIN),
    .disp_back_color(DISP_BACK_COLOR),

    .rom_addra(disp_enc_img_addra),
    .rom_data(disp_enc_dout),

    .Frame_Begin(Frame_Begin),
    .disp_data_req(disp_data_req),
    .visible_hcount(visible_hcount),
    .visible_vcount(visible_vcount),
    .disp_data(disp_data_1)
);

// Original image display
image_extract #(
    .H_Visible_area(TFT_WIDTH),
    .V_Visible_area(TFT_HEIGHT),
    .IMG_WIDTH(DISP_IMAGE_W),
    .IMG_HEIGHT(DISP_IMAGE_W),
    .IMG_DATA_WIDTH(24),
    .ROM_ADDR_WIDTH(ROM_ADDR_WIDTH)
) image_extract2 (
    .clk_ctrl(loc_clk33M),
    .reset_n(pll_locked),
    .img_disp_hbegin(IMG2_HBEGIN),
    .img_disp_vbegin(IMG2_VBEGIN),
    .disp_back_color(DISP_BACK_COLOR),

    .rom_addra(disp_img_addr),
    .rom_data(disp_img_out),

    .Frame_Begin(Frame_Begin),
    .disp_data_req(disp_data_req),
    .visible_hcount(visible_hcount),
    .visible_vcount(visible_vcount),
    .disp_data(disp_data_2)
);

// ============================================================================
// Image Multiplexer (merge two images)
// ============================================================================

image_mux #(
    .TFT_WIDTH(TFT_WIDTH),
    .TFT_HEIGHT(TFT_HEIGHT),
    .IMG_WIDTH(DISP_IMAGE_W),
    .IMG_HEIGHT(DISP_IMAGE_H),
    .IMG_DATA_WIDTH(16),
    .BACK_COLOR(DISP_BACK_COLOR),
    .IMG1_HBEGIN(IMG1_HBEGIN),
    .IMG1_VBEGIN(IMG1_VBEGIN),
    .IMG2_HBEGIN(IMG2_HBEGIN),
    .IMG2_VBEGIN(IMG2_VBEGIN)
) u_image_mux (
    .clk(loc_clk33M),
    .rst_n(pll_locked),
    .visible_hcount(visible_hcount),
    .visible_vcount(visible_vcount),
    .disp_data_1(disp_data_1),
    .disp_data_2(disp_data_2),
    .final_disp_data(final_disp_data)
);

// ============================================================================
// TFT Display Driver
// ============================================================================

wire [4:0] Disp_Red;
wire [5:0] Disp_Green;
wire [4:0] Disp_Blue;
wire tft_reset_p;

disp_driver disp_driver (
    .ClkDisp(loc_clk33M),
    .Rst_p(tft_reset_p),

    .Data(final_disp_data),
    .DataReq(disp_data_req),

    .H_Addr(visible_hcount),
    .V_Addr(visible_vcount),

    .Disp_HS(TFT_hs),
    .Disp_VS(TFT_vs),
    .Disp_Red(Disp_Red),
    .Disp_Green(Disp_Green),
    .Disp_Blue(Disp_Blue),
    .Frame_Begin(Frame_Begin),

    .Disp_DE(TFT_de),
    .Disp_PCLK(TFT_clk)
);

assign tft_reset_p = ~pll_locked;
assign TFT_rgb = {Disp_Red, Disp_Green, Disp_Blue};
assign TFT_pwm = 1'b1;

// ============================================================================
// HDMI Initialization (SiI9022)
// ============================================================================

wire Go;

// Delay generator (0 ms)
delay_pulse_gen #(
    .DELAY_TIME_MS(0),
    .CLK_FREQ_MHZ(250)
) u_delay_pulse (
    .clk(clk80M),
    .rst_n(reset_n),
    .pulse_out(Go)
);

// HDMI initialization module
SiI9022_Init SiI9022_Init (
    .Clk(clk80M),
    .Rst_n(reset_n),
    .Go(Go),
    .device_id(8'h72),
    .Init_Done(led),
    .i2c_sclk(SiI9022_sclk),
    .i2c_sdat(SiI9022_sdat)
);

endmodule





