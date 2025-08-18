/*
--------------------------------------------------------------------------------
 Title        : sync_and_filter
 Project      : 180-voltmeter
 File         : sync_and_filter.v
 Description  : Synchronization and filtering module that provides metastability
                protection and glitch filtering for asynchronous input signals.
                Implements a two-flop synchronizer followed by a saturating
                up/down counter with hysteresis for robust signal conditioning.
 
 Author       : Tristan Wood tdwood2@ncsu.edu
 Created      : 2025-08-13
 License      : See LICENSE in the project root

 Revision History:
   - 0.1 2025-08-13 Tristan Wood Initial implementation with two-FF sync and counter filter
--------------------------------------------------------------------------------
*/

module sync_and_filter #(
    parameter CTR_WIDTH   = 4,         // width of saturating counter
    parameter HIGH_THRESH = 12,        // value at/above = logic 1
    parameter LOW_THRESH  = 3          // value at/below = logic 0
)(
    input  wire clk_i,
    input  wire rst_i,
    input  wire async_in,
    output reg  clean_out
);

    // ---------------------------------------------------------
    // 1. Two-FF synchronizer
    // ---------------------------------------------------------
    reg sync_ff1, sync_ff2;
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            sync_ff1 <= 1'b0;
            sync_ff2 <= 1'b0;
        end else begin
            sync_ff1 <= async_in;
            sync_ff2 <= sync_ff1;
        end
    end

    // ---------------------------------------------------------
    // 2. Saturating Up/Down Counter
    // ---------------------------------------------------------
    reg [CTR_WIDTH-1:0] ctr;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            ctr       <= {CTR_WIDTH{1'b0}};
            clean_out <= 1'b0;
        end else begin
            // Increment or decrement
            if (sync_ff2 && ctr != {CTR_WIDTH{1'b1}})
                ctr <= ctr + 1'b1;
            else if (!sync_ff2 && ctr != {CTR_WIDTH{1'b0}})
                ctr <= ctr - 1'b1;

            // Decision with hysteresis
            if (ctr >= HIGH_THRESH)
                clean_out <= 1'b1;
            else if (ctr <= LOW_THRESH)
                clean_out <= 1'b0;
        end
    end

endmodule
