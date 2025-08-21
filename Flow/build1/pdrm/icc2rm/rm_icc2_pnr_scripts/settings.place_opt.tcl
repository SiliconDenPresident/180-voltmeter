puts "RM-info: Running script [info script]\n"

##########################################################################################
# Tool: IC Compiler II
# Script: settings.place_opt.tcl 
# Version: P-2019.03-SP2
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

##########################################################################################
## Set QoR Strategy
##########################################################################################
## set_qor_strategy is a commmand which folds various settings of placement, optimization, timing, CTS, and routing, etc.
## - To query the target metric being set, use the "get_attribute [current_design] metric_target" command
## - Refer to templates/place_opt.set_qor_strategy.tcl if you plan to override settings applied by set_qor_strategy, which is 
##   a template that lists all settings to be set, then uncomment any setting you want to override, and uncomment the line below :
#	source -echo templates/place_opt.set_qor_strategy.tcl
set_qor_strategy -stage pnr -metric timing -report_only
set_qor_strategy -stage pnr -metric timing

## Prefix
if {$PLACE_OPT_USER_INSTANCE_NAME_PREFIX != ""} {
	set_app_options -name opt.common.user_instance_name_prefix -value $PLACE_OPT_USER_INSTANCE_NAME_PREFIX
	set_app_options -name cts.common.user_instance_name_prefix -value ${PLACE_OPT_USER_INSTANCE_NAME_PREFIX}_cts
}

##########################################################################################
## RM default settings
##########################################################################################
## Logic resturcturing (RM default on; requires Digital-AF license)
## Uses synthesis engine to improve area, power, and timing either standalone or in combinations
## RM default is area_timing for area and TNS. Tool default is none. Runs in place_opt and clock_opt final_opto.
## 	specify area for leakage-aware area improvement where leakage is a secondary costing factor;
## 	specify timing for timing improvement;
## 	specify power for both total power and area improvement; 
## 	specify timing_power for timing, total power, and area improvement
## Optionally set opt.common.advanced_logic_restructuring_wirelength_costing to medium or none if design is not routing challenging,
## to allow more flexibility in wirelength increase for more logic restructuring  
if {[check_license -quiet "Digital-AF"]} {
	puts "RM-info: Setting opt.common.advanced_logic_restructuring_mode to area_timing (tool default none)"
	set_app_options -name opt.common.advanced_logic_restructuring_mode -value area_timing ;# tool default none
}

##########################################################################################
## Optimization settings 
##########################################################################################
## Layer optimization in preroute flows (optional)
## - Enables automatic layer optimization that assigns long timing-critical nets to 
##   upper metal layers to improve timing; supported in place_opt final_opt stage rebuffering.
##   place_opt.flow.optimize_layers and clock_opt.flow.optimize_layers are both false by default
##	set_app_options -name place_opt.flow.optimize_layers -value true ;# tool default false
##	set_app_options -name clock_opt.flow.optimize_layers -value true ;# tool default false
## - Overlap bins: when the switch is enabled, layer bins can be overlapped;
##   This might help improve QoR when routing resouces is unbalanced.
##	set_app_options -name place_opt.flow.optimize_layers_overlap_bins -value true ;# tool default false
##	set_app_options -name clock_opt.flow.optimize_layers_overlap_bins -value true ;# tool default false

## CCD WNS effort level - controls CCD engine effort on setup WNS optimization (optional)
## Higher effort may sacrify TNS and power to achieve better WNS result. Applies to clock_opt final_opto and route_opt.
#	set_app_options -name ccd.fmax_optimization_effort -value low(default)|medium|high

## CCD timing effort - controls CCD engine effort on overall setup timing optimization (optional)
## Higher effort improves setup timing more at possible cost of power. Applies to clock_opt final_opto and route_opt.
#	set_app_options -name ccd.timing_effort -value low|medium(default)|high

## CCD hold control effort for hold critical designs (optional)
## Higher effort improves hold timing more but can reduce the improvement on setup timing
#	set_app_options -name ccd.hold_control_effort -value low(default)|medium|high|ultra

