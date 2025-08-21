##########################################################################################
# Tool: IC Compiler II
# Script: init_design.flat_design_planning_example.tcl (template)
# Version: P-2019.03-SP2
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

set REPORT_PREFIX $INIT_DESIGN_BLOCK_NAME

##################################################
# IO placement 
##################################################
if {[file exists [which $TCL_PAD_CONSTRAINTS_FILE]]} {
	puts "RM-info: Loading TCL_PAD_CONSTRAINTS_FILE file ($TCL_PAD_CONSTRAINTS_FILE)"
	source -echo $TCL_PAD_CONSTRAINTS_FILE
	
	puts "RM-info: running place_io"
	place_io
	set_attribute -objects [get_cells -quiet -filter is_io==true -hier] -name status -value fixed
	set_attribute -objects [get_cells -quiet -filter pad_cell==true -hier] -name status -value fixed
}

##################################################
# Macro placement 
##################################################
redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_macro_constraints.rpt {report_macro_constraints}

## To place macro only, set the following :
#	set_app_options -name plan.macro.macro_place_only -value true ;# default false
create_placement -floorplan

## To poly rule violations, add -poly_rule option and set plan.place.poly_rule to an integer as the threshold
redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_placement.rpt {report_placement -physical_hierarchy_violations all -wirelength all -hard_macro_overlap -verbose high}

