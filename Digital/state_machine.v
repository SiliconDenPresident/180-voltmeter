// Measurement state machine for the digital voltmeter
// Orchestrates analog control sequencing (autozero, integrate, deintegrate)
// using comparator and saturation feedback. Produces a time/count result.

module state_machine #(
    parameter integer AFE_SEL_WIDTH          = 2,
    parameter integer RANGE_SEL_WIDTH        = 2,
    parameter integer CMP_TRIM_WIDTH         = 4,
    parameter integer TESTMUX_WIDTH          = 4,

    // Timing parameters in clock cycles (placeholder defaults)
    parameter integer AZ_TICKS               = 1000,
    parameter integer INTEGRATE_TICKS        = 100000,
    parameter integer DEINTEGRATE_TIMEOUT    = 200000
) (
    input  wire                        clk_i,
    input  wire                        rst_i,

    // Analog status
    input  wire                        comp_i,
    input  wire                        sat_hi_i,
    input  wire                        sat_lo_i,
    input  wire                        ref_ok_i,

    // Optional start (if 1, run continuously)
    input  wire                        start_i,

    // Control to analog
    output reg  [AFE_SEL_WIDTH-1:0]    afe_sel_o,
    output reg  [RANGE_SEL_WIDTH-1:0]  range_sel_o,
    output reg                         afe_reset_o,
    output reg                         ref_sign_o,
    output reg                         itest_en_o,
    output reg                         ishunt_en_o,
    output reg  [CMP_TRIM_WIDTH-1:0]   cmp_trim_o,
    output reg  [TESTMUX_WIDTH-1:0]    testmux_sel_o,

    // Result/status
    output reg                         busy_o,
    output reg                         data_ready_o,
    output reg                         error_o,
    output reg  [31:0]                 result_count_o
);

    // State encoding
    localparam [2:0] S_RESET    = 3'd0;
    localparam [2:0] S_WAIT_REF = 3'd1;
    localparam [2:0] S_AZ       = 3'd2;
    localparam [2:0] S_INT      = 3'd3;
    localparam [2:0] S_DEINT    = 3'd4;
    localparam [2:0] S_DONE     = 3'd5;
    localparam [2:0] S_ERROR    = 3'd6;

    reg [2:0] state_q;
    reg [2:0] state_d;

    reg [31:0] tick_cnt_q;
    reg [31:0] tick_cnt_d;

    reg        comp_at_deint_start_q;
    reg        comp_at_deint_start_d;

    // Default/control outputs
    always @(*) begin
        // Hold previous values by default
        state_d                 = state_q;
        tick_cnt_d              = tick_cnt_q;
        comp_at_deint_start_d   = comp_at_deint_start_q;

        // Defaults for outputs
        afe_sel_o               = {AFE_SEL_WIDTH{1'b0}}; // 0: AZ, 1: INT, 2: DEINT (convention)
        range_sel_o             = {RANGE_SEL_WIDTH{1'b0}};
        afe_reset_o             = 1'b0;
        ref_sign_o              = 1'b0;
        itest_en_o              = 1'b0;
        ishunt_en_o             = 1'b0;
        cmp_trim_o              = {CMP_TRIM_WIDTH{1'b0}};
        testmux_sel_o           = {TESTMUX_WIDTH{1'b0}};

        busy_o                  = 1'b0;
        data_ready_o            = 1'b0;
        error_o                 = 1'b0;

        case (state_q)
            S_RESET: begin
                afe_reset_o = 1'b1;
                if (ref_ok_i) begin
                    state_d   = S_AZ;
                    tick_cnt_d= 32'd0;
                end else begin
                    state_d   = S_WAIT_REF;
                end
            end

            S_WAIT_REF: begin
                afe_reset_o = 1'b1;
                if (ref_ok_i) begin
                    state_d   = S_AZ;
                    tick_cnt_d= 32'd0;
                end
            end

            S_AZ: begin
                busy_o     = 1'b1;
                afe_sel_o  = {{(AFE_SEL_WIDTH-1){1'b0}}, 1'b0}; // 0: AZ
                if (tick_cnt_q >= AZ_TICKS) begin
                    state_d    = S_INT;
                    tick_cnt_d = 32'd0;
                end else begin
                    tick_cnt_d = tick_cnt_q + 32'd1;
                end
            end

            S_INT: begin
                busy_o     = 1'b1;
                afe_sel_o  = {{(AFE_SEL_WIDTH-1){1'b0}}, 1'b1}; // 1: INT
                if (sat_hi_i | sat_lo_i) begin
                    state_d    = S_ERROR;
                end else if (tick_cnt_q >= INTEGRATE_TICKS) begin
                    state_d                 = S_DEINT;
                    tick_cnt_d              = 32'd0;
                    comp_at_deint_start_d   = comp_i;
                end else begin
                    tick_cnt_d = tick_cnt_q + 32'd1;
                end
            end

            S_DEINT: begin
                busy_o     = 1'b1;
                afe_sel_o  = {{(AFE_SEL_WIDTH-2){1'b0}}, 2'b10}; // 2: DEINT (if width>=2)
                // Choose reference polarity to drive integrator toward zero
                ref_sign_o = comp_at_deint_start_q; // simple heuristic

                if (sat_hi_i | sat_lo_i) begin
                    state_d = S_ERROR;
                end else if (comp_i != comp_at_deint_start_q) begin
                    // Zero crossing detected
                    result_count_o = tick_cnt_q;
                    state_d        = S_DONE;
                end else if (tick_cnt_q >= DEINTEGRATE_TIMEOUT) begin
                    state_d = S_ERROR;
                end else begin
                    tick_cnt_d = tick_cnt_q + 32'd1;
                end
            end

            S_DONE: begin
                data_ready_o = 1'b1;
                if (start_i) begin
                    state_d    = S_AZ;
                    tick_cnt_d = 32'd0;
                end else begin
                    state_d    = S_WAIT_REF;
                end
            end

            default: begin // S_ERROR
                error_o   = 1'b1;
                if (!sat_hi_i && !sat_lo_i && ref_ok_i && start_i) begin
                    state_d    = S_AZ;
                    tick_cnt_d = 32'd0;
                end
            end
        endcase
    end

    // State registers
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            state_q               <= S_RESET;
            tick_cnt_q            <= 32'd0;
            comp_at_deint_start_q <= 1'b0;
            result_count_o        <= 32'd0;
        end else begin
            state_q               <= state_d;
            tick_cnt_q            <= tick_cnt_d;
            comp_at_deint_start_q <= comp_at_deint_start_d;
            // result_count_o updated in S_DEINT to capture count; hold otherwise
        end
    end

endmodule
