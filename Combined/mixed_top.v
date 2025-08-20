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
    // Analog signals
    input wire vin_p_i,
    input wire vin_n_i,
    input wire vref_p_i,
    input wire vref_n_i,
    output wire analog_test_o,

    // Digital signals
    input wire clk_i,
    input wire rst_i,
    input wire [1:0] mode_sel_i,

    // -- SPI signals
    input wire spi_sclk_i,
    input wire spi_cs_i,
    input wire spi_mosi_i,
    output wire spi_miso_o,
    output wire interrupt_o,
    
    // -- JTAG signals 
    input wire tck_i,
    input wire trst_i,
    input wire tms_i,
    input wire tdi_i,
    output wire tdo_o, 
    output wire tdo_padoe_o,

    // --  -- Boundary Scan signals
    input wire [27:0] bsr_i,
    output wire [13:0] bsr_o,
    output wire [13:0] bsr_oe,
    output wire extest_select
);

    //---------------------------------------------------------
    // Declarations
    //---------------------------------------------------------

    // Analog 
    wire [1:0] afe_sel;     // per-phase AFE select (AZ / VIN / +VREF / −VREF) driven by the measure FSM
    wire [2:0] range_sel;   // autorange code: selects ladder/shunt/test-current per MODE, updated between conversions
    wire       afe_reset;   // integrator reset/discharge pulse for deterministic start/abort
    wire       ref_sign;    // deintegrate polarity (0:+VREF, 1:−VREF) if not encoded inside afe_sel

    // Digital 
    wire comp;  // comparator sign: 1 => Vint ≥ 0 V (positive side), 0 => Vint < 0 V (negative); sync in digital
    wire sat_hi;   // integrator saturated at +rail (early overrange/abort hint)
    wire sat_lo;   // integrator saturated at −rail (early overrange/abort hint)
    wire ref_ok;   // reference settled/ready; gate start of conversion or switch to ±VREF

    // - JTAG 
    wire shift_dr;
    wire pause_dr;
    wire update_dr;
    wire capture_dr;

    wire test_logic_reset;
    wire sample_preload_select;
    wire mbist_select;
    wire debug_select;

    wire chip_tdi;
    wire tdi_mbist;

    // -- Boundary Scan
    wire tdi_bs;

    // -- Debug  
    wire tdi_debug;
    wire [31:0] dbg_i;  // Debug input signals (32-bit)
    wire [31:0] dbg_o;  // Debug output signals (32-bit)

    //---------------------------------------------------------
    // Instantiations
    //---------------------------------------------------------

    analog_top analog_top_inst (
        // Probes & reference from pads
        .vin_p_i(vin_p_i),
        .vin_n_i(vin_n_i),
        .vref_p_i(vref_p_i),
        .vref_n_i(vref_n_i),

        // Control from digital
        .afe_sel_i(afe_sel),
        .range_sel_i(range_sel),
        .afe_reset_i(afe_reset),
        .ref_sign_i(ref_sign),
        .mode_sel_i(mode_sel_i),

        // Status back to digital
        .comp_o(comp),
        .sat_hi_o(sat_hi),
        .sat_lo_o(sat_lo),
        .ref_ok_o(ref_ok),

        // Validation Signals
        .dbg_i(dbg_o[7:0]),
        .analog_test_o(analog_test_o)
    );

    digital_top digital_top_inst(
        .clk_i(clk_i),
        .rst_i(rst_i),

        // Analog control out
        .afe_sel_o(afe_sel),
        .range_sel_o(range_sel),
        .afe_reset_o(afe_reset),
        .ref_sign_o(ref_sign),
        .mode_sel_i(mode_sel_i),

        // Analog status in
        .comp_i(comp),
        .sat_hi_i(sat_hi),
        .sat_lo_i(sat_lo),
        .ref_ok_i(ref_ok),

        // SPI Signals
        .spi_sclk_i(spi_sclk_i),
        .spi_cs_i(spi_cs_i),
        .spi_mosi_i(spi_mosi_i),
        .spi_miso_o(spi_miso_o),
        .interrupt_o(interrupt_o),

        // Validation Signals
        .dbg_o(dbg_i),
        .dbg_i(dbg_o)
    );

    jtag_tap jtag_tap_inst(
        // JTAG Pins
        .tck_pad_i(tck_i),
        .trst_pad_i(trst_i),
        .tms_pad_i(tms_i),
        .tdi_pad_i(tdi_i),
        .tdo_pad_o(tdo_o),
        .tdo_padoe_o(tdo_padoe_o),

        // Output from jtag_tap to test_interface, to allow monitoring of TAP states
        .shift_dr_o(shift_dr),
        .pause_dr_o(pause_dr),
        .update_dr_o(update_dr),
        .capture_dr_o(capture_dr),
        .test_logic_reset_o(test_logic_reset),

        // Select signals for boundary scan or mbist (outputs that tell what instruction is currently loaded)
        .extest_select_o(extest_select),
        .sample_preload_select_o(sample_preload_select),
        .mbist_select_o(mbist_select),
        .debug_select_o(debug_select),

        // TDO signal that is connected to TDI of sub-modules.
        .tdo_o(chip_tdi),

        // Input from test_interface to jtag_tap, to allow monitoring of TAP states
        .debug_tdi_i(tdi_debug),
        .bs_chain_tdi_i(tdi_bs),
        .mbist_tdi_i(tdi_mbist)    
    );

    jtag_test_if jtag_test_if_inst(
        // JTAG Pins
        .tck_i(tck_i),
        .test_logic_reset_i(test_logic_reset),

        // Output from jtag_tap to test_interface, to allow monitoring of TAP states
        .shift_dr_i(shift_dr),
        .pause_dr_i(pause_dr),
        .update_dr_i(update_dr),
        .capture_dr_i(capture_dr),

        // Select signals for boundary scan or mbist (outputs that tell what instruction is currently loaded)
        .extest_select_i(extest_select),
        .sample_preload_select_i(sample_preload_select),
        .mbist_select_i(mbist_select),
        .debug_select_i(debug_select),

        // TDI signal that is connected to TDI of sub-modules.
        .tdi_i(chip_tdi),

        // Input from test_interface to jtag_tap, to allow monitoring of TAP states
        .debug_tdi_o(tdi_debug),
        .bs_chain_tdi_o(tdi_bs),
        .mbist_tdi_o(tdi_mbist),

        // Boundary Scan Signals
        .bsr_i(bsr_i),
        .bsr_o(bsr_o),
        .bsr_oe(bsr_oe),

        // Debug Signals
        .dbg_i(dbg_i),
        .dbg_o(dbg_o)
    );
    
endmodule