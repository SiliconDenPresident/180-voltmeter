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
    input wire clk_i,
    input wire rst_i,

    // Analog status in
    input wire comp_i,
    input wire sat_hi_i,
    input wire sat_lo_i,
    input wire ref_ok_i,

    // SPI Signals
    input wire spi_sclk_i,
    input wire spi_cs_i,
    input wire spi_mosi_i,
    output wire spi_miso_o,
    output wire data_valid_o,

    // Analog control out
    output wire [1:0] afe_sel_o,
    output wire [2:0] range_sel_o,
    output wire afe_reset_o,
    output wire ref_sign_o,

    output wire [15:0] dbg_o
);

    // Analog sanitizer instance
    analog_sanitizer analog_sanitizer_inst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .comp_i(comp_i),
        .sat_hi_i(sat_hi_i),
        .sat_lo_i(sat_lo_i),
        .ref_ok_i(ref_ok_i),
        .comp_o(comp_o),
        .sat_hi_o(sat_hi_o),
        .sat_lo_o(sat_lo_o),
        .ref_ok_o(ref_ok_o)
    );

    // Internal signals for SPI slave interface
    wire [31:0] spi_data_in;   // Data to send to master
    wire [31:0] spi_data_out;  // Data received from master
    wire spi_di_req;           // Data input request
    wire spi_wren;             // Write enable
    wire spi_wr_ack;           // Write acknowledge
    wire spi_do_valid;         // Data output valid
    
    // Debug signals from SPI slave
    wire spi_do_transfer;
    wire spi_wren_dbg;
    wire spi_rx_bit_next;
    wire [3:0] spi_state_dbg;
    wire [31:0] spi_sh_reg_dbg;

    // SPI slave instance
    spi_slave #(
        .N(32),               // 32-bit data width
        .CPOL(1'b0),          // Clock polarity 0
        .CPHA(1'b0),          // Clock phase 0
        .PREFETCH(3)          // 3 cycle prefetch
    ) spi_slave_inst (
        .clk_i(clk_i),        // System clock
        .spi_ssel_i(spi_cs_i),    // Chip select (active low)
        .spi_sck_i(spi_sclk_i),   // SPI clock
        .spi_mosi_i(spi_mosi_i),  // Master out, slave in
        .spi_miso_o(spi_miso_o),  // Master in, slave out
        
        // Parallel data interface
        .di_req_o(spi_di_req),    // Data input request
        .di_i(spi_data_in),       // Data to send to master
        .wren_i(spi_wren),        // Write enable
        .wr_ack_o(spi_wr_ack),    // Write acknowledge
        .do_valid_o(spi_do_valid), // Data output valid
        .do_o(spi_data_out),      // Received data
        
        // Debug ports
        .do_transfer_o(spi_do_transfer),
        .wren_o(spi_wren_dbg),
        .rx_bit_next_o(spi_rx_bit_next),
        .state_dbg_o(spi_state_dbg),
        .sh_reg_dbg_o(spi_sh_reg_dbg)
    );

    // Connect data_valid_o to SPI slave's do_valid_o
    assign data_valid_o = spi_do_valid;

    // TODO: Add logic to handle spi_data_in and spi_data_out based on your protocol
    // For now, we'll set some default values
    assign spi_data_in = 32'h0;  // Data to send to master
    assign spi_wren = 1'b0;      // Write enable (can be controlled by your logic)

    // Debug output - you can modify this based on what you want to observe
    assign dbg_o = {spi_state_dbg, 12'h0};

endmodule