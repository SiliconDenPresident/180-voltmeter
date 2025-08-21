puts "RM-info: Running script [info script]\n"

##########################################################################################
# Tool: IC Compiler II
# Script: settings.route_opt.tcl 
# Version: P-2019.03-SP2
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

## Prefix
if {$ROUTE_OPT_USER_INSTANCE_NAME_PREFIX != ""} {
	set_app_options -name opt.common.user_instance_name_prefix -value $ROUTE_OPT_USER_INSTANCE_NAME_PREFIX
	set_app_options -name cts.common.user_instance_name_prefix -value ${ROUTE_OPT_USER_INSTANCE_NAME_PREFIX}_cts
}

## Enable route_opt CCD for the first route_opt
puts "RM-info: Setting route_opt.flow.enable_ccd to true for the first route_opt"
set_app_options -name route_opt.flow.enable_ccd -value true ;# tool default false

## Enable route_opt power optimization
## The type of power optimization depends on scenario setup (set_scenario_status)
puts "RM-info: Setting route_opt.flow.enable_power to true (tool default false)"
set_app_options -name route_opt.flow.enable_power -value true ;# tool default false

## AWP, and CCS receiver for route_opt
puts "RM-info: Setting time.delay_calc_waveform_analysis_mode to full_design"
set_app_options -name time.delay_calc_waveform_analysis_mode -value full_design ;# tool default disabled; enables AWP
puts "RM-info: Setting time.enable_ccs_rcv_cap to true"
set_app_options -name time.enable_ccs_rcv_cap -value true ;# tool default false; enables CCS receiver model

## CTS : Clock DRC fixing during route_opt
## Note: this feature affects both CCD and non-CCD route_opt
## - If CCD is enabled (route_opt.flow.enable_ccd = true), with auto (tool and RM default), route_opt will enable the feature.
##   Set ROUTE_OPT_CTO to "always_off" if you want it disabled. 
## - If CCD is not enabled, with auto (tool and RM default), route_opt will not enable the feature.
##   Set ROUTE_OPT_CTO to "always_on" if you want to enable the feature.
puts "RM-info: Setting route_opt.flow.enable_ccd_clock_drc_fixing to $ROUTE_OPT_CTO (tool default auto)"
set_app_options -name route_opt.flow.enable_ccd_clock_drc_fixing -value $ROUTE_OPT_CTO ;# tool default auto

## ECO route : spreading
## To disable soft-rule-based timing optimization during ECO routing, uncomment the following.
#  This is to limit spreading which can impact convergence by touching multiple routes.
#	set_app_options -name route.detail.eco_route_use_soft_spacing_for_timing_optimization -value false

## Incremental reshielding 
if {$ROUTE_AUTO_CREATE_SHIELDS != "none" && $ROUTE_OPT_RESHIELD == "incremental"} {
	puts "RM-info: Setting route.common.reshield_modified_nets to reshield (tool default off)"
	set_app_options -name route.common.reshield_modified_nets -value reshield
}

## To disable soft-rule-based timing optimization during ECO routing, uncomment the following.
## This is to limit spreading which can touch multiple routes and impact convergence.
#	set_app_options -name route.detail.eco_route_use_soft_spacing_for_timing_optimization -value false

puts "RM-info: Completed script [info script]\n"
