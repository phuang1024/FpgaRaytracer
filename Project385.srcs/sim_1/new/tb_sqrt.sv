// Test fx_sqrt.sv

module tb_sqrt();
    logic clk, reset, start, done;
    q8_16_t in, out;
    fx_sqrt dut(.v(in), .root(out), .*);

    // Clock.
    initial begin
        clk = 1;
    end
    always begin
        #5 clk = ~clk;
    end

    // Main test.
    initial begin
        start = 0;
        reset = 1;
        repeat(4) @(posedge clk);
        reset = 0;
        repeat(4) @(posedge clk);

        test_number(24'h010000);
        test_number(24'h020000);
        test_number(24'h040000);
        test_number(24'h070000);
        test_number(24'h090000);
        test_number(24'h7c0000);

        $finish;
    end

    task test_number(q8_16_t x);
        in <= x;
        start = 1;
        @(posedge clk);
        start = 0;

        wait (done);
        repeat(4) @(posedge clk);
    endtask
endmodule
