##########################################################################################
# Tool: IC Compiler II
# Script: summary.tcl
# Version: P-2019.03-SP2
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_pnr_setup.tcl 

####################################
## Summary Report
####################################			 
if {$REPORT_QOR} {
	set REPORT_PREFIX summary
	puts "RM-info: Sourcing [which print_results.tcl]"
	source print_results.tcl
        print_results -tns_sig_digits 2 -outfile ${REPORTS_DIR}/${REPORT_PREFIX}.rpt
	## Specify -tns_sig_digits N to display N digits for the TNS results in the report. Default is 0
}

print_message_info -ids * -summary
echo [date] > summary

exit 