## ICG merging (RM default is true; optional to set it to false)
## When set to true, ICG merging (merge_clock_gates) runs internally inside place_opt as a first step in initial_place stage;
## In case of SPG flow, ICG merging happens as a first step in initial_opto phase
puts "RM-info: Setting place_opt.flow.merge_clock_gates to $PLACE_OPT_MERGE_ICGS (tool default true)"
set_app_options -name place_opt.flow.merge_clock_gates -value $PLACE_OPT_MERGE_ICGS

## NDR optimization in preroute (optional)
## Assigns long timing critical nets to NDR to improve timing 
puts "RM-info: Setting place_opt.flow.optimize_ndr to $PREROUTE_NDR_OPTIMIZATION (tool default false)"
set_app_options -name place_opt.flow.optimize_ndr -value $PREROUTE_NDR_OPTIMIZATION ;# tool default false 
puts "RM-info: Setting clock_opt.flow.optimize_ndr to $PREROUTE_NDR_OPTIMIZATION (tool default false)"
set_app_options -name clock_opt.flow.optimize_ndr -value $PREROUTE_NDR_OPTIMIZATION ;# tool default false

## Fanout constraint for data path optimization (optional)
## Optimization will try to ensure that data path cells do not drive cells more than the specified limit.
#	set_app_options -name opt.common.max_fanout -value 32 ;# tool default 40

## Repeatability settings
## Here are the recommeded settings to produce repeatable results with respect to multicore runs
## Refer to SolvNet #2724517 for complete details
## place_opt repeatability
#	set_app_options -name place_opt.flow.repeatability -value true ;# tool default true
## clock_opt repeatability (note: run time impact expected)
#	set_app_options -name clock_opt.flow.repeatability -value true ;# tool default false
## route_global repeatability
#	set_app_options -name route.global.deterministic -value on ;# tool default off

## DFT related : to disable DFT optimization step at each placement call (optional)
#	set_app_options -name opt.dft.optimize_scan_chain -value false ;# tool default true

## DFT related : enable the clock aware reorder/repartition engines to help the hold violations in the scan paths
## The recommendation is to use them during clock_opt or post CTS with hold scenarios enabled.
## May degrade scan chain wire length due to giving higher priority to the clock drive crossing reduction. 
## opt.dft.clock_aware_scan_reorder : if the reconnections are only expected within each scan chain  
## opt.dft.clock_aware_scan_repartition_reorder : if the reconnections are expected to be across scan chains; this is super set of the above  
#	set_app_options -name opt.dft.clock_aware_scan_reorder -value true ;# tool default false; for within each scan chain
#	set_app_options -name opt.dft.clock_aware_scan_repartition_reorder -value true ;# tool default false; for across scan chains

## DFT related : to prevent optimization from modifying the ports  (optional)
## Specify a list of cells, such as clock gen or customized logics, where existing ports should be preserved or new ports should not be punched.
## Useful if you do formal verification by modules.
if {$OPTIMIZATION_FREEZE_PORT_LIST != ""} {
	puts "RM-info: Setting opt.dft.hier_preservation to true (tool default false)"
	set_app_options -name opt.dft.hier_preservation -value true ;# honors hierarchy port preservation during dft optimization
	set_freeze_port -all [get_cells $OPTIMIZATION_FREEZE_PORT_LIST] ;# sets freeze_clock_ports and freeze_data_ports attributes on the specified cells
}

## Non-Clock NDR
if {[file exists [which $TCL_NON_CLOCK_NDR_RULES_FILE]]} {
	puts "RM-info: Sourcing [which $TCL_NON_CLOCK_NDR_RULES_FILE]"
	source $TCL_NON_CLOCK_NDR_RULES_FILE
} elseif {$TCL_NON_CLOCK_NDR_RULES_FILE != ""} {
	puts "RM-error: TCL_NON_CLOCK_NDR_RULES_FILE($TCL_NON_CLOCK_NDR_RULES_FILE) is invalid. Please correct it."
}

