/////////////////////////////////////////////////////////////////////////////////
// Company       : CoreCourse Technology Co., Ltd.
//                 http://xiaomeige.taobao.com
// Web           : http://www.corecourse.cn
// 
// Create Date   : 2020/07/20 00:00:00
// Module Name   : Display Device Hardware Parameter Header File
// Description   : Hardware timing and color depth parameters for various displays.
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
/////////////////////////////////////////////////////////////////////////////////

/* Usage Instructions:
When using, please select two predefined macros based on your actual hardware.

Setting 1: MODE_RGBxxx
Predefined color depth macros. Select either 16-bit or 24-bit mode:
  MODE_RGB888: 24-bit mode
  MODE_RGB565: 16-bit mode

Common device recommendations:
  4.3-inch TFT Display: Use 16-bit RGB565 mode
  5-inch TFT Display:   Use 16-bit RGB565 mode
  GM7123 VGA Module:    Use 24-bit RGB888 mode

Setting 2: Resolution_xxxx
Predefined resolution macros. Select based on your hardware:

4.3-inch TFT:
  Resolution_480x272

5-inch TFT:
  Resolution_800x480

VGA Resolutions:
  Resolution_640x480
  Resolution_800x600
  Resolution_1024x600
  Resolution_1024x768
  Resolution_1280x720
  Resolution_1920x1080
*/

// Select the display device type by uncommenting ONE of the following lines:

// Use 4.3-inch 480x272 TFT Display
// `define HW_TFT43

// Use 5-inch 800x480 TFT Display
`define HW_TFT50

// Use VGA Display (Default: 640x480, 24-bit). 
// You can modify resolution or bit depth in the logic below.
// `define HW_VGA

//===============================================================================
// Macro Mapping: Assigns Color Depth and Resolution based on Hardware Selection
//===============================================================================
`ifdef HW_TFT43  // 4.3-inch 480x272
  `define MODE_RGB565
  `define Resolution_480x272 1 // Clock: 9MHz

`elsif HW_TFT50  // 5-inch 800x480
  `define MODE_RGB565
  `define Resolution_800x480 1 // Clock: 33MHz

`elsif HW_VGA    // VGA Display
  // Select bit depth and resolution for VGA here:
  `define MODE_RGB565
  // `define MODE_RGB888
  `define Resolution_640x480   1 // Clock: 25.175MHz
  // `define Resolution_800x600   1 // Clock: 40MHz
  // `define Resolution_1024x600  1 // Clock: 51MHz
  // `define Resolution_1024x768  1 // Clock: 65MHz
  // `define Resolution_1280x720  1 // Clock: 74.25MHz
  // `define Resolution_1920x1080 1 // Clock: 148.5MHz
`endif

//===============================================================================
// Automatic Parameter Definitions (Do not modify below this line)
//===============================================================================

// Define color bit widths
`ifdef MODE_RGB888
  `define Red_Bits   8
  `define Green_Bits 8
  `define Blue_Bits  8
  
`elsif MODE_RGB565
  `define Red_Bits   5
  `define Green_Bits 6
  `define Blue_Bits  5
`endif

// Define Timing Parameters for various resolutions
`ifdef Resolution_480x272
  `define H_Total_Time    12'd525
  `define H_Right_Border  12'd0
  `define H_Front_Porch   12'd2
  `define H_Sync_Time     12'd41
  `define H_Back_Porch    12'd2
  `define H_Left_Border   12'd0

  `define V_Total_Time    12'd286
  `define V_Bottom_Border 12'd0
  `define V_Front_Porch   12'd2
  `define V_Sync_Time     12'd10
  `define V_Back_Porch    12'd2
  `define V_Top_Border    12'd0
  
`elsif Resolution_640x480
  `define H_Total_Time    12'd800
  `define H_Right_Border  12'd8
  `define H_Front_Porch   12'd8
  `define H_Sync_Time     12'd96
  `define H_Back_Porch    12'd40
  `define H_Left_Border   12'd8

  `define V_Total_Time    12'd525
  `define V_Bottom_Border 12'd8
  `define V_Front_Porch   12'd2
  `define V_Sync_Time     12'd2
  `define V_Back_Porch    12'd25
  `define V_Top_Border    12'd8

`elsif Resolution_800x480
  `define H_Total_Time    12'd1056
  `define H_Right_Border  12'd0
  `define H_Front_Porch   12'd40
  `define H_Sync_Time     12'd128
  `define H_Back_Porch    12'd88
  `define H_Left_Border   12'd0

  `define V_Total_Time    12'd525
  `define V_Bottom_Border 12'd8
  `define V_Front_Porch   12'd2
  `define V_Sync_Time     12'd2
  `define V_Back_Porch    12'd25
  `define V_Top_Border    12'd8

`elsif Resolution_800x600
  `define H_Total_Time    12'd1056
  `define H_Right_Border  12'd0
  `define H_Front_Porch   12'd40
  `define H_Sync_Time     12'd128
  `define H_Back_Porch    12'd88
  `define H_Left_Border   12'd0

  `define V_Total_Time    12'd628
  `define V_Bottom_Border 12'd0
  `define V_Front_Porch   12'd1
  `define V_Sync_Time     12'd4
  `define V_Back_Porch    12'd23
  `define V_Top_Border    12'd0

`elsif Resolution_1024x600
  `define H_Total_Time    12'd1344
  `define H_Right_Border  12'd0
  `define H_Front_Porch   12'd24
  `define H_Sync_Time     12'd136
  `define H_Back_Porch    12'd160
  `define H_Left_Border   12'd0

  `define V_Total_Time    12'd628
  `define V_Bottom_Border 12'd0
  `define V_Front_Porch   12'd1
  `define V_Sync_Time     12'd4
  `define V_Back_Porch    12'd23
  `define V_Top_Border    12'd0

`elsif Resolution_1024x768
  `define H_Total_Time    12'd1344
  `define H_Right_Border  12'd0
  `define H_Front_Porch   12'd24
  `define H_Sync_Time     12'd136
  `define H_Back_Porch    12'd160
  `define H_Left_Border   12'd0

  `define V_Total_Time    12'd806
  `define V_Bottom_Border 12'd0
  `define V_Front_Porch   12'd3
  `define V_Sync_Time     12'd6
  `define V_Back_Porch    12'd29
  `define V_Top_Border    12'd0

`elsif Resolution_1280x720
  `define H_Total_Time    12'd1650
  `define H_Right_Border  12'd0
  `define H_Front_Porch   12'd110
  `define H_Sync_Time     12'd40
  `define H_Back_Porch    12'd220
  `define H_Left_Border   12'd0

  `define V_Total_Time    12'd750
  `define V_Bottom_Border 12'd0
  `define V_Front_Porch   12'd5
  `define V_Sync_Time     12'd5
  `define V_Back_Porch    12'd20
  `define V_Top_Border    12'd0
  
`elsif Resolution_1920x1080
  `define H_Total_Time    12'd2200
  `define H_Right_Border  12'd0
  `define H_Front_Porch   12'd88
  `define H_Sync_Time     12'd44
  `define H_Back_Porch    12'd148
  `define H_Left_Border   12'd0

  `define V_Total_Time    12'd1125
  `define V_Bottom_Border 12'd0
  `define V_Front_Porch   12'd4
  `define V_Sync_Time     12'd5
  `define V_Back_Porch    12'd36
  `define V_Top_Border    12'd0

`endif