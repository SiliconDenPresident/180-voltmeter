source -echo -verbose ./rm_setup/dc_setup.tcl

# Design Compiler must be run in topographical mode for MCMM flow support
# MCMM also requires a license for Design Compiler Graphical
if {![shell_is_in_topographical_mode]} {
  puts "RM-Error: dc_shell must be run in topographical mode for MCMM support."
  exit 1
}

read_file -format ddc "results/counter.mapped.ddc"

#################################################################################
# Set Up the Multicorner Multimode (MCMM) Scenarios
#
# Note: The MCMM flow is only supported in topographical mode and it requires
#       a license for Design Compiler Graphical. 
#################################################################################

# Use the dc.mcmm.scenarios.tcl example file as as reference for
# what should be included in the ${DCRM_MCMM_SCENARIOS_SETUP_FILE}

puts "RM-Info: Sourcing script file [which ${DCRM_MCMM_SCENARIOS_SETUP_FILE}]\n"
source -echo -verbose ${DCRM_MCMM_SCENARIOS_SETUP_FILE}

#################################################################################
# Create Default Path Groups
#
# Separating these paths can help improve optimization.
# Remove these path group settings if user path groups have already been defined.
#################################################################################

set current_scenario_saved [current_scenario]
foreach scenario [all_active_scenarios] {
  current_scenario ${scenario}
  set ports_clock_root [filter_collection [get_attribute [get_clocks] sources] object_class==port]
  group_path -name REGOUT -to [all_outputs] 
  group_path -name REGIN -from [remove_from_collection [all_inputs] ${ports_clock_root}] 
  group_path -name FEEDTHROUGH -from [remove_from_collection [all_inputs] ${ports_clock_root}] -to [all_outputs]
}
current_scenario ${current_scenario_saved}
