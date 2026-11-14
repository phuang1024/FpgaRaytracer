// Ray-plane intersection logic.

import constants::*;


module planeSect
    import divider_pkg::*;
(
    input logic clk, reset,
    input logic start,
    output logic done,

    input q8_16_t prim_x, prim_y,
    output q8_16_t intersect_x, intersect_y
);
    typedef enum logic[2:0] {
        S_IDLE,

        S1
    } state_t;
    state_t state;

    // Tmp wire for multiplication.
    logic signed[47:0] intersect_x_tmp;

    // TODO this should be in higher level module
    divider_if div_if;
    divider divider(.*);

    always @(posedge clk) begin
        done <= 0;
        div_if.start <= 0;

        if (reset) begin
            state <= S_IDLE;

        end else if (state == S_IDLE) begin
            if (start) begin
                state <= S1;
                // Initiate Cz / Rz.
                div_if.a <= CAM_Z;
                div_if.b <= prim_y;
                div_if.start <= 1;
            end

        end else if (state == S1) begin
            // Wait for divider.
            if (div_if.done) begin
                state <= S_IDLE;
                done <= 1;
                // Assign results.
                intersect_y = div_if.q;
                intersect_x_tmp = intersect_y * prim_x;
                intersect_x <= intersect_x_tmp[39:16];
            end
        end
    end
endmodule
