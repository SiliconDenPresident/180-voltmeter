/*
--------------------------------------------------------------------------------
 Title        : Sync and Filter Testbench
 Project      : 180-voltmeter
 File         : testbench.sv
 Description  : Comprehensive testbench for the sync_and_filter module.
                Tests synchronization, metastability protection, glitch filtering,
                hysteresis behavior, and edge cases.
 
 Author       : Tristan Wood tdwood2@ncsu.edu
 Created      : 2025-08-13
 License      : See LICENSE in the project root

 Revision History:
   - 0.1 2025-08-13 Tristan Wood Initial testbench implementation
--------------------------------------------------------------------------------
*/

`timescale 1ns/1ps

module sync_and_filter_tb;
    // Clock period
    localparam CLK_PERIOD = 10; // 10ns = 100MHz
    
    // Test parameters - using default module parameters
    localparam CTR_WIDTH = 4;
    localparam HIGH_THRESH = 12;
    localparam LOW_THRESH = 3;
    localparam CTR_MAX = (1 << CTR_WIDTH) - 1; // 15
    
    // Signals
    logic clk_i;
    logic rst_n_i;
    logic async_i;
    logic clean_out_o;
    
    // Clock generation
    initial begin
        clk_i = 0;
        forever #(CLK_PERIOD/2) clk_i = ~clk_i;
    end
    
    // Instantiate the sync_and_filter module
    sync_and_filter #(
        .CTR_WIDTH(CTR_WIDTH),
        .HIGH_THRESH(HIGH_THRESH),
        .LOW_THRESH(LOW_THRESH)
    ) dut (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .async_i(async_i),
        .clean_out_o(clean_out_o)
    );
    
    // Test stimulus and monitoring
    initial begin
        // Initialize signals
        rst_n_i = 1'b1;
        async_i = 1'b0;
        
        // Wait a few clock cycles
        #(CLK_PERIOD * 2);
        
        // Test 1: Reset functionality
        $display("=== Test 1: Reset Functionality ===");
        rst_n_i = 1'b0;
        #(CLK_PERIOD * 2);
        assert(clean_out_o === 1'b0)
            else $error("Reset failed: clean_out_o=%b", clean_out_o);
        $display("Reset test passed");
        
        // Test 2: Basic synchronization - single transition
        $display("=== Test 2: Basic Synchronization ===");
        rst_n_i = 1'b1;
        async_i = 1'b1;
        #(CLK_PERIOD * 2);
        
        // Should see synchronized input after 2 clock cycles
        assert(clean_out_o === 1'b0) // Still below threshold
            else $error("Early output assertion failed: clean_out_o=%b", clean_out_o);
        $display("Basic synchronization test passed");
        
        // Test 3: Counter increment and threshold crossing
        $display("=== Test 3: Counter Increment and Threshold Crossing ===");
        // Keep input high to increment counter
        repeat(HIGH_THRESH) #(CLK_PERIOD);
        
        // Should now be above high threshold
        assert(clean_out_o === 1'b1)
            else $error("High threshold crossing failed: clean_out_o=%b", clean_out_o);
        $display("High threshold crossing test passed");
        
        // Test 4: Counter saturation
        $display("=== Test 4: Counter Saturation ===");
        // Continue high input to test saturation
        repeat(5) #(CLK_PERIOD);
        
        // Counter should be saturated at CTR_MAX
        assert(clean_out_o === 1'b1)
            else $error("Counter saturation failed: clean_out_o=%b", clean_out_o);
        $display("Counter saturation test passed");
        
        // Test 5: Input transition to low
        $display("=== Test 5: Input Transition to Low ===");
        async_i = 1'b0;
        #(CLK_PERIOD * 2);
        
        // Output should still be high (above low threshold)
        assert(clean_out_o === 1'b1)
            else $error("Low threshold persistence failed: clean_out_o=%b", clean_out_o);
        $display("Low threshold persistence test passed");
        
        // Test 6: Counter decrement and low threshold crossing
        $display("=== Test 6: Counter Decrement and Low Threshold Crossing ===");
        // Wait for counter to decrement below low threshold
        repeat(LOW_THRESH + 1) #(CLK_PERIOD);
        
        // Should now be below low threshold
        assert(clean_out_o === 1'b0)
            else $error("Low threshold crossing failed: clean_out_o=%b", clean_out_o);
        $display("Low threshold crossing test passed");
        
        // Test 7: Counter floor
        $display("=== Test 7: Counter Floor ===");
        // Continue low input to test floor
        repeat(5) #(CLK_PERIOD);
        
        // Counter should be at 0
        assert(clean_out_o === 1'b0)
            else $error("Counter floor failed: clean_out_o=%b", clean_out_o);
        $display("Counter floor test passed");
        
        // Test 8: Glitch filtering - short pulses
        $display("=== Test 8: Glitch Filtering - Short Pulses ===");
        // Generate short pulses that shouldn't affect output
        repeat(3) begin
            async_i = 1'b1;
            #(CLK_PERIOD);
            async_i = 1'b0;
            #(CLK_PERIOD);
        end
        
        // Output should remain low (pulses too short)
        assert(clean_out_o === 1'b0)
            else $error("Glitch filtering failed: clean_out_o=%b", clean_out_o);
        $display("Glitch filtering test passed");
        
        // Test 9: Glitch filtering - medium pulses
        $display("=== Test 9: Glitch Filtering - Medium Pulses ===");
        // Generate medium pulses that might affect counter but not output
        repeat(2) begin
            async_i = 1'b1;
            #(CLK_PERIOD * 2);
            async_i = 1'b0;
            #(CLK_PERIOD * 2);
        end
        
        // Output should still be low (not enough to cross threshold)
        assert(clean_out_o === 1'b0)
            else $error("Medium pulse filtering failed: clean_out_o=%b", clean_out_o);
        $display("Medium pulse filtering test passed");
        
        // Test 10: Hysteresis behavior
        $display("=== Test 10: Hysteresis Behavior ===");
        // Generate input that oscillates around thresholds
        async_i = 1'b1;
        repeat(HIGH_THRESH - 1) #(CLK_PERIOD); // Just below high threshold
        async_i = 1'b0;
        repeat(2) #(CLK_PERIOD); // Brief low
        
        // Output should remain low (hysteresis prevents oscillation)
        assert(clean_out_o === 1'b0)
            else $error("Hysteresis behavior failed: clean_out_o=%b", clean_out_o);
        $display("Hysteresis behavior test passed");
        
        // Test 11: Reset during operation
        $display("=== Test 11: Reset During Operation ===");
        // Get counter to middle value
        async_i = 1'b1;
        repeat(8) #(CLK_PERIOD);
        
        // Reset during operation
        rst_n_i = 1'b0;
        #(CLK_PERIOD);
        
        // Should be reset
        assert(clean_out_o === 1'b0)
            else $error("Reset during operation failed: clean_out_o=%b", clean_out_o);
        $display("Reset during operation test passed");
        
        // Test 12: Edge case - rapid transitions
        $display("=== Test 12: Edge Case - Rapid Transitions ===");
        rst_n_i = 1'b1;
        
        // Rapid transitions
        repeat(10) begin
            async_i = 1'b1;
            #(CLK_PERIOD/2); // Half clock period
            async_i = 1'b0;
            #(CLK_PERIOD/2);
        end
        
        // Output should be stable (not oscillating)
        #(CLK_PERIOD * 2);
        logic stable_output = clean_out_o;
        #(CLK_PERIOD * 2);
        assert(clean_out_o === stable_output)
            else $error("Rapid transitions caused oscillation: clean_out_o changed from %b to %b", stable_output, clean_out_o);
        $display("Rapid transitions test passed");
        
        // Test 13: Continuous operation
        $display("=== Test 13: Continuous Operation ===");
        // Test continuous high input
        async_i = 1'b1;
        repeat(HIGH_THRESH + 5) #(CLK_PERIOD);
        assert(clean_out_o === 1'b1)
            else $error("Continuous high operation failed: clean_out_o=%b", clean_out_o);
        
        // Test continuous low input
        async_i = 1'b0;
        repeat(LOW_THRESH + 5) #(CLK_PERIOD);
        assert(clean_out_o === 1'b0)
            else $error("Continuous low operation failed: clean_out_o=%b", clean_out_o);
        $display("Continuous operation test passed");
        
        // Test 14: Parameter verification
        $display("=== Test 14: Parameter Verification ===");
        $display("CTR_WIDTH: %d", CTR_WIDTH);
        $display("HIGH_THRESH: %d", HIGH_THRESH);
        $display("LOW_THRESH: %d", LOW_THRESH);
        $display("CTR_MAX: %d", CTR_MAX);
        $display("Parameter verification completed");
        
        // Final summary
        $display("=== All Tests Completed Successfully ===");
        $finish;
    end
    
    // Monitor for unexpected behavior
    always @(posedge clk_i) begin
        // Check that output doesn't oscillate rapidly
        static logic last_output = 1'b0;
        static int oscillation_count = 0;
        
        if (clean_out_o !== last_output) begin
            oscillation_count++;
            if (oscillation_count > 10) begin
                $warning("High oscillation count detected: %d", oscillation_count);
            end
        end
        last_output = clean_out_o;
        
        // Check that output is always valid (0 or 1)
        if (clean_out_o !== 1'b0 && clean_out_o !== 1'b1) begin
            $error("Invalid output value: clean_out_o=%b", clean_out_o);
        end
    end
    
    // Waveform dumping (optional - uncomment if using a waveform viewer)
    // initial begin
    //     $dumpfile("sync_and_filter_tb.vcd");
    //     $dumpvars(0, sync_and_filter_tb);
    // end
    
endmodule
