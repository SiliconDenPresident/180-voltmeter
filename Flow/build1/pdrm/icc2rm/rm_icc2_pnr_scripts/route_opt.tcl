##########################################################################################
# Tool: IC Compiler II
# Script: route_opt.tcl
# Version: P-2019.03-SP2
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_pnr_setup.tcl 
set REPORT_PREFIX $ROUTE_OPT_BLOCK_NAME

open_lib $DESIGN_LIBRARY
copy_block -from ${DESIGN_NAME}/${ROUTE_AUTO_BLOCK_NAME} -to ${DESIGN_NAME}/${ROUTE_OPT_BLOCK_NAME}
current_block ${DESIGN_NAME}/${ROUTE_OPT_BLOCK_NAME}
link_block

## The following only applies to hierarchical designs
## Swap abstracts if abstracts specified for route_auto and route_opt are different
if {$DESIGN_STYLE == "hier"} {
	if {$USE_ABSTRACTS_FOR_BLOCKS != "" && ($BLOCK_ABSTRACT_FOR_ROUTE_OPT != $BLOCK_ABSTRACT_FOR_ROUTE_AUTO)} {
		puts "RM-info: Swapping from $BLOCK_ABSTRACT_FOR_ROUTE_AUTO to $BLOCK_ABSTRACT_FOR_ROUTE_OPT abstracts for all blocks."
		change_abstract -references $USE_ABSTRACTS_FOR_BLOCKS -label $BLOCK_ABSTRACT_FOR_ROUTE_OPT
		report_abstracts
	}
}

if {$ROUTE_OPT_ACTIVE_SCENARIO_LIST != ""} {
	set_scenario_status -active false [get_scenarios -filter active]
	set_scenario_status -active true $ROUTE_OPT_ACTIVE_SCENARIO_LIST
}

source -echo settings.route_opt.tcl ;# step specific settings
source -echo settings.non_persistent.tcl ;# non-persistent settings to be re-applied in each session

##########################################################################################
## Additional flavors (optional)
##########################################################################################
## ICC2-RM provides additional files (flavors) to override a small set of RM default settings for high connectivity, run time,
#  and area/power focused designs. This is controlled by ADDITIONAL_FLAVOR, which is by default unspecified; 
#  if unspecified, runs RM default flow that works/balances all PPA.
if {$ADDITIONAL_FLAVOR == "run_time"} {
	puts "RM-info: Sourcing [which flavor.run_time_focused.tcl]"
	source -echo flavor.run_time_focused.tcl
} elseif {$ADDITIONAL_FLAVOR == "area_power"} {
	puts "RM-info: Sourcing [which flavor.area_power_focused.tcl]"
	source -echo flavor.area_power_focused.tcl
}

##########################################################################################
## Pre-route_opt customizations
##########################################################################################
if {[file exists [which $TCL_USER_ROUTE_OPT_PRE_SCRIPT]]} {
	puts "RM-info: Sourcing [which $TCL_USER_ROUTE_OPT_PRE_SCRIPT]"
	source -echo $TCL_USER_ROUTE_OPT_PRE_SCRIPT
} elseif {$TCL_USER_ROUTE_OPT_PRE_SCRIPT != ""} {
	puts "RM-error : TCL_USER_ROUTE_OPT_PRE_SCRIPT($TCL_USER_ROUTE_OPT_PRE_SCRIPT) is invalid. Please correct it."
}

redirect -tee -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_app_options.start {report_app_options -non_default *}
redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_lib_cell_purpose {report_lib_cell -objects [get_lib_cells] -column {full_name:20 valid_purposes}}

## The following only applies to designs with physical hierarchy
## Ignore the sub-blocks (bound to abstracts) internal timing paths
if {$DESIGN_STYLE == "hier" && $PHYSICAL_HIERARCHY_LEVEL != "bottom"} {
	set_timing_paths_disabled_blocks  -all_sub_blocks
}

##########################################################################################
## route_opt flow
##########################################################################################
compute_clock_latency 

