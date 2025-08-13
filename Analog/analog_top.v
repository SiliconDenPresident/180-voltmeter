module analog_top (
    input wire clk_i,
    input wire rst_i,

    input wire vin_p_i,
    input wire vin_n_i,
    input wire vref_p_i,
    input wire vref_n_i,

    input wire afe_sel_i,
    input wire range_sel_i,
    input wire afe_reset_i,
    input wire ref_sign_i,
    input wire mode_sel_i,

    output wire comp_o,
    output wire sat_hi_o,
    output wire sat_lo_o,
    output wire ref_ok_o,

    input wire cmp_trim_i,
    input wire testmux_sel_i,
    output wire analog_test_o
);


endmodule