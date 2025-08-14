module test_if (
    input wire tck_i,
    input wire test_logic_reset_i,

    input wire shift_dr_i,
    input wire pause_dr_i,
    input wire update_dr_i,
    input wire capture_dr_i,

    input wire extest_select_i,
    input wire sample_preload_select_i,
    input wire mbist_select_i,
    input wire debug_select_i,

    input wire tdi_i,

    output wire debug_tdi_o,
    output wire bs_chain_tdi_o,
    output wire mbist_tdi_o,

    input wire [32:0] bsr_i,
    output wire [14:0] bsr_o,
    output wire [14:0] bsr_oe
);
// MBIST Parameters, Wires, & Registers

// EXTEST & SAMPLE_PRELOAD Parameters, Wires, & Registers
// Chain order (LSB-first): [OE | OUT | IN]
localparam int BSR_LEN = 64;  // MSB is a r/w bit for sample_preload/extest
localparam int OE_LEN  = 15;  // GPIO only
localparam int OUT_LEN = 15;  // GPIO only
localparam int IN_LEN  = 33;  // 15 GPIO + 18 DIN

localparam int SLICE_IN_LO   = 0;
localparam int SLICE_IN_HI   = IN_LEN-1;
localparam int SLICE_OUT_LO  = IN_LEN;
localparam int SLICE_OUT_HI  = IN_LEN + OUT_LEN - 1;
localparam int SLICE_OE_LO   = IN_LEN + OUT_LEN;
localparam int SLICE_OE_HI   = IN_LEN + OUT_LEN + OE_LEN - 1;

reg [BSR_LEN-1:0] bsr_shift;
reg [OUT_LEN-1:0] bsr_preload_o, bsr_extest_o;
reg [OE_LEN-1:0] bsr_preload_oe, bsr_extest_oe;

// DEBUG Parameters, Wires, & Registers

//------------ MBIST --------------
// Built-in Self-Test (BIST), which is used to test SRAM/ROMs/Registers, is not implemented

//------------ SAMPLE_PRELOAD --------------
// Is used to update the Boundary Scan Register (BSR) without affecting the pad pins.

always @(posedge tck_i or posedge test_logic_reset_i) begin
  if (test_logic_reset_i) begin
    bsr_preload_o <= 0;
    bsr_preload_oe <= 0;
  end else begin
    if (capture_dr_i && sample_preload_select_i) begin
      bsr_shift[SLICE_IN_HI:SLICE_IN_LO] <= bsr_i;
      bsr_shift[SLICE_OUT_HI:SLICE_OUT_LO] <= bsr_preload_o;
      bsr_shift[SLICE_OE_HI:SLICE_OE_LO] <= bsr_preload_oe;
      bsr_shift[BSR_LEN-1] <= 1'b0;
    end
    if (shift_dr_i && sample_preload_select_i) begin
      bsr_shift <= {tdi_i, bsr_shift[BSR_LEN-1:1]};
    end
    if (update_dr_i && sample_preload_select_i) begin
      if(bsr_shift[BSR_LEN-1]) begin
        bsr_preload_o <= bsr_shift[SLICE_OUT_HI:SLICE_OUT_LO];
        bsr_preload_oe <= bsr_shift[SLICE_OE_HI:SLICE_OE_LO];
      end
    end
  end
end

//------------ EXTEST --------------
always @(posedge tck_i or posedge test_logic_reset_i) begin
  if (test_logic_reset_i) begin
    bsr_extest_o <= 0;
    bsr_extest_oe <= 0;
  end else begin
    if (capture_dr_i && extest_select_i) begin
      bsr_shift[SLICE_IN_HI:SLICE_IN_LO] <= bsr_i;
      bsr_shift[SLICE_OUT_HI:SLICE_OUT_LO] <= bsr_preload_o;
      bsr_shift[SLICE_OE_HI:SLICE_OE_LO] <= bsr_preload_oe;
      bsr_shift[BSR_LEN-1] <= 1'b0;
    end
    if (shift_dr_i && extest_select_i) begin
      bsr_shift <= {tdi_i, bsr_shift[BSR_LEN-1:1]};
    end
    if (update_dr_i && extest_select_i) begin
      if(bsr_shift[BSR_LEN-1]) begin
        bsr_extest_o <= bsr_shift[SLICE_OUT_HI:SLICE_OUT_LO];
        bsr_extest_oe <= bsr_shift[SLICE_OE_HI:SLICE_OE_LO];
      end
    end
  end
end

assign bs_chain_tdi_o = (sample_preload_select_i | extest_select_i) ? bsr_shift[0] : 1'b0;
assign bsr_o = bsr_extest_o;
assign bsr_oe = bsr_extest_oe;

// ----------------- DEBUG -----------------


//cmp 
//wire [3:0] testmux_sel; 
//wire [6:0] cmp_trim;    // comparator offset trim code (mid-code≈zero); set via JTAG/CSR, static during runs

endmodule