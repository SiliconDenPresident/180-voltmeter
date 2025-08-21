puts "RM-info: Running script [info script]\n"

##########################################################################################
# Tool: IC Compiler II
# Script: settings.clock_opt_opto.tcl 
# Version: P-2019.03-SP2
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

## Prefix
if {$PLACE_OPT_USER_INSTANCE_NAME_PREFIX != ""} {
	set_app_options -name opt.common.user_instance_name_prefix -value $CLOCK_OPT_OPTO_USER_INSTANCE_NAME_PREFIX
	set_app_options -name cts.common.user_instance_name_prefix -value ${CLOCK_OPT_OPTO_USER_INSTANCE_NAME_PREFIX}_cts
}

puts "RM-info: Completed script [info script]\n"