##########################################################################################
## Power related settings
##########################################################################################
## Multibit banking and debanking (optional)
## Banking (single bit and multibit to multibit sequential cells) takes effect during place_opt initial_opto.
## Debanking (multibit to lower width multibit and/or single bit sequential cells) takes effect during place_opt final_opto for TNS.
puts "RM-info: Setting place_opt.flow.enable_multibit_banking to $PLACE_OPT_MULTIBIT_BANKING (tool default false)" 
set_app_options -name place_opt.flow.enable_multibit_banking -value $PLACE_OPT_MULTIBIT_BANKING 
puts "RM-info: Setting place_opt.flow.enable_multibit_debanking to $PLACE_OPT_MULTIBIT_DEBANKING (tool default false)" 
set_app_options -name place_opt.flow.enable_multibit_debanking -value $PLACE_OPT_MULTIBIT_DEBANKING

## Set your threshold_voltage_group attributes. For example:
## 	define_user_attribute -type string -class lib_cell threshold_voltage_group
## 	set_attribute -quiet [get_lib_cells -quiet */*LVT] threshold_voltage_group LVt
## 	set_attribute -quiet [get_lib_cells -quiet */*RVT] threshold_voltage_group RVt
## 	set_attribute -quiet [get_lib_cells -quiet */*HVT] threshold_voltage_group HVt

## set_threshold_voltage_group_type is not persistent and should be defined in settings.non_persistent.tcl.*
## Listed here for your reference:
## 	set_threshold_voltage_group_type -type low_vt LVt
## 	set_threshold_voltage_group_type -type normal_vt RVt
## 	set_threshold_voltage_group_type -type high_vt HVt

## CTS power aware pruning (optional)
## Allows selection of repeater cells to also consider internal and leakage power in order to reduce dynamic 
## and also leakage power of the clock trees
puts "RM-info: Setting cts.common.power_aware_pruning to $PREROUTE_CTS_POWER_AWARE_PRUNING (tool default false)"
set_app_options -name cts.common.power_aware_pruning -value $PREROUTE_CTS_POWER_AWARE_PRUNING

## CTS low power techniques (optional)
## gate_relocation: sets cts.compile.power_opt_mode to gate_relocation to enable activity aware gate 
##                  relocation (moves cells with low input clock toggling rates closer to their drivers)
##      	    at the end of gate by gate clock tree synthesis;
## low_power_targets: sets cts.compile.power_opt_mode to low_power_targets for CTS to relax certain
##                    internal constraints and build clock trees with less area and power;
## all: sets cts.compile.power_opt_mode to all to enable both the above features 
if {$PREROUTE_CTS_LOW_POWER_TECHNIQUE != ""} {
	puts "RM-info: Setting cts.compile.power_opt_mode to $PREROUTE_CTS_LOW_POWER_TECHNIQUE (tool default none)"
	set_app_options -name cts.compile.power_opt_mode -value $PREROUTE_CTS_LOW_POWER_TECHNIQUE
}

##########################################################################################
## Placement and Congestion related settings: max density, max util, and automatic control
##########################################################################################
## You can explicitly control the placement max density and max utilization by following (optional)
## 1. Max density
##    - When this value is set, coarse placer attempts to limit local cell density to be less than the value
if {$PREROUTE_PLACEMENT_MAX_DENSITY != ""} {	
	puts "RM-info: Setting place.coarse.max_density to $PREROUTE_PLACEMENT_MAX_DENSITY"
	set_app_options -name place.coarse.max_density -value $PREROUTE_PLACEMENT_MAX_DENSITY
}
## 2. Max utilization
##    - Specifies the max design utilization after congestion driven padding (during congestion driven placement) is done
if {$PREROUTE_PLACEMENT_MAX_UTIL != ""} {
	puts "RM-info: Setting place.coarse.congestion_driven_max_util to $PREROUTE_PLACEMENT_MAX_UTIL" 
	set_app_options -name place.coarse.congestion_driven_max_util -value $PREROUTE_PLACEMENT_MAX_UTIL
}

