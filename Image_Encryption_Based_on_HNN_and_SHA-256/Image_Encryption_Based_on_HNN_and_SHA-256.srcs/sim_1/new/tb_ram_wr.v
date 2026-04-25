


`timescale 1ns/1ps

module tb_ram_wr;

    // ====================================================================
    // 时钟和复位信号
    // ====================================================================
    reg clk;          // 主时钟 50MHz
    reg reset_n;      // 复位信号
    
    // ====================================================================
    // DUT 输出信号
    // ====================================================================
    wire signed [7:0] chaos_out;
    wire              enc_img_valid;
    
    // ====================================================================
    // 图像存储器接口信号
    // ====================================================================
    wire [15:0] img_addr, img_addr_case1, img_addr_case2;
    wire [7:0]  img_out;
    
    // ====================================================================
    // 加密图像存储器接口信号
    // ====================================================================
    wire        wr_enc_ena;
    wire [7:0]  enc_din, enc_dout;
    wire [15:0] enc_img_addra, enc_img_addra_case1, enc_img_addra_case2;
    
    // ====================================================================
    // PLL 和显示相关信号
    // ====================================================================
    wire        pll_locked;
    wire        loc_clk33M;
    wire        tft_reset_p;
    
    // 显示接口信号
    wire [15:0] disp_data;
    wire        disp_data_req;
    wire [11:0] visible_hcount;
    wire [11:0] visible_vcount;
    wire        Frame_Begin;
    
    // TFT 输出信号
    wire [15:0] TFT_rgb;
    wire        TFT_hs;
    wire        TFT_vs;
    wire        TFT_clk;
    wire        TFT_de;
    wire        TFT_pwm;
    wire [4:0]  Disp_Red;
    wire [5:0]  Disp_Green;
    wire [4:0]  Disp_Blue;
    
    // ====================================================================
    // 参数定义
    // ====================================================================
    parameter DISP_IMAGE_W    = 256;
    parameter DISP_IMAGE_H    = 256;
    parameter ROM_ADDR_WIDTH  = 16;
    parameter DISP_BACK_COLOR = 16'hFFFF;
    parameter TFT_WIDTH       = 800;
    parameter TFT_HEIGHT      = 480;
    parameter DISP_HBEGIN     = (TFT_WIDTH  - DISP_IMAGE_W)/2;
    parameter DISP_VBEGIN     = (TFT_HEIGHT - DISP_IMAGE_H)/2;
    
    // ====================================================================
    // 时钟生成 (50MHz)
    // ====================================================================
    initial begin
        clk = 1'b0;
        forever #2 clk = ~clk;  // 4ns 周期 = 250MHz
    end
    
    // ====================================================================
    // 复位生成
    // ====================================================================
    initial begin
        reset_n = 1'b0;
        #200;                    // 等待 200ns
        reset_n = 1'b1;
        $display("[%0t] Reset released", $time);
    end
    
    // ====================================================================
    // 仿真超时保护
    // ====================================================================
    initial begin
        #100_000_000;  // 100ms 超时
        $display("ERROR: Simulation timeout!");
        $finish;
    end
    
    // ====================================================================
    // PLL 实例化 (50MHz -> 33MHz)
    // ====================================================================
    pll pll_inst(
        .clk_in1  (clk),
        .clk_out1 (loc_clk33M),
        .resetn   (reset_n),
        .locked   (pll_locked)
    );
    
    // ====================================================================
    // 图像 ROM (原始图像)
    // ====================================================================
    image256x256 image_inst(
        .addra (img_addr),
        .clka  (loc_clk33M),
        .douta (img_out)
    );
    
    // ====================================================================
    // 加密图像 RAM
    // ====================================================================
    Encrypted_image Enc_img(
        .clka  (loc_clk33M),
        .wea   (wr_enc_ena),
        .addra (enc_img_addra),
        .dina  (enc_din),
        .douta (enc_dout)
    );
    
    // ====================================================================
    // 地址多路选择器
    // ====================================================================
    assign img_addr      = wr_enc_ena ? img_addr_case1      : img_addr_case2;
    assign enc_img_addra = wr_enc_ena ? enc_img_addra_case1 : enc_img_addra_case2;
    
    // ====================================================================
    // DUT：RAM 写入控制模块
    // ====================================================================
    Image_encryption u_Image_encryption(
        .clk           (loc_clk33M),
        .rst_n         (reset_n),

        .enc_img_valid (enc_img_valid),
        .img_addra     (img_addr_case1),
        .img_out       (img_out),
        .wr_enc_ena    (wr_enc_ena),
        .enc_img_addra (enc_img_addra_case1),
        .enc_din       (enc_din),
        .enc_dout      (enc_dout)
    );
    
    // ====================================================================
    // 图像提取模块
    // ====================================================================
    image_extract #(
        .H_Visible_area (TFT_WIDTH),
        .V_Visible_area (TFT_HEIGHT),
        .IMG_WIDTH      (DISP_IMAGE_W),
        .IMG_HEIGHT     (DISP_IMAGE_H),
        .IMG_DATA_WIDTH (16),
        .ROM_ADDR_WIDTH (ROM_ADDR_WIDTH)
    ) image_extract_inst (
        .clk_ctrl       (loc_clk33M),
        .reset_n        (pll_locked),
        .img_disp_hbegin(DISP_HBEGIN),
        .img_disp_vbegin(DISP_VBEGIN),
        .disp_back_color(DISP_BACK_COLOR),
        .rom_addra      (img_addr_case2),
        .rom_data       (img_out),
        .Frame_Begin    (Frame_Begin),
        .disp_data_req  (disp_data_req),
        .visible_hcount (visible_hcount),
        .visible_vcount (visible_vcount),
        .disp_data      (disp_data)
    );
    
    // ====================================================================
    // 显示驱动模块
    // ====================================================================
    assign tft_reset_p = ~pll_locked;
    
    disp_driver disp_driver_inst(
        .ClkDisp    (loc_clk33M),
        .Rst_p      (tft_reset_p),
        .Data       (disp_data),
        .DataReq    (disp_data_req),
        .H_Addr     (visible_hcount),
        .V_Addr     (visible_vcount),
        .Disp_HS    (TFT_hs),
        .Disp_VS    (TFT_vs),
        .Disp_Red   (Disp_Red),
        .Disp_Green (Disp_Green),
        .Disp_Blue  (Disp_Blue),
        .Frame_Begin(Frame_Begin),
        .Disp_DE    (TFT_de),
        .Disp_PCLK  (TFT_clk)
    );
    
    assign TFT_rgb = {Disp_Red, Disp_Green, Disp_Blue};
    assign TFT_pwm = 1'b1;
    
    // ====================================================================
    // 测试流程
    // ====================================================================
    initial begin
        $display("========================================");
        $display("  RAM Write Testbench");
        $display("========================================");
        
        // 等待复位完成
        wait(reset_n == 1'b1);
        $display("[%0t] Reset completed", $time);
        
        // 等待 PLL 锁定
        wait(pll_locked == 1'b1);
        $display("[%0t] PLL locked", $time);
        
        // 等待几个时钟周期
        repeat(10) @(posedge loc_clk33M);
        
        // 检查是否有 write_done 信号
        if ($test$plusargs("check_write")) begin
            // 等待写入完成（如果 ram_wr 有 write_done 信号）
            // wait(u_ram_wr.write_done == 1);
            // $display("[%0t] ✅ Write completed! Count: %d", $time, u_ram_wr.write_cnt);
        end
        
        // 等待至少一帧图像显示
        wait(Frame_Begin == 1'b1);
        $display("[%0t] First frame started", $time);
        
        wait(Frame_Begin == 1'b0);
        wait(Frame_Begin == 1'b1);
        $display("[%0t] Second frame started", $time);
        
        // 仿真足够长的时间
        #1_000_000;  // 1ms
        
        $display("[%0t] Simulation completed successfully!", $time);
        $finish;
    end
    
    // ====================================================================
    // 监视器：显示加密图像写入进度
    // ====================================================================
    integer enc_write_count = 0;
    
    always @(posedge loc_clk33M) begin
        if (wr_enc_ena && enc_img_valid) begin
            enc_write_count = enc_write_count + 1;
            if (enc_write_count % 1000 == 0) begin
                $display("[%0t] Encrypted %d pixels", $time, enc_write_count);
            end
        end
    end
    
    // ====================================================================
    // 监视器：显示混沌输出
    // ====================================================================
    integer chaos_count = 0;
    
    always @(posedge loc_clk33M) begin
        if (enc_img_valid) begin
            chaos_count = chaos_count + 1;
            if (chaos_count <= 10 || chaos_count % 1000 == 0) begin
                $display("[%0t] Chaos[%0d] = 0x%02X (%d)", 
                         $time, chaos_count, chaos_out, $signed(chaos_out));
            end
        end
    end
    
    // ====================================================================
    // 波形文件生成
    // ====================================================================
    initial begin
        $dumpfile("tb_ram_wr.vcd");
        $dumpvars(0, tb_ram_wr);
        
        // 可选：只转储关键信号以减小文件大小
        // $dumpvars(1, tb_ram_wr);
        // $dumpvars(1, u_ram_wr);
    end

endmodule



