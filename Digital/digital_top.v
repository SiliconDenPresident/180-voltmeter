module digital_top (
    input wire clk_i,
    input wire rst_i,

    // Analog status in
    input wire comp_i,
    input wire sat_hi_i,
    input wire sat_lo_i,
    input wire ref_ok_i,

    // Analog control out
    output wire [3:0] afe_sel_o,
    output wire [4:0] range_sel_o,
    output wire afe_reset_o,
    output wire ref_sign_o,

    output wire [15:0] dbg_o
);



endmodule