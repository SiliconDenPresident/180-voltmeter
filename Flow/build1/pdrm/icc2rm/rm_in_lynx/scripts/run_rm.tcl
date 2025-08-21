source ../../../../../scripts_global/conf/header_start.tcl

## NAME: TEV(alternate_script)
## TYPE: file
## INFO:
## * Used to alternate script location when <task_name> not equal
## * <task_Name>.tcl
set TEV(alternate_script) ""

source ../../../../../scripts_global/conf/header_stop.tcl

## SECTION_START: initial
## SECTION_STOP: initial

## SECTION_START: setup
set cwd [pwd]
cd ../../../../../
## SECTION_STOP: setup

## SECTION_START: body
## For special cases in DC when task_name = script_name
if {$TEV(alternate_script) != "" } {
  set fname $TEV(alternate_script)
} else {
  set fname [glob */$SEV(task).tcl]
}

set fin [open $fname r]
set fout_adjusted $SEV(log_dir)/$SEV(task).adjusted_script.tcl 
file delete -force $fout_adjusted
set fout [open $fout_adjusted w]
while {[gets $fin line] >= 0} {
  if { [regexp {set_host_option} $line] } {
    while (![info complete $line]) {
      gets $fin cont_line
      set line $cont_line
    }
  }
  if { [regexp {^quit} $line] || [regexp {^exit} $line] } {
    puts $fout "## run_rm replacement"
    puts $fout "## $line" 
  } else {
    puts $fout $line
  }
}
close $fin
close $fout
## SECTION_STOP: body

## SECTION_START: run_task
source $fout_adjusted
## SECTION_STOP: run_task

## SECTION_START: post
## Copy log file
set rm_type [string range $SEV(step_name) 3 end]
if {[regexp $rm_type icc2]} {
  set RM_log_dir logs_icc2
  file mkdir $RM_log_dir
} else {
  set RM_log_dir .
}
file copy -force $SEV(log_file) $RM_log_dir/$SEV(task).log
## Link report files for DT
if {$synopsys_program_name == "icc2_shell"} {
  foreach ind_file [glob [file normalize $REPORTS_DIR]/$SEV(task).*] {
    file delete -force $SEV(rpt_dir)/$SEV(task)/[file tail $ind_file]
    file link $SEV(rpt_dir)/$SEV(task)/[file tail $ind_file] $ind_file
  }
} elseif {$synopsys_program_name == "dc_shell"} {
  foreach ind_file [glob [file normalize $REPORTS_DIR/*]] {
    if {[regexp mapped.qor.rpt $ind_file]} {
      file delete -force $SEV(rpt_dir)/$SEV(task)/dc.report_qor
      file link $SEV(rpt_dir)/$SEV(task)/dc.report_qor $ind_file
    } elseif {[regexp mapped.power.rpt $ind_file]} {
      file delete -force $SEV(rpt_dir)/$SEV(task)/dc.report_power
      file link $SEV(rpt_dir)/$SEV(task)/dc.report_power $ind_file
    } else {
      file delete -force $SEV(rpt_dir)/$SEV(task)/[file tail $ind_file]
      file link $SEV(rpt_dir)/$SEV(task)/[file tail $ind_file] $ind_file
    }
  }
}

## SECTION_STOP: post

sproc_script_stop
