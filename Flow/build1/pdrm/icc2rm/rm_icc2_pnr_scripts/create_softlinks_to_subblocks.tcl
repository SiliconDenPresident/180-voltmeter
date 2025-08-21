##########################################################################################
# Tool: IC Compiler II
# Script: create_softlinks_to_subblocks.tcl
# Version: P-2019.03-SP2
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

	## For top or intermediate level of hier designs, create soft-links to sub-blocks present in ICC2 PNR release area,

	foreach BLOCK $SUB_BLOCK_REFS {
		if {![file exists ./${BLOCK}${LIBRARY_SUFFIX}]} {
			if {[file exists ${RELEASE_DIR_PNR}/${BLOCK}${LIBRARY_SUFFIX}]} {
				puts "RM-info: Creating soft-link to ${RELEASE_DIR_PNR}/${BLOCK}${LIBRARY_SUFFIX} in ./"
				sh ln -s ${RELEASE_DIR_PNR}/${BLOCK}${LIBRARY_SUFFIX}
			} else {
				puts "RM-error: Creating soft-link to ${RELEASE_DIR_PNR}/${BLOCK}${LIBRARY_SUFFIX} in ./ but it doesn't exist. Exiting"
				exit 
			}
		} else {
			puts "RM-error: Creating soft-link to ${BLOCK}${LIBRARY_SUFFIX} in ./ but it already exists. Please correct it. Exiting"
			exit 
		}
	}

