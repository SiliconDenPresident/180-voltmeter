module state_machine (
    input wire clk_i,
    input wire rst_i,
    input wire comp_i,
    input wire sat_hi_i,
    input wire sat_lo_i,
    input wire ref_ok_i,
    output wire data_valid_o,
    output wire [1:0] afe_sel_o,
    output wire [2:0] range_sel_o,
    output wire afe_reset_o,
    output wire ref_sign_o
);

    reg [2:0] current_state, next_state;
    reg counter_en;
    reg counter_rst;
    reg [15:0] counter_count;
    wire counter_busy;
    wire counter_done;

    localparam S_RESET = 3'b000;
    localparam S_WAIT_REF = 3'b001;
    localparam S_AUTO_ZERO = 3'b010;
    localparam S_INTEGRATE = 3'b011;
    localparam S_DEINTEGRATE = 3'b100;
    localparam S_DONE = 3'b101;
    localparam S_ERROR = 3'b110;

    localparam [1:0] AFE_IDLE = 2'b00;
    localparam [1:0] AFE_AUTO_ZERO = 2'b01;
    localparam [1:0] AFE_INTEGRATE = 2'b10;
    localparam [1:0] AFE_DEINTEGRATE = 2'b11;

    always @(posedge clk_i or posedge rst_i) begin 
        if (rst_i) begin
            current_state <= S_RESET;
        end else begin
            current_state <= next_state;
        end
    end
    
    always @(*) begin
        afe_reset_o = 1'b0;
        afe_sel_o = AFE_IDLE;
        counter_rst = 1'b0;
        counter_en = 1'b0;
        counter_count = 16'b0;
        case (current_state)
            S_RESET: begin
                afe_reset_o = 1'b1;
                counter_rst = 1'b1;
                next_state = S_WAIT_REF;
            end
            S_WAIT_REF: begin
                afe_reset_o = 1'b1;
                counter_rst = 1'b1;
                if (ref_ok_i) begin
                    next_state = S_AUTO_ZERO;
                end else begin
                    next_state = S_WAIT_REF;
                end
            end
            S_AUTO_ZERO: begin
                afe_sel_o = AFE_AUTO_ZERO;
                counter_en = 1'b1;
                counter_count = 16'b0000_0000_0001_0000;
                if(counter_done) begin
                    next_state = S_INTEGRATE;
                end else begin
                    next_state = S_AUTO_ZERO;
                end
            end
            S_INTEGRATE: begin
                afe_sel_o = AFE_INTEGRATE;
                if(counter_done) begin
                    next_state = S_DEINTEGRATE;
                end else begin
                    next_state = S_INTEGRATE;
                end
            end
            S_DEINTEGRATE: begin
                afe_sel_o = AFE_DEINTEGRATE;
                next_state = S_DONE;
            end
            S_DONE: begin
                next_state = S_RESET;
            end
            S_ERROR: begin
                next_state = S_RESET;
            end
            default: begin
                next_state = S_RESET;
            end
        endcase
    end

endmodule