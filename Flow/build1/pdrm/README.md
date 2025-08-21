ECE 720 Physical Design Reference Methodologies
====================

This repository contains physical design reference methodologies for ECE 720 - Electronic System Level and Physical Design.  These flows are adapted from the Design Compiler and IC Compiler 2 reference methodologies from Synopsys to use the Google/Skywater 130nm Open PDK on the NCSU ECE Linux system.

## Quick Start

    $ git clone https://github.ncsu.edu/engr-ece-720/pdrm.git
    $ module load syn/X-2025.06-SP1 icc2/W-2024.09-SP2
    $ make setup  # Do this the once to create headings in results.csv
    $ make        # Change variables in Makefile and re-run to append results.csv

## Modifying the flows for a new deisgn

### dcrm flow
* modify dcrm/rm_setup/common_setup.tcl
  * Change DESIGN_NAME to name of the top-level module
  * Change DESIGN_REF_DATA_PATH and ADDITIONAL_SEARCH_PATH to a list of directories containing RTL source code
* modify dcrm/rm_setup/dc_setup.tcl
  * Change RTL_SOURCE_FILES to a list of source files found in the search path
  * Change alib_library_analysis_path to a directory that contains a previously generated "alib-52" library directory (if desired, in order to avoid regenerating it, which slows the flow down) 
* Copy template/counter.constraints.tcl to a new file template/${DESIGN_NAME}.constratints.tcl
  * Change clkname to name of clock pin
  * Change CLK_PER to target clock-period
* Copy dcrm/src/rtl/counter/counter.dft_signal_defs.tcl to a new file ${DESIGN_NAME}.dft_signal_defs.tcl in the search path
  * Change "set_dft_signal –type ScanClock" to new clock port name
  * Change "set_dft_signal –type Reset" to new reset port name
    * active_state 1 for active high
    * active_state 0 for active low

### icc2rm flow
* modify template/icc2_common_setup.tcl
  * Set DESIGN_NAME to name of the top-level module

### Design flow Makefiles and scripts
* modify top-level Makefile, change DESIGN to name of the top-level module (same as DESIGN_NAME above)
* modify set_constraints.py to ensure that template/${DESIGN_NAME}.constratints.tcl is copied into the search path with the new CLK_PER constraint

