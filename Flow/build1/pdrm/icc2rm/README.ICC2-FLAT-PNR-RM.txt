###############################################################################
# Synopsys(R) IC Compiler(TM) II Flat Place and Route Reference Methodology
# Version: P-2019.03-SP2
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
###############################################################################

Overview
========
A reference methodology (RM) provides a set of reference scripts that serve 
as a good starting point for running a tool. These scripts are not designed 
to run in their current form. You should use them as a reference and adapt 
them for use in your design environment.

This RM can optionally be run directly in LYNX.
See ./rm_in_lynx/README.running_RM_in_Lynx_RTM.txt for more details.

Features
========
* Supports UPF-prime and golden UPF flows
* Supports advanced node designs with settings specific to the established nodes:
  20nm, 16nm, 14nm, 10nm, 8nm, 7nm, and 7nm+
* Supports Design Compiler to the IC Compiler II ASCII and physical guidance flows
* Supports design library hand-off from the ICC2-DP-RM
* Supports the multicorner-multimode flow 
* Supports advanced on-chip variation (AOCV) and parametric on-chip variation 
  (POCV)
* Identifies settings specific to power, performance, and area-focused (PPA) 
  flows in the generated scripts
* Supports low-power placement, leakage-power optimizations, total-power 
  optimizations, multibit banking, and multibit debanking
* Includes integrated clock-gating (ICG) optimization features in place_opt
* Includes concurrent clock and data optimization (CCD) for preroute and 
  postroute optimizations
* Supports nondefault clock routing rules, such as double spacing, double 
  width, and shielding
* Supports clock tree optimization after clock routing and after signal routing
* Includes antenna fixing, redundant via insertion, shielding, and 
  crosstalk reduction
* Includes signal electromigration analysis and fixing
* Includes metal and non-metal filler cell insertion
* Includes IC Validator In-Design signoff design rule checking and automatic 
  design rule fixing
* Includes IC Validator In-Design pattern-based or track-based metal fill 
  insertion
* Includes a consolidated reporting step at the end of each stage
* Includes a write_data step to write out Verilog, UPF, DEF, Tcl, SPEF, 
  GDSII, and OASIS files
* Supports PrimeTime ECO using either the non-freeze-silicon flow with minimum 
  physical impact mode or the freeze-silicon flow
* Supports the Galaxy incremental ECO flow
* Supports Formality formal verification
* Supports RedHawk Fusion Flows.
* Supports Verification Compiler low power static signoff analysis
* Supports three alterative flavors: 
   -  High-connectivity and congestion focused
   -  Area and power reduction focused
   -  Run time focused
* Supports design fusion, which performs logic restructuring using the synthesis engine to improve area, 
  power, and timing
* Supports ECO fusion, which blends IC Compiler II, StarRC, and PrimeTime features in a single native 
  invocation system 

Instructions for Using the IC Compiler II Flat Reference Methodology
====================================================================
To run the standard reference methodology flow, use the following command:

   % make -f rm_setup/Makefile_pnr all

You can replace "all" with any other step, such as place_opt or clock_opt_cts,
in the Makefile_pnr file.

Available flows
===============
* For the Technology Node option in RMgen, you can select Established Nodes 
  (default), 20nm, 16nm, 14nm, 12nm, 10nm, or 7nm. The flat RM scripts are configured 
  to enable the settings corresponding to the selected technology node.

  When you select the 16nm, 12nm, 10nm, or 7nm node, a "Foundry" option appears asking 
  you to specify the foundry name. In addition, due to NDA restrictions, the 
  settings specific to these technology nodes are included in separate files
  (called side files), which are not available in the RMgen script you 
  download from SolvNet. You can contact your Synopsys support team for 
  these side files.

  After you obtain these files from the support team, copy these files to the 
  same rm_icc2_pnr_scripts directory which was downloaded from the SolvNet 
  RMgen page and extracted earlier, and then the corresponding implementation 
  script will source them.

  Also when you select the 16nm, 12nm, or 7nm node, after the "Foundry" option appears,
  and if you specify the foundry name, Synopsys Logic Libraries option appears. 
  When you select TRUE for this option, the download scripts will be configured for 
  Synopsys logic libraries.

