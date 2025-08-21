## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This task is used to interactively open a session with tx.
## -----------------------------------------------------------------------------

source ../../../../../scripts_global/conf/header_start.tcl

source ../../../../../scripts_global/conf/header_stop.tcl

## -----------------------------------------------------------------------------
## End of script header
## -----------------------------------------------------------------------------

## SECTION_START: initial
## SECTION_STOP: initial

## SECTION_START: setup
set cwd [pwd]
cd ../../../../../
## SECTION_STOP: setup

## SECTION_START: body
source rm_setup/common_setup.tcl
source rm_setup/pwr_setup.tcl

## SECTION_STOP: body

## SECTION_START: final
## SECTION_STOP: final

sproc_script_stop

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
