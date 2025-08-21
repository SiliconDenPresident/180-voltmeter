## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This task is used to interactively open a session with ICC II.
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
source rm_setup/icc2_pnr_setup.tcl

open_lib ${DESIGN_LIBRARY} -ref_libs_for_edit > /dev/null
set block [lindex [split $SEV(dst_name) .] 1]
open_block ${DESIGN_NAME}/$block
save_block -force -label view_$block
close_lib -purge -force -all
open_block ${DESIGN_LIBRARY}:${DESIGN_NAME}/view_$block -ref_libs_for_edit
puts "RM-info : Make a copy of  ${DESIGN_NAME}/[lindex [split $SEV(dst_name) .] 1]"
puts "RM-info : Opening block ${DESIGN_NAME}/view"

## SECTION_STOP: body

## SECTION_START: final

## SECTION_STOP: final

sproc_script_stop

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
