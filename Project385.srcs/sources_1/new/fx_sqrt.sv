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
        if (reset)
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

    
    assign root = {4'b0, Q};

endmodule