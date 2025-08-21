##########################################################################################
# Tool: IC Compiler II
# Script: place_opt.tcl
# Version: P-2019.03-SP2
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_pnr_setup.tcl 
set REPORT_PREFIX $PLACE_OPT_BLOCK_NAME

open_lib $DESIGN_LIBRARY
copy_block -from ${DESIGN_NAME}/${INIT_DESIGN_BLOCK_NAME} -to ${DESIGN_NAME}/${PLACE_OPT_BLOCK_NAME}
current_block ${DESIGN_NAME}/${PLACE_OPT_BLOCK_NAME}
link_block

## For top and intermediate level of hierarchical designs, check the editability of the sub-blocks;
## if the editability is true for any sub-block, set it to false
## In RM, we are setting the editability of all the sub-blocks to false in the init_design.tcl script
## The following check is implemented to ensure that the editability of the sub-blocks is set to false in flows not running the init_design.tcl script
if {$USE_ABSTRACTS_FOR_BLOCKS != ""} {
      	foreach_in_collection c [get_blocks -hierarchical] {
	  	if {[get_editability -blocks ${c}] == true } {
			set_editability -blocks ${c} -value false
   	  	}
      	}
	report_editability -blocks [get_blocks -hierarchical]
}

## Set active scenarios for the step (please include CTS and hold scenarios for CCD) 
if {$PLACE_OPT_ACTIVE_SCENARIO_LIST != ""} {
	set_scenario_status -active false [get_scenarios -filter active]
	set_scenario_status -active true $PLACE_OPT_ACTIVE_SCENARIO_LIST
}

if {[sizeof_collection [get_scenarios -filter "hold && active"]] == 0} {
	puts "RM-warning: No active hold scenario is found. Recommended to enable hold scenarios here such that CCD skewing can consider them." 
	puts "RM-info: Please activate hold scenarios for place_opt if they are available." 
}

source -echo settings.place_opt.tcl ;# common settings before place_opt, including clock NDR
source -echo settings.non_persistent.tcl ;# non-persistent settings to be re-applied in each session

##########################################################################################
## Additional flavors (optional)
##########################################################################################
## ICC2-RM provides additional files (flavors) to override a small set of RM default settings for high connectivity, run time,
## and area/power focused designs. This is controlled by ADDITIONAL_FLAVOR, which is by default unspecified; 
## if unspecified, runs RM default flow that works/balances all PPA.
if {$ADDITIONAL_FLAVOR == "run_time"} {
	puts "RM-info: Sourcing [which flavor.run_time_focused.tcl]"
	source -echo flavor.run_time_focused.tcl
} elseif {$ADDITIONAL_FLAVOR == "area_power"} {
	puts "RM-info: Sourcing [which flavor.area_power_focused.tcl]"
	source -echo flavor.area_power_focused.tcl
} elseif {$ADDITIONAL_FLAVOR == "high_connectivity_high_congestion"} {
	puts "RM-info: Sourcing [which flavor.high_connectivity_high_congestion_focused.tcl]"
	source -echo flavor.high_connectivity_high_congestion_focused.tcl
}

##########################################################################################
## Additional setup
##########################################################################################
## Lib cell usage restrictions (set_lib_cell_purpose)
## By default, RM sources set_lib_cell_purpose.tcl for dont use, tie cell, hold fixing, CTS and CTS-exclusive cell restrictions. 
## You can replace it with your own script by specifying the TCL_LIB_CELL_PURPOSE_FILE variable.  
if {[file exists [which $TCL_LIB_CELL_PURPOSE_FILE]]} {
	puts "RM-info: Sourcing [which $TCL_LIB_CELL_PURPOSE_FILE]"
	source $TCL_LIB_CELL_PURPOSE_FILE
} elseif {$TCL_LIB_CELL_PURPOSE_FILE != ""} {
	puts "RM-error: TCL_LIB_CELL_PURPOSE_FILE($TCL_LIB_CELL_PURPOSE_FILE) is invalid. Please correct it."
}

## Placement spacing labels and rules 
if {[file exists [which $TCL_PLACEMENT_SPACING_LABEL_RULE_FILE]]} {
	puts "RM-info: Sourcing [which $TCL_PLACEMENT_SPACING_LABEL_RULE_FILE]"
	source $TCL_PLACEMENT_SPACING_LABEL_RULE_FILE
} elseif {$TCL_PLACEMENT_SPACING_LABEL_RULE_FILE != ""} {
	puts "RM-error: TCL_PLACEMENT_SPACING_LABEL_RULE_FILE($TCL_PLACEMENT_SPACING_LABEL_RULE_FILE) is invalid. Please correct it."
}

