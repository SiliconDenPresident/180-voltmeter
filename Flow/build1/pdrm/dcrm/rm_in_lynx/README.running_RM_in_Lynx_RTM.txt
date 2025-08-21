################################################################################
# README for the Synopsys(R) Reference Methodology in Lynx-RTM Option 
# Version: P-2019.03-SP2
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
################################################################################

An option is now available to run the Synopsys Reference Methodologies directly 
within the Synopsys Lynx Design System. Running a "RM in Lynx" provides access 
to a number of productivity and automation benefits with no user changes to the 
existing Reference Methodology (RM) scripts. Some of the baseline benefits 
gained when running a RM in Lynx includes:

*  Visualization of the RM flow
*  Visual execution and monitoring
*  Log file error checking
*  Tool version control
*  Graphical and Web based reporting (for tracking flow progress and Quality of
   Results (QoR))

Additional benefits can be optionally enabled with user modifications to the 
scripts, such as:

*  Job distribution and optimization
*  View and configure defined script variables from the GUI
*  Manage common variables at different layers (global, technology, project, 
   and block-specific)
*  Graphically edit flows (scripts and data implicitly follow)
*  Use advanced flow control (generators, MUXes, connection groups, and 
   subflows)
*  Use local overrides to global flow configuration points

These features are not covered in this README file but interested users 
should contact the Synopsys support.

To setup RM scripts for running in the Lynx Design System Runtime Manager (RTM),

(1) Make sure the Lynx product is loaded in your environment.
(2) Change the directory to your RM workarea.
(3) Run the "RM in Lynx" setup utility from the RM download, as follows:
     unix% ./rm_in_lynx/setup_rm_in_lynx.tcl -build <my_build> \
                                             -flow_xml <default_flow>
(4) Launch Lynx Runtime Manager, as follows:
     unix% rtm_shell -gui

The reports, results, and logs remain at the root workarea where launched.
The scripts_global and build directory structures are added to support this run
model. 

There is an additional ./rm_in_lynx directory downloaded as part of each RM. It 
is the same across all RMs. These files support the "RM in Lynx" use model.

Files Included in the "RM in Lynx" Use Model
===============================================================

--------------------------------------------------------------------------------
File                                Description
--------------------------------------------------------------------------------
README.running_RM_in_Lynx_RTM.txt   

setup_rm_in_lynx.tcl                This utility augments the current RM 
                                    workarea with the files needed to orient 
                                    the Lynx Runtime Manager (RTM) around the 
                                    flow. 
                                    Run the utility with the -help option to 
                                    see the options and basic operation:
                                      ./rm_in_lynx/setup_rm_in_lynx.tcl -help

flows/rm_<RM>.xml                   These Lynx Runtime Manager flow files are 
                                    created for each RM. These flows reflect 
                                    either the Makefiles or shell scripts 
                                    provided for the RM flow. 

scripts/run_rm.tcl                  This is the wrapper script used by almost 
                                    every task in the xml flows. It is copied 
                                    into the global script area during setup 
                                    and implicitly loads the corresponding RM 
                                    script based on the task name. This wrapper
                                    does basic initialization and also makes a 
                                    minor change to the original RM script 
                                    on-the-fly to remove the "exit" from the 
                                    script. This allows the RTM to control 
                                    batch and interactive operation of the 
                                    task. In the case of tasks like PrimeTime 
                                    distributed multi-scenario analysis (DMSA), 
                                    it also substitutes host options to 
                                    leverage the RTM job distribution interface.

scripts/starrc.tcl                  This is the wrapper script for StarRCXT 
                                    that runs slightly different than the 
                                    run_rm.tcl. It is referenced in any flow 
                                    task that runs the StarRCXT tool.
                                     
scripts/dt_shell/                   This directory contains files needed to 
                                    support RM specific reporting and parsing 
                                    for the Lynx Design Track. It is copied 
                                    into the Lynx global script area during 
                                    setup.

scripts/view/                       This directory contains view files which 
                                    act as a wrapper for starting interactive 
                                    loads of task resulting databases. There is
                                    a view file for each of the products 
                                    supported in the flow.

For information about how to set up the Reference Methodology to run using Lynx
Design System, see the instructions in the following documents:

*  SolvNet article 3000048, "Running the Reference Methodology in Lynx"

   https://solvnet.synopsys.com/retrieve/3000048.html

For information about the Reference Methodology, see the introduction in the 
following documents:

*  SolvNet article 025090, "Introduction to Reference Methodology"

   https://solvnet.synopsys.com/retrieve/025090.html
