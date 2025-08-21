##########################################################################################
# Tool: IC Compiler II
# Script: redhawk_in_design_pnr.tcl
# Version: P-2019.03-SP2
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_pnr_setup.tcl

open_lib $DESIGN_LIBRARY
open_block $REDHAWK_IN_DESIGN_PNR_FROM_BLOCK_NAME
current_block $REDHAWK_IN_DESIGN_PNR_FROM_BLOCK_NAME
link_block

if {![check_license -quiet "SNPS_INDESIGN_RH_RAIL"]} {
        puts "RM-error: Unable to find SNPS_INDESIGN_RH_RAIL license. Exiting...."
        exit 
}

if {$REDHAWK_SEARCH_PATH == "" || ![check_license -quiet "SNPS_INDESIGN_RH_RAIL"]} {
        puts "RM-error: Unable to find NDM data search path. Exiting...."
        exit 
}

if {[which $REDHAWK_DIR/redhawk] == "" } {
        puts "RM-error: Unable to find redhawk at \"$REDHAWK_DIR\". Exiting...."
	exit 
} else {
	puts "RM-info: Setting rail.redhawk_path to $REDHAWK_DIR"
	set_app_options -name rail.redhawk_path -value $REDHAWK_DIR
}

if {[which $REDHAWK_TECH_FILE] == ""} {
        puts "RM-error: Unable to find redhawk tech file at \"$REDHAWK_TECH_FILE\".  Exiting...."
	exit 
} else {
	puts "RM-info: Setting rail.tech_file to $REDHAWK_TECH_FILE"
	set_app_options -name rail.tech_file -value $REDHAWK_TECH_FILE
}

if {$REDHAWK_LIB_FILES == ""} {
        puts "RM-error: No .lib files are provided.  Exiting...."
	exit 
} else {
	puts "RM-info: Setting rail.lib_files to $REDHAWK_LIB_FILES"
	set_app_options -name rail.lib_files -value $REDHAWK_LIB_FILES
}


if {$REDHAWK_APL_FILES == "" && ($REDHAWK_ANALYSIS == "dynamic_vectorless" || $REDHAWK_ANALYSIS == "dynamic_vcd")} {
        puts "RM-error: No APL files provided for the dynamic analysis.  Exiting...."
        exit 
} else {
        puts "RM-info: Setting rail.apl_files to $REDHAWK_APL_FILES"
        set_app_options -name rail.apl_files -value $REDHAWK_APL_FILES
}

set_app_options -name rail.enable_redhawk -value true

if {[file exists [which $REDHAWK_PAD_FILE]]} {
        create_taps -import $REDHAWK_PAD_FILE
} else {
        create_taps -top_pg
}

if {$REDHAWK_MACROS != ""} {
        set_app_options -name rail.macro_models -value $REDHAWK_MACROS
}




if {$REDHAWK_SWITCH_MODEL_FILES != ""} {
        set_app_options -name rail.switch_model_files -value $REDHAWK_SWITCH_MODEL_FILES
}

set_missing_via_check_options -exclude_stack_via -threshold -1

set_app_options -name rail.database -value $REDHAWK_RAIL_DATABASE

if {$REDHAWK_MISSING_VIA_POS_THRESHOLD != ""} {

	set_missing_via_check_options -exclude_stack_via -threshold $REDHAWK_MISSING_VIA_POS_THRESHOLD
}

if {$REDHAWK_EXTRA_GSR == ""} {
        exec touch extra.gsr
        set REDHAWK_EXTRA_GSR "extra.gsr"
}

