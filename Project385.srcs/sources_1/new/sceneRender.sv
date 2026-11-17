// This module renders the entire frame.
// It samples and computes primary rays,
// and calls ray renderer cores.

import constants::*;


package scene_pkg;
    typedef struct packed {
        q8_16_t x, y, z;
    } vec3;

    // Intersection point and normal.
    typedef struct packed {
        logic sect;
        vec3 loc;
        vec3 nrm;
    } sect_if;
endpackage


module sceneRender(
    input logic clk, reset,
    input logic start,
    output logic done
);
    typedef enum logic[1:0] {
        S_IDLE = 0,
        S_WAIT_CORE = 1,
        S_NEXT_PX = 2
    } state_t;
    state_t state;

    // Pixel indices for sweep through frame.
    logic[9:0] px_x, px_y;
    // Primary ray. During sweep, X increases, Z decreases. Y is 1.
    vec3 primary;

    logic core_start, core_done;
    // Pixel render RGB output.
    logic[7:0] render_r, render_g, render_b;
    rayRender render_core(
        .clk(clk), .reset(reset),
        .start(core_start), .done(core_done),
        .primary(primary),
        .out_r(render_r), .out_g(render_g), .out_b(render_b)
    );

    // Next state logic to sweep through frame.
    always_ff @(posedge clk) begin
        done <= 0;
        core_start <= 0;

        if (reset) begin
            state <= S_IDLE;
            px_x <= 0;
            px_y <= 0;
            primary <= 0;

        end else if (state == S_IDLE) begin
            if (start) begin
                px_x <= 0;
                px_y <= 0;
                primary.x <= PRIM_MIN_X;
                primary.y <= 0;
                primary.z <= PRIM_MAX_Y;

                core_start <= 1;
                state <= S_WAIT_CORE;
            end

        end else if (state == S_WAIT_CORE) begin
            if (core_done) begin
                state <= S_NEXT_PX;
            end

        end else if (state == S_NEXT_PX) begin
            core_start <= 1;
            state <= S_WAIT_CORE;

            if (px_x == FRAME_W - 1) begin
                if (px_y == FRAME_H - 1) begin
                    // Done.
                    done <= 1;
                    core_start <= 0;
                    state <= S_IDLE;

                end else begin
                    // Next row.
                    px_x <= 0;
                    px_y <= px_y + 1;
                    primary.x <= PRIM_MIN_X;
                    primary.z <= primary.z - PX_ANGLE;
                end

            end else begin
                // Next col.
                px_x <= px_x + 1;
                primary.x <= primary.x + PX_ANGLE;
            end
        end
    end
endmodule
