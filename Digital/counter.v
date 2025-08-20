/*
--------------------------------------------------------------------------------
 Title        : counter
 Project      : 180-voltmeter
 File         : counter.v
 Description  : Configurable down-counter module that provides precise timing
                control for the voltmeter system. Generates a busy signal while
                counting and a single-cycle done pulse when the count reaches zero.
                Supports 16-bit count values for flexible timing requirements.
 
 Author       : Tristan Wood tdwood2@ncsu.edu
 Created      : 2025-08-13
 License      : See LICENSE in the project root

 Revision History:
   - 0.1 2025-08-13 Tristan Wood Initial implementation of configurable down-counter
--------------------------------------------------------------------------------
*/

module counter (
    input  wire clk_i,
    input  wire rst_i,
    input  wire en_i,
    input  wire clear_i,
    input  wire [15:0] limit_i,
    output reg busy_o,
    output reg done_o,
    output reg [15:0] count_o
);
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i || clear_i) begin
            busy_o  <= 1'b0;
            done_o  <= 1'b0;
            count_o <= 16'd0;
        end else begin  
            if(en_i) begin
                if(busy_o) begin
                    if(count_o == limit_i) begin
                        busy_o <= 1'b0;
                        done_o <= 1'b1;
                    end else begin
                        count_o <= count_o + 1'b1;
                    end
                end else begin
                    busy_o <= 1'b1;
                    done_o <= 1'b0;
                    count_o <= 16'd0;
                end
            end else begin
                busy_o <= 1'b0;
                done_o <= 1'b0;
                count_o <= 16'd0;
            end
        end
    end
endmodule
