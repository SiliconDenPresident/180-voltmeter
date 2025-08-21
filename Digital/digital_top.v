/*
--------------------------------------------------------------------------------
 Title        : digital_top
 Project      : 180-voltmeter
 File         : digital_top.v
 Description  : Top-level digital control module that orchestrates the voltmeter
                system. Integrates analog signal sanitization, SPI slave interface,
                and provides control signals to the analog front-end. Handles
                communication with external SPI master and manages analog control
                outputs for measurement operations.
 
 Author       : Tristan Wood tdwood2@ncsu.edu
 Created      : 2025-08-13
 License      : See LICENSE in the project root

 Revision History:
   - 0.1 2025-08-13 Tristan Wood Initial implementation with analog sanitizer and SPI slave
--------------------------------------------------------------------------------
*/

module digital_top (
    // Analog Signals
    input wire comp_i,
    input wire sat_hi_i,
    input wire sat_lo_i,
    input wire ref_ok_i,

    // Digital Signals
    input wire clk_i,
    input wire rst_n_i,

    // -- State Machine Signals
    input wire [1:0] mode_sel_i,
    output wire [1:0] afe_sel_o,
    output wire [2:0] range_sel_o,
    output wire afe_reset_o,
    output wire ref_sign_o,

    // -- SPI Signals
    input wire spi_sclk_i,
    input wire spi_cs_i,
    input wire spi_mosi_i,
    output wire spi_miso_o,
    output wire interrupt_o,

    // -- Debug Interface Signals
    input wire [31:0] dbg_ctrl_i,     // Debug control input signals
    output wire [31:0] dbg_status_o    // Debug status output signals
);
    //---------------------------------------------------------
    // Declarations
    //---------------------------------------------------------

    wire [15:0] counter_limit;  // Counter limit value from state machine
    wire [15:0] counter_count;  // Current counter value
    wire counter_en;           // Counter enable signal
    wire counter_clear;        // Counter clear signal
    wire counter_busy;         // Counter busy status
    wire counter_done;         // Counter done status
    wire done;                // State machine done signal
    wire range_error_o;       // Range error signal
    wire comp_o, sat_hi_o, sat_lo_o, ref_ok_o;  // Sanitized analog signals
 
    wire [31:0] tx_data_in;
    wire [31:0] tx_data_out;

    //---------------------------------------------------------
    // Instantiations
    //---------------------------------------------------------

    // Analog 
    analog_sanitizer analog_sanitizer_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .comp_i(comp_i),
        .sat_hi_i(sat_hi_i),
        .sat_lo_i(sat_lo_i),
        .ref_ok_i(ref_ok_i),
        .comp_o(comp_o),
        .sat_hi_o(sat_hi_o),
        .sat_lo_o(sat_lo_o),
        .ref_ok_o(ref_ok_o)
    );

    // State Machine
    state_machine state_machine_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .comp_i(comp_o),
        .sat_hi_i(sat_hi_o),
        .sat_lo_i(sat_lo_o),
        .ref_ok_i(ref_ok_o),
        .afe_sel_o(afe_sel_o),
        .range_sel_o(range_sel_o),
        .afe_reset_o(afe_reset_o),
        .ref_sign_o(ref_sign_o),
        .range_error_o(range_error_o),
        .done_o(done),
        .counter_done_i(counter_done),
        .counter_busy_i(counter_busy),
        .counter_clear_o(counter_clear),
        .counter_en_o(counter_en),
        .counter_limit_o(counter_limit)
    );

    // Counter
    counter counter_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(counter_en),
        .clear_i(counter_clear),
        .limit_i(counter_limit),
        .busy_o(counter_busy),
        .done_o(counter_done),
        .count_o(counter_count)
    );

    // SPI slave instance
    spi_slave #(
        .SPI_MODE(0)
    ) spi_slave_inst (
        .i_Rst_L(rst_n_i),
        .i_Clk(clk_i),
        .o_RX_DV(interrupt_o),
        .o_RX_Byte(tx_data_in),
        .i_TX_DV(done),
        .i_TX_Byte(tx_data_out),
        .i_SPI_Clk(spi_sclk_i),
        .o_SPI_MISO(spi_miso_o),
        .i_SPI_MOSI(spi_mosi_i),
        .i_SPI_CS_n(spi_cs_i)
    );

    //---------------------------------------------------------
    // Assignments
    //---------------------------------------------------------

    // Debug Status Register
    assign tx_data_out[15:0] = counter_count;
    assign tx_data_out[16] = comp_o;
    assign tx_data_out[17] = sat_hi_o;
    assign tx_data_out[18] = sat_lo_o;
    assign tx_data_out[19] = ref_ok_o;
    assign tx_data_out[21:20] = afe_sel_o;
    assign tx_data_out[24:22] = range_sel_o;
    assign tx_data_out[25] = afe_reset_o;
    assign tx_data_out[26] = ref_sign_o;
    assign tx_data_out[27] = range_error_o;
    assign tx_data_out[28] = done;
    assign tx_data_out[29] = counter_done;
    assign tx_data_out[30] = counter_en;
    assign tx_data_out[31] = counter_clear;

    assign dbg_status_o[15:0] = (tx_data_in[31] || dbg_ctrl_i[31]) ? tx_data_in[15:0] : counter_count;
    assign dbg_status_o[16] = (tx_data_in[31] || dbg_ctrl_i[31]) ? tx_data_in[16] : comp_o;
    assign dbg_status_o[17] = (tx_data_in[31] || dbg_ctrl_i[31]) ? tx_data_in[17] : sat_hi_o;
    assign dbg_status_o[18] = (tx_data_in[31] || dbg_ctrl_i[31]) ? tx_data_in[18] : sat_lo_o;
    assign dbg_status_o[19] = (tx_data_in[31] || dbg_ctrl_i[31]) ? tx_data_in[19] : ref_ok_o;
    assign dbg_status_o[21:20] = (tx_data_in[31] || dbg_ctrl_i[31]) ? tx_data_in[21:20] : afe_sel_o;
    assign dbg_status_o[24:22] = (tx_data_in[31] || dbg_ctrl_i[31]) ? tx_data_in[24:22] : range_sel_o;
    assign dbg_status_o[25] = (tx_data_in[31] || dbg_ctrl_i[31]) ? tx_data_in[25] : afe_reset_o;
    assign dbg_status_o[26] = (tx_data_in[31] || dbg_ctrl_i[31]) ? tx_data_in[26] : ref_sign_o;
    assign dbg_status_o[27] = (tx_data_in[31] || dbg_ctrl_i[31]) ? tx_data_in[27] : range_error_o;
    assign dbg_status_o[28] = (tx_data_in[31] || dbg_ctrl_i[31]) ? tx_data_in[28] : done;
    assign dbg_status_o[29] = (tx_data_in[31] || dbg_ctrl_i[31]) ? tx_data_in[29] : counter_done;
    assign dbg_status_o[30] = (tx_data_in[31] || dbg_ctrl_i[31]) ? tx_data_in[30] : counter_en;
    assign dbg_status_o[31] = tx_data_in[31];

endmodule