* In the N-2017.09 (or earlier) releases, you select the optimization flow by 
  setting the OPTIMIZATION_FLOW variable in the icc2_pnr_setp.tcl script.

  Starting with the N-2017.09-SP2 release, RM now provides the optimization 
  flow as one single default flow with a good balance of power, performance, and 
  area QoR. No more differences in the command variations and no more optimization
  flow selections. 

  However you can still choose to enable three additional flavors of the flow.
  They each follow the same command set as the RM default flow.
  Only differences are in some of the application option settings.
  Three such flavor side files are provided, which are:
  - flavor.high_connectivity_high_congestion_focused.tcl for high connectivity and high congestion
    design styles
  - flavor.area_power_focused.tcl for area reduction focused design styles
  - flavor.run_time_focused.tcl for run time focused design styles
  These flavor side files are optional. They are provided as part of the RM.
  
  They can be enabled by the ADDITIONAL_FLAVOR Tcl variable (located in icc2_pnr_setup.tcl)
  - Default is unspecified; if unspecified, runs the RM default flow that balances performance, power, and area (PPA)
  - Set it to high_connectivity_high_congestion for high connectivity design styles with heavy congestions.
    Set it to area_power for extra area and power optimizations.
    Set it to run_time if run time is the primary concern  

Flow Steps
==========
The IC Compiler II Flat Reference Methodology flow includes the following 
steps (see the makefile: rm_setup/Makefile_pnr):

The following list includes the default steps with brief descriptions:
* init_design 
  Data preparation. Reads design inputs. Creates the design. Floorplanning. 
 
* place_opt
  Placement and optimization.
  Concurrent clock and data (CCD) optimization is on-by-default.
 
* clock_opt_cts
  Clock tree synthesis and clock routing.
  Concurrent clock and data (CCD) optimization is on-by-default, which performs
  CCD clock tree synthesis.
 
* clock_opt_opto
  Data path optimization based on propagated clock latencies and clock 
  route patching.
  Concurrent clock and data (CCD) optimization is on-by-default.
  
* route_auto
  Global route optimization or global routing, track assignment, detail routing for signal nets, and 
  shield creation.
  
* route_opt
  Postroute optimization and ECO fusion.
  Concurrent clock and data (CCD) optimization is on-by-default.
  
* chip_finish
  Decouping capacitance cell insertion, regular filler cell insertion, 
  and signal electromigration analysis and fixing.
  
* icv_in_design
  Signoff design rule checking, automatic design rule fixing, and metal 
  fill creation with IC Validator In-Design.
  
* (Optional) write_data
  Runs the change_names command and writes out Verilog, DEF, GDSII, OASIS, 
  UPF, UPF supplemental file, write_script, and parasitics output, with write_data.tcl

* (Optional) redhawk_in_design
  RedHawk Fusion flows with the
  redhawk_in_design_pnr.tcl

* (Optional) fm
  Formality formal verification with the fm.tcl script.

* (Optional) vc_lp
  Verification Compiler low-power static signoff analysis with the 
  vc_lp.tcl script.

* (Optional) pt_eco
  Freeze-silicon or non-freeze-silicon PrimeTime ECO flow.

* (Optional) pt_eco_incremental_1 and pt_eco_incremental_2
  pt_eco_incremental_1 initializes the Galaxy incremental ECO flow.
  pt_eco_incremental_2 runs the Galaxy incremental ECO flow.

* (Optional) summary
  Summary report (in the table format) for all the steps across the flow,
  with summary.tcl

Files Included With the IC Compiler II Flat Reference Methodology
=================================================================
## Makefile and setup scripts are all in the rm_setup

* rm_setup/Makefile_pnr
  Makefile for running the IC Compiler II Flat Place and Route Reference 
  Methodology scripts

* rm_setup/icc2_pnr_setp.tcl
  Variables for running and controlling the IC Compiler II Flat Place and
  Route Reference Methodology, such as REPORT_QOR, and REPORTS_DIR.

* rm_setup/icc2_common_setup.tcl          
  It includes the following two types of variables:

     - Variables specific to design input. These variables are shared 
       by all IC Compiler II Reference Methodology scripts, such as 
       TECH_FILE, REFERENCE_LIBRARY, and VERILOG_NETLIST_FILE
  
     - Cross-flow control variables, such as PHYSICAL_HIERARCHY_LEVEL or 
       RELEASE_DIR_DP. The first is used by the hierarchical place and 
       route flow; the latter is used by the design planning, flat place
       and route, and hierarchical place and route flows.

## Implementation scripts are all in the rm_icc2_pnr_scripts directory

