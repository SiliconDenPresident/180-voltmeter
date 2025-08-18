// reference_filter.v  (Verilog-2001)
// Qualifies an async ref_ok-ish flag using a leaky up/down counter,
// adds guard (hold-off) after reconfig, edge pulses, and "low too long" flag.

module reference_filter #(
  parameter integer CTR_WIDTH     = 8,     // filter strength (counter bits)
  parameter integer RISE_THRESH   = 200,   // cycles high to assert OK
  parameter integer FALL_THRESH   = 20,    // cycles low  to drop OK
  parameter integer GUARD_TICKS   = 1000,  // hold-off after reconfig (clk cycles)
  parameter integer LOW_HOLD_TKS  = 5000   // consecutive low cycles => low_long_o
)(
  input  wire clk_i,
  input  wire rst_i,
  input  wire ref_raw_i,       // async-ish analog flag (1=good)
  input  wire guard_start_i,   // pulse on mode/range/trim change

  output wire ref_ok_o,        // qualified "reference OK"
  output reg  rise_pulse_o,    // 1 clk when ref_ok_o goes 0->1
  output reg  fall_pulse_o,    // 1 clk when ref_ok_o goes 1->0
  output wire guard_active_o,  // 1 while in hold-off window
  output wire low_long_o       // 1 when ref bad long enough
);

  // --------- utility: integer clog2 (Verilog-2001) ---------
  function integer CLOG2;
    input integer value;
    integer v, i;
    begin
      v = (value <= 1) ? 1 : value - 1;
      i = 0;
      while (v > 0) begin
        v = v >> 1;
        i = i + 1;
      end
      CLOG2 = (i == 0) ? 1 : i;
    end
  endfunction

  // Pre-sized constants for compares/loads
  localparam integer GCW = (GUARD_TICKS > 0) ? CLOG2(GUARD_TICKS+1) : 1;
  localparam integer LLW = (LOW_HOLD_TKS > 0) ? CLOG2(LOW_HOLD_TKS+1) : 1;
  localparam [GCW-1:0] GUARD_TICKS_P   = GUARD_TICKS[GCW-1:0];
  localparam [LLW-1:0] LOW_HOLD_TKS_P  = LOW_HOLD_TKS[LLW-1:0];

  // --------- 2-FF synchronizer for the async input ---------
  reg sync0, sync1;
  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      sync0 <= 1'b0;
      sync1 <= 1'b0;
    end else begin
      sync0 <= ref_raw_i;
      sync1 <= sync0;
    end
  end
  wire ref_sync = sync1;

  // --------- guard/hold-off timer after reconfig -----------
  reg [GCW-1:0] guard_q;
  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i)
      guard_q <= {GCW{1'b0}};
    else if (guard_start_i)
      guard_q <= GUARD_TICKS_P;
    else if (guard_q != {GCW{1'b0}})
      guard_q <= guard_q - {{GCW-1{1'b0}},1'b1};
  end
  wire guard_active_w = (guard_q != {GCW{1'b0}});
  assign guard_active_o = guard_active_w;

  // --------- leaky up/down counter (debounce / filter) -----
  reg [CTR_WIDTH-1:0] acc_q;
  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i)
      acc_q <= {CTR_WIDTH{1'b0}};
    else if (guard_active_w)
      acc_q <= {CTR_WIDTH{1'b0}};
    else if (ref_sync && acc_q != {CTR_WIDTH{1'b1}})
      acc_q <= acc_q + {{CTR_WIDTH-1{1'b0}},1'b1};
    else if (!ref_sync && acc_q != {CTR_WIDTH{1'b0}})
      acc_q <= acc_q - {{CTR_WIDTH-1{1'b0}},1'b1};
  end

  // --------- hysteresis + edge pulses ----------------------
  reg ref_ok_q;
  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      ref_ok_q      <= 1'b0;
      rise_pulse_o  <= 1'b0;
      fall_pulse_o  <= 1'b0;
    end else begin
      // default: no pulse
      rise_pulse_o  <= 1'b0;
      fall_pulse_o  <= 1'b0;

      // assert when accumulator reaches RISE threshold
      if (!ref_ok_q && (acc_q >= RISE_THRESH[CTR_WIDTH-1:0])) begin
        ref_ok_q     <= 1'b1;
        rise_pulse_o <= 1'b1;
      end
      // deassert when it falls to FALL threshold
      else if (ref_ok_q && (acc_q <= FALL_THRESH[CTR_WIDTH-1:0])) begin
        ref_ok_q     <= 1'b0;
        fall_pulse_o <= 1'b1;
      end
    end
  end

  // Mask OK with guard window
  assign ref_ok_o = ref_ok_q & ~guard_active_w;

  // --------- low-long detector -----------------------------
  reg [LLW-1:0] low_q;
  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i)
      low_q <= {LLW{1'b0}};
    else if (ref_ok_o)
      low_q <= {LLW{1'b0}};
    else if (low_q != LOW_HOLD_TKS_P)
      low_q <= low_q + {{LLW-1{1'b0}},1'b1};
  end
  assign low_long_o = (low_q == LOW_HOLD_TKS_P);

endmodule
