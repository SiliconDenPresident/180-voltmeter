puts "RM-info: Running script [info script]\n"

##########################################################################################
# Tool: IC Compiler II
# Script: route_opt.eco_opt.tcl to be sourced by route_opt.tcl
# Version: P-2019.03-SP2
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

## Use ECO_OPT_DB_PATH to specify search path to all db locations, if not already in your search_path.
#  PT needs to read db.
if {$ROUTE_OPT_ECO_OPT_DB_PATH != ""} { 
	lappend search_path $ROUTE_OPT_ECO_OPT_DB_PATH
}

################################################
## Set PT options
################################################
#  Use "set_pt_options -help" to check all the available options of set_pt_options
#  set_host_options example:
#	set_host_options -name eco_opt_host_option -submit_command "/lsf/bin/bsub -R \"rusage\[mem=$MEM\]"
#	set_pt_options -host_option eco_opt_host_option 
set set_pt_options_cmd "set_pt_options -pt_exec $ROUTE_OPT_ECO_OPT_PT_PATH"

if {$ROUTE_OPT_ECO_OPT_WORK_DIR != ""} {lappend set_pt_options_cmd -work_dir $ROUTE_OPT_ECO_OPT_WORK_DIR}

if {[file exists [which $ROUTE_OPT_ECO_OPT_PRE_LINK_SCRIPT]]} {
	lappend set_pt_options_cmd -pre_link_script $ROUTE_OPT_ECO_OPT_PRE_LINK_SCRIPT
} elseif {$ROUTE_OPT_ECO_OPT_PRE_LINK_SCRIPT != ""} {
	puts "RM-error: ROUTE_OPT_ECO_OPT_PRE_LINK_SCRIPT($ROUTE_OPT_ECO_OPT_PRE_LINK_SCRIPT) is invalid. Please correct it."
}

if {[file exists [which $ROUTE_OPT_ECO_OPT_POST_LINK_SCRIPT]]} {
	lappend set_pt_options_cmd -post_link_script $ROUTE_OPT_ECO_OPT_POST_LINK_SCRIPT
} elseif {$ROUTE_OPT_ECO_OPT_POST_LINK_SCRIPT != ""} {
	puts "RM-error: ROUTE_OPT_ECO_OPT_POST_LINK_SCRIPT($ROUTE_OPT_ECO_OPT_POST_LINK_SCRIPT) is invalid. Please correct it."
}

puts "RM-info: Running $set_pt_options_cmd"
eval $set_pt_options_cmd
redirect -tee -file ${REPORTS_DIR}/${ROUTE_OPT_BLOCK_NAME}.report_pt_options {report_pt_options}

################################################
## Enable StarRC in-design extraction (optional)
################################################
#  Config file is required to properly set up StarRC run
if {[file exists [which $ROUTE_OPT_ECO_OPT_STARRC_CONFIG_FILE]]} {
	set_app_options -name extract.starrc_mode -value true
	set_starrc_options -config $ROUTE_OPT_ECO_OPT_STARRC_CONFIG_FILE ;# example: route_opt.starrc_config_example.txt
	redirect -tee -file ${REPORTS_DIR}/${ROUTE_OPT_BLOCK_NAME}.report_starrc_options.rpt {report_starrc_options} 
} elseif {$ROUTE_OPT_ECO_OPT_STARRC_CONFIG_FILE != ""} {
	puts "RM-error: ROUTE_OPT_ECO_OPT_STARRC_CONFIG_FILE($ROUTE_OPT_ECO_OPT_STARRC_CONFIG_FILE) is invalid. Please correct it."
}

################################################
## Check and show PT QoR
################################################
#  Use "check_pt_qor -help" to check all the available options of check_pt_qor 
redirect -tee -file ${REPORTS_DIR}/${ROUTE_OPT_BLOCK_NAME}.check_pt_qor.pre.rpt {check_pt_qor}
redirect -tee -file ${REPORTS_DIR}/${ROUTE_OPT_BLOCK_NAME}.check_pt_qor.pre.summary.rpt {check_pt_qor -type summary}

################################################
## Perform PT-ECO
################################################
#  Use "eco_opt -help" to check all the available options of eco_opt 
set eco_opt_cmd "eco_opt"
if {$ROUTE_OPT_ECO_OPT_TYPE != ""} {lappend eco_opt_cmd -type $ROUTE_OPT_ECO_OPT_TYPE}
puts "RM-info: Running $eco_opt_cmd"
eval $eco_opt_cmd

################################################
## Check and show PT QoR
################################################
#  Use "check_pt_qor -help" to check all the available options of check_pt_qor 
redirect -tee -file ${REPORTS_DIR}/${ROUTE_OPT_BLOCK_NAME}.check_pt_qor.post.rpt {check_pt_qor}
redirect -tee -file ${REPORTS_DIR}/${ROUTE_OPT_BLOCK_NAME}.check_pt_qor.post.summary.rpt {check_pt_qor -type summary}

## Reset extract.starrc_mode when StarRC extraction is enabled for eco_opt but StarRC-in-design for route_opt is not enabled.
#  This is to avoid NEX-054 error message when this app option is left on after eco_opt but StarRC-in-design is not used.
if {[get_app_option_value -name extract.starrc_mode] && ![file exists [which $ROUTE_OPT_STARRC_CONFIG_FILE]]} {
	reset_app_options extract.starrc_mode
}

puts "RM-info: Completed script [info script]\n"
