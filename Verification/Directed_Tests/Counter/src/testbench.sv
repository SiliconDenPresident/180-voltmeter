/*
--------------------------------------------------------------------------------
 Title        : Counter Testbench
 Project      : 180-voltmeter
 File         : testbench.sv
 Description  : Comprehensive testbench for the configurable down-counter module.
                Tests reset, enable, clear, counting behavior, and edge cases.
 
 Author       : Tristan Wood tdwood2@ncsu.edu
 Created      : 2025-08-13
 License      : See LICENSE in the project root

 Revision History:
   - 0.1 2025-08-13 Tristan Wood Initial testbench implementation
--------------------------------------------------------------------------------
*/

`timescale 1ns/1ps

module testbench;
    // Clock period
    localparam CLK_PERIOD = 10; // 10ns = 100MHz
    
    // Test parameters
    localparam TEST_LIMIT_1 = 16'd5;   // Small value for quick testing
    localparam TEST_LIMIT_2 = 16'd10;  // Medium value
    localparam TEST_LIMIT_3 = 16'd100; // Larger value
    
    // Signals
    logic clk_i;
    logic rst_n_i;
    logic en_i;
    logic clear_i;
    logic [15:0] limit_i;
    logic busy_o;
    logic done_o;
    logic [15:0] count_o;
    
    // Clock generation
    initial begin
        clk_i = 0;
        forever #(CLK_PERIOD/2) clk_i = ~clk_i;
    end
    
    // Instantiate the counter module
    counter uut (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),
        .clear_i(clear_i),
        .limit_i(limit_i),
        .busy_o(busy_o),
        .done_o(done_o),
        .count_o(count_o)
    );
    
    // Test stimulus and monitoring
    initial begin
        // Initialize signals
        rst_n_i = 1'b1;
        en_i = 1'b0;
        clear_i = 1'b0;
        limit_i = 16'd0;
        
        // Wait a few clock cycles
        #(CLK_PERIOD * 2);
        
        // Test 1: Reset functionality
        $display("=== Test 1: Reset Functionality ===");
        rst_n_i = 1'b0;
        #(CLK_PERIOD * 2);
        assert(busy_o === 1'b0 && done_o === 1'b0 && count_o === 16'd0)
            else $error("Reset failed: busy_o=%b, done_o=%b, count_o=%d", busy_o, done_o, count_o);
        $display("Reset test passed");
        
        // Test 2: Basic counting functionality
        $display("=== Test 2: Basic Counting Functionality ===");
        rst_n_i = 1'b1;
        limit_i = TEST_LIMIT_1;
        en_i = 1'b1;
        #(CLK_PERIOD);
        
        // Should start counting
        assert(busy_o === 1'b1 && count_o === 16'd0)
            else $error("Start counting failed: busy_o=%b, count_o=%d", busy_o, count_o);
        
        // Wait for count to reach limit
        repeat(TEST_LIMIT_1) #(CLK_PERIOD);
        
        // Should be done
        assert(busy_o === 1'b0 && done_o === 1'b1 && count_o === TEST_LIMIT_1)
            else $error("Counting completion failed: busy_o=%b, done_o=%b, count_o=%d", busy_o, done_o, count_o);
        $display("Basic counting test passed");
        
        // Test 3: Clear functionality during counting
        $display("=== Test 3: Clear Functionality ===");
        en_i = 1'b0; // Stop current count
        #(CLK_PERIOD);
        en_i = 1'b1; // Start new count
        #(CLK_PERIOD);
        clear_i = 1'b1; // Clear during counting
        #(CLK_PERIOD);
        clear_i = 1'b0;
        
        // Should be cleared
        assert(busy_o === 1'b0 && done_o === 1'b0 && count_o === 16'd0)
            else $error("Clear failed: busy_o=%b, done_o=%b, count_o=%d", busy_o, done_o, count_o);
        $display("Clear test passed");
        
        // Test 4: Enable/disable behavior
        $display("=== Test 4: Enable/Disable Behavior ===");
        limit_i = TEST_LIMIT_2;
        en_i = 1'b1;
        #(CLK_PERIOD);
        
        // Should start counting
        assert(busy_o === 1'b1 && count_o === 16'd0)
            else $error("Enable failed: busy_o=%b, count_o=%d", busy_o, count_o);
        
        // Disable during counting
        en_i = 1'b0;
        #(CLK_PERIOD * 3);
        
        // Should stop counting and maintain state
        assert(busy_o === 1'b1 && count_o === 16'd3)
            else $error("Disable failed: busy_o=%b, count_o=%d", busy_o, count_o);
        
        // Re-enable to continue
        en_i = 1'b1;
        repeat(TEST_LIMIT_2 - 3) #(CLK_PERIOD);
        
        // Should complete counting
        assert(busy_o === 1'b0 && done_o === 1'b1 && count_o === TEST_LIMIT_2)
            else $error("Re-enable failed: busy_o=%b, done_o=%b, count_o=%d", busy_o, done_o, count_o);
        $display("Enable/disable test passed");
        
        // Test 5: Edge case - limit of 0
        $display("=== Test 5: Edge Case - Limit of 0 ===");
        limit_i = 16'd0;
        en_i = 1'b1;
        #(CLK_PERIOD);
        
        // Should immediately complete
        assert(busy_o === 1'b0 && done_o === 1'b1 && count_o === 16'd0)
            else $error("Limit 0 failed: busy_o=%b, done_o=%b, count_o=%d", busy_o, done_o, count_o);
        $display("Limit 0 test passed");
        
        // Test 6: Edge case - maximum limit
        $display("=== Test 6: Edge Case - Maximum Limit ===");
        limit_i = 16'hFFFF;
        en_i = 1'b1;
        #(CLK_PERIOD);
        
        // Should start counting
        assert(busy_o === 1'b1 && count_o === 16'd0)
            else $error("Max limit start failed: busy_o=%b, count_o=%d", busy_o, count_o);
        
        // Wait for a few counts to verify it's working
        repeat(5) #(CLK_PERIOD);
        assert(count_o === 16'd5)
            else $error("Max limit counting failed: count_o=%d", count_o);
        $display("Max limit test passed");
        
        // Test 7: Reset during counting
        $display("=== Test 7: Reset During Counting ===");
        limit_i = TEST_LIMIT_3;
        en_i = 1'b1;
        #(CLK_PERIOD * 5);
        
        // Should be counting
        assert(busy_o === 1'b1 && count_o === 16'd5)
            else $error("Reset during counting setup failed: busy_o=%b, count_o=%d", busy_o, count_o);
        
        // Reset during counting
        rst_n_i = 1'b0;
        #(CLK_PERIOD);
        
        // Should be reset
        assert(busy_o === 1'b0 && done_o === 1'b0 && count_o === 16'd0)
            else $error("Reset during counting failed: busy_o=%b, done_o=%b, count_o=%d", busy_o, done_o, count_o);
        $display("Reset during counting test passed");
        
        // Test 8: Multiple clear operations
        $display("=== Test 8: Multiple Clear Operations ===");
        rst_n_i = 1'b1;
        limit_i = TEST_LIMIT_1;
        en_i = 1'b1;
        #(CLK_PERIOD);
        
        // Clear multiple times
        repeat(3) begin
            clear_i = 1'b1;
            #(CLK_PERIOD);
            clear_i = 1'b0;
            #(CLK_PERIOD);
        end
        
        // Should remain cleared
        assert(busy_o === 1'b0 && done_o === 1'b0 && count_o === 16'd0)
            else $error("Multiple clear failed: busy_o=%b, done_o=%b, count_o=%d", busy_o, done_o, count_o);
        $display("Multiple clear test passed");
        
        // Test 9: Done signal behavior
        $display("=== Test 9: Done Signal Behavior ===");
        limit_i = TEST_LIMIT_1;
        en_i = 1'b1;
        #(CLK_PERIOD);
        
        // Wait for completion
        repeat(TEST_LIMIT_1) #(CLK_PERIOD);
        
        // Done should be high for one cycle
        assert(done_o === 1'b1)
            else $error("Done signal not asserted: done_o=%b", done_o);
        
        #(CLK_PERIOD);
        
        // Done should be low on next cycle
        assert(done_o === 1'b0)
            else $error("Done signal not cleared: done_o=%b", done_o);
        $display("Done signal test passed");
        
        // Test 10: Continuous operation
        $display("=== Test 10: Continuous Operation ===");
        limit_i = TEST_LIMIT_1;
        en_i = 1'b1;
        
        // Run multiple cycles
        repeat(3) begin
            #(CLK_PERIOD);
            assert(busy_o === 1'b1)
                else $error("Continuous operation busy failed: busy_o=%b", busy_o);
            
            // Wait for completion
            repeat(TEST_LIMIT_1) #(CLK_PERIOD);
            
            // Should complete
            assert(busy_o === 1'b0 && done_o === 1'b1)
                else $error("Continuous operation completion failed: busy_o=%b, done_o=%b", busy_o, done_o);
            
            #(CLK_PERIOD);
        end
        $display("Continuous operation test passed");
        
        // Final summary
        $display("=== All Tests Completed Successfully ===");
        $finish;
    end
    
    // Monitor for unexpected behavior
    always @(posedge clk_i) begin
        // Check that done is only high for one cycle
        if (done_o) begin
            @(posedge clk_i);
            if (done_o) begin
                $error("Done signal remained high for more than one cycle");
            end
        end
        
        // Check that count never exceeds limit when busy
        if (busy_o && count_o > limit_i) begin
            $error("Count exceeded limit: count_o=%d, limit_i=%d", count_o, limit_i);
        end
        
        // Check that busy is never high when count equals limit
        if (busy_o && count_o == limit_i) begin
            $error("Busy high when count equals limit: count_o=%d, limit_i=%d", count_o, limit_i);
        end
    end
    
    // Waveform dumping (optional - uncomment if using a waveform viewer)
    // initial begin
    //     $dumpfile("counter_tb.vcd");
    //     $dumpvars(0, counter_tb);
    // end
    
endmodule
