## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This task is used to interactively open a session with Formality
## -----------------------------------------------------------------------------

source ../../../../../scripts_global/conf/header_start.tcl

## NAME: TEV(session_override)
## TYPE: file
## INFO:
## * Use this to optionally open a different session than default dst_dir
set TEV(session_override) ""

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
if { $TEV(session_override) != "" } {
  set session_name $TEV(session_override)
} else {
  if { $SEV(step_name)=="rm_dc" } {
    source rm_setup/dc_setup.tcl
    set session_name ${REPORTS_DIR}/${FMRM_FAILING_SESSION_NAME}
  } 
  if { $SEV(step_name)=="rm_icc2" } {
    source rm_setup/icc2_pnr_setup.tcl
    set session_name ${REPORTS_DIR}/${DESIGN_NAME}
  } 
}

if { [file exists $session_name] } {
  restore_session  $session_name
  sproc_msg -info "Saved session $src_session is restored"
} else {
  sproc_msg -warning "$session_name does not exist."
}


## SECTION_STOP: body

## SECTION_START: final

## SECTION_STOP: final

sproc_script_stop

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
