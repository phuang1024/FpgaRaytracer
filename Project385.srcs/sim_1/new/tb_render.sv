// Render image, and save to bitmap.

import constants::*;

module tb_render();
    logic clk, reset, start, done;
    sceneRender dut(clk, reset, start, done);

    // Output image. TODO RGB?
    logic[23:0] render_result[FRAME_W][FRAME_H];

    // Clock.
    initial begin
        clk = 1;
    end
    always begin
        #5 clk = ~clk;
    end

    // Main test.
    initial begin
        reset = 1;
        repeat(4) @(posedge clk);
        reset = 0;
        repeat(4) @(posedge clk);

        start = 1;
        @(posedge clk);
        start = 0;

        wait(done);
        $finish;
    end

    // Extract render result from dut.
    always @(posedge clk) begin
        if (reset) begin
            for (j = 0; j < FRAME_H; j++)
                for (i = 0; i < FRAME_W; i++)
                    bitmap[i][j] <= 24'h0F0F0F;
        end else begin
            if (dut.core_done)
                bitmap[dut.px_x][dut.px_y] = {dut.render_r, dut.render_g, dut.render_b};
        end
    end

    // Write output image. From Lab7.
    task save_bmp(string bmp_file_name);
        begin

            integer unsigned        fout_bmp_pointer, BMP_file_size,BMP_row_size,r;
            logic   unsigned [31:0] BMP_header[0:12];

                                      BMP_row_size  = 32'(BMP_WIDTH) & 32'hFFFC;  // When saving a bitmap, the row size/width must be
        if ((BMP_WIDTH & 32'd3) !=0)  BMP_row_size  = BMP_row_size + 4;           // padded to chunks of 4 bytes.

        fout_bmp_pointer= $fopen(bmp_file_name,"wb");
        if (fout_bmp_pointer==0) begin
            $display("Could not open file '%s' for writing",bmp_file_name);
            $stop;
        end
        $display("Saving bitmap '%s'.",bmp_file_name);

        BMP_header[0:12] = '{BMP_file_size,0,0054,40,BMP_WIDTH,BMP_HEIGHT,{16'd24,16'd8},0,(BMP_row_size*BMP_HEIGHT*3),2835,2835,0,0};

        //Write header out
        $fwrite(fout_bmp_pointer,"BM");
        for (int i =0 ; i <13 ; i++ ) $fwrite(fout_bmp_pointer,"%c%c%c%c",BMP_header[i][7 -:8],BMP_header[i][15 -:8],BMP_header[i][23 -:8],BMP_header[i][31 -:8]); // Better compatibility with Lattice Active_HDL.

        //Write image out (note that image is flipped in Y)
        for (int y=BMP_HEIGHT-1;y>=0;y--) begin
          for (int x=0;x<BMP_WIDTH;x++)
            $fwrite(fout_bmp_pointer,"%c%c%c",render_result[x][y][23:16],render_result[x][y][15:8],render_result[x][y][7:0]) ;
        end

        $fclose(fout_bmp_pointer);
        end
    endtask
endmodule
