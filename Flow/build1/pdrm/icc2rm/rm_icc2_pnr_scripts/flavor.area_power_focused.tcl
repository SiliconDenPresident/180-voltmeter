puts "RM-info: Running script [info script]\n"

##########################################################################################
# Script: flavor.area_power_focused.tcl
# Version: P-2019.03-SP2
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

## A side file to override RM default flow settings for area and power focused designs

set_app_options -name opt.area.effort -value ultra ;# tool default low; set_qor_strategy default high

set_app_options -name place_opt.initial_drc.global_route_based -value 0 ;# tool default 0; set_qor_strategy default 1

set_app_options -name place_opt.place.congestion_effort -value medium ;# tool default medium; set_qor_strategy default high

set_app_options -name cts.common.power_aware_pruning -value true ;# tool default false; RM default true

set_app_options -name clock_opt.flow.enable_clock_power_recovery -value power ;# tool default auto; RM default auto

set_app_options -name route_opt.flow.enable_clock_power_recovery -value power ;# tool default auto; RM default auto

puts "RM-info: Completed script [info script]\n"
