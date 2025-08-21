/*module************************************
*
* NAME:  counter
*
* DESCRIPTION:
*  downcounter with zero flag and synchronous clear
*
* NOTES:
*
* REVISION HISTORY
*    Date     Programmer    Description
*    7/10/97  P. Franzon    ece520-specific version
*
*M*/

/*======Declarations===============================*/

module counter (clock, reset, in, latch, dec,  zero);


/*-----------Inputs--------------------------------*/

input       clock;  /* clock */
input       reset;  /* reset input */
input [3:0] in;  /* input initial count */
input       latch;  /* `latch input' */
input       dec;   /* decrement */

/*-----------Outputs--------------------------------*/

output      zero;  /* zero flag */

/*----------------Nets and Registers----------------*/
/*---(See input and output for unexplained variables)---*/

reg [3:0] value;       /* current count value */
wire      zero;

// Count Flip-flops with input multiplexor
always@(posedge clock)
  begin  // begin-end not actually need here as there is only one statement
    if (reset) value <= 4'b0;
    else if (latch) value <= in;
    else if (dec && !zero) value <= value - 1'b1;  
  end

// combinational logic for zero flag
assign zero = ~|value;

endmodule /* counter */