* For the init_design step: rm_icc2_pnr_scripts/init_design.tcl

  This script reads or creates the design, depending on the setting of 
  INIT_DESIGN_INPUT.

     - If INIT_DESIGN_INPUT is set to DP_RM_NDM, the RM script 
       sources init_design.from_dp_rm_ndm.tcl to read 
       the handoff design library from ICC2-DP-RM, 
       and sources init_design.from_dp_rm_ndm.tcl

     - If INIT_DESIGN_INPUT is set to DC_ASCII, the RM script sources 
       init_design.from_dc_ascii.tcl to create 
       the design library, sources the script generated by the 
       write_icc2_scripts command in Design Compiler, re-creates the 
       design, and then commits the UPF. 
 
     - If INIT_DESIGN_INPUT is set to ASCII, the RM script 
       sources init_design.from_ascii.tcl to creates the 
       design library, reads the Verilog netlist, loads the UPF file, 
       commits the UPF, sources your multicorner-multimode script 
       (templates provided by the RM), sets the routing direction and 
       site information, reads or creates floorplan, and reads the 
       SCANDEF file.

  Afterwards, regardless of the INIT_DESIGN_INPUT setting, the RM script 
  reads the POCV files or AOCV tables, removes the propagated 
  clocks, insert boundary cells, sources your multivoltage-related scripts,
  insert tap cells, and performs zero-interconnect reporting.

* For the place_opt step: rm_icc2_pnr_scripts/place_opt.tcl

  This script runs the place_opt, CCD, and the route_global 
  command for generating the congestion map, and performs reporting. 

  The place_opt flow in place_opt.tcl has dependency on which flow you are in, 
  and whether you enable physical guidance. For details, see the
  place_opt.tcl script and the training slides.

  It sources the settings.place_opt.tcl for common optimization, placement, legalization, CTS, 
  routing, and timing settings.

* For the clock_opt_cts step: rm_icc2_pnr_scripts/clock_opt_cts.tcl

  This script performs CCD clock tree synthesis, routing, and reporting. 

  It sources the settings.clock_opt_cts.tcl for settings that are specific to the clock_opt command, such as 
  global-route-based CTS and concurrent clock and data (CCD) optimization. 

* For the clock_opt_opto step: rm_icc2_pnr_scripts/clock_opt_opto.tcl

  This script runs the clock_opt -from final_opto command which performs CCD optimizations.

* For the route_auto step: rm_icc2_pnr_scripts/route_auto.tcl

  This script runs the route_global command for global route, 
  the route_track command for track assignment, and the route_detail command for detail routing 
  of signal nets.

  Optionally, you can enable clock_opt -from global_route_opt command for global route optimization which replaces
  route_global by setting CLOCK_OPT_GLOBAL_ROUTE_OPT to true. You can also set ROUTE_AUTO_USE_SINGLE_COMMAND to true
  to run route_auto to replace the standalone route_global, route_track, and route_detail.

  It sources the settings.route_auto.tcl script, which includes the
  settings specific to route_auto such as redundant via insertion settings.

* For the route_opt step: rm_icc2_pnr_scripts/route_opt.tcl

  This script runs three consecutive route_opt commands for postroute optimization, 
  postroute CCD, and postroute clock tree optimization. 
  The first route_opt is with CCD. The second route_opt is without CCD. The last route_opt 
  is size-only.
  Optionally, you can run the eco_fusion command as the replacement of the last route_opt command. 

  It sources the settings.route_opt.tcl script to set the related 
  settings and constraints.  

* For the chip_finish step: rm_icc2_pnr_scripts/chip_finish.tcl

  This script runs the create_stdcell_fillers command for metal and non-metal 
  filler cell insertion; it also runs signal electromigration analysis and fixing. 

* For the icv_in_design step: rm_icc2_pnr_scripts/icv_in_design.tcl

  This script runs the IC Validator In-Design signoff_check_drc command for 
  design rule checking, the signoff_fix_drc command for automatic design rule fixing,
  and the signoff_create_metal_fill command for metal fill creation.

* For the write_data step: rm_icc2_pnr_scripts/write_data.tcl

  This script generates output files for the design. It runs the 
  write_verilog, save_upf, write_def, write_script, write_parasitics, write_routing_scripts,
  write_gds, and write_gds commands.

* For the eco_opt step: rm_icc2_pnr_scripts/eco_opt.tcl

  If ECO_OPT_PT_PATH (PT path) is specified, the script runs the following commands:
   - set_pt_options to set PrimeTime options
   - report_pt_options to report PrimeTime options 
   - set_starrc_options to set StarRC configurations (optional)
   - check_pt_qor to check PrimeTime timing before running the eco_opt command
   - eco_opt on specified metrics 
   - check_pt_qor afterwards to check PrimeTime timing after the eco_opt command

