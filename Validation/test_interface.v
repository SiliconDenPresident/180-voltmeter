// -----------------------------------------------------------------------------
// Digital Test Interface between WISP and JTAG TAP
// -----------------------------------------------------------------------------
//
// This module provides a JTAG-accessible test interface for the digital core.
// It allows configuration and observation of internal signals via a JTAG TAP.
// The interface includes a configuration register (TCR) that controls muxes
// and debug paths, and a shift register for JTAG data movement. The TCR is
// only updated on JTAG UPDATE_DR, so muxes are stable during shifting.
//
// At this point this *assumes* that the WISP will have some sort of resistive
// pullup connected to the master JTAG trst (reset pin) which is active high.
// If the WISP sees that the trst has been pulled low it will use the tr_ctrl
// pins of the test_interface to determine how to handle clocking and routing
// of the data to and from the testregister.
// -----------------------------------------------------------------------------

`timescale 1ns/10ps

`define JTAGOFF        32'd0
`define SOURCEDEMOD    5'b10001
`define SINKDEMOD      5'b10100
`define SOURCEMODOUT   5'b10010
`define SINKMODOUT     5'b11000

module jtag_test_if #(
    parameter CONRLEN = 32,      // JTAG configuration register length
    parameter TRCAL_SIZE = 128    // JTAG shift register size
) (
    // -------------------------------------------------------------------------
    // JTAG Interface Ports
    // -------------------------------------------------------------------------
    input  wire tclk,                // JTAG test clock
    input  wire test_logic_reset_i,   // JTAG test reset pad

    // TAP state monitor inputs
    input  wire shift_dr_i,
    input  wire pause_dr_i,
    input  wire update_dr_i,
    input  wire capture_dr_i,

    // JTAG chain outputs
    output wire debug_tdi_o,          // Debug chain
    output reg  bs_chain_tdi_o,       // Boundary scan chain
    output wire mbist_tdi_o,          // MBIST chain

    input  wire chiptdi,              // The tap's tdo_o pin (connects to tdi_pad_i)
    output wire tdo2,                 // Secondary TDO (for test/debug)

    // -------------------------------------------------------------------------
    // Encoder/Decoder Interface Ports
    // -------------------------------------------------------------------------
    input  wire txbitout_in,          // Input from encoder
    output wire txbitout_out,         // Muxed output to Analog Modulator
    input  wire txbitouten_in,        // Input from encoder
    output wire txbitouten_out,       // Muxed output to Analog Modulator

    // -------------------------------------------------------------------------
    // JTAG Instruction Select
    // -------------------------------------------------------------------------
    input  wire sample_preload_sel,   // SAMPLE_PRELOAD instruction select
    input  wire extest_sel,           // EXTEST instruction select
    input  wire debug_sel,            // DEBUG instruction select
    input  wire mbist_sel,            // MBIST instruction select

    // -------------------------------------------------------------------------
    // Control Register and Test Data Ports
    // -------------------------------------------------------------------------
    output wire [CONRLEN-1:0] tcr_out,        // Output of the test control register
    input  wire chipreset,                    // Chip-level reset signal for config reg
    input  wire [TRCAL_SIZE-1:0] trcal_tr_in, // Input for trcal shift register
    output reg  [TRCAL_SIZE-1:0] trcal_tr_out,// Output for trcal shift register
    input  wire NFC_demod_in,                 // Input from analog receiver
    output wire used_demodin                  // Muxed output to decoder
);

// -----------------------------------------------------------------------------
// Internal Registers
// -----------------------------------------------------------------------------
reg [CONRLEN-1:0] tcr;        // Latched config register (used for muxes)
reg [CONRLEN-1:0] tcr_shift;  // Shift register (for JTAG shifting)

// -----------------------------------------------------------------------------
// Mux Logic (TCR controls muxes)
// -----------------------------------------------------------------------------
// The following assignments allow the TCR to select any combination of values
// from the muxes. Only the latched TCR register is used for mux selection, so
// shifting does not cause glitches.

