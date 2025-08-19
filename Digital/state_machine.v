/*
--------------------------------------------------------------------------------
 Title        : state_machine
 Project      : 180-voltmeter
 File         : state_machine.v
 Description  : Finite state machine that controls the voltmeter measurement
                sequence. Manages the auto-zero, integrate, and deintegrate phases
                of dual-slope analog-to-digital conversion. Coordinates timing
                control through counter instances and generates appropriate AFE
                control signals for each measurement phase.
 
 Author       : Tristan Wood tdwood2@ncsu.edu
 Created      : 2025-08-13
 License      : See LICENSE in the project root

 Revision History:
   - 0.1 2025-08-13 Tristan Wood Initial implementation of voltmeter measurement FSM
--------------------------------------------------------------------------------
*/

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
    reg counter_rst, counter_clear;
    reg [15:0] counter_count;
    wire counter_busy;
    wire counter_done;
    reg afe_reset;
    reg [1:0] afe_sel;

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

    localparam [15:0] COUNTER_LIMIT_AUTO_ZERO = 16'b0000_0000_0000_1000;
    localparam [15:0] COUNTER_LIMIT_INTEGRATE = 16'b0000_0001_0000_0000;
    localparam [15:0] COUNTER_LIMIT_DEINTEGRATE = 16'b1111_1111_1111_1111;

    always @(posedge clk_i or posedge rst_i) begin 
        if (rst_i) begin
            current_state <= S_RESET;
        end else if (!ref_ok_i) begin
            current_state <= S_WAIT_REF;
        end else if (sat_hi_i || sat_lo_i) begin
            current_state <= S_ERROR;
        end else begin
            current_state <= next_state;
        end
    end
    
    always @(*) begin
        afe_reset = 1'b0;
        afe_sel = AFE_IDLE;
        counter_clear = 1'b0;
        counter_en = 1'b0;
        counter_limit = COUNTER_LIMIT_DEINTEGRATE;
        case (current_state)
            S_RESET: begin
                afe_reset = 1'b1;
                counter_clear = 1'b1;
                counter_count = 16'b0;
                next_state = S_WAIT_REF;
            end
            S_WAIT_REF: begin
                afe_reset = 1'b1;
                counter_clear = 1'b1;
                if (ref_ok_i) begin
                    next_state = S_AUTO_ZERO;
                end else begin
                    next_state = S_WAIT_REF;
                end
            end
            S_AUTO_ZERO: begin
                afe_sel = AFE_AUTO_ZERO;
                counter_en = 1'b1;
                counter_count = COUNTER_LIMIT_AUTO_ZERO;
                if(counter_done) begin
                    counter_clear = 1'b1;
                    next_state = S_INTEGRATE;
                end else begin
                    next_state = S_AUTO_ZERO;
                end
            end
            S_INTEGRATE: begin
                afe_sel = AFE_INTEGRATE;
                if(counter_done) begin
                    next_state = S_DEINTEGRATE;
                end else begin
                    next_state = S_INTEGRATE;
                end
            end
            S_DEINTEGRATE: begin
                afe_reset = 1'b1;
                afe_sel = AFE_DEINTEGRATE;
                next_state = S_DONE;
            end
            S_DONE: begin
                next_state = S_RESET;
            end
            S_ERROR: begin
                next_state = S_RESET;
            end
        endcase
    end

    counter counter_inst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .en_i(counter_en),
        .limit_i(counter_limit),
        .count_o(counter_count),
        .done_o(counter_done)
    );

    assign counter_rst = rst_i || counter_clear;
    assign afe_reset_o = afe_reset;
    assign afe_sel_o = afe_sel;
endmodule