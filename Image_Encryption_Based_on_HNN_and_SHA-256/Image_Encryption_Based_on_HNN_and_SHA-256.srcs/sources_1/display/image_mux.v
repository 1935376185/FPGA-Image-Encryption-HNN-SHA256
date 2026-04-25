`timescale 1ns / 1ps
// ============================================================================
// Module Name: image_mux
// Description:
//   Dual-image pixel selector.
//   Selects which image data to output based on current display coordinates.
//
// Parameters:
//   - TFT_WIDTH / TFT_HEIGHT : Display resolution
//   - IMG_WIDTH / IMG_HEIGHT : Image size
//   - IMG_DATA_WIDTH         : Pixel bit width
//   - BACK_COLOR             : Background color
// ============================================================================

module image_mux #(
    parameter TFT_WIDTH      = 800,
    parameter TFT_HEIGHT     = 480,
    parameter IMG_WIDTH      = 256,
    parameter IMG_HEIGHT     = 256,
    parameter IMG_DATA_WIDTH = 16,
    parameter BACK_COLOR     = 16'hFFFF,  // Default: white background

    // Image 1 position (left image)
    parameter IMG1_HBEGIN    = 80,
    parameter IMG1_VBEGIN    = 112,

    // Image 2 position (right image)
    parameter IMG2_HBEGIN    = 464,
    parameter IMG2_VBEGIN    = 112
)(
    input  wire                         clk,
    input  wire                         rst_n,

    // Current scan coordinates
    input  wire [11:0]                  visible_hcount,
    input  wire [11:0]                  visible_vcount,

    // Pixel data from two images
    input  wire [IMG_DATA_WIDTH-1:0]    disp_data_1,
    input  wire [IMG_DATA_WIDTH-1:0]    disp_data_2,

    // Output merged pixel data
    output wire [IMG_DATA_WIDTH-1:0]    final_disp_data
);

    // ------------------------------------------------------------------------
    // Region detection
    // ------------------------------------------------------------------------
    wire in_img1_region;
    wire in_img2_region;

    assign in_img1_region =
        (visible_hcount >= IMG1_HBEGIN) &&
        (visible_hcount <  IMG1_HBEGIN + IMG_WIDTH) &&
        (visible_vcount >= IMG1_VBEGIN) &&
        (visible_vcount <  IMG1_VBEGIN + IMG_HEIGHT);

    assign in_img2_region =
        (visible_hcount >= IMG2_HBEGIN) &&
        (visible_hcount <  IMG2_HBEGIN + IMG_WIDTH) &&
        (visible_vcount >= IMG2_VBEGIN) &&
        (visible_vcount <  IMG2_VBEGIN + IMG_HEIGHT);

    // ------------------------------------------------------------------------
    // Pixel selection logic
    // ------------------------------------------------------------------------
    assign final_disp_data =
        in_img1_region ? disp_data_1 :
        in_img2_region ? disp_data_2 :
        BACK_COLOR;

endmodule
