// Ray-plane intersection logic.
// Is used in rayRender.sv


task automatic plane_sect_loop();
    // Tmp var for multiplication.
    logic signed[47:0] intersect_x_tmp;

    case (state)
        PLANE_SECT_1: begin
            state <= PLANE_SECT_2;
            // Initiate Cz / Rz.
            div_a <= CAM_Z;
            div_b <= prim_y;
            div_start <= 1;
        end

        PLANE_SECT_2: begin
            // Wait for divider.
            if (div_done) begin
                state <= S2;
                // Assign results.
                intersect_y <= div_out[47:24];
                intersect_x_tmp = q8_16_t'(div_out[47:24]) * prim_x;
                intersect_x <= intersect_x_tmp[39:16];
            end
        end
    endcase
endtask
