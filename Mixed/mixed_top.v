module mixed_top (
    input wire clk_i,
    input wire rst_i,

    // Analog signals
    input wire vin_p_i,
    input wire vin_n_i,
    input wire vref_p_i,
    input wire vref_n_i,

    // Digital signals

    // JTAG signals 
    input wire tck_i,
    input wire trst_i,
    input wire tms_i,
    input wire tdi_i,
    output wire tdo_o
);
    // Analog wires
    wire afe_sel;
    wire range_sel;
    wire afe_reset;
    wire ref_sign;
    wire itest_en;
    wire ishunt_en;
    wire cmp_trim;
    wire testmux_sel;

    // Digital wires
    wire comp_in;
    wire sat_hi;
    wire sat_lo;
    wire ref_ok;

    // JTAG wires
    wire tdo_internal;
    wire tdo_pad_oe_o;

    wire shift_dr;
    wire pause_dr;
    wire update_dr;
    wire capture_dr;
    wire test_logic_reset;

    wire extest_select;
    wire sample_preload_select;
    wire mbist_select;
    wire debug_select;

    wire chip_tdi;

    wire tdi_debug;
    wire tdi_bs;
    wire tdi_bist;

analog_top analog_top_inst (
  .clk_i        (clk_i),
  .rst_i        (rst_i),

  // Probes & reference from pads
  .vin_p_i      (vin_p_i),
  .vin_n_i      (vin_n_i),
  .vref_p_i     (vref_p_i),
  .vref_n_i     (vref_n_i),

  // Control from digital (autozero/integrate/deintegrate, range, etc.)
  .afe_sel_i    (afe_sel),      // [AFE_SEL_WIDTH-1:0]
  .range_sel_i  (range_sel),    // [RANGE_SEL_WIDTH-1:0]
  .afe_reset_i  (afe_reset),
  .ref_sign_i   (ref_sign),     // 0:+Vref, 1:-Vref (or vice versa) 
  .itest_en_i   (itest_en),     // Ω-mode current source enable
  .ishunt_en_i  (ishunt_en),    // I-mode shunt/PGA enable
  .cmp_trim_i   (cmp_trim),     // [CMP_TRIM_WIDTH-1:0] (optional)
  .testmux_sel_i(testmux_sel),  // [TESTMUX_WIDTH-1:0] (optional)

  // Status back to digital
  .comp_o       (comp_in),      // comparator result to engine
  .sat_hi_o     (sat_hi),       // optional: integrator at +rail
  .sat_lo_o     (sat_lo),       // optional: integrator at -rail
  .ref_ok_o     (ref_ok)        // optional: bandgap settled
);

digital_top digital_top_inst(
    .clk_i(clk_i),
    .rst_i(rst_i)
);

jtag_tap jtag_tap_inst(
    // JTAG Pins
    .tck_pad_i(tck_i),
    .trst_pad_i(trst_i),
    .tms_pad_i(tms_i),
    .tdi_pad_i(tdi_i),
    .tdo_pad_o(tdo_internal),
    .tdo_pad_oe_o(tdo_pad_oe_o),

    // Output from jtag_tap to test_interface, to allow monitoring of TAP states
    .shift_dr_o(shift_dr),
    .pause_dr_o(pause_dr),
    .update_dr_o(update_dr),
    .capture_dr_o(capture_dr),
    .test_logic_reset_o(test_logic_reset),

    // Select signals for boundary scan or mbist (outputs that tell what instruction is currently loaded)// Output from jtag_tap to test_interface, to allow monitoring of TAP states
    .extest_select_o(extest_select),
    .sample_preload_select_o(sample_preload_select),
    .mbist_select_o(mbist_select),
    .debug_select_o(debug_select),

    // TDO signal that is connected to TDI of sub-modules.
    .tdo_o(chip_tdi),

    .debug_tdi_o(tdi_debug),
    .bs_chain_tdi_i(tdi_bs),
    .mbist_tdi_i(tdi_bist)    
);

jtag_test_if jtag_test_if_inst(
    .clk_i(clk_i),
    .test_logic_reset_i(test_logic_reset),

    .shift_dr_i(shift_dr),
    .pause_dr_i(pause_dr),
    .update_dr_i(update_dr),
    .capture_dr_i(capture_dr),

    .extest_select_i(extest_select),
    .sample_preload_select_i(sample_preload_select),
    .mbist_select_i(mbist_select),
    .debug_select_i(debug_select),

    .chip_tdi_i(chip_tdi),

    .debug_tdi_o(tdi_debug),
    .bs_chain_tdi_i(tdi_bs),
    .mbist_tdi_i(tdi_bist)
);

assign tdo_o = tdo_pad_oe_o ? tdo_internal : 1'bz;

endmodule