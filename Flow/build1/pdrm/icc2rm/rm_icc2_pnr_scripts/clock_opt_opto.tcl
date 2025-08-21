##########################################################################################
# Tool: IC Compiler II
# Script: clock_opt_opto.tcl
# Version: P-2019.03-SP2
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_pnr_setup.tcl 
set REPORT_PREFIX $CLOCK_OPT_OPTO_BLOCK_NAME

open_lib $DESIGN_LIBRARY
copy_block -from ${DESIGN_NAME}/${CLOCK_OPT_CTS_BLOCK_NAME} -to ${DESIGN_NAME}/${CLOCK_OPT_OPTO_BLOCK_NAME}
current_block ${DESIGN_NAME}/${CLOCK_OPT_OPTO_BLOCK_NAME}
link_block

## The following only applies to hierarchical designs
## Swap abstracts if abstracts specified for clock_opt_cts and clock_opt_opto are different
if {$DESIGN_STYLE == "hier"} {
	if {$USE_ABSTRACTS_FOR_BLOCKS != "" && ($BLOCK_ABSTRACT_FOR_CLOCK_OPT_OPTO != $BLOCK_ABSTRACT_FOR_CLOCK_OPT_CTS)} {
		puts "RM-info: Swapping from $BLOCK_ABSTRACT_FOR_CLOCK_OPT_CTS to $BLOCK_ABSTRACT_FOR_CLOCK_OPT_OPTO abstracts for all blocks."
		change_abstract -references $USE_ABSTRACTS_FOR_BLOCKS -label $BLOCK_ABSTRACT_FOR_CLOCK_OPT_OPTO
		report_abstracts
	}
}

if {$CLOCK_OPT_OPTO_ACTIVE_SCENARIO_LIST != ""} {
	set_scenario_status -active false [get_scenarios -filter active]
	set_scenario_status -active true $CLOCK_OPT_OPTO_ACTIVE_SCENARIO_LIST

        ## Propagate clocks and compute IO latencies for modes or corners which are not active during clock_opt_cts step
        synthesize_clock_trees -propagate_only
        compute_clock_latency
}

source -echo settings.clock_opt_opto.tcl ;# step specific settings
source -echo settings.non_persistent.tcl ;# non-persistent settings to be re-applied in each session

##########################################################################################
## Pre-opto customizations
##########################################################################################
if {[file exists [which $TCL_USER_CLOCK_OPT_OPTO_PRE_SCRIPT]]} {
	puts "RM-info: Sourcing [which $TCL_USER_CLOCK_OPT_OPTO_PRE_SCRIPT]"
	source -echo $TCL_USER_CLOCK_OPT_OPTO_PRE_SCRIPT
} elseif {$TCL_USER_CLOCK_OPT_OPTO_PRE_SCRIPT != ""} {
	puts "RM-error: TCL_USER_CLOCK_OPT_OPTO_PRE_SCRIPT($TCL_USER_CLOCK_OPT_OPTO_PRE_SCRIPT) is invalid. Please correct it."
}

redirect -tee -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_app_options.start {report_app_options -non_default *}
redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_lib_cell_purpose {report_lib_cell -objects [get_lib_cells] -column {full_name:20 valid_purposes}}

## The following only applies to designs with physical hierarchy
## Ignore the sub-blocks (bound to abstracts) internal timing paths
if {$DESIGN_STYLE == "hier" && $PHYSICAL_HIERARCHY_LEVEL != "bottom"} {
	set_timing_paths_disabled_blocks  -all_sub_blocks
}

##########################################################################################
## clock_opt final_opto flow
##########################################################################################
if {[file exists [which $TCL_USER_CLOCK_OPT_OPTO_SCRIPT]]} {
	puts "RM-info: Sourcing [which $TCL_USER_CLOCK_OPT_OPTO_SCRIPT]"
	source -echo $TCL_USER_CLOCK_OPT_OPTO_SCRIPT
} elseif {$TCL_USER_CLOCK_OPT_OPTO_SCRIPT != ""} {
	puts "RM-error: TCL_USER_CLOCK_OPT_OPTO_SCRIPT($TCL_USER_CLOCK_OPT_OPTO_SCRIPT) is invalid. Please correct it."
} else {

	puts "RM-info: Running clock_opt -from final_opto -to final_opto command"
	clock_opt -from final_opto -to final_opto

}

##########################################################################################
## Post-route clock tree optimization for non-CCD flow
##########################################################################################
if {$CLOCK_OPT_OPTO_CTO && ![get_app_option_value -name clock_opt.flow.enable_ccd]} {
	if {$CLOCK_OPT_OPTO_CTO_USER_INSTANCE_NAME_PREFIX != ""} {
		set_app_options -name cts.common.user_instance_name_prefix -value ${CLOCK_OPT_OPTO_CTO_USER_INSTANCE_NAME_PREFIX}
	}
	save_block -as ${DESIGN_NAME}/${CLOCK_OPT_OPTO_BLOCK_NAME}_before_cto
	synthesize_clock_trees -postroute -routed_clock_stage detail
}

##########################################################################################
## Post-opto customizations
##########################################################################################
if {[file exists [which $TCL_USER_CLOCK_OPT_OPTO_POST_SCRIPT]]} {
	puts "RM-info: Sourcing [which $TCL_USER_CLOCK_OPT_OPTO_POST_SCRIPT]"
	source -echo $TCL_USER_CLOCK_OPT_OPTO_POST_SCRIPT
} elseif {$TCL_USER_CLOCK_OPT_OPTO_POST_SCRIPT != ""} {
	puts "RM-error: TCL_USER_CLOCK_OPT_OPTO_POST_SCRIPT($TCL_USER_CLOCK_OPT_OPTO_POST_SCRIPT) is invalid. Please correct it."
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

## Run check_routes to save updated routing DRC to the block
redirect -tee -file ${REPORTS_DIR}/${REPORT_PREFIX}.check_routes {check_routes -open_net false}

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
echo [exec date +%s] > clock_opt_opto 
exit

