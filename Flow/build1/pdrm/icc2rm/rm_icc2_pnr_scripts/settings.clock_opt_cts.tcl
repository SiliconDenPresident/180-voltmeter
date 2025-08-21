puts "RM-info: Running script [info script]\n"

##########################################################################################
# Tool: IC Compiler II
# Script: settings.clock_opt_cts.tcl 
# Version: P-2019.03-SP2
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

## For non-CCD flow, to improve local skew of timing critical register pairs,
## uncomment the following to enable local skew optimization during CTS and CTO:
#	set_app_options -name cts.compile.enable_local_skew -value true
#	set_app_options -name cts.optimize.enable_local_skew -value true

## For non-CCD flow, the clock SI prevention feature for minimizing the impact of SI from/on clock nets 
##  at postroute can be turned on by uncommenting the following application options:
#	set_app_options -name cts.optimize.enable_congestion_aware_ndr_promotion -value true

## Prefix
if {$CLOCK_OPT_CTS_USER_INSTANCE_NAME_PREFIX != ""} {
	set_app_options -name cts.common.user_instance_name_prefix -value $CLOCK_OPT_CTS_USER_INSTANCE_NAME_PREFIX
	set_app_options -name opt.common.user_instance_name_prefix -value ${CLOCK_OPT_CTS_USER_INSTANCE_NAME_PREFIX}_opt
}

puts "RM-info: Completed script [info script]\n"
