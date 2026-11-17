// This rendering core renders a given primary ray.
// It computes bounces and interactions with the scene.

import constants::*;


module rayRender
    import divider_pkg::*;
    import scene_pkg::*;
(
    input logic clk, reset,
    input logic start,
    output logic done,

    // Primary ray to render.
    input vec3 primary,

    output logic[7:0] out_r, out_g, out_b
);
    typedef enum logic[2:0] {
        S_IDLE,
        S_DONE,

        PLANE_SECT,
        SPHERE_SECT
    } state_t;
    state_t state;

    // Fixed point divider, shared across all submodules.
    divider_if div_if;
    divider divider(.*);

    logic plane_sect_start, plane_sect_done;
    divider_if plane_sect_div;
    sect_if plane_sect;
    planeSect planeSect(
        .start(plane_sect_start),
        .done(plane_sect_done),
        .div_if(plane_sect_div),
        .sect_if(plane_sect),
        .*
    );

    logic sphere_sect_start, sphere_sect_done;
    divider_if sphere_sect_div;
    sect_if sphere_sect;
    sphereSect sphereSect(
        .start(sphere_sect_start),
        .done(sphere_sect_done),
        .div_if(sphere_sect_div),
        .sect_if(sphere_sect),
        .*
    );

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
            out_r <= 0;
            out_g <= 0;
            out_b <= 0;
            if (plane_sect.sect) begin
                if (plane_sect.loc.x[16] ^ plane_sect.loc.y[16])
                    out_r <= 255;
                else
                    out_b <= 255;
            end
        end
    end

    // Mux for div_if.
    always_comb begin
        case (state)
            PLANE_SECT: begin
                div_if.start = plane_sect_div.start;
                div_if.a = plane_sect_div.a;
                div_if.b = plane_sect_div.b;
                plane_sect_div.done = div_if.done;
                plane_sect_div.q = div_if.q;
                plane_sect_div.overflow = div_if.overflow;
            end
            default: div_if = 0;
        endcase
    end
endmodule