// If enabled, drive the source from external TDI; otherwise, use NFC_demod_in.
assign used_demodin = ((tcr[4] && tcr[0]) == 1'b1) ? chiptdi : NFC_demod_in;

// If enabled, drive chiptdi to analog mod (digital output); otherwise, use txbitout_in.
assign txbitout_out = ((tcr[4] && tcr[1]) == 1'b1) ? chiptdi : txbitout_in;

// If enabled, drive output enable high; otherwise, use txbitouten_in.
//sinkmodout 
assign txbitouten_out = ((tcr[4] && tcr[3]) == 1'b1) ? 1'b1 : txbitouten_in;

// Secondary TDO for test/debug.
assign tdo2 = txbitout_out;

// If enabled, drive used_demodin (decoder input) to debug_tdi_o; otherwise, 0.
//sinkdemod
assign debug_tdi_o = ((tcr[4] && tcr[2]) == 1'b1) ? used_demodin : 1'b0;
//assign debug_tdi_o = ((tcr[CONRLEN-10] && tcr[2]) == 1'b1) ? used_demodin : encoded_bit_o_analog;

// Boundary scan and MBIST TDI outputs are currently unused, so just set them to 0.
assign mbist_tdi_o = 1'b0;
// assign bs_chain_tdi_o = trcal_tr_out[0];

// -----------------------------------------------------------------------------
// JTAG Shift Register for trcal (EXTEST)
// -----------------------------------------------------------------------------
// Handles shifting for the EXTEST instruction. Registers shifting IN are clocked
// on the POSEDGE. Registers shifting OUT are clocked on the NEGEDGE.

always @(posedge tclk or posedge test_logic_reset_i) begin
    if (test_logic_reset_i) begin
        trcal_tr_out <= #1 {TRCAL_SIZE{1'b0}}; // Default state. If JTAG is not powered, use PU/PD resistors at mux for default state.
        // trcal_tr_out <= #1 ~tcr;
    end else begin
        // EXTEST CAPTURE/UPDATE EXAMPLE
        if (extest_sel & shift_dr_i) begin
            trcal_tr_out[TRCAL_SIZE-1] <= chiptdi;
            trcal_tr_out[TRCAL_SIZE-2:0] <= trcal_tr_out[TRCAL_SIZE-1:1];
        end
        if (extest_sel & capture_dr_i) begin
            trcal_tr_out <= #1 trcal_tr_in; // Read out the current state to be shifted to the JTAG
        end
    end
end

always @(negedge tclk or posedge test_logic_reset_i) begin
    if (test_logic_reset_i) begin
        bs_chain_tdi_o <= #1 1'b0;
    end else if (extest_sel) begin
        bs_chain_tdi_o <= #1 trcal_tr_out[0];
    end else if (sample_preload_sel) begin
        bs_chain_tdi_o <= #1 tcr_shift[0];
    end
end

// -----------------------------------------------------------------------------
// TCR Shift/Capture/Update Logic (SAMPLE_PRELOAD)
// -----------------------------------------------------------------------------
// Handles JTAG shifting, capture, and update for the TCR. Only updates tcr
// (the latched config) on UPDATE_DR. Registers shifting IN are clocked on the POSEDGE.

always @(posedge tclk or posedge test_logic_reset_i) begin
    if (test_logic_reset_i) begin
        tcr <= #1 {CONRLEN{1'b0}}; // Default state. If JTAG is not powered, use PU/PD resistors at mux for default state.
        ///tcr_shift <= #1 ~tcr;
        tcr_shift <= #1 {CONRLEN{1'b1}};
    end else begin
        // SAMPLE PRELOAD CAPTURE/UPDATE EXAMPLE
        if (sample_preload_sel & shift_dr_i) begin
            tcr_shift[CONRLEN-1] <= #1 chiptdi;
            tcr_shift[CONRLEN-2:0] <= #1 tcr_shift[CONRLEN-1:1];
        end
        if (sample_preload_sel & capture_dr_i) begin
            tcr_shift <= #1 tcr; // Read out the current state to be shifted to the JTAG
        end
        if (sample_preload_sel & update_dr_i) begin
            // Only update tcr if MSB (bit 31) is set (write operation)
            // On read (MSB == 0), tcr is not updated and remains unchanged
            if (tcr_shift[CONRLEN-1])
                tcr <= #1 {1'b0, tcr_shift[CONRLEN-2:0]}; // Mask out MSB so it does not affect mux logic
            // else: do nothing (read operation)
        end
    end
end

assign tcr_out = tcr;

endmodule