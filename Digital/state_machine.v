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

    // Inputs from AFE
    input wire comp_i,
    input wire sat_hi_i,
    input wire sat_lo_i,
    input wire ref_ok_i,

    // Outputs to AFE
    output reg [1:0] afe_sel_o,
    output reg [2:0] range_sel_o,
    output reg afe_reset_o,
    output reg ref_sign_o,
    output reg range_error_o,
    output reg done_o,

    // Outputs to counter
    input wire counter_done_i,
    input wire counter_busy_i,
    output reg counter_clear_o,
    output reg counter_en_o,
    output reg [15:0] counter_limit_o
);

    // ---------------------------------------------------------
    // Declarations
    // ---------------------------------------------------------

    // AFE 
    localparam [1:0] AFE_IDLE = 2'b00;
    localparam [1:0] AFE_AUTO_ZERO = 2'b01; 
    localparam [1:0] AFE_INTEGRATE = 2'b10;
    localparam [1:0] AFE_DEINTEGRATE = 2'b11;

    reg sat_hi_flag, sat_lo_flag, comp_prev;

    // State machine
    localparam S_WAIT_REF = 3'b000;
    localparam S_AUTO_ZERO = 3'b001;
    localparam S_INTEGRATE = 3'b010;
    localparam S_DEINTEGRATE = 3'b011;
    localparam S_DONE = 3'b100;
    localparam S_ERROR = 3'b101;

    reg [2:0] current_state, next_state;

    // Counter
    localparam [15:0] COUNTER_LIMIT_AUTO_ZERO = 16'b0000_0010_0000_0000;
    localparam [15:0] COUNTER_LIMIT_INTEGRATE = 16'b0100_0000_0000_0000;
    localparam [15:0] COUNTER_LIMIT_DEINTEGRATE = 16'b1111_1111_1111_1111;

    // ---------------------------------------------------------
    // Implementation
    // ---------------------------------------------------------

    always @(posedge clk_i or posedge rst_i) begin 
        if (rst_i || !ref_ok_i) begin
            current_state <= S_WAIT_REF;
        end else if (sat_hi_i || sat_lo_i) begin
            current_state <= S_ERROR;
        end else begin
            current_state <= next_state;
        end
    end
    
    always @(*) begin
        afe_reset_o = 1'b0;
        range_sel_o = 3'b000;
        afe_sel_o = AFE_IDLE;
        ref_sign_o = 1'b0;
        counter_clear_o = 1'b0;
        counter_en_o = 1'b0;
        counter_limit_o = COUNTER_LIMIT_DEINTEGRATE;
        done_o = 1'b0;
        case (current_state)
            S_WAIT_REF: begin
                afe_reset_o = 1'b1;
                comp_prev = 1'b0;
                if (ref_ok_i) begin
                    next_state = S_AUTO_ZERO;
                end else begin
                    next_state = S_WAIT_REF;
                end
            end
            S_AUTO_ZERO: begin
                afe_sel_o = AFE_AUTO_ZERO;
                counter_en_o = 1'b1;
                counter_limit_o = COUNTER_LIMIT_AUTO_ZERO;
                if(sat_hi_flag) begin
                    if(range_sel_o != 3'b111) begin
                        range_sel_o = range_sel_o + 1'b1;
                    end else begin
                        range_error_o = 1'b1;
                    end
                end else if(sat_lo_flag) begin
                    if(range_sel_o != 3'b000) begin
                        range_sel_o = range_sel_o - 1'b1;
                    end else begin
                        range_error_o = 1'b1;
                    end
                end
                if(counter_done_i) begin
                    counter_clear_o = 1'b1;
                    next_state = S_INTEGRATE;
                end else begin
                    next_state = S_AUTO_ZERO;
                end
            end
            S_INTEGRATE: begin
                counter_en_o = 1'b1;
                counter_limit_o = COUNTER_LIMIT_INTEGRATE;
                afe_sel_o = AFE_INTEGRATE;
                if(comp_i) begin
                    comp_prev = 1'b1;
                    ref_sign_o = 1'b0;
                end else begin
                    comp_prev = 1'b0;
                    ref_sign_o = 1'b1;
                end
                if(counter_done_i) begin
                    counter_clear_o = 1'b1;
                    next_state = S_DEINTEGRATE;
                end else begin
                    next_state = S_INTEGRATE;
                end
            end
            S_DEINTEGRATE: begin
                afe_sel_o = AFE_DEINTEGRATE;
                counter_en_o = 1'b1;
                counter_limit_o = COUNTER_LIMIT_DEINTEGRATE;
                if(comp_i != comp_prev) begin
                    next_state = S_DONE;
                end else begin
                    next_state = S_DEINTEGRATE;
                end
            end
            S_DONE: begin
                done_o = 1'b1;
                afe_reset_o = 1'b1;
                next_state = S_AUTO_ZERO;
            end
            S_ERROR: begin
                afe_reset_o = 1'b1;
                if(sat_hi_i) begin
                    sat_hi_flag = 1'b1;
                end else if(sat_lo_i) begin
                    sat_lo_flag = 1'b1;
                end
                counter_en_o = 1'b1;
                counter_limit_o = COUNTER_LIMIT_DEINTEGRATE;
                if(counter_done_i) begin
                    range_error_o = 1'b1;
                    next_state = S_ERROR;
                end
                if(!sat_hi_i && !sat_lo_i) begin
                    range_error_o = 1'b0;
                    next_state = S_AUTO_ZERO;
                end else begin
                    next_state = S_ERROR;
                end
            end
        endcase
    end

endmodule