## Automatic density control (tool default)
## - If you do not specify either of the above two settings and keep the tool defaults, the automatic density control,
##   which is enabled by tool default, selects the value for max density and max util based on the design stage
## - Message PLACE-027 is issued to report the chosen settings
puts "RM-info: Setting place.coarse.auto_density_control to $PREROUTE_PLACEMENT_AUTO_DENSITY (tool default true)"
set_app_options -name place.coarse.auto_density_control -value $PREROUTE_PLACEMENT_AUTO_DENSITY

## Enhanced automatic density control (optional)
## - Requires place.coarse.auto_density_control to be true otherwise no-op
## - Selects max density based on the design stage as well as design utilization
## - Selects max util based on the design stage as well as design tchnology
## - Potentially benefits design TNS
puts "RM-info: Setting place.coarse.enhanced_auto_density_control to $PREROUTE_PLACEMENT_ENHANCED_AUTO_DENSITY (tool default false)"
set_app_options -name place.coarse.enhanced_auto_density_control -value $PREROUTE_PLACEMENT_ENHANCED_AUTO_DENSITY

##########################################################################################
## Placement and Congestion related settings: other settigs
##########################################################################################
## DFT related: to continue the placement without SCANDEF (optional)
#	set_app_options -name place.coarse.continue_on_missing_scandef -value true
if {[get_scan_chains] == 0} {
	puts "RM-warning: No SCANDEF is found. If there are scan elements in the netlist, placement QoR may be degraded due to influence of the connections with scan elements."
        puts "RM-info: By default coarse placement will not proceed. If you wish to proceed knowing the consequences, set place.coarse.continue_on_missing_scandef to true."
}

## Target routing density for congestion-driven placement (optional)
## Tool default is 0 which allows the placer to make the decision.
if {$PREROUTE_PLACEMENT_TARGET_ROUTING_DENSITY != ""} {
	puts "RM-info: Setting place.coarse.target_routing_density to $PREROUTE_PLACEMENT_TARGET_ROUTING_DENSITY"
	set_app_options -name place.coarse.target_routing_density -value $PREROUTE_PLACEMENT_TARGET_ROUTING_DENSITY
}

## Pin density aware placement for preroute flows (optional)
## For designs with pin access and local density hot spot issues. 
puts "RM-info: Setting place.coarse.pin_density_aware to $PREROUTE_PLACEMENT_PIN_DENSITY_AWARE (tool default false)" 
set_app_options -name place.coarse.pin_density_aware -value $PREROUTE_PLACEMENT_PIN_DENSITY_AWARE

## Enable keep going legalizer to improve legalizer turn-around time (optional)
#	set_app_options -name place.legalize.limit_legality_checks -value true ;# tool default false

## Soft blockage enhancement : to prevent incremental coarse placer from moving cells out of soft blockages
#	set_app_options -name place.coarse.enable_enhanced_soft_blockages -value true

## Create soft bounds with effort level
## Tool default effort is ultra, which is useful for small groups of instances or around MV regions.
## For modules or large groups of cells, consider using medium effort.
##	create_bound -name abc -type soft -effort medium ...
##	set_attribute [get_bounds {abc} ] effort medium

## Uncomment below for designs with fishbone PG structure, to support PDC checking with EoL rule
##  and VIA enclosure for pin access point, uncomment to apply the following
#	set_app_options -name place.legalize.use_eol_spacing_for_access_check -value true ;# tool default false

## Specify congestion driven cell expansion direction to both (optional)
## When there is low-layer horizontal congestion associated with high pin-density, wide non-register cells in your design, 
## set this to both to improve congestion. A cell is consider wide when the aspect ratio of width to height is greater than 2:1.
#	set_app_option -name place.coarse.congestion_expansion_direction -value both ;# tool default horizonrtal

