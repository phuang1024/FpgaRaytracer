// This rendering core renders a given primary ray.
// It computes bounces and interactions with the scene.

import constants::*;

module rayRender(
    input logic clk, reset,
    input logic start,
    output logic done,

    // Primary ray to render.
    input q8_16_t prim_x, prim_y,

    output logic[7:0] out_r, out_g, out_b
);
    typedef enum logic[2:0] {
        S_IDLE,
        S_OUTPUT,

        PLANE_SECT1,
        PLANE_SECT2
    } state_t;
    state_t state;

    // Fixed point divider IP.
    logic div_start, div_done;
    logic signed[23:0] div_a, div_b;
    logic[63:0] div_out;
    div_q8_16 divider(
        .aclk(clk),
        .aresetn(~reset),

        // Bit shift A by 16 (fractional part).
        .s_axis_dividend_tvalid(div_start),
        .s_axis_dividend_tdata({div_a, 16'b0}),
        // Keep B as is.
        .s_axis_divisor_tvalid(div_start),
        .s_axis_divisor_tdata(div_b),
        // Output 64 bit result (40 quotient and 24 remainder).
        .m_axis_dout_tvalid(div_done),
        .m_axis_dout_tdata(div_out)
    );

    // TODO test: Intersect primary ray with ground plane. Checkerboard texture.
    q8_16_t intersect_x, intersect_y;

    `include "planeSect.svh"

    always_ff @(posedge clk) begin
        done <= 0;
        div_start <= 0;

        if (reset) begin
            state <= S_IDLE;
            out_r <= 0;
            out_g <= 0;
            out_b <= 0;

        end else begin
            case (state)
                S_IDLE: begin
                    if (start)
                        state <= PLANE_SECT1;
                end

                S_OUTPUT: begin
                    state <= S_IDLE;
                    done <= 1;

                    // Checkerboard texture.
                    if (intersect_x[16] ^ intersect_y[16]) begin
                        out_r <= 255;
                        out_g <= 0;
                        out_b <= 0;
                    end else begin
                        out_r <= 0;
                        out_g <= 0;
                        out_b <= 255;
                    end
                end

                PLANE_SECT1, PLANE_SECT2:
                    plane_sect_loop();
            endcase
        end
    end
endmodule
