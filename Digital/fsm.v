module fsm(
    input  wire                        clk_i,
    input  wire                        rst_i,

    // Analog status
    input  wire                        comp_i,
    input  wire                        sat_hi_i,
    input  wire                        sat_lo_i,
    input  wire                        ref_ok_i,

    // Optional start (if 1, run continuously)
    input  wire                        start_i,

    // Control to analog
    output reg  [AFE_SEL_WIDTH-1:0]    afe_sel_o,
    output reg  [RANGE_SEL_WIDTH-1:0]  range_sel_o,
    output reg                         afe_reset_o,
    output reg                         ref_sign_o,
    output reg                         mode_sel_o,

    // Result/status
    output reg                         busy_o,
    output reg                         data_ready_o,
    output reg                         error_o,
    output reg  [31:0]                 result_count_o
);
    localparam [2:0] S_RESET    = 3'd0;
    localparam [2:0] S_IDLE     = 3'd1;
    localparam [2:0] S_INTE     = 3'd2;

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
                next_state = S_IDLE;  
            end
            S_IDLE: begin
                next_state = S_IDLE;
            end
        endcase
    end

endmodule