if {[file exists [which $TCL_USER_ROUTE_OPT_SCRIPT]]} {
	puts "RM-info: Sourcing [which $TCL_USER_ROUTE_OPT_SCRIPT]"
	source -echo $TCL_USER_ROUTE_OPT_SCRIPT
} elseif {$TCL_USER_ROUTE_OPT_SCRIPT != ""} {
	puts "RM-error: TCL_USER_ROUTE_OPT_SCRIPT($TCL_USER_ROUTE_OPT_SCRIPT) is invalid. Please correct it."
} else {

	##########################################################################
	## First route_opt (CCD)
	##########################################################################
	## Without CLIB, route_opt issues TIM-260 and reverts to native timer, even if search_path includes .db paths. 
	## Refer to TIM-260 on how to enable library configuration to update reference libraries during open_lib.
	puts "RM-info: Running first route_opt (CCD)."
	route_opt
	#save_block -as ${DESIGN_NAME}/${ROUTE_OPT_BLOCK_NAME}_1

	##########################################################################
	## Second route_opt (non-CCD)
	##########################################################################
	## Turn off route_opt CCD for the second route_opt
	puts "RM-info: Setting route_opt.flow.enable_ccd to false for the second route_opt"
	set_app_options -name route_opt.flow.enable_ccd -value false ;# tool default false
	
	## Enable path based analysis (PBA) during PrimeTime delay calculation (optional)
	if {$ROUTE_OPT_PT_DELAY_CALCULATION_WITH_PBA} {
		## time.pba_optimization_mode enables path-based analysis during route_opt; tool default false;
		## you can also set it to exhaustive to apply an exhaustive path search algorithm to determine worst pba path to an endpoint;
		## in report_qor.tcl, script will add -pba_mode with the specified value to report_qor/timing/global_timing commands.
		set_app_options -name time.pba_optimization_mode -value path 
		
		## Disable CCD when PBA is enabled, if CCD is not already disabled
		if {[get_app_option_value -name route_opt.flow.enable_ccd]} {
			set_app_options -name route_opt.flow.enable_ccd -value false
		}
	}

	## Enable StarRC in-design extraction (optional)
	## Config file is required to set up a proper StarRC run
	if {[file exists [which $ROUTE_OPT_STARRC_CONFIG_FILE]]} {
		set_starrc_in_design -config $ROUTE_OPT_STARRC_CONFIG_FILE ;# example: templates/route_opt.starrc_config_example.txt
	} elseif {$ROUTE_OPT_STARRC_CONFIG_FILE != ""} {
		puts "RM-error: ROUTE_OPT_STARRC_CONFIG_FILE($ROUTE_OPT_STARRC_CONFIG_FILE) is invalid. Please correct it."
	}

	puts "RM-info: Running second route_opt (non-CCD)"
	route_opt
	#save_block -as ${DESIGN_NAME}/${ROUTE_OPT_BLOCK_NAME}_2

	##########################################################################
	## Third route_opt (non-CCD and size-only) or ECO fusion
	##########################################################################
	if {$ROUTE_OPT_ECO_OPT_PT_PATH == ""} {
	
		#########################################
		## Third route_opt (non-CCD and size-only
		#########################################
		## Turn off route_opt CCD for the third route_opt
		puts "RM-info: Setting route_opt.flow.enable_ccd to false for the third route_opt"
		set_app_options -name route_opt.flow.enable_ccd -value false ;# tool default false
	
		## Reset power recovery to tool default for the third route_opt
		puts "RM-info: Resetting route_opt.flow.enable_clock_power_recovery for the third route_opt"
		reset_app_options route_opt.flow.enable_clock_power_recovery ;# tool default auto
	
		## Reset clock DRC fixing to tool default for the third route_opt
		puts "RM-info: Resetting route_opt.flow.enable_ccd_clock_drc_fixing for the third route_opt"
		reset_app_options route_opt.flow.enable_ccd_clock_drc_fixing ;# tool default auto
		
		## Size-only is recommended for the last route_opt in the flow
		## Please uncomment and set the app option to a value appropriate to your library models, 
		## such as footprint, equal, or equal_or_smaller
		puts "RM-info: Setting route_opt.flow.size_only_mode to equal_or_smaller"   
		set_app_options -name route_opt.flow.size_only_mode -value equal_or_smaller
		
		puts "RM-info: Running third route_opt (non-CCD and size-only)"
		route_opt
	
	} else {

		#########################################
		## ECO fusion  
		#########################################
		## Prerequisites : (1) PT path is specified (2) license found 
		## Best to use check_pt_qor with ECO fusion for timing/QoR reporting. 
		## After ECO fusion is completed, any additional ICC-II report_* commands are based on ICC-II's native timer. 
		if {[check_license -quiet "Digital-AF"]} {
			puts "RM-info: Running ECO fusion"
			source -echo route_opt.eco_opt.tcl
		} else {
			puts "RM-error: Unable to find Digital-AF license. ECO fusion is skipped"
		}
	
	}
}

##########################################################################################
## Target endpoint optimization	
##########################################################################################
## To optimize specific endpoints for setup, hold, or max_tran, specify the endpoints in a file 
## by using the -setup_endpoints, -hold_endpoints, or -max_transition options
## For ex, 
##	set_route_opt_target_endpoints -setup_endpoints $your_setup_endpoints_file
##	route_opt

## To adjust the timing at specific endpoints for setup or hold (such as to adjust timing to achieve PT slack), 
## specify the endpoints and slack information in a file by using the -setup_timing or -hold_timing options
## For ex, 
##	set_route_opt_target_endpoints -setup_timing $your_setup_timing_file
##	report_qor -summary ;# generate report with adjusted timing before route_opt
##	route_opt
##	report_qor -summary ;# generate report with adjusted timing after route_opt
##	set_route_opt_target_endpoints -reset ;# remove adjusted timing
##	report_qor -summary ;# generate report without adjusted timing after route_opt