## Repeater path spreading (optional)
## For fragmented floorplans, in channels, enables coarse placement to perform cell spreading in areas dominated by long wires
## of repeaters around macro & blockage boundaries and corners, minimizing clumping and hugging on those areas.
#	 set_app_options -name place.coarse.spread_repeater_paths -value true ;# tool default false

## Congestion modeling : enable placer support for GR soft congestion map
## Placer uses GR congestion map to perform cell expansion to make room for more routing resources.
## By supporting soft congestion during cell expansion can help additional demaind during DR.
## Soft congestion can be contributed by external or internal soft routing rules.
## External is from create_routing_rule command. Internal is from GR modeling automatically.
#	set_app_options -name route.global.export_soft_congestion_maps -value true ;# tool default false

## ICG related: auto bound for ICG placement (optional)
## Can be enabled along with PLACE_OPT_OPTIMIZE_ICGS
puts "RM-info: Setting place.coarse.icg_auto_bound to $PLACE_OPT_ICG_AUTO_BOUND (tool default false)"
set_app_options -name place.coarse.icg_auto_bound -value $PLACE_OPT_ICG_AUTO_BOUND

## ICG related: clock-aware placement (optional)
## Redundant if PLACE_OPT_OPTIMIZE_ICGS is enabled since tool will enable this feature automatically.
puts "RM-info: Setting place_opt.flow.clock_aware_placement to $PLACE_OPT_CLOCK_AWARE_PLACEMENT (tool default false)"
set_app_options -name place_opt.flow.clock_aware_placement -value $PLACE_OPT_CLOCK_AWARE_PLACEMENT

##########################################################################################
## CTS settings
##########################################################################################
## CTS max transition and capacitance 
## Here are the examples :
##	foreach_in_collection m [get_modes] {
##		set_max_transition -clock_path 0.15 [get_clocks -mode $m] -scenarios [get_scenarios -mode $m]
##		set_max_capacitance -clock_path 0.5 [get_clocks -mode $m] -scenarios [get_scenarios -mode $m]
##	}

foreach_in_collection m [get_modes] {
  set_max_transition -clock_path 0.5 [get_clocks -mode $m] -scenarios [get_scenarios -mode $m]
}


## CTS target skew and latency 
## By default CTS targets best skew and latency. These options can be used in case user wants to relax the target.
##	Example : set_clock_tree_options -clocks [get_clocks clk -mode Mode1] -corner Corner1WC -target_latency 1 -target_skew 0.3

## CTS balance points 
## To modify the clock tree balancing requirements (for the current scenario)
##	Example: set_clock_balance_points -delay 2.0 -balance_point gck/CP ;# -clock option is not mandatory
## Correspondingly, you should also set clock latency accordingly for place_opt and compile (for the current scenario)
##	Example: set_clock_latency -2.0 gck/CP

## CTS skew groups 
## Create user-defined skew groups which usually are to improve timing
##	Example: 
##	foreach_in_collection m [get_modes] {
##		create_clock_skew_group -name [get_object_name ${m}]_grp1 -mode $m -objects "reg1/clk reg2/clk"
##	}

## CTS ICDB (Inter-clock delay balancing) constraints
## ICDB is performed automatically in build_clock phase of clock_opt
## Use create_clock_balance_group to control it. For ex,
##	foreach_in_collection m [get_modes] {
##		current_mode $m
##		create_clock_balance_group -objects {clk1 clk2} -name group1 -offset_latencies {0.0 -0.5}
##	}

## CTS Latency adjustments for compute_clock_latency
## For clock_opt non-CCD flow, compute_clock_latency is performed automatically in route_clock phase of clock_opt
## For clock_opt CCD flow, compute_clock_latency is performed automatically during both build_clock and route_clock phases.
## For place_opt with trial_clock or optimize_icgs enabled, compute_clock_latency is performed automatically during place_opt.
## However you have to use set_latency_adjustment_options to control it. For ex, to associate virtual clocks to real clocks :
##	foreach_in_collection m [get_modes] {
##		current_mode $m
##		set_latency_adjustment_options -reference_clock <real_clock> -clocks_to_update <virtual_clock>
##	}

