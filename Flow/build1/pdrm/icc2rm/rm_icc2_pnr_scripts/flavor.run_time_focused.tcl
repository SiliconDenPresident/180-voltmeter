puts "RM-info: Running script [info script]\n"

##########################################################################################
# Script: flavor.run_time_focused.tcl
# Version: P-2019.03-SP2
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

## A side file to override RM default flow settings for run time considerations

set_app_options -name opt.timing.effort -value medium ;# tool default low; set_qor_strategy default high

set_app_options -name opt.power.effort -value medium ;# tool default low; set_qor_strategy default high

set_app_options -name opt.common.use_route_aware_estimation -value false ;# tool default false; set_qor_strategy default true for >16nm

set_app_options -name place_opt.initial_drc.global_route_based -value false ;# tool default false; set_qor_strategy default true

set_app_options -name place_opt.final_place.effort -value medium ;# tool default medium; set_qor_strategy default high

set_app_options -name place_opt.place.congestion_effort -value medium ;# tool default medium; set_qor_strategy default high

set_app_options -name place.coarse.enhanced_low_power_effort -value none ;# tool default low; RM default low

set_app_options -name route_opt.flow.enable_ccd -value false ;# tool default false; RM default true

set CLOCK_OPT_GLOBAL_ROUTE_OPT		false ;# true|false; tool default false; RM default true; 
					;# enables Global Route Based Optimization by setting clock_opt.flow.enable_global_route_opt 
					;# and route_opt.flow.enable_power to true, sources routing settings, and runs clock_opt -from global_route_opt;
					;# this feature is added to route_auto.tcl; if enabled, it replaces route_global command

puts "RM-info: Completed script [info script]\n"