if {$REDHAWK_SCRIPT_FILE == ""} {
        if {$REDHAWK_SWITCHING_ACTIVITY_FILE == ""} {
		if {($REDHAWK_ANALYSIS == "static" || $REDHAWK_ANALYSIS == "dynamic_vcd" || $REDHAWK_ANALYSIS == "dynamic_vectorless") && !$REDHAWK_EM_ANALYSIS} {
                        analyze_rail -nets $REDHAWK_ANALYSIS_NETS -voltage_drop $REDHAWK_ANALYSIS -extra_gsr_option $REDHAWK_EXTRA_GSR
                } elseif {($REDHAWK_ANALYSIS == "static" || $REDHAWK_ANALYSIS == "dynamic_vcd" || $REDHAWK_ANALYSIS == "dynamic_vectorless") && $REDHAWK_EM_ANALYSIS} {
                        analyze_rail -nets $REDHAWK_ANALYSIS_NETS -voltage_drop $REDHAWK_ANALYSIS -electromigration  -extra_gsr_option $REDHAWK_EXTRA_GSR
                } elseif {$REDHAWK_ANALYSIS == "effective_resistance" } {
                        analyze_rail -nets $REDHAWK_ANALYSIS_NETS -effective_resistance -extra_gsr_option $REDHAWK_EXTRA_GSR
                } elseif {$REDHAWK_ANALYSIS == "min_path_resistance" } {
                        analyze_rail -nets $REDHAWK_ANALYSIS_NETS  -min_path_resistance -extra_gsr_option $REDHAWK_EXTRA_GSR
                } elseif {$REDHAWK_ANALYSIS == "check_missing_via" && $REDHAWK_MISSING_VIA_POS_THRESHOLD == ""} {
                        analyze_rail -nets $REDHAWK_ANALYSIS_NETS -check_missing_via -extra_gsr_option $REDHAWK_EXTRA_GSR
                } elseif {$REDHAWK_ANALYSIS == "check_missing_via" && $REDHAWK_MISSING_VIA_POS_THRESHOLD != ""} {
                        analyze_rail -nets $REDHAWK_ANALYSIS_NETS -voltage_drop static -check_missing_via -extra_gsr_option $REDHAWK_EXTRA_GSR
		} else {
                        puts "RM-error: Please enable at least one analysis"
			exit
                }
       } else {
		if {($REDHAWK_ANALYSIS == "static" || $REDHAWK_ANALYSIS == "dynamic_vcd" || $REDHAWK_ANALYSIS == "dynamic_vectorless") && !$REDHAWK_EM_ANALYSIS} {
                        analyze_rail -nets $REDHAWK_ANALYSIS_NETS -voltage_drop $REDHAWK_ANALYSIS -extra_gsr_option $REDHAWK_EXTRA_GSR -switching_activity $REDHAWK_SWITCHING_ACTIVITY_FILE
                } elseif {($REDHAWK_ANALYSIS == "static" || $REDHAWK_ANALYSIS == "dynamic_vcd" || $REDHAWK_ANALYSIS == "dynamic_vectorless") && $REDHAWK_EM_ANALYSIS} {
                        analyze_rail -nets $REDHAWK_ANALYSIS_NETS -voltage_drop $REDHAWK_ANALYSIS -electromigration  -extra_gsr_option $REDHAWK_EXTRA_GSR -switching_activity $REDHAWK_SWITCHING_ACTIVITY_FILE
                } elseif {$REDHAWK_ANALYSIS == "effective_resistance" } {
                        analyze_rail -nets $REDHAWK_ANALYSIS_NETS -effective_resistance -extra_gsr_option $REDHAWK_EXTRA_GSR
                } elseif {$REDHAWK_ANALYSIS == "min_path_resistance" } {
                         analyze_rail -nets $REDHAWK_ANALYSIS_NETS  -min_path_resistance -extra_gsr_option $REDHAWK_EXTRA_GSR
                } elseif {$REDHAWK_ANALYSIS == "check_missing_via" && $REDHAWK_MISSING_VIA_POS_THRESHOLD == ""} {
                        analyze_rail -nets $REDHAWK_ANALYSIS_NETS -check_missing_via -extra_gsr_option $REDHAWK_EXTRA_GSR
                } elseif {$REDHAWK_ANALYSIS == "check_missing_via" && $REDHAWK_MISSING_VIA_POS_THRESHOLD != ""} {
			analyze_rail -nets $REDHAWK_ANALYSIS_NETS -voltage_drop static -check_missing_via -extra_gsr_option $REDHAWK_EXTRA_GSR 
		} else {
                        puts "RM-error: Please enable at least one analysis"
			exit
                }
        }
} else {
        analyze_rail -redhawk_script_file $REDHAWK_SCRIPT_FILE
}




if {$REDHAWK_FIX_MISSING_VIAS} {
        foreach_in_collection err_file [get_drc_error_data -all *miss_via*] {
                set errdm [open_drc_error_data $err_file]
                set errs [get_drc_errors -error_data $errdm]
                fix_pg_missing_vias -error_data $errdm $errs
        }
}

if {$REDHAWK_ANALYSIS == "static" || $REDHAWK_ANALYSIS == "dynamic_vcd" || $REDHAWK_ANALYSIS == "dynamic_vectorless"} {
        report_rail_result -type effective_voltage  -supply_nets $REDHAWK_ANALYSIS_NETS $REDHAWK_OUTPUT_REPORT
}

