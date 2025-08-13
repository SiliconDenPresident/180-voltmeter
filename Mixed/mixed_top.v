/*
--------------------------------------------------------------------------------
 Title        : mixed_top
 Project      : 180-voltmeter
 File         : mixed_top.v
 Description  : Mixed-signal top-level wrapper integrating the analog front-end,
                digital control, and IEEE 1149.1 JTAG TAP along with its Test Interface. 
 
 Author       : Tristan Wood tdwood2@ncsu.edu
 Created      : 2025-08-13
 License      : See LICENSE in the project root

 Revision History:
   - 0.1 2025-08-13 Tristan Wood Initial instantiations of sub-modules and connections
--------------------------------------------------------------------------------
*/

module mixed_top(
    input wire clk_i,
    input wire rst_i,

    // Analog signals
    input wire vin_p_i,
    input wire vin_n_i,
    input wire vref_p_i,
    input wire vref_n_i,
    output wire analog_test_o,

    // Digital signals

    // JTAG signals 
    input wire tck_i,
    input wire trst_i,
    input wire tms_i,
    input wire tdi_i,
    output wire tdo_o, 

    // Boundary Scan Signals
    input wire [32:0] bsr_i,
    output wire extest_select,
    output wire [32:0] bsr_o,
    output wire [32:0] bsr_oe
);
    // Analog wires
    wire [3:0] afe_sel;     // per-phase AFE select (AZ / VIN / +VREF / −VREF) driven by the measure FSM
    wire [4:0] range_sel;   // autorange code: selects ladder/shunt/test-current per MODE, updated between conversions
    wire       afe_reset;   // integrator reset/discharge pulse for deterministic start/abort
    wire       ref_sign;    // deintegrate polarity (0:+VREF, 1:−VREF) if not encoded inside afe_sel
    wire [2:0] mode_sel;    // measurement family: e.g., 0=V, 1=I, 2=R (latched at conversion boundary)

    // Digital wires
    wire comp_in;  // comparator sign: 1 => Vint ≥ 0 V (positive side), 0 => Vint < 0 V (negative); sync in digital
    wire sat_hi;   // integrator saturated at +rail (early overrange/abort hint)
    wire sat_lo;   // integrator saturated at −rail (early overrange/abort hint)
    wire ref_ok;   // reference settled/ready; gate start of conversion or switch to ±VREF

    // JTAG wires
    wire tdo_internal;
    wire tdo_padoe_o;

    wire shift_dr;
    wire pause_dr;
    wire update_dr;
    wire capture_dr;
    wire test_logic_reset;

    wire sample_preload_select;
    wire mbist_select;
    wire debug_select;

    wire chip_tdi;

    wire tdi_debug;
    wire tdi_bs;
    wire tdi_bist;

analog_top analog_top_inst (
  .clk_i(clk_i),
  .rst_i(rst_i),

  // Probes & reference from pads
  .vin_p_i(vin_p_i),
  .vin_n_i(vin_n_i),
  .vref_p_i(vref_p_i),
  .vref_n_i(vref_n_i),

  // Control from digital (autozero/integrate/deintegrate, range, etc.)
  .afe_sel_i(afe_sel),
  .range_sel_i(range_sel),
  .afe_reset_i(afe_reset),
  .ref_sign_i(ref_sign),
  .mode_sel_i(mode_sel),

  // Status back to digital
  .comp_o(comp_in),
  .sat_hi_o(sat_hi),
  .sat_lo_o(sat_lo),
  .ref_ok_o(ref_ok),

  // Control from JTAG
  .cmp_trim_i(cmp_trim),
  .testmux_sel_i(testmux_sel),
  .analog_test_o(analog_test_o)
);

digital_top digital_top_inst(
    .clk_i(clk_i),
    .rst_i(rst_i),

    // Analog status in
    .comp_i       (comp_in),
    .sat_hi_i     (sat_hi),
    .sat_lo_i     (sat_lo),
    .ref_ok_i     (ref_ok),

    // Analog control out
    .afe_sel_o    (afe_sel),
    .range_sel_o  (range_sel),
    .afe_reset_o  (afe_reset),
    .ref_sign_o   (ref_sign),
    .mode_sel_o   (mode_sel),
);

jtag_tap jtag_tap_inst(
    // JTAG Pins
    .tck_pad_i(tck_i),
    .trst_pad_i(trst_i),
    .tms_pad_i(tms_i),
    .tdi_pad_i(tdi_i),
    .tdo_pad_o(tdo_internal),
    .tdo_padoe_o(tdo_padoe_o),

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

    .debug_tdi_i(tdi_debug),
    .bs_chain_tdi_i(tdi_bs),
    .mbist_tdi_i(tdi_bist)    
);

jtag_test_if jtag_test_if_inst(
    .tck_i(tck_i),
    .test_logic_reset_i(test_logic_reset),

    .shift_dr_i(shift_dr),
    .pause_dr_i(pause_dr),
    .update_dr_i(update_dr),
    .capture_dr_i(capture_dr),

    .extest_select_i(extest_select),
    .sample_preload_select_i(sample_preload_select),
    .mbist_select_i(mbist_select),
    .debug_select_i(debug_select),

    .tdi_i(chip_tdi),

    .debug_tdi_o(tdi_debug),
    .bs_chain_tdi_i(tdi_bs),
    .mbist_tdi_i(tdi_bist),

    .cmp_trim_o(cmp_trim),
    .testmux_sel_o(testmux_sel)
);


// JTAG TDO tristate
assign tdo_o = tdo_padoe_o ? tdo_internal : 1'bz;

endmodule