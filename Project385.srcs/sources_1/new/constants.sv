// Global constants.

package constants;
    // Fixed point 8bit int, 16bit frac.
    typedef logic signed [23:0] q8_16_t;


    // Dimensions of render result in pixels.
    localparam int FRAME_W = 320,
                   FRAME_H = 240;

    // Primary ray step size for single pixel. Assume Z = 1.
    // Hori FOV is 1 rad.
    localparam q8_16_t PX_ANGLE = 24'h0000cc;
    // Primary ray X and Y components at top left pixel location.
    localparam q8_16_t PRIM_MIN_X = PX_ANGLE * (FRAME_W / 2 - 0.5) * -1,
                       PRIM_MIN_Y = PX_ANGLE * (FRAME_H / 2 - 0.5) * -1;


    // Scene objects.
    // Cam location = (0, 0, 1).
    localparam q8_16_t CAM_X = 0, CAM_Y = 0, CAM_Z = 24'h010000;
endpackage
