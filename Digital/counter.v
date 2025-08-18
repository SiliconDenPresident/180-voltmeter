module counter (
    input wire clk_i,
    input wire rst_i,
    input wire en_i,
    input wire [15:0] count_i,
    output wire [15:0] count_o,
    output wire busy_o,
    output wire done_o
);

    reg [15:0] count_reg;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            count_reg <= 16'b0;
            busy_o <= 1'b0;
        end else if (en_i) begin
            count_reg <= count_reg + 1;
        end
    end


endmodule