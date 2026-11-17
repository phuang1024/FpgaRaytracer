// Ray-plane intersection logic.

import constants::*;


// TODO hardcoded plane at Z=0 fixed size.
module planeSect
    import divider_pkg::*;
    import scene_pkg::*;
(
    input logic clk, reset,
    input logic start,
    output logic done,

    divider_if div_if,
    sect_if sect_if,

    vec3 primary
);
    typedef enum logic[2:0] {
        S_IDLE,

        S1
    } state_t;
    state_t state;

    // Tmp wire for multiplication.
    logic signed[47:0] sect_x_tmp;

    always @(posedge clk) begin
        done <= 0;
        div_if.start <= 0;

        if (reset) begin
            state <= S_IDLE;

        end else if (state == S_IDLE) begin
            if (start) begin
                // Only intersects if ray is downward.
                if (prim_y < 24'sh0) begin
                    state <= S1;
                    // Initiate Cz / Rz.
                    div_if.a <= CAM_Z;
                    div_if.b <= prim_y;
                    div_if.start <= 1;

                end else begin
                    state <= S_IDLE;
                    done <= 1;
                    sect_if.sect <= 0;
                end
            end

        end else if (state == S1) begin
            // Wait for divider.
            if (div_if.done) begin
                state <= S_IDLE;
                done <= 1;

                // Calculate XY intersection coords.
                sect_if.loc.y <= -div_if.q + CAM_Y;
                sect_x_tmp = -div_if.q * prim_x;
                sect_if.loc.x <= sect_x_tmp[39:16] + CAM_X;
                sect_if.loc.z <= 0;
                sect_if.nrm.x <= 0;
                sect_if.nrm.y <= 0;
                sect_if.nrm.z <= 1;

                // Check if in bounds of plane.
                sect_if.sect <= (~div_if.overflow
                                    && -24'sh050000 < sect_if.loc.x
                                    && sect_if.loc.x < 24'sh050000
                                    && -24'sh050000 < sect_if.loc.y
                                    && sect_if.loc.y < 24'sh050000);
            end
        end
    end
endmodule
