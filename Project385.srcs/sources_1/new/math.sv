import constants::*;


module fx_sqrt (
    input  logic   clk, reset,
    input  logic   start,          // 1-cycle pulse, v must be valid this cycle
    input  q8_16_t v,              // input, should be >= 0
    output q8_16_t root,           // sqrt(v), valid when done = 1
    output logic   done            // high for 1 cycle when root is ready
);

    localparam int XW    = 40;     // radicand width: 24-bit v + 16 frac bits
    localparam int QW    = XW / 2; // root width: 20 bits
    localparam int AW    = QW + 2; // remainder width: 22 bits
    localparam int ITERS = QW;     // 20 iterations


    typedef enum logic [1:0] { IDLE, BUSY, FINISH } state_t;
    state_t state, state_next;

    logic [XW-1:0] X, X_next;
    logic [AW-1:0] A, A_next;
    logic [QW-1:0] Q, Q_next;
    logic [4:0]    count, count_next;   // counts 0..19


    logic [AW-1:0]       A_shift;       // A after shifting in 2 bits of X
    logic signed [AW:0]  T;             // A_shift - {Q, 01}, 1 extra bit for sign




    always_comb begin
        // Default: hold everything
        state_next = state;
        X_next     = X;
        A_next     = A;
        Q_next     = Q;
        count_next = count;
        done       = 1'b0;


        A_shift = {A[AW-3:0], X[XW-1:XW-2]};     // "Left shift X by two places into A"
        T = {1'b0, A_shift}
          - {1'b0, Q, 2'b01};              // "Set T = A - {Q,01}" ; (zero-extend both sides to AW+1 bits so T[AW] is the sign bit)



        case (state)
        IDLE: begin
            if (start) begin
                if (v < 0) begin
                    X_next = '0;
                end else begin
                    X_next = {24'(unsigned'(v)), 16'b0}; // v << 16
                end
                A_next     = '0;
                Q_next     = '0;
                count_next = '0;
                state_next = BUSY;
            end
        end


        BUSY: begin
            X_next = X << 2;
            if (T[AW] == 1'b0) begin // T >= 0
                A_next = T[AW-1:0];
                Q_next = {Q[QW-2:0], 1'b1};
            end else begin
                A_next = A_shift;
                Q_next = {Q[QW-2:0], 1'b0};
            end
            count_next = count + 5'd1;
            if (count == ITERS - 1) begin
                state_next = FINISH;
            end
        end


        FINISH: begin
            done = 1'b1;
            state_next = IDLE;
        end

        default: state_next = IDLE;
        endcase
    end


    always_ff @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            X <= 0;
            A <= 0;
            Q <= 0;
            count <= 0;
        end else begin
            state <= state_next;
            X <= X_next;
            A <= A_next;
            Q <= Q_next;
            count <= count_next;
        end
    end


    assign root = {4'b0, Q};

endmodule


module fx_multiply(
    input q8_16_t a, b,
    output q8_16_t prod
);
    logic signed[47:0] prod_tmp;
    assign prod_tmp = a * b;
    assign prod = prod_tmp[39:16];
endmodule


module fx_dot(
    input  logic   clk, reset,
    input  logic   start,
    output logic   done,

    input  vec3    a, b,
    output q8_16_t prod
);
    typedef enum logic [2:0] {
        S_IDLE,
        SADD1,
        SADD2,
        SADD3,
        S_DONE
    } state_t;
    state_t state;

    q8_16_t mult_a, mult_b, mult_prod;
    fx_multiply multiplier(.a(mult_a), .b(mult_b), .prod(mult_prod));

    // 1. Drive multiplier inputs combinationally based on current state
    always_comb begin
        mult_a = '0;
        mult_b = '0;
        case (state)
            SADD1: begin mult_a = a.x; mult_b = b.x; end
            SADD2: begin mult_a = a.y; mult_b = b.y; end
            SADD3: begin mult_a = a.z; mult_b = b.z; end
            default: begin mult_a = '0; mult_b = '0; end
        endcase
    end

    // 2. Accumulate the settled multiplier output on each clock edge
    always_ff @(posedge clk) begin
        if (reset) begin
            state <= S_IDLE;
            prod  <= '0;
            done  <= 1'b0;
        end else begin
            done <= 1'b0; // Default low
            case (state)
                S_IDLE: begin
                    if (start) begin
                        state <= SADD1;
                        prod  <= '0;
                    end
                end
                SADD1: begin
                    state <= SADD2;
                    prod  <= prod + mult_prod;
                end
                SADD2: begin
                    state <= SADD3;
                    prod  <= prod + mult_prod;
                end
                SADD3: begin
                    state <= S_DONE;
                    prod  <= prod + mult_prod;
                end
                S_DONE: begin
                    state <= S_IDLE;
                    done  <= 1'b1;
                end
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule


// Compute norm of a vector.
module fx_norm(
    input  logic   clk, reset,
    input  logic   start,
    output logic   done,

    input  vec3    v,
    output q8_16_t norm
);
    logic dot_start, dot_done;
    q8_16_t norm_squared;
    fx_dot dotter(
        .start(dot_start),
        .done(dot_done),
        .a(v),
        .b(v),
        .prod(norm_squared),
        .*
    );

    logic root_start, root_done;
    fx_sqrt rooter(
        .start(root_start),
        .done(root_done),
        .v(norm_squared),
        .root(norm),
        .*
    );

    typedef enum logic [2:0] {
        S_IDLE,
        S_DOT_WAIT,
        S_SQRT_WAIT,
        S_DONE
    } state_t;
    state_t state;

    always_ff @(posedge clk) begin
        // Default single-cycle pulses to 0
        done       <= 1'b0;
        dot_start  <= 1'b0;
        root_start <= 1'b0;

        if (reset) begin
            state <= S_IDLE;

        end else begin
            case (state)
                S_IDLE: begin
                    if (start) begin
                        dot_start <= 1'b1;
                        state     <= S_DOT_WAIT;
                    end
                end

                S_DOT_WAIT: begin
                    if (dot_done) begin
                        root_start <= 1'b1;
                        state      <= S_SQRT_WAIT;
                    end
                end

                S_SQRT_WAIT: begin
                    if (root_done) begin
                        state <= S_DONE;
                    end
                end

                S_DONE: begin
                    done  <= 1'b1;
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule


// Normalize a vector.
module fx_normalize(
    input logic clk, reset,
    input logic start,
    output logic done,

    input vec3 v,
    output vec3 v_norm,
);
endmodule