if {$REDHAWK_EM_ANALYSIS && $REDHAWK_EM_REPORT != ""} {
        set fileName $REDHAWK_EM_REPORT
        set fd [open $fileName w]
        foreach_in_collection em_err_file [get_drc_error_data -all *em*] {
                set dm [open_drc_error_data $em_err_file]
                set all_errs [get_drc_errors -error_data $dm *]
                foreach_in_collection err $all_errs {
                        set info [get_attribute $err error_info];
                        puts $fd $info
                }
        }
        close $fd
}

if {$REDHAWK_ANALYSIS == "min_path_resistance"} {
        report_rail_result -type minimum_path_resistance  -supply_nets $REDHAWK_ANALYSIS_NETS $REDHAWK_OUTPUT_REPORT
}

if {$REDHAWK_ANALYSIS == "effective_resistance"} {
        report_rail_result -type effective_resistance  -supply_nets $REDHAWK_ANALYSIS_NETS $REDHAWK_OUTPUT_REPORT
}

if {$REDHAWK_ANALYSIS == "check_missing_via"} {
        report_rail_result -type missing_vias  -supply_nets $REDHAWK_ANALYSIS_NETS $REDHAWK_OUTPUT_REPORT
}

if {$REDHAWK_PGA_NODE != ""} {

	if {[which $REDHAWK_PGA_ICV_DIR/bin/LINUX.64/icv] == "" } {
        	puts "RM-error: Unable to find icv at \"$REDHAWK_PGA_ICV_DIR/bin/LINUX.64\". Exiting...."
        		exit 
	} else {
        	puts "RM-info: Setting ICV binary path"
		setenv ICV_HOME_DIR $REDHAWK_PGA_ICV_DIR
	        setenv ICV_INCLUDES [getenv ICV_HOME_DIR]/include/
        	setenv PATH [getenv ICV_HOME_DIR]/bin/LINUX.64:[getenv PATH]

	}

	# ---------------------------------------------------------------------------
	# QOR Reports Pre PGA
	# ---------------------------------------------------------------------------
	  set REPORTS_DIR ./reports
	  if [file exists reports] {
	    file delete -force reports
	  }
	  file mkdir reports
	  file mkdir reports/pre_pga
	  file mkdir reports/post_pga
	  set step pre_pga
	  redirect -file $REPORTS_DIR/${step}/qor.sum -tee { report_qor -summary -significant_digits 4 }
	  redirect -file $REPORTS_DIR/${step}/qor.rpt -tee { report_qor -scenario [all_scenarios] -significant_digits 4 }
	  redirect -file $REPORTS_DIR/${step}/check_route.rpt -tee { check_routes }


	# ---------------------------------------------------------------------------
	# Run Power Grid Augmentation
	# ---------------------------------------------------------------------------

	if {$REDHAWK_PGA_GROUND_NET == "" || $REDHAWK_PGA_POWER_NET == ""} {
	        puts "RM-error: Please specify one ground net and one power net for PGA.  Exiting...."
	        exit 
	} 

	copy_block -from $REDHAWK_IN_DESIGN_PNR_FROM_BLOCK_NAME -to ${REDHAWK_IN_DESIGN_PNR_FROM_BLOCK_NAME}_pga 
	current_block $DESIGN_LIBRARY:${REDHAWK_IN_DESIGN_PNR_FROM_BLOCK_NAME}_pga
	link

	set_app_option -name signoff.create_pg_augmentation.ground_net_name -value $REDHAWK_PGA_GROUND_NET 
	set_app_option -name signoff.create_pg_augmentation.power_net_name -value $REDHAWK_PGA_POWER_NET 

	signoff_create_pg_augmentation -node $REDHAWK_PGA_NODE -mode remove

	signoff_create_pg_augmentation -node $REDHAWK_PGA_NODE -mode add

	save_lib -all

	# ---------------------------------------------------------------------------
	# QOR Reports Post PGA
	# ---------------------------------------------------------------------------
	set REPORTS_DIR ./reports
	set step post_pga
	redirect -file $REPORTS_DIR/${step}/qor.sum -tee { report_qor -summary -significant_digits 4 }
	redirect -file $REPORTS_DIR/${step}/qor.rpt -tee { report_qor -scenario [all_scenarios] -significant_digits 4 }
	redirect -file $REPORTS_DIR/${step}/check_route.rpt -tee { check_routes }

}


## gui_close_window -all

print_message_info -ids * -summary
echo [date] > redhawk_in_design_pnr
exit

