puts "RM-info: Running script [info script]\n"

# The following is an MCMM scenarios setup file to be used 
# with the ASCII input mode.  To use it, set the TCL_MCMM_SETUP_FILE
# variable in icc2_common_setup.tcl to the path to this file. 
# Make sure to also set the TCL_PARASITIC_SETUP_FILE variable as well.
#
# This file is not currently used.  Instead, MCMM scenarios are read
# from ${DCRM_RESULTS_DIR}/ICC2_files/${DESIGN_NAME}.MCMM/top.tcl
# although we need to make some hacks to enable dynamic power analysis.
# In the future, it's probably better to define our own scenarios.
# To do that, however, we need to find a convenient way to read the
# constraints, since the format is slightly different between DC and ICC2,
# and it's a pain to have to specify them twice.
# 9/25/2019 Rhett Davis

remove_modes -all; remove_corners -all; remove_scenarios -all

create_mode mode_norm
create_corner slow
create_corner fast

create_scenario -name mode_norm.slow.RCmax -mode mode_norm -corner slow
set_parasitic_parameters -corners slow -early_spec RCmax -late_spec RCmax
source "${DESIGN_NAME}.constraints.tcl"
set_scenario_status mode_norm.slow.RCmax -setup true -hold false -leakage_power false 

create_scenario -name mode_norm.fast.RCmin -mode mode_norm -corner fast
set_parasitic_parameters -corners fast -early_spec RCmin -late_spec RCmin
source "${DESIGN_NAME}.constraints.tcl"
set_scenario_status mode_norm.fast.RCmin -setup true -hold true -leakage_power true -dynamic_power true



# Below are just examples to show usage of set_scenario_status (actual usage shold depend on your objective)
# scenario1 is a setup scenario and scenario2 is a hold scenario
#set_scenario_status $scenario1 -none -setup true -hold false -leakage_power true -dynamic_power true -max_transition true -max_capacitance true -min_capacitance false -active true
#set_scenario_status $scenario2 -none -setup false -hold true -leakage_power true -dynamic_power false -max_transition true -max_capacitance false -min_capacitance true -active true

#redirect -file ${REPORTS_DIR}/${INIT_DESIGN_BLOCK_NAME}.report_scenarios.rpt {report_scenarios} 

puts "RM-info : Completed script [info script]\n"
