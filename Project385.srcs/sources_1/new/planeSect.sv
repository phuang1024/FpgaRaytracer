// Ray-plane intersection logic.

import constants::*;


// TODO hardcoded plane at Z=0 fixed size.
module planeSect
    import divider_pkg::*;
(
    input logic clk, reset,
    input logic start,
    output logic done,

    divider_if div_if,
    sect_if sect,

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
                if (primary.z < 24'sh0) begin
                    state <= S1;
                    // Initiate Cz / Rz.
                    div_if.a <= CAM_Z;
                    div_if.b <= primary.z;
                    div_if.start <= 1;

                end else begin
                    state <= S_IDLE;
                    done <= 1;
                    sect.sect <= 0;
                end
            end

        end else if (state == S1) begin
            // Wait for divider.
            if (div_if.done) begin
                state <= S_IDLE;
                done <= 1;

                // Calculate XY intersection coords.
                sect.loc.y <= -div_if.q + CAM_Y;
                sect_x_tmp = -div_if.q * primary.x;
                sect.loc.x <= sect_x_tmp[39:16] + CAM_X;
                sect.loc.z <= 0;
                sect.nrm.x <= 0;
                sect.nrm.y <= 0;
                sect.nrm.z <= 1;

                // Check if in bounds of plane.
                sect.sect <= (~div_if.overflow
                                    && -24'sh050000 < sect.loc.x
                                    && sect.loc.x < 24'sh050000
                                    && -24'sh050000 < sect.loc.y
                                    && sect.loc.y < 24'sh050000);
            end
        end
    end
endmodule
