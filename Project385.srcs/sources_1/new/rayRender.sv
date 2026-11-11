// This rendering core renders a single primary ray.
// It computes bounces and interactions with the scene.

import constants::*;

module rayRender(
    input logic clk, reset
    input logic start,
    output logic done
);
    always_ff @(posedge clk) begin
        done <= start;
    end
endmodule