## read_saif 
if {[file exists [which $SAIF_FILE]]} {
	if {$SAIF_FILE_POWER_SCENARIO != ""} {
		set read_saif_cmd "read_saif $SAIF_FILE -scenarios \"$SAIF_FILE_POWER_SCENARIO\""
	} else {
		set read_saif_cmd "read_saif $SAIF_FILE"
	}
	if {$SAIF_FILE_SOURCE_INSTANCE != ""} {lappend read_saif_cmd -strip_path $SAIF_FILE_SOURCE_INSTANCE}
	if {$SAIF_FILE_TARGET_INSTANCE != ""} {lappend read_saif_cmd -path $SAIF_FILE_TARGET_INSTANCE}
	puts "RM-info: Running $read_saif_cmd"
        eval ${read_saif_cmd}
} elseif {$SAIF_FILE != ""} {
	puts "RM-error: SAIF_FILE($SAIF_FILE) is invalid. Please correct it."	
}

## Spare cell insertion before place_opt (Example: templates/place_opt.spare_cell.tcl)
if {[file exists [which $TCL_USER_SPARE_CELL_PRE_SCRIPT]]} {
	puts "RM-info: Sourcing [which $TCL_USER_SPARE_CELL_PRE_SCRIPT]"
	source $TCL_USER_SPARE_CELL_PRE_SCRIPT
} elseif {$TCL_USER_SPARE_CELL_PRE_SCRIPT != ""} {
	puts "RM-error: TCL_USER_SPARE_CELL_PRE_SCRIPT($TCL_USER_SPARE_CELL_PRE_SCRIPT) is invalid. Please correct it."
}

##########################################################################################
## Pre-place_opt customizations
##########################################################################################
if {[file exists [which $TCL_USER_PLACE_OPT_PRE_SCRIPT]]} {
	puts "RM-info: Sourcing [which $TCL_USER_PLACE_OPT_PRE_SCRIPT]"
	source -echo $TCL_USER_PLACE_OPT_PRE_SCRIPT
} elseif {$TCL_USER_PLACE_OPT_PRE_SCRIPT != ""} {
	puts "RM-error: TCL_USER_PLACE_OPT_PRE_SCRIPT($TCL_USER_PLACE_OPT_PRE_SCRIPT) is invalid. Please correct it."
}

redirect -tee -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_app_options.start {report_app_options -non_default *}
redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_lib_cell_purpose {report_lib_cell -objects [get_lib_cells] -column {full_name:20 valid_purposes}}

## The following only applies to designs with physical hierarchy
## Ignore the sub-blocks (bound to abstracts) internal timing paths
if {$DESIGN_STYLE == "hier" && $PHYSICAL_HIERARCHY_LEVEL != "bottom"} {
	set_timing_paths_disabled_blocks -all_sub_blocks
}

##########################################################################################
## Clock NDR modeling at place_opt
##########################################################################################
## Clock NDRs are created in settings.place_opt.tcl. 
## mark_clock_trees makes place_opt recognize them to model the congestion impact
puts "RM-info: Running mark_clock_trees -routing_rules to model clock NDR impact during place_opt"
mark_clock_trees -routing_rules

