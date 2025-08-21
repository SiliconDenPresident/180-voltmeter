puts "RM-info: Running script [info script]\n"

# The following is a parasitic setup file to be used with the ASCII input mode.
# To use it, set the TCL_PARASITIC_SETUP_FILE variable in icc2_common_setup.tcl
# to the path to this file. 
# Do not use this file if reading MCMM scenarios from
# ${DCRM_RESULTS_DIR}/ICC2_files/${DESIGN_NAME}.MCMM/top.tcl
# because that script already reads parasitics.

########################################
## Variables
########################################
## Parasitic tech files for read_parasitic_tech command; expand the section as needed
set parasitic1				"RCmax" ;# name of parasitic tech model 1
set tluplus_file($parasitic1)           "${TECH_HOME}/dk_synopsys/pdk-180/PnR/PR-000179_PDK_DAC-000542_1752848026487/gf180mcu_1p5m_1tm_11k_sp_smim_OPTB_tluplus/gf180mcu_1p5m_1tm_11k_sp_smim_OPTB_wst.TLUplus" ;# TLU+ files to read for parasitic 1
set layer_map_file($parasitic1)         "${TECH_HOME}/dk_synopsys/pdk-180/PnR/PR-000179_PDK_DAC-000542_1752848026487/gf180mcu_1p5m_1tm_11k_sp_smim_OPTB_tluplus/mdb2itf.map" ;# layer mapping file between ITF and tech for parasitic 1

set parasitic2				"RCmin" ;# name of parasitic tech model 2
set tluplus_file($parasitic2)           "${TECH_HOME}/dk_synopsys/pdk-180/PnR/PR-000179_PDK_DAC-000542_1752848026487/gf180mcu_1p5m_1tm_11k_sp_smim_OPTB_tluplus/gf180mcu_1p5m_1tm_11k_sp_smim_OPTB_bst.TLUplus" ;# TLU+ files to read for parasitic 2
set layer_map_file($parasitic2)         "${TECH_HOME}/dk_synopsys/pdk-180/PnR/PR-000179_PDK_DAC-000542_1752848026487/gf180mcu_1p5m_1tm_11k_sp_smim_OPTB_tluplus/mdb2itf.map" ;# layer mapping file between ITF and tech for parasitic 2

########################################
## Read parasitic files
########################################
## Read in the TLUPlus files first.
#  Later on in the corner constraints, you can then refer to these parasitic models.
foreach p [array name tluplus_file] {  
	puts "RM-info: read_parasitic_tech -tlup $tluplus_file($p) -layermap $layer_map_file($p) -name $p"
	read_parasitic_tech -tlup $tluplus_file($p) -layermap $layer_map_file($p) -name $p
}

puts "RM-info: Completed script [info script]\n"

