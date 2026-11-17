// Ray-sphere intersection.


// TODO hardcoded sphere at (0, 0, 1) radius 1.
module sphereSect
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

    always @(posedge clk) begin
        done <= 0;
        div_if.start <= 0;

        if (reset) begin
            state <= S_IDLE;

        end else if (state == S_IDLE) begin
            if (start) begin
                // TODO
                done <= 1;
                sect.sect <= 0;
            end
        end
    end
endmodule
