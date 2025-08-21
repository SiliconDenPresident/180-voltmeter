puts "RM-info: Running script [info script]\n"

##########################################################################################
# Tool: IC Compiler II
# Script: report_qor.tcl
# Purpose: Reporting with -nosplit options added to commands that support it
# Version: P-2019.03-SP2
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################
if {$REPORT_PREFIX != ""} {



####################################
## Clock tree QoR
####################################
if {[regexp $REPORT_PREFIX $INIT_DESIGN_BLOCK_NAME]} {
	puts "RM-info: Reporting clock tree information ...\n"
	parallel_execute {
		{report_clock_qor -type area -nosplit} ${REPORTS_DIR}/${REPORT_PREFIX}.report_clock_qor.cell_area
		{report_clock_qor -type structure -nosplit} ${REPORTS_DIR}/${REPORT_PREFIX}.report_clock_qor.structure
		{report_clock_timing -type summary -nosplit -scenarios [get_scenarios] } ${REPORTS_DIR}/${REPORT_PREFIX}.report_clock_timing
	}
} else {
	puts "RM-info: Reporting clock tree information and QoR ...\n"
	redirect -tee -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_clock_qor.summary {report_clock_qor -nosplit}
	parallel_execute {
		{report_clock_qor -type latency -show_paths -nosplit} ${REPORTS_DIR}/${REPORT_PREFIX}.report_clock_qor.latency
		{report_clock_qor -type area -nosplit} ${REPORTS_DIR}/${REPORT_PREFIX}.report_clock_qor.cell_area
		{report_clock_qor -type structure -nosplit} ${REPORTS_DIR}/${REPORT_PREFIX}.report_clock_qor.structure
		{report_clock_qor -type drc_violators -all -nosplit} ${REPORTS_DIR}/${REPORT_PREFIX}.report_clock_qor.drc_violators
		{report_clock_timing -type summary -nosplit -scenarios [get_scenarios] } ${REPORTS_DIR}/${REPORT_PREFIX}.report_clock_timing
	}
	if {[get_app_option_value -name cts.compile.enable_local_skew] || [get_app_option_value -name cts.optimize.enable_local_skew] || [get_app_option_value -name clock_opt.flow.enable_ccd]} {\
		redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_clock_qor.local_skew {report_clock_qor -type local_skew -nosplit}
	}
}

if {$REPORT_QOR_REPORT_POWER} { 
	puts "RM-info: Running report_clock_qor -type power ...\n"
	redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_clock_qor.power {report_clock_qor -type power -nosplit}
}

####################################
## Timing Constraints 
####################################
puts "RM-info: Reporting timing constraints ...\n"
parallel_execute {
	{report_mode -nosplit} ${REPORTS_DIR}/${REPORT_PREFIX}.report_mode
	{report_pvt -nosplit} ${REPORTS_DIR}/${REPORT_PREFIX}.report_pvt
}
redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_scenarios {report_scenarios -nosplit}
redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_clocks {report_clocks -mode [all_modes] -nosplit}

####################################
## Timing and QoR 
####################################
puts "RM-info: Reporting timing and QoR ...\n"

## Show special inbuilt path groups **async_default** and **clock_gating_default** in timing report 
## Note: User specified path groups has higher precedence than these. (global-scoped)
#	set_app_options -name time.use_special_default_path_groups -value true ;# tool default false

## QoR
redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_qor {report_qor -scenarios [all_scenarios] -pba_mode [get_app_option_value -name time.pba_optimization_mode] -nosplit}
redirect -tee -append -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_qor {report_qor -summary -pba_mode [get_app_option_value -name time.pba_optimization_mode] -nosplit}

## global timing 
redirect -tee -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_global_timing {report_global_timing -pba_mode [get_app_option_value -name time.pba_optimization_mode] -nosplit}

## Timing (-variation enabled for POCV)
if {[get_app_option_value -name time.pocvm_enable_analysis]} {
	redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_timing.max {report_timing -delay max -scenarios [all_scenarios] \
	-input_pins -nets -transition_time -capacitance -attributes -physical -derate -report_by group -pba_mode [get_app_option_value -name time.pba_optimization_mode] -variation -nosplit}
} else {
	redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_timing.max {report_timing -delay max -scenarios [all_scenarios] \
	-input_pins -nets -transition_time -capacitance -attributes -physical -derate -report_by group -pba_mode [get_app_option_value -name time.pba_optimization_mode] -nosplit}
}

# Min timing report is generated in postcts (-variation enabled for POCV)
if {[regexp $REPORT_PREFIX "$CLOCK_OPT_CTS_BLOCK_NAME|$CLOCK_OPT_OPTO_BLOCK_NAME|$ROUTE_AUTO_BLOCK_NAME|$ROUTE_OPT_BLOCK_NAME|$CHIP_FINISH_BLOCK_NAME|$ICV_IN_DESIGN_BLOCK_NAME"]} {
	if {[get_app_option_value -name time.pocvm_enable_analysis]} {
		redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_timing.min {report_timing -delay min -scenarios [all_scenarios] \
		-input_pins -nets -transition_time -capacitance -attributes -physical -derate -report_by group -pba_mode [get_app_option_value -name time.pba_optimization_mode] -variation -nosplit}
	} else {
		redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_timing.min {report_timing -delay min -scenarios [all_scenarios] \
		-input_pins -nets -transition_time -capacitance -attributes -physical -derate -report_by group -pba_mode [get_app_option_value -name time.pba_optimization_mode] -nosplit}
	}
}

## Constraint violations
redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_constraint {report_constraint -all_violators -max_transition -max_capacitance -scenarios [all_scenarios] -nosplit}

## Debugging
puts "RM-info: Analyzing design violations ...\n"
# analyze_design_violations for setup
# The command will automatically add "type" (ie, setup or hold) as part of the report name
# For example, the report name for setup type would be ${REPORTS_DIR}/${REPORT_PREFIX}.analyze_design_violations.setup
if {[regexp $REPORT_PREFIX "$PLACE_OPT_BLOCK_NAME|$CLOCK_OPT_OPTO_BLOCK_NAME"]} {
	analyze_design_violations -type setup -stage preroute -output ${REPORTS_DIR}/${REPORT_PREFIX}.analyze_design_violations
} elseif {[regexp $REPORT_PREFIX "$ROUTE_OPT_BLOCK_NAME"]} {
	analyze_design_violations -type setup -stage postroute -output ${REPORTS_DIR}/${REPORT_PREFIX}.analyze_design_violations
}

# analyze_design_violations for hold
if {[regexp $REPORT_PREFIX "$CLOCK_OPT_OPTO_BLOCK_NAME"]} {
	analyze_design_violations -type hold -stage preroute -output ${REPORTS_DIR}/${REPORT_PREFIX}.analyze_design_violations
} elseif {[regexp $REPORT_PREFIX "$ROUTE_OPT_BLOCK_NAME"]} {
	analyze_design_violations -type hold -stage postroute -output ${REPORTS_DIR}/${REPORT_PREFIX}.analyze_design_violations
}


####################################
## UPF and power 
####################################
# check_mv_design -erc_mode and -power_connectivity
	redirect -tee -file ${REPORTS_DIR}/${REPORT_PREFIX}.check_mv_design.erc_mode {check_mv_design -erc_mode}
	redirect -tee -file ${REPORTS_DIR}/${REPORT_PREFIX}.check_mv_design.power_connectivity {check_mv_design -power_connectivity}
	redirect -tee -file ${REPORTS_DIR}/${REPORT_PREFIX}.check_mv_design {check_mv_design} ;# check_mv_design is also covered by check_design
	redirect -tee -file ${REPORTS_DIR}/${REPORT_PREFIX}.check_pg_connectivity {check_pg_connectivity}

if {[regexp $REPORT_PREFIX $INIT_DESIGN_BLOCK_NAME]} {
	redirect -tee -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_power_domains {report_power_domains -nosplit}
	redirect -tee -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_voltage_areas {report_voltage_areas -nosplit}
}

if {![regexp $REPORT_PREFIX $INIT_DESIGN_BLOCK_NAME]} {
	redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_threshold_voltage_group {report_threshold_voltage_group -nosplit}
}

if {$REPORT_QOR_REPORT_POWER} { 
	puts "RM-info: Running report_power ...\n"
	## For hierarchical designs, use report_power -blocks to get the power consumption for the top and sub-blocks separately
	if {$USE_ABSTRACTS_FOR_BLOCKS != "" && $USE_ABSTRACTS_FOR_POWER_ANALYSIS == "true"} {
		redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_power {report_power -blocks -verbose -scenarios [all_scenarios] -nosplit}
	} else {
		redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_power {report_power -verbose -scenarios [all_scenarios] -nosplit}
	}
}

redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_mv_path {report_mv_path -all_not_associated}

####################################
## report_design  
####################################
puts "RM-info: Reporting design information ...\n"
if {[regexp $REPORT_PREFIX "$CLOCK_OPT_CTS_BLOCK_NAME|$CLOCK_OPT_OPTO_BLOCK_NAME|$ROUTE_AUTO_BLOCK_NAME|$ROUTE_OPT_BLOCK_NAME|$CHIP_FINISH_BLOCK_NAME|$ICV_IN_DESIGN_BLOCK_NAME|$PT_ECO_BLOCK_NAME"]} {
	redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_design {report_design -library -netlist -floorplan -routing -nosplit}
} else {
	redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_design {report_design -library -netlist -floorplan -nosplit}
}
redirect -tee -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_utilization {report_utilization}

####################################
## check_design, check_netlist & check_legality 
####################################
puts "RM-info: Checking design issues ...\n"

## The following lines are applicable for hierarchical designs with abstracts
# The following enables checking consistency of timing constraints between top and sub-blocks
if {$USE_ABSTRACTS_FOR_BLOCKS != ""} {
   if { $CHECK_HIER_TIMING_CONSTRAINTS_CONSISTENCY == "true" } {
       set_app_options -name abstract.check_constraints_consistency -value true
   } elseif { $CHECK_HIER_TIMING_CONSTRAINTS_CONSISTENCY == "false" } {
       set_app_options -name abstract.check_constraints_consistency -value false
   }
}

## Run the pre-defined mega-check pre_placement_stage which includes
#  atomic checks such as mv_design, design_mismatch, rp_constraints, timing, and scan chain.
if {[regexp $REPORT_PREFIX "$INIT_DESIGN_BLOCK_NAME"]} {
	redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.check_design.pre_placement_stage {check_design -ems_database check_design.pre_placement_stage.ems -checks pre_placement_stage}
	redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.check_netlist {check_netlist -summary}
}

## Run the pre-defined mega-check pre_clock_tree_stage which includes
#  atomic checks such as mv_design, design_mismatch, timing, scan chain, legality, design_extraction, and clock tree.
if {[regexp $REPORT_PREFIX "$PLACE_OPT_BLOCK_NAME"]} {
	redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.check_design.pre_clock_tree_stage {check_design -ems_database check_design.pre_clock_tree_stage.ems -checks pre_clock_tree_stage}
}

## Run the pre-defined mega-check pre_route_stage which includes
#  atomic checks such as mv_design, design_mismatch, timing, scan chain, design_extraction, and routeability. 
if {[regexp $REPORT_PREFIX "$CLOCK_OPT_OPTO_BLOCK_NAME"]} {
	redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.check_design.pre_route_stage {check_design -ems_database check_design.pre_route_stage.ems -checks pre_route_stage}
}

####################################
## MISC  
####################################
puts "RM-info: Reporting units ...\n"
if {[regexp $REPORT_PREFIX "$INIT_DESIGN_BLOCK_NAME"]} {
	redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_units {report_units -nosplit}
}

puts "RM-info: Reporting non-default app option settings ...\n"
redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_app_options.end {report_app_options -non_default *}

########################################################################
## Additional Zero interconnect delay reporting at init_design stage  
########################################################################
if {[regexp $REPORT_PREFIX $INIT_DESIGN_BLOCK_NAME]} {
	puts "RM-info: time.delay_calculation_style is set to zero_interconnect ...\n"
	# To restore user settings later
	set RM_current_value_high_fanout_net_pin_capacitance [get_app_option_value -name time.high_fanout_net_pin_capacitance]
	set RM_current_value_high_fanout_net_threshold [get_app_option_value -name time.high_fanout_net_threshold]

	set_app_options -name time.delay_calculation_style -value zero_interconnect ;# tool default auto
	set_app_options -name time.high_fanout_net_pin_capacitance -value 0pF ;# tool default 1pF
	set_app_options -name time.high_fanout_net_threshold -value 100 ;# tool default 1000

	puts "RM-info: Reporting timing and QoR in zero_interconnect mode with zero pin cap ...\n"
	## QoR
	redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.zwlm.report_qor {report_qor -scenarios [all_scenarios] -nosplit}
	redirect -tee -append -file ${REPORTS_DIR}/${REPORT_PREFIX}.zwlm.report_qor {report_qor -summary -nosplit}
	
	## Timing (-variation enabled for POCV)
	if {[get_app_option_value -name time.pocvm_enable_analysis]} {
		redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.zwlm.report_timing.max {report_timing -delay max -scenarios [all_scenarios] \
		-input_pins -nets -transition_time -capacitance -attributes -physical -derate -report_by group -variation -nosplit}
	} else {
		redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.zwlm.report_timing.max {report_timing -delay max -scenarios [all_scenarios] \
		-input_pins -nets -transition_time -capacitance -attributes -physical -derate -report_by group -nosplit}
	}

	puts "RM-info: time.delay_calculation_style is reset...\n"
	reset_app_options time.delay_calculation_style
	set_app_options -name time.high_fanout_net_pin_capacitance -value $RM_current_value_high_fanout_net_pin_capacitance
	set_app_options -name time.high_fanout_net_threshold -value $RM_current_value_high_fanout_net_threshold
}

########################################################################
## Additional non-SI reporting at route_auto stage  
########################################################################
if {[regexp $REPORT_PREFIX $ROUTE_AUTO_BLOCK_NAME]} {
	if {[get_app_option_value -name time.si_enable_analysis]} {
		set RM_current_value_enable_si true
	}
	puts "RM-info: time.si_enable_analysis is set to false ...\n"
	set_app_options -name time.si_enable_analysis -value false
	
	puts "RM-info: Reporting timing and QoR in non-SI mode ...\n"
	## QoR
	redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.no_si.report_qor {report_qor -scenarios [all_scenarios] -nosplit}
	redirect -tee -append -file ${REPORTS_DIR}/${REPORT_PREFIX}.no_si.report_qor {report_qor -summary -nosplit}
	
	## Timing (-variation enabled for POCV)
	if {[get_app_option_value -name time.pocvm_enable_analysis]} {
		redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.no_si.report_timing.max {report_timing -delay max -scenarios [all_scenarios] \
		-input_pins -nets -transition_time -capacitance -attributes -physical -derate -report_by group -variation -nosplit}
	} else {
		redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.no_si.report_timing.max {report_timing -delay max -scenarios [all_scenarios] \
		-input_pins -nets -transition_time -capacitance -attributes -physical -derate -report_by group -nosplit}
	}

	## Restore user default of time.si_enable_analysis
	if {[info exists RM_current_value_enable_si] && ${RM_current_value_enable_si}} {
		set_app_options -name time.si_enable_analysis -value true
	}
}

########################################################################
## report_congestion and global route congestion map 
########################################################################
if {$REPORT_QOR_REPORT_CONGESTION && [regexp $REPORT_PREFIX "$PLACE_OPT_BLOCK_NAME|$CLOCK_OPT_CTS_BLOCK_NAME|$CLOCK_OPT_OPTO_BLOCK_NAME"]} {
	redirect -tee -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_congestion {report_congestion -layers [get_layers -filter "layer_type==interconnect"] -rerun_global_router -nosplit}
	if {[info exists env(DISPLAY)]} {
		gui_start
		#gui_execute_menu_item -menu "View->Layout View"
		gui_execute_menu_item -menu "View->Map->Global Route Congestion"
		gui_write_window_image -format png -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_congestion.png
		gui_stop
	} else {
		puts "RM-info: env(DISPLAY) is not defined. Global route congestion map snapshot is skipped."
	}
}


########################################################################
## Other reporting commands 
########################################################################
## report_ccd_timing : Reports CCD timing information of a design
## - To Print D slacks and Q slacks of the top 5 critical endpoints
##   (D slack : worst slack of the paths captured by a flop)
##   (Q slack : worst slack of the paths lauched by a flop)
##	report_ccd_timing 
## - To report slacks of timing paths that precede or succeed a critical end point with a specified stage number up/down the chain
##	report_ccd_timing -type stage -pin <pin> -max_stages <integer>
## - To report top 5 timing paths in the fanin(fanout) cone of a critical end point
##	report_ccd_timing -type fanin -pin <pin>

} else {

puts "RM-error: REPORT_PREFIX is not specified. Exiting."

}

puts "RM-info: Completed script [info script]\n"

