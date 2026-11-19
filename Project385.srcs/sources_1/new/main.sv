// Top level module.

module main(
    input logic clk, reset,
    
    //UART
    input logic uart_rtl_0_rxd,
    output logic uart_rtl_0_txd,
    //HDMI
    output logic hdmi_tmds_clk_n,
    output logic hdmi_tmds_clk_p,
    output logic [2:0]hdmi_tmds_data_n,
    output logic [2:0]hdmi_tmds_data_p
);
    logic render_start, render_done;
    logic[9:0] px_x, px_y;
    logic[7:0] render_r, render_g, render_b;
    
    //logic[23:0][FRAME_W:0][FRAME_H:0] render_result;

    //assign render_start = 1;
    sceneRender renderer(.start(render_start), .done(render_done), .*);
    
    /*
    always_ff @(posedge clk) begin
        render_result[px_y][px_x] <= {render_r, render_g, render_b};
    end
    */
    
    
    logic locked, hsync, vsync, vde;
    logic[9:0] drawX, drawY;
    logic[7:0] red, green, blue;
    
    //assign locked = 0;
    
    /*
    mb_block mb_block_i
       (.clk_100MHz(clk),
        .reset_rtl_0(~reset),
        .uart_rtl_0_rxd(uart_rtl_0_rxd),
        .uart_rtl_0_txd(uart_rtl_0_txd));
    */
        
    //clock wizard configured with a 1x and 5x clock for HDMI
    clk_wiz_0 clk_wiz (
        .clk_out1(clk_25MHz),
        .clk_out2(clk_125MHz),
        .reset(reset),
        .locked(locked),
        .clk_in1(clk)
    );
    
    //VGA Sync signal generator
    vga_controller vga (
        .pixel_clk(clk_25MHz),
        .reset(reset),
        .hs(hsync),
        .vs(vsync),
        .active_nblank(vde),
        .drawX(drawX),
        .drawY(drawY)
    );

    //Real Digital VGA to HDMI converter
    hdmi_tx_0 vga_to_hdmi (
        //Clocking and Reset
        .pix_clk(clk_25MHz),
        .pix_clkx5(clk_125MHz),
        .pix_clk_locked(locked),
        .rst(reset),
        //Color and Sync Signals
        .red(red),
        .green(green),
        .blue(blue),
        .hsync(hsync),
        .vsync(vsync),
        .vde(vde),

        //aux Data (unused)
        .aux0_din(4'b0),
        .aux1_din(4'b0),
        .aux2_din(4'b0),
        .ade(1'b0),

        //Differential outputs
        .TMDS_CLK_P(hdmi_tmds_clk_p),
        .TMDS_CLK_N(hdmi_tmds_clk_n),
        .TMDS_DATA_P(hdmi_tmds_data_p),
        .TMDS_DATA_N(hdmi_tmds_data_n)
    );
    
    /*
    always_ff @(posedge clk) begin
        red <= render_result[drawY][drawX][23:16];
        green <= render_result[drawY][drawX][15:8];
        blue <= render_result[drawY][drawX][7:0];
    end
    */
endmodule
