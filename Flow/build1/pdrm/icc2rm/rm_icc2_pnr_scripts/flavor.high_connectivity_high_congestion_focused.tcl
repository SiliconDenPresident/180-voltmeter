puts "RM-info: Running script [info script]\n"

##########################################################################################
# Script: flavor.high_connectivity_high_congestion_focused.tcl
# Version: P-2019.03-SP2
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

## A side file to override RM default flow settings for high connectivity and high congestion design styles.

set_app_options -name place.coarse.cong_restruct_effort -value ultra ;# tool default medium; RM default medium

set_app_options -name cts.compile.enable_global_route -value true ;# tool default false; RM default false

set_app_options -name clock_opt.place.effort -value high ;# tool default medium; RM default medium

puts "RM-info: Completed script [info script]\n"