##########################################################################################
## Redundant via insertion
##########################################################################################
## For designs with advanced nodes where DRC convergence could be a concern, 
## redundant via insertion is recommended to be done after route_auto/route_opt
## Please refer to settings.route_auto.tcl for relevant settings
if {$REDUNDANT_VIA_INSERTION} {
	add_redundant_vias
}

##########################################################################################
## Reshield after route_opt
##########################################################################################
if {$ROUTE_AUTO_CREATE_SHIELDS != "none" && $ROUTE_OPT_RESHIELD == "after_route_opt"} {
	create_shields ;# without specifying -nets option, all nets with shielding rules will be shielded 
}

##########################################################################################
## Post-route_opt customizations
##########################################################################################
if {[file exists [which $TCL_USER_ROUTE_OPT_POST_SCRIPT]]} {
	puts "RM-info: Sourcing [which $TCL_USER_ROUTE_OPT_POST_SCRIPT]"
	source -echo $TCL_USER_ROUTE_OPT_POST_SCRIPT
} elseif {$TCL_USER_ROUTE_OPT_POST_SCRIPT != ""} {
	puts "RM-error : TCL_USER_ROUTE_OPT_POST_SCRIPT($TCL_USER_ROUTE_OPT_POST_SCRIPT) is invalid. Please correct it."
}

## You can use route_detail to reduce routing DRC further
#	check_routes
#	route_detail -incremental true -initial_drc_from_input true

## Example to resolve short violated nets
## Note that remove and reroute nets could potentially degrade timing QoR.
#set data [open_drc_error_data -name zroute.err]
#open_drc_error_data -name zroute.err
#if { [sizeof_collection [get_drc_errors -quiet -error_data zroute.err -filter "type_name==Short"] ] > 0} {
#	set remove_net ""
#	foreach_in_collection net [get_attribute [get_drc_errors -error_data zroute.err -filter {type_name=="Crossing top-cell boundary"} objects] {
#		set net_type [get_attribute $net net_type]
#		if {$net_type=="signal"} {append_to_collection remove_net $net}
#	}
#	remove_routes -detail_route -nets $remove_net
#	route_eco
#}

##########################################################################################
## connect_pg_net
##########################################################################################
if {$TCL_USER_CONNECT_PG_NET_SCRIPT != ""} {
	if {[file exists [which $TCL_USER_CONNECT_PG_NET_SCRIPT]]} {
		puts "RM-info: Sourcing [which $TCL_USER_CONNECT_PG_NET_SCRIPT]"
		source $TCL_USER_CONNECT_PG_NET_SCRIPT
	} else {
		puts "RM-error: TCL_USER_CONNECT_PG_NET_SCRIPT($TCL_USER_CONNECT_PG_NET_SCRIPT) is invalid. Please correct it."
	}
} else {
	connect_pg_net
}

## Run check_routes to save updated routing DRC to the block
redirect -tee -file ${REPORTS_DIR}/${REPORT_PREFIX}.check_routes {check_routes}

## Save block
save_block

##########################################################################################
## Create abstract and frame
##########################################################################################
## Enabled for hierarchical designs; for bottom and intermediate levels of physical hierarchy
if {$DESIGN_STYLE == "hier"} {
	if {$USE_ABSTRACTS_FOR_POWER_ANALYSIS == "true"} {
		set_app_options -name abstract.annotate_power -value true
	}
	if { $PHYSICAL_HIERARCHY_LEVEL == "bottom" } {
		create_abstract -read_only
                create_frame -block_all true
                derive_hier_antenna_property -design ${DESIGN_NAME}/${ROUTE_OPT_BLOCK_NAME}

	} elseif { $PHYSICAL_HIERARCHY_LEVEL == "intermediate"} {
		if { $ABSTRACT_TYPE_FOR_MPH_BLOCKS == "nested"} {
			## Create nested abstract for the intermediate level of physical hierarchy
			create_abstract -read_only
		} elseif { $ABSTRACT_TYPE_FOR_MPH_BLOCKS == "flattened"} {
			## Create flattened abstract for the intermediate level of physical hierarchy
			create_abstract -read_only -preserve_block_instances false
		}
                create_frame -block_all true
                derive_hier_antenna_property -design ${DESIGN_NAME}/${ROUTE_OPT_BLOCK_NAME}
	}
}

##########################################################################################
## Report and output
##########################################################################################

## The following is a hack added by Rhett Davis 
## to enable dynamic power analysis with MCMM scenarios read from DC
set_scenario_status mode_norm.fast.RCmin -setup true -hold true -leakage_power true -dynamic_power true


if {$REPORT_QOR} {source report_qor.tcl}

print_message_info -ids * -summary
echo [exec date +%s] > route_opt 
exit

