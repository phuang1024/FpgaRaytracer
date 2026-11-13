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
    assign out_r = 255;
    assign out_g = 0;
    assign out_b = 0;

    always_ff @(posedge clk) begin
        done <= start;
    end
endmodule