* For the pt_eco step: rm_icc2_pnr_scripts/pt_eco.tcl

  For the non-freeze-silicon flow, the script sources the
  PrimeTime ECO change file and runs the place_eco_cells command in the 
  minimum-physical-impact mode.

  For the freeze-silicon flow, the script runs the add_spare_cells and 
  place_eco_cells commands, sources the PrimeTime ECO change file, and runs 
  the place_freeze_silicon command.

* For the pt_eco_incremental_1 step: 
  rm_icc2_pnr_scripts/pt_eco_incremental_1.tcl
  For the pt_eco_incremental_2 step: 
  rm_icc2_pnr_scripts/pt_eco_incremental_2.tcl

  These scripts show an example of running the incremental ECO flow in two 
  steps.

  The first step (pt_eco_incremental_1) initializes the flow by establishing 
  the initial design reference data (NDM, Verilog, and DEF) for the IC Compiler II, 
  StarRC, and PrimeTime tools.

  The second step (pt_eco_incremental_2) performs the subsequent ECO 
  iterations. Near the end of the second step, the script suggests that you 
  assess the timing and design rule constraints in the PrimeTime tool to 
  determine if another ECO iteration is needed. If more ECO iterations are 
  needed, continue with your PrimeTime ECO commands and after that, repeat the 
  same steps as in pt_eco_incremental_2.tcl.

* For formal verification: rm_icc2_pnr_scripts/fm.tcl

  This script runs in Formality and checks the files going into the
  IC Compiler II tool against the resulting Verilog netlist from the
  IC Compiler II tool.

* For RedHawk Fusion flows:
  rm_icc2_pnr_scripts/redhawk_in_design_pnr.tcl

  This script can perform the following analyses on the power grid structure:
    - Rail Integrity Check (including the Missing Via Check)
    - Missing Via Insertion
    - Static
    - Vectorless Dynamic
    - Vector-Based Dynamic
    - Electromigration
    - Minimum Path Resistance
    - Effective Resistance
    - Power Grid Augmentation (PGA)

  Before performing any of the previous analyses, you must
  - Set the REDHAWK_* variables in rm_setup/icc2_common_setup.tcl
    and rm_setup/icc2_pnr_setup.tcl.
  - Ensure that the RedHawk executable can be found by your scripts
    by setting the following variable:
    * The REDHAWK_DIR Tcl variable in rm_setup/icc2_common_setup.tcl

* For Verification Compiler low power static signoff: 
  rm_icc2_pnr_scripts/vc_lp.tcl    

  This script runs in VC-LP and checks the Verilog and UPF files 
  generated by the IC Compiler II tool with the check_lp and report_lp 
  commands. 

## Supporting scripts

* rm_icc2_pnr_scripts/report_qor.tcl

  You specify which reporting script to run by setting the REPORT_QOR_SCRIPT 
  variable. By default, it runs the report_qor.tcl script. To use the
  -no_split option with the reporting commands, set the REPORT_QOR_SCRIPT
  variable to report_qor.nosplit.tcl.

  The script specified by the REPORT_QOR_SCRIPT variable is called by each 
  of the implementation scripts to run the following reporting commands: 
  report_mode, report_scenarios, report_pvt, report_constraint, report_qor, 
  report_timing, analyze_design_violations, report_threshold_voltage_group, 
  report_power, report_mv_path, report_clock_qor, report_design, report_congestion 
  check_design, check_netlist, report_app_options, and report_user_units.
 
  The reports are written to the $REPORTS_DIR directory.  

* rm_icc2_pnr_scripts/templates/init_design.mcmm_example.explicit.tcl 
  init_design.mcmm_example.auto_expanded.tcl

     - init_design.mcmm_example.explicit.tcl: 
       This script creates a shared mode, two corners, and two scenarios 
       with mode, corner, and scenario constraints all explicitly provided.

     - init_design.mcmm_example.auto_expanded.tcl:
       This script creates two scenarios with scenario constraints, and
       automatically expands the constraints to the associated modes and
       scenarios. 

  This script is sourced in init_design.tcl.

* rm_icc2_pnr_scripts/templates/init_design.flat_design_planning_example.tcl
  This script includes examples for I/O and macro placement.
  This script is sourced in init_design.tcl.

* rm_icc2_pnr_scripts/templates/init_design.std_cell_rail_example.tcl
  This script includes examples for standard cell PG rail creation.
  This script is sourced in init_design.tcl.

