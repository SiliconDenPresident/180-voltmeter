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

    // -- Validation Signals
    input wire [7:0] dbg_i,     // Debug input signals
    output wire [15:0] dbg_o    // Debug output signals
);
    //---------------------------------------------------------
    // Declarations
    //---------------------------------------------------------

    // Analog Parameters, Wires, & Registers

    // Digital Parameters, Wires, & Registers
    wire [15:0] counter_limit;  // Counter limit value from state machine
    wire [15:0] counter_count;  // Current counter value
    wire counter_en;           // Counter enable signal
    wire counter_clear;        // Counter clear signal
    wire counter_busy;         // Counter busy status
    wire counter_done;         // Counter done status
    wire done;                // State machine done signal
    wire range_error_o;       // Range error signal
    wire comp_o, sat_hi_o, sat_lo_o, ref_ok_o;  // Sanitized analog signals

    // SPI interface signals
    wire spi_di_req;          // SPI data input request
    wire [31:0] spi_data_in;  // SPI data to send to master
    wire spi_wr_ack;          // SPI write acknowledge
    wire [31:0] spi_data_out; // SPI received data
    wire spi_do_transfer;     // SPI data transfer flag
    wire spi_wren_dbg;        // SPI write enable debug
    wire spi_rx_bit_next;     // SPI next bit to receive
    wire [3:0] spi_state_dbg; // SPI state machine debug
    wire [31:0] spi_sh_reg_dbg; // SPI shift register debug

    //---------------------------------------------------------
    // Instantiations
    //---------------------------------------------------------

    // Analog 
    analog_sanitizer analog_sanitizer_inst (
        .clk_i(clk_i),
        .rst_i(rst_n_i),
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
        .rst_i(rst_n_i),
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
        .rst_i(rst_n_i),
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
        .o_RX_DV(spi_di_req),
        .o_RX_Byte(spi_data_in),
        .i_TX_DV(done),
        .i_TX_Byte(spi_data_out),
        .i_SPI_Clk(spi_sclk_i),
        .o_SPI_MISO(spi_miso_o),
        .i_SPI_MOSI(spi_mosi_i),
        .i_SPI_CS_n(spi_cs_i)
    );

    //---------------------------------------------------------
    // Assignments
    //---------------------------------------------------------

    // TODO: Add logic to handle spi_data_in and spi_data_out based on your protocol
    // For now, we'll set some default values
    assign spi_data_in = 32'h0;  // Data to send to master
    assign spi_wren = 1'b0;      // Write enable (can be controlled by your logic)

    // Debug output - you can modify this based on what you want to observe
    assign dbg_o = {spi_state_dbg, 12'h0};

endmodule