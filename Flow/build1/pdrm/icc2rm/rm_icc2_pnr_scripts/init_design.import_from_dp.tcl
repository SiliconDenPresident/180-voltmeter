puts "RM-info: Running script [info script]\n"

##########################################################################################
# Tool: IC Compiler II
# Script: init_design.import_from_dp.tcl
# Version: P-2019.03-SP2
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

## Copy design library from ICC2 DP RM release area

if {![file exists ./${DESIGN_LIBRARY}]} {
	if {[file exists ${RELEASE_DIR_DP}/${DESIGN_LIBRARY}]} {
		puts "RM-info: Copying ${RELEASE_DIR_DP}/${DESIGN_LIBRARY} to ./"
		file copy ${RELEASE_DIR_DP}/${DESIGN_LIBRARY} ./
	} else {
		puts "RM-error: Copying ${RELEASE_DIR_DP}/${DESIGN_LIBRARY} to ./ but it doesn't exist. Exiting"
	}
} else {
	puts "RM-error: Copying ${DESIGN_LIBRARY} to ./ but it already exists. Please correct it. Exiting"
}	
puts "RM-info: Completed script [info script]\n"
