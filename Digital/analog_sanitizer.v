/*
--------------------------------------------------------------------------------
 Title        : analog_sanitizer
 Project      : 180-voltmeter
 File         : analog_sanitizer.v
 Description  : Analog signal sanitization module that provides metastability
                protection and glitch filtering for all analog status signals
                from the analog front-end. Instantiates multiple sync_and_filter
                modules to condition comparator, saturation, and reference
                ready signals before they enter the digital domain.
 
 Author       : Tristan Wood tdwood2@ncsu.edu
 Created      : 2025-08-13
 License      : See LICENSE in the project root

 Revision History:
   - 0.1 2025-08-13 Tristan Wood Initial implementation with four sync_and_filter instances
--------------------------------------------------------------------------------
*/

module analog_sanitizer (
    input wire clk_i,
    input wire rst_n_i,
    input wire comp_i,
    input wire sat_hi_i,
    input wire sat_lo_i,
    input wire ref_ok_i,
    output wire comp_o,
    output wire sat_hi_o,
    output wire sat_lo_o,
    output wire ref_ok_o
);

    // ---------------------------------------------------------
    // Signal Sanitization Strategy
    // ---------------------------------------------------------
    // Each analog input signal is processed through a dedicated sync_and_filter
    // module that provides:
    //   1. Two-flop synchronizer to prevent metastability issues
    //   2. Up/down counter with hysteresis for glitch filtering
    //   3. Threshold-based decision making:
    //      - Above HIGH_THRESH (12) = logic 1
    //      - Below LOW_THRESH (3) = logic 0  
    //      - Between thresholds = hysteresis (maintains previous value)
    //      - This prevents oscillation around the threshold levels
    // ---------------------------------------------------------

    sync_and_filter #(
        .CTR_WIDTH(4),
        .HIGH_THRESH(12), 
        .LOW_THRESH(3) 
    ) sync_and_filter_inst1 (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .async_i(comp_i),
        .clean_out_o(comp_o)
    );

    sync_and_filter #(
        .CTR_WIDTH(4),
        .HIGH_THRESH(12),
        .LOW_THRESH(3)
    ) sync_and_filter_inst2 (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .async_i(sat_hi_i),
        .clean_out_o(sat_hi_o)
    );

    sync_and_filter #(
        .CTR_WIDTH(4),
        .HIGH_THRESH(12),
        .LOW_THRESH(3)
    ) sync_and_filter_inst3 (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .async_i(sat_lo_i),
        .clean_out_o(sat_lo_o)
    );

    sync_and_filter #(
        .CTR_WIDTH(4),
        .HIGH_THRESH(12),
        .LOW_THRESH(3)
    ) sync_and_filter_inst4 (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .async_i(ref_ok_i),
        .clean_out_o(ref_ok_o)
    );
endmodule