* rm_icc2_pnr_scripts/templates/init_design.power_switch_example.tcl
  This script includes examples for power-switch insertion, assignment, and 
  connection.
  This script is sourced in init_design.tcl.

* rm_icc2_pnr_scripts/init_design.tech_setup.tcl
  This script includes technology-related settings, such as routing direction, 
  offset, site default, and the site symmetry list.

  If you use a technology file (TECH_FILE is defined), the init_design.tcl
  script sources the technology setup script before the read_def or
  initialize_floorplan command.

  If you use a technology library (TECH_LIB is defined), by default, the
  init_design.tcl script assumes that the technology information is already 
  loaded and does not source the technology setup script. To source the 
  technology setup script, set the TECH_LIB_INCLUDES_TECH_SETUP_INFO variable 
  to false.

* rm_icc2_pnr_scripts/import_from_dp.tcl
  If the INIT_DESIGN_INPUT variable is set to DP_RM_NDM, init_design.tcl 
  accepts the design library generated by the ICC2-DP-RM. This script copies 
  the design library from the ICC2-DP-RM release area specified by the
  RELEASE_DIR_DP variable.
  This script is sourced in init_design.tcl.

* rm_icc2_pnr_scripts/settings.non_persistent.tcl
  This script includes sample settings that are not persistently stored, such as
  the keepout margins defined on library cells, and the set_threshold_voltage_group_type 
  commands.
  This script is sourced in all the implementation scripts.

* The following files are step-specific setting files:
  - rm_icc2_pnr_scripts/settings.place_opt.tcl
    This script includes settings for common optimization, placement, legalization, CTS, 
    routing, and timing. This script is sourced at the beginning of the place and route stage, which is 
    place_opt.tcl.    
  - rm_icc2_pnr_scripts/settings.clock_opt_cts.tcl
    This script is sourced in clock_opt_cts.tcl.
  - rm_icc2_pnr_scripts/settings.clock_opt_opto.tcl
    This script is sourced in clock_opt_opto.tcl.
  - rm_icc2_pnr_scripts/settings.route_auto.tcl 
    This script is sourced in route_auto.tcl.
  - rm_icc2_pnr_scripts/settings.route_opt.tcl 
    This script is sourced in route_opts.tcl.

* rm_icc2_pnr_scripts/set_lib_cell_purpose.tcl
  This script includes the following library cell purpose restrictions, and is sourced 
  by rm_icc2_pnr_scripts/settings.place_opt.tcl:
  - Don't use, which is controlled by the TCL_LIB_CELL_DONT_USE_FILE variable
  - Hold fixing, which is controlled by the HOLD_FIX_LIB_CELL_PATTERN_LIST
    variable
  - Clock tree synthesis, which is controlled by the 
    CTS_LIB_CELL_PATTERN_LIST variable
  - Clock tree synthesis only, which is controlled by the 
    CTS_ONLY_LIB_CELL_PATTERN_LIST variable

* rm_icc2_pnr_scripts/summary.tcl
  This script is sourced when you choose the "summary" target. It generates 
  a summary report (summary.rpt) in the $REPORTS_DIR directory for all steps 
  completed in the flow. The summary data is presented in the table format.

* The following files are generated if you select the 16nm node for 
  the "Technology Node" option and then select True for the Synopsys Logic 
  Libraries" option. These files contain the information specific for 
  customizing Synopsys logic libraries.

  - init_design.tcl.sg_16nm.boundary_cells, which is the boundary cell list 
    specific to the "Synopsys logic libraries" 
  - cts_ndr.tcl.sg_16nm, which defines nondefault
    routing rules specific to the "Synopsys logic libraries" 
  - settings.place_opt.tcl.sg_16nm.dont_use, which specifies the don't use
    library cell list specific to the "Synopsys logic libraries". The UHD 
    settings are valid only for Synopsys UHD library version 2.01a.
  - place_opt.tcl.sg_16nm.place_spacing_rules, which specifies
    the spacing rules specific to the "Synopsys logic libraries".
    The UHD settings are valid only for Synopsys UHD library version 2.01a. 
  - init_design.tcl.sg_16nm.create_pg.hs, which provides a PG
    example for the high-speed (HS) library
  - init_design.tcl.sg_16nm.create_pg.hd, which provides a PG
    example for the high-density (HD) library
  - init_design.tcl.sg_16nm.create_pg.uhd, which provides a PG
    example for the ultra-high-density (UHD) library
  - route_opt.tcl.sg_16nm.via_stitching, which provides a
    via-stitching example for the HD and UHD libraries
