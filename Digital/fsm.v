module fsm(
    input  wire                        clk_i,
    input  wire                        rst_i,

    // Analog status
    input  wire                        comp_i,   // comparator output
    input  wire                        sat_hi_i,  // Range shows vin is too high
    input  wire                        sat_lo_i,  // Range shows vin is too low
    input  wire                        ref_ok_i,  // Reference voltage is good

    // Control to analog
    output reg  [AFE_SEL_WIDTH-1:0]    afe_sel_o,  
    output reg  [RANGE_SEL_WIDTH-1:0]  range_sel_o,
    output reg                         afe_reset_o,
    output reg                         ref_sign_o,

    // Result/status
    output reg                         busy_o,
    output reg                         data_ready_o,
    output reg                         error_o,
    output reg  [31:0]                 result_count_o
);
    localparam [2:0] S_RESET = 3'd0;
    localparam [2:0] S_WAIT_REF = 3'd1;
    localparam [2:0] S_AZ = 3'd2;
    localparam [2:0] S_INT = 3'd3;
    localparam [2:0] S_DEINT = 3'd4;
    localparam [2:0] S_DONE = 3'd5;
    localparam [2:0] S_ERROR = 3'd6;

    reg [2:0] current_state, next_state;

    always@(posedge clk_i or posedge rst_i) begin
        if(rst_i) begin
            current_state <= S_RESET;
        end else begin
            current_state <= next_state;
        end
    end

    always@(*) begin
        case(current_state)
            S_RESET: begin
                next_state = S_WAIT_REF;  
            end
            S_WAIT_REF: begin
                if(ref_ok_i) begin
                    next_state = S_AZ;
                end else begin
                    next_state = S_WAIT_REF;
                end
            end
            S_AZ: begin

            end
            S_INT: begin

            end
            S_DEINT: begin

            end
            S_DONE: begin

            end
            S_ERROR: begin

            end
        endcase
    end

endmodule