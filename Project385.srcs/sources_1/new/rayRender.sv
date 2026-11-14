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
        S_DONE,

        PLANE_SECT
    } state_t;
    state_t state;

    // Fixed point divider, shared across all submodules.
    // divider_if div_if(.*);
    // divider divider(.*);

    // TODO test: Intersect primary ray with ground plane. Checkerboard texture.
    q8_16_t intersect_x, intersect_y;

    logic plane_sect_start, plane_sect_done;
    planeSect planeSect(.start(plane_sect_start), .done(plane_sect_done), .*);

    always_ff @(posedge clk) begin
        done <= 0;
        plane_sect_start <= 0;

        if (reset) begin
            state <= S_IDLE;
            out_r <= 0;
            out_g <= 0;
            out_b <= 0;

        end else if (state == S_IDLE) begin
            if (start) begin
                state <= PLANE_SECT;
                plane_sect_start <= 1;
            end

        end else if (state == PLANE_SECT) begin
            if (plane_sect_done)
                state <= S_DONE;

        end else if (state == S_DONE) begin
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
    end
endmodule
