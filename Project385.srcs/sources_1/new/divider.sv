// Instances and wraps fixed point divider IP.


typedef struct packed {
    logic start, done;
    logic signed[23:0] a, b, q;
} divider_if;


// Computes Q = A / B, all q8_16_t
module divider(
    input logic clk, reset,
    inout divider_if div_if
);
    logic[63:0] q_tmp;
    assign div_if.q = q_tmp[47:24];

    div_q8_16 divider(
        .aclk(div_if.clk),
        .aresetn(~div_if.reset),

        // Bit shift A by 16 (fractional part).
        .s_axis_dividend_tvalid(div_if.start),
        .s_axis_dividend_tdata({div_if.a, 16'b0}),
        // Keep B as is.
        .s_axis_divisor_tvalid(div_if.start),
        .s_axis_divisor_tdata(div_if.b),
        // Output 64 bit result (40 quotient and 24 remainder).
        .m_axis_dout_tvalid(div_if.done),
        .m_axis_dout_tdata(q_tmp)
    );
endmodule
