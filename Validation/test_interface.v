module jtag_test_if (
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
    output wire [14:0] bsr_oe,

    input wire [DBG_STATUS_LEN-1:0] dbg_i,
    output wire [DBG_CONTROL_LEN-1:0] dbg_o
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
reg extest_select_prev;

// DEBUG Parameters, Wires, & Registers
localparam int DBG_LEN = 25; // msb is for r/w 
localparam int DBG_CONTROL_LEN = 8;
localparam int DBG_STATUS_LEN = 16;

reg [DBG_LEN-1:0] dbg_shift;
reg [DBG_CONTROL_LEN-1:0] dbg_control;

//------------ MBIST --------------
// Built-in Self-Test (BIST), which is used to test SRAM/ROMs/Registers, is not implemented

assign mbist_tdi_o = 1'b0;

//------------ SAMPLE_PRELOAD --------------
// It is used to update the Output portions of the BSR without affecting the pad pins.

always@(posedge tck_i or posedge test_logic_reset_i) begin
  if(test_logic_reset_i) begin
    bsr_preload_o <= 0;
    bsr_preload_oe <= 0;
    bsr_shift <= 0;
  end else begin
    if(sample_preload_select_i) begin
      if(capture_dr_i) begin
        bsr_shift[SLICE_IN_HI:SLICE_IN_LO] <= bsr_i;
        bsr_shift[SLICE_OUT_HI:SLICE_OUT_LO] <= bsr_preload_o;
        bsr_shift[SLICE_OE_HI:SLICE_OE_LO] <= bsr_preload_oe;
        bsr_shift[BSR_LEN-1] <= 1'b0;
      end
      if(shift_dr_i) begin
        bsr_shift <= {tdi_i, bsr_shift[BSR_LEN-1:1]};
      end
      if(update_dr_i) begin
        if(bsr_shift[BSR_LEN-1]) begin
          bsr_preload_o <= bsr_shift[SLICE_OUT_HI:SLICE_OUT_LO];
          bsr_preload_oe <= bsr_shift[SLICE_OE_HI:SLICE_OE_LO];
        end
      end
    end
  end
end

//------------ EXTEST --------------
// It is used to update the output portions of the Boundary Scan Register (BSR) with the values 
// from sample_preload first and then future extest values

always@(posedge tck_i or posedge test_logic_reset_i) begin
  if(test_logic_reset_i) begin
    bsr_extest_o <= 0;
    bsr_extest_oe <= 0;
    extest_select_prev <= 0;
  end else begin
    extest_select_prev <= extest_select_i;
    if(extest_select_i) begin
      if(!extest_select_prev)begin
        bsr_extest_o <= bsr_preload_o;
        bsr_extest_oe <= bsr_preload_oe;
      end
      if(capture_dr_i) begin
        bsr_shift[SLICE_IN_HI:SLICE_IN_LO] <= bsr_i;
        bsr_shift[SLICE_OUT_HI:SLICE_OUT_LO] <= bsr_extest_o;
        bsr_shift[SLICE_OE_HI:SLICE_OE_LO] <= bsr_extest_oe;
        bsr_shift[BSR_LEN-1] <= 1'b0;
      end
      if(shift_dr_i) begin
        bsr_shift <= {tdi_i, bsr_shift[BSR_LEN-1:1]};
      end
      if(update_dr_i) begin
        if(bsr_shift[BSR_LEN-1]) begin
          bsr_extest_o <= bsr_shift[SLICE_OUT_HI:SLICE_OUT_LO];
          bsr_extest_oe <= bsr_shift[SLICE_OE_HI:SLICE_OE_LO];
        end
      end
    end
  end
end

assign bs_chain_tdi_o = (sample_preload_select_i | extest_select_i) ? bsr_shift[0] : 1'b0;
assign bsr_o = bsr_extest_o;
assign bsr_oe = bsr_extest_oe;

// ----------------- DEBUG -----------------
// This is used to control and monitor the design through debug signals

always @(posedge tck_i or posedge test_logic_reset_i) begin
  if(test_logic_reset_i) begin
    dbg_control <= 0;
    dbg_shift <= 0;
  end else begin
    if(debug_select_i) begin
      if(capture_dr_i) begin
        dbg_shift[DBG_CONTROL_LEN-1:0] <= dbg_control;
        dbg_shift[DBG_CONTROL_LEN+DBG_STATUS_LEN-1:DBG_CONTROL_LEN] <= dbg_i;
        dbg_shift[DBG_LEN-1] <= 1'b0;
      end
      if(shift_dr_i) begin
        dbg_shift <= {tdi_i, dbg_shift[DBG_LEN-1:1]};
      end
      if(update_dr_i) begin
        if(dbg_shift[DBG_LEN-1]) begin
          dbg_control <= dbg_shift[DBG_CONTROL_LEN-1:0];
        end
      end
    end
  end
end

assign debug_tdi_o = debug_select_i ? dbg_shift[0] : 1'b0;
assign dbg_o = dbg_control;
endmodule