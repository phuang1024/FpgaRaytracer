// This module renders the entire frame.
// It samples and computes primary rays,
// and calls ray renderer cores.

import constants::*;

module sceneRender(
    input logic clk, reset
);
    rayRender render_core(clk, reset);
endmodule
