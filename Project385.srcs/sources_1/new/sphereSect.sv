// Ray-sphere intersection.


// TODO hardcoded sphere at (0, 0, 1) radius 1.
module planeSect
    import divider_pkg::*;
(
    input logic clk, reset,
    input logic start,
    output logic done,

    divider_if div_if,

    input q8_16_t prim_x, prim_y,
    output logic sect,
    output q8_16_t sect_x, sect_y
);
    typedef enum logic[2:0] {
        S_IDLE,

        S1
    } state_t;
    state_t state;

    always @(posedge clk) begin
        done <= 0;
        div_if.start <= 0;

        if (reset) begin
            state <= S_IDLE;

        end else if (state == S_IDLE) begin
            if (start) begin
                // TODO
                done <= 1;
                sect <= 0;
            end
        end
    end
endmodule
