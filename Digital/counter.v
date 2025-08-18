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
    input  wire [15:0] count_i,
    output wire busy_o,
    output wire done_o
);

    reg [15:0] count;
    reg busy, done;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            count <= 16'd0;
            busy  <= 1'b0;
            done  <= 1'b0;
        end else begin
            done <= 1'b0;  
            if (en_i && !busy) begin
                count <= count_i;
                busy  <= 1'b1;
            end else if (busy) begin
                if (count == 16'd0) begin
                    busy <= 1'b0;
                    done <= 1'b1;
                end else begin
                    count <= count - 1'b1;
                end
            end
        end
    end

    assign busy_o = busy;
    assign done_o = done;

endmodule