## derive_clock_cell_references
## Check non-repeater cells on clock trees and suggest logically equivalent cells for CTS to use
##	derive_clock_cell_references -output refs.tcl
## Edit refs.tcl and source it

## CTS cell spacing 
## Apply placement based cell to cell spacing rule to avoid EM problem on P/G rails.
## This rule will be applied to the clock buffers/inverters, the clock gating cells only.
##	Example : set_clock_cell_spacing -x_spacing 0.9 -y_spacing 0.4 -lib_cells mylib/BUFFD2BWP

## CTS hierarchy preservation 
## To prevent CTS from punching new logical ports for logical hierarchies
##	Example : set_freeze_ports -clocks [get_cells {block1}]

## Apply root NDR on internal nets based on transitive fanout limit 
## This feature benefits if you have differnt NDR for root and internal nets while root NDR has better RC. 
## Specify a limit, for each internal net, if its downstream transitive fanout is
## - equal or greater than the limit, root NDR is applied
## - smaller than the limit, internal NDR is still applied
##	set_clock_tree_options -root_ndr_fanout_limit <integer> 

##########################################################################################
## Create clock NDR
##########################################################################################
## Specify TCL_CTS_NDR_RULE_FILE with your script to create and associate your clock NDR rules
## By default it is set to cts_ndr.tcl which is an RM provided example. 
## You can replace it with yours, or use it as a base to build yours.

## cts_ndr.tcl :
## 1. Can be used to create and associate clock NDR rules for root, internal, and leaf nets
## 2. Prerequisite: you need to also specify CTS_NDR_RULE_NAME, CTS_INTERNAL_NDR_RULE_NAME, or CTS_LEAF_NDR_RULE_NAME,
##    otherwise cts_ndr.tcl will be skipped.
##	- CTS_NDR_RULE_NAME: for root nets
##        CTS_INTERNAL_NDR_RULE_NAME: for internal nets
##		- Valid selections for both of them are:
##			- rm_2w2s: double width double spacing
##			- rm_2w2s_shield_default: double width double spacing with shield
##			- rm_2w2s_shield_list: double width double spacing with shield customized width and spacing
##	- CTS_LEAF_NDR_RULE_NAME: for leaf nets
##		- Valid selection is rm_leaf: default width and spacing
## 3. You can specify either or all of them, and the rule(s) will be created and associated.
##    If same rule is specified for both CTS_NDR_RULE_NAME and CTS_INTERNAL_NDR_RULE_NAME, rule creation for CTS_INTERNAL_NDR_RULE_NAME
##    will be skipped if already created. (rule association still happen for both root and internal nets)
if {[file exists [which $TCL_CTS_NDR_RULE_FILE]]} {
	source -echo $TCL_CTS_NDR_RULE_FILE
} elseif {$TCL_CTS_NDR_RULE_FILE != ""} {
	puts "RM-error: TCL_CTS_NDR_RULE_FILE($TCL_CTS_NDR_RULE_FILE) is invalid. Please correct it!"
}

##########################################################################################
## Reports
##########################################################################################
redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_routing_rules {report_routing_rules -verbose}
redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_clock_routing_rules {report_clock_routing_rules}
redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_clock_settings {report_clock_settings}

##########################################################################################
## Routing Settings
##########################################################################################
## Set max routing layer
if {$MAX_ROUTING_LAYER != ""} {set_ignored_layers -max_routing_layer $MAX_ROUTING_LAYER}
## Set min routing layer
if {$MIN_ROUTING_LAYER != ""} {set_ignored_layers -min_routing_layer $MIN_ROUTING_LAYER}
##########################################################################################
## Extraction Settings
##########################################################################################
## For better end of the flow correlation with StarRC, apply the following settings
## The ICC-II timing and run time may be impacted
#	set_extraction_options -include_pin_resistance
#	set_app_options -name extract.cut_loop -value false ;# tool default true

puts "RM-info: Completed script [info script]\n"
