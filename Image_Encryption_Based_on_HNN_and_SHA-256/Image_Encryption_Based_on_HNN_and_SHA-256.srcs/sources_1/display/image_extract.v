
// ============================================================================
// Module: image_extract
// Description:
//   Image extraction and display control module.
//
// Functions:
//   - Generates ROM read address for image pixels
//   - Determines whether current pixel is inside image region
//   - Aligns ROM data with display timing (1-cycle delay)
//   - Outputs either image pixel or background color
// ============================================================================

module image_extract
#(
  parameter H_Visible_area = 800,
  parameter V_Visible_area = 480,
  parameter IMG_WIDTH      = 256,
  parameter IMG_HEIGHT     = 256,
  parameter IMG_DATA_WIDTH = 16,
  parameter ROM_ADDR_WIDTH = 16
)
(
  input                       clk_ctrl,
  input                       reset_n,

  input  [15:0]               img_disp_hbegin,
  input  [15:0]               img_disp_vbegin,

  input  [IMG_DATA_WIDTH-1:0] disp_back_color,

  output reg [ROM_ADDR_WIDTH-1:0] rom_addra,
  input      [IMG_DATA_WIDTH-1:0] rom_data,

  input                       Frame_Begin,
  input                       disp_data_req,
  input      [11:0]           visible_hcount,
  input      [11:0]           visible_vcount,

  output     [IMG_DATA_WIDTH-1:0] disp_data
);

  // ------------------------------------------------------------------------
  // Internal signals
  // ------------------------------------------------------------------------
  wire h_exceed;
  wire v_exceed;

  wire img_h_disp;
  wire img_v_disp;
  wire img_disp;

  reg  img_disp_d1;   // 1-cycle delayed valid signal

  wire [15:0] hcount_max;

  // ------------------------------------------------------------------------
  // Boundary checking (overflow handling)
  // ------------------------------------------------------------------------
  assign h_exceed = img_disp_hbegin + IMG_WIDTH  > H_Visible_area - 1'b1;
  assign v_exceed = img_disp_vbegin + IMG_HEIGHT > V_Visible_area - 1'b1;

  // ------------------------------------------------------------------------
  // Horizontal display region detection
  // ------------------------------------------------------------------------
  assign img_h_disp = h_exceed ? 
      (visible_hcount >= img_disp_hbegin && visible_hcount < H_Visible_area) :
      (visible_hcount >= img_disp_hbegin && visible_hcount < img_disp_hbegin + IMG_WIDTH);

  // ------------------------------------------------------------------------
  // Vertical display region detection
  // ------------------------------------------------------------------------
  assign img_v_disp = v_exceed ? 
      (visible_vcount >= img_disp_vbegin && visible_vcount < V_Visible_area) :
      (visible_vcount >= img_disp_vbegin && visible_vcount < img_disp_vbegin + IMG_HEIGHT);

  // ------------------------------------------------------------------------
  // Final display enable signal
  // ------------------------------------------------------------------------
  assign img_disp = disp_data_req && img_h_disp && img_v_disp;

  // ------------------------------------------------------------------------
  // Horizontal boundary (used for address jump)
  // ------------------------------------------------------------------------
  assign hcount_max = h_exceed ? 
      (H_Visible_area - 1'b1) : 
      (img_disp_hbegin + IMG_WIDTH - 1'b1);

  // ------------------------------------------------------------------------
  // Pipeline alignment (critical for ROM latency)
  // ------------------------------------------------------------------------
  always @(posedge clk_ctrl or negedge reset_n) begin
    if(!reset_n)
      img_disp_d1 <= 1'b0;
    else
      img_disp_d1 <= img_disp;
  end

  // ------------------------------------------------------------------------
  // ROM address generation
  // ------------------------------------------------------------------------
  always @(posedge clk_ctrl or negedge reset_n) begin
    if(!reset_n)
      rom_addra <= 'd0;
    else if(Frame_Begin)
      rom_addra <= 'd0;
    else if(img_disp) begin
      if(visible_hcount == hcount_max)
        // Jump to next row
        rom_addra <= rom_addra + (img_disp_hbegin + IMG_WIDTH - hcount_max);
      else
        // Next pixel
        rom_addra <= rom_addra + 1'b1;
    end
  end

  // ------------------------------------------------------------------------
  // Output pixel selection
  // NOTE:
  //   ROM has 1-cycle latency → must use delayed valid signal
  // ------------------------------------------------------------------------
  assign disp_data = img_disp_d1 ?
      {rom_data[23:19], rom_data[15:10], rom_data[7:3]} :
      disp_back_color;

endmodule