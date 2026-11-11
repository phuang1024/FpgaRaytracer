// Render image, and save to bitmap.

module tb_render();
    logic clk, reset, start, done;

    sceneRender dut(clk, reset, start, done);

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
endmodule