##########################################################################################
## place_opt flow
##########################################################################################
if {[file exists [which $TCL_USER_PLACE_OPT_SCRIPT]]} {
	puts "RM-info: Sourcing [which $TCL_USER_PLACE_OPT_SCRIPT]"
	source -echo $TCL_USER_PLACE_OPT_SCRIPT
} elseif {$TCL_USER_PLACE_OPT_SCRIPT != ""} {
	puts "RM-error:TCL_USER_PLACE_OPT_SCRIPT($TCL_USER_PLACE_OPT_SCRIPT) is invalid. Please correct it."
} else {

	##########################################################################
	## Regular MSCTS at place_opt 
	##########################################################################
	if {$PLACE_OPT_MSCTS} {
		## Define MSCTS critical scenario as current_scenario as this will be the scenario considered for tap assignment
		if {$PLACE_OPT_MSCTS_CRITICAL_SCENARIO != ""} {
			set cur_scenario [get_object_name [current_scenario]]
			current_scenario $PLACE_OPT_MSCTS_CRITICAL_SCENARIO
		}

		if {[file exists [which $TCL_REGULAR_MSCTS_FILE]]} {
			set_app_options -name place_opt.flow.enable_multisource_clock_trees -value true
		        puts "RM-info: Sourcing [which $TCL_REGULAR_MSCTS_FILE]"
        		source $TCL_REGULAR_MSCTS_FILE
			save_block -as ${DESIGN_NAME}/${PLACE_OPT_BLOCK_NAME}_MSCTS

		} elseif {$TCL_REGULAR_MSCTS_FILE != ""} {
        		puts "RM-error: TCL_REGULAR_MSCTS_FILE($TCL_REGULAR_MSCTS_FILE) is invalid. Please correct it."
		}

		if {$PLACE_OPT_MSCTS_CRITICAL_SCENARIO != ""} {current_scenario $cur_scenario}
	}

	##########################################################################
	## Two pass place_opt: first pass
	##########################################################################
	## Flow with non-SPG inputs ($PLACE_OPT_SPG_FLOW set to false)
	if {!$PLACE_OPT_SPG_FLOW} {
		puts "RM-info: Running place_opt -from initial_place -to initial_place" ;# initial_place phase is buffering-aware with CDR
		place_opt -from initial_place -to initial_place
		puts "RM-info: Running place_opt -from initial_drc -to initial_drc"
		place_opt -from initial_drc -to initial_drc
		puts "RM-info: Running update_timing -full"
		update_timing -full
	} 

	## Flow with SPG inputs ($PLACE_OPT_SPG_FLOW set to true)
	if {$PLACE_OPT_SPG_FLOW} {
		puts "RM-info: For designs starting with SPG input, seed placement comes from SPG, so the first pass is not needed."
	}

	##########################################################################
	## Two pass place_opt: second pass
	##########################################################################
	## Trial CTS (optional; this feature is not needed if PLACE_OPT_OPTIMIZE_ICGS is enabled)
	if {$PLACE_OPT_TRIAL_CTS} {
		set_app_options -name place_opt.flow.trial_clock_tree -value true ;# default false
	}

	## ICG optimization  (optional)
	## Automatic ICG optimization that performs trial CTS (starting in initial_drc phase), 
	## timing-driven ICG splitting (initial_opto phase), and clock-aware placement (final_place phase)
	if {$PLACE_OPT_OPTIMIZE_ICGS} {
		set_app_options -name place_opt.flow.optimize_icgs -value true ;# default false
		if {$PLACE_OPT_OPTIMIZE_ICGS_CRITICAL_RANGE != ""} {
			set_app_options -name place_opt.flow.optimize_icgs_critical_range -value $PLACE_OPT_OPTIMIZE_ICGS_CRITICAL_RANGE ;# default 0.75
		}
	}

	## Flow with non-SPG inputs ($PLACE_OPT_SPG_FLOW set to false)
	if {!$PLACE_OPT_SPG_FLOW} {
		puts "RM-info: Running create_placement -incremental -timing_driven -congestion"
		# Note: to increase the congestion alleviation effort, add -congestion_effort high
		create_placement -incremental -timing_driven -congestion
		save_block -as ${DESIGN_NAME}/${PLACE_OPT_BLOCK_NAME}_two_pass_placement

		puts "RM-info: Running place_opt -from initial_drc"
		place_opt -from initial_drc
	} 

	## Flow with SPG inputs ($PLACE_OPT_SPG_FLOW set to true)
	if {$PLACE_OPT_SPG_FLOW} {
		puts "RM-info: Running place_opt with place_opt.flow.do_spg true"
		set_app_options -name place_opt.flow.do_spg -value true 
		place_opt
	}
}

##########################################################################################
## Post-place_opt customizations
##########################################################################################
if {[file exists [which $TCL_USER_PLACE_OPT_POST_SCRIPT]]} {
	puts "RM-info: Sourcing [which $TCL_USER_PLACE_OPT_POST_SCRIPT]"
	source -echo $TCL_USER_PLACE_OPT_POST_SCRIPT
} elseif {$TCL_USER_PLACE_OPT_POST_SCRIPT != ""} {
	puts "RM-error:TCL_USER_PLACE_OPT_POST_SCRIPT($TCL_USER_PLACE_OPT_POST_SCRIPT) is invalid. Please correct it."
}

## Spare cell insertion after place_opt (Example: templates/place_opt.spare_cell.tcl)
if {[file exists [which $TCL_USER_SPARE_CELL_POST_SCRIPT]]} {
	puts "RM-info: Sourcing [which $TCL_USER_SPARE_CELL_POST_SCRIPT]"
	source $TCL_USER_SPARE_CELL_POST_SCRIPT
} elseif {$TCL_USER_SPARE_CELL_POST_SCRIPT != ""} {
	puts "RM-error: TCL_USER_SPARE_CELL_POST_SCRIPT($TCL_USER_SPARE_CELL_POST_SCRIPT) is invalid. Please correct it."
}

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
	} elseif { $PHYSICAL_HIERARCHY_LEVEL == "intermediate"} {
            if { $ABSTRACT_TYPE_FOR_MPH_BLOCKS == "nested"} { 
                ## Create nested abstract for the intermediate level of physical hierarchy
	   	create_abstract -read_only
                create_frame -block_all true
            } elseif { $ABSTRACT_TYPE_FOR_MPH_BLOCKS == "flattened"} {
                ## Create flattened abstract for the intermediate level of physical hierarchy
                create_abstract -read_only -preserve_block_instances false
                create_frame -block_all true
            }
	}
}

##########################################################################################
## Report and output
##########################################################################################
if {$REPORT_QOR} {source report_qor.tcl}

print_message_info -ids * -summary
echo [exec date +%s] > place_opt 
exit

