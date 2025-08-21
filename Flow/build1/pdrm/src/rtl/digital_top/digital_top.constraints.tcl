set clkname clk_i

#---------------------------------------------------------
# Specify a 5ns clock period with 50% duty cycle     
# and a skew of 200ps                                 
#---------------------------------------------------------
 set CLK_PER  5
 set CLK_SKEW 0.2
 create_clock -name $clkname -period $CLK_PER -waveform "0 [expr $CLK_PER / 2]" $clkname
 set_clock_uncertainty $CLK_SKEW $clkname

#---------------------------------------------------------
# Now set up the 'CONSTRAINTS' on the design:          
# 1.  How much of the clock period is lost in the      
#     modules connected to it                          
# 2.  What type of cells are driving the inputs        
# 3.  What type of cells and how many (fanout) must it 
#     be able to drive                                 
#---------------------------------------------------------

# Following parameters have been modified based on Nangate 45nm library (slow conditional):
# DFF_CKQ, IP_DELAY, DFF_SETUP, OP_DELAY, WIRE_LOAD_EST
# These values are based on simulation. Credited to: Christopher Mineo

#---------------------------------------------------------
# ASSUME being driven by a slowest D-flip-flop         
# The DFF cell has a clock-Q delay of 200 ps          
# EX: 50um M3 has R of 178.57 Ohms and C of 12.5585fF. 0.69RC = 1.55ps
# Therefore, roughly 20ps wire delay is assumed.                
# NOTE: THESE ARE INITIAL ASSUMPTIONS ONLY             
#---------------------------------------------------------
#
 set DFF_CKQ 0.2
 set IP_DELAY [expr 0.2 + $DFF_CKQ]
 set_input_delay $IP_DELAY -clock $clkname [remove_from_collection [all_inputs] $clkname]

#---------------------------------------------------------
# ASSUME this module is driving a D-flip-flip          
# The DFF cell has a set-up time of 200 ps             
# Same wire delay as mentioned above           
# NOTE: THESE ARE INITIAL ASSUMPTIONS ONLY             
#---------------------------------------------------------
 set DFF_SETUP 0.2
 set OP_DELAY [expr 0.2 + $DFF_SETUP]
 set_output_delay $OP_DELAY -clock $clkname [all_outputs]

#---------------------------------------------------------	
# ASSUME being driven by a D-flip-flop                 
#---------------------------------------------------------

 set DR_CELL_NAME gf180mcu_fd_sc_mcu7t5v0__sdffrnq_1
 set DR_CELL_PIN  Q

 set_driving_cell -lib_cell "$DR_CELL_NAME" -pin "$DR_CELL_PIN" [remove_from_collection [all_inputs] $clkname]

#---------------------------------------------------------
# ASSUME the worst case output load is                 
# 4 D-flip-flop (D-inputs) and                         
# 0.013 units of wiring capacitance                     
#---------------------------------------------------------
 set PORT_LOAD_CELL  gf180mcu_fd_sc_mcu7t5v0/gf180mcu_fd_sc_mcu7t5v0__sdffrnq_1/D
 set WIRE_LOAD_EST   0.013
 set FANOUT          4
 set PORT_LOAD [expr $WIRE_LOAD_EST + $FANOUT * [load_of $PORT_LOAD_CELL]]
 set_load $PORT_LOAD [all_outputs]

#---------------------------------------------------------
# Now set the GOALS for the compile                    
# In most cases you want minimum area, so set the      
# goal for maximum area to be 0                        
#---------------------------------------------------------
 set_max_area 0
#---------------------------------------------------------
# This command prevents feedthroughs from input to output and avoids assign statements                 
#--------------------------------------------------------- 
 set_fix_multiple_port_nets -all -buffer_constants [get_designs]

