#! /usr/bin/env tclsh
## -----------------------------------------------------------------------------
## HEADER_MSG  Lynx Design System: Baseline Flow
## HEADER_MSG  Version 2019.03-SP2
## HEADER_MSG  Copyright (c) 2019 Synopsys
## HEADER_MSG  Perforce Label: lynx_flow_2019.03-SP2
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * TBD
## -----------------------------------------------------------------------------

## -----------------------------------------------------------------------------
## Parse arguments
## -----------------------------------------------------------------------------

set garg(config_list) ""
set garg(config_file) ""
set garg(report_file) ""
set garg(message)     0
set garg(debug)       0

set error 0

for { set i 0 } { $i < [llength $argv] } { incr i } {
  set arg [lindex $argv $i]
  switch -- $arg {
    -config_list {
      incr i
      set garg(config_list) [lindex $argv $i]
    }
    -config_file {
      incr i
      set garg(config_file) [lindex $argv $i]
    }
    -report_file {
      incr i
      set garg(report_file) [lindex $argv $i]
    }
    -message {
      set garg(message) 1
    }
    -debug {
      set garg(debug) 1
    }
    default {
      puts "Error: Unrecognized option: $arg"
      set error 1
    }
  }
}

if { ($garg(config_file) != "") && ![file exists $garg(config_file)] } {
  incr error
  puts "Error: File specified by -config_file does not exist: '$garg(config_file)'"
}

if { $error } {
  puts "Usage: gen_tool_license_summary.tcl"
  puts "         \[-config_list <config_list>\]"
  puts "         \[-config_file <config_file>\]"
  puts "         \[-report_file <report_file>\]"
  puts "         \[-message\]"
  puts "         \[-debug\]"

  exit
}

## -----------------------------------------------------------------------------
## Global variables
## -----------------------------------------------------------------------------

set gvar(prog_path) [file dirname [file normalize $argv0]]
source $gvar(prog_path)/procs.tcl

## These are set by sproc_config
set gvar(build_item_list) [list]
set gvar(report_file) ""
set gvar(message_file) ""

## -----------------------------------------------------------------------------
## sproc_gather_data:
## -----------------------------------------------------------------------------

proc sproc_gather_data {} {
  global env garg gvar
  global misc_status

  array set misc_status {}

  foreach build_item $gvar(build_item_list) {
    lassign $build_item build_label build_dir
    sproc_gather_build_data $build_label $build_dir
  }
}

## -----------------------------------------------------------------------------
## sproc_gather_build_data:
## -----------------------------------------------------------------------------

proc sproc_gather_build_data { build_label build_dir } {

  global env garg gvar
  global misc_status

  ## -------------------------------------
  ## Get tasks and reports
  ## -------------------------------------

  set reports [list]

  sproc_build_info -cmd init -build_label $build_label -build_dir $build_dir -reports $reports

  if { $garg(debug) } {
    sproc_debug $build_label $build_dir
  }

  ## -------------------------------------
  ## Gather metrics for each task
  ## -------------------------------------

  set task_info_list [sproc_build_info -build_label $build_label -cmd get_all]
  foreach task_info $task_info_list {
    lassign $task_info task_flow_order task_step task_dst task_name task_id task_tool task_report_list

    ## -------------------------------------
    ## Parse the reports for this task
    ## -------------------------------------

    set resource_file $build_dir/$task_step/$task_dst/rpts/$task_name/.$task_name.lynx_task

    set fid [open $resource_file r]
    set string_file [read $fid]
    close $fid
    set lines [split $string_file \n]

    set task_flow_order ""
    set tool_name       "undefined"
    set tool_version    ""
    set license_list    ""

    foreach line $lines {
      regexp {^flow_order\|(\d+)} $line match task_flow_order
      regexp {^Tool\|(.*)}        $line match tool_name
      regexp {^Version\|(.*)}     $line match tool_version
      regexp {^License\|(.*)}     $line match license_list
    }

    ## -------------------------------------
    ## Stuff results into misc_status
    ## -------------------------------------

    if { ![info exists misc_status(tool_name_list)] } {
      set misc_status(tool_name_list) [list]
    }

    if { [lsearch $misc_status(tool_name_list) $tool_name] == -1 } {
      lappend misc_status(tool_name_list) $tool_name
      set misc_status(count,$tool_name) 0
      set misc_status(tool_version_list,$tool_name) [list]
    }

    incr misc_status(count,$tool_name)

    if { [lsearch $misc_status(tool_version_list,$tool_name) $tool_version] == -1 } {
      lappend misc_status(tool_version_list,$tool_name) $tool_version
      set misc_status(count,$tool_name,$tool_version) 0
      set misc_status(license_list,$tool_name,$tool_version) [list]
    }

    incr misc_status(count,$tool_name,$tool_version)

    foreach license $license_list {
      if { [lsearch $misc_status(license_list,$tool_name,$tool_version) $license] == -1 } {
        lappend misc_status(license_list,$tool_name,$tool_version) $license
        set misc_status(count,$tool_name,$tool_version,$license) 0
      }
      incr misc_status(count,$tool_name,$tool_version,$license)
    }

  }

  ## -------------------------------------
  ## Sort results
  ## -------------------------------------

  set misc_status(tool_name_list) [lsort -ascii $misc_status(tool_name_list)]

  foreach tool_name $misc_status(tool_name_list) {
    set misc_status(tool_version_list,$tool_name) [lsort -ascii $misc_status(tool_version_list,$tool_name)]
    foreach tool_version $misc_status(tool_version_list,$tool_name) {
      set misc_status(license_list,$tool_name,$tool_version) [lsort -ascii $misc_status(license_list,$tool_name,$tool_version)]
    }
  }

}

## -----------------------------------------------------------------------------
## sproc_create_final_report:
## -----------------------------------------------------------------------------

proc sproc_create_final_report {} {

  global env garg gvar
  global misc_status

  set fid [open $gvar(report_file) w]

  ## -------------------------------------
  ## Print the LYNX_BEGIN statement
  ## -------------------------------------

  puts $fid "LYNX_BEGIN|lynx_table_merge|license_report"
  puts $fid ""

  ## -------------------------------------
  ## Print the TABLE_BEGIN statement
  ## -------------------------------------

  puts $fid "TABLE_BEGIN"
  puts $fid ""

  ## -------------------------------------
  ## Print the DATA section
  ## -------------------------------------

  unset -nocomplain attr_lines
  unset -nocomplain link_lines

  set attr(rowHeader) #ffffff:#3333ff:L
  set attr(rowValue)  #000000:#ffffff:A

  puts $fid "DATA_BEGIN"
  puts $fid ""

  puts $fid "HEADER|Tool Name|Tool version|License Feature|Number of Invocations"
  lappend attr_lines "HEADER|$attr(rowHeader)|$attr(rowHeader)|$attr(rowHeader)|$attr(rowHeader)"

  foreach tool_name $misc_status(tool_name_list) {
    puts $fid "VALUE|$tool_name|||$misc_status(count,$tool_name)"
    lappend attr_lines "VALUE|$attr(rowValue)|$attr(rowValue)|$attr(rowValue)|$attr(rowValue)"
    foreach tool_version $misc_status(tool_version_list,$tool_name) {
      puts $fid "VALUE||$tool_version||$misc_status(count,$tool_name,$tool_version)"
      lappend attr_lines "VALUE|$attr(rowValue)|$attr(rowValue)|$attr(rowValue)|$attr(rowValue)"
      foreach license $misc_status(license_list,$tool_name,$tool_version) {
        puts $fid "VALUE|||$license|$misc_status(count,$tool_name,$tool_version,$license)"
        lappend attr_lines "VALUE|$attr(rowValue)|$attr(rowValue)|$attr(rowValue)|$attr(rowValue)"
      }
    }
  }

  puts $fid "DATA_END"
  puts $fid ""

  ## -------------------------------------
  ## Print the ATTR section
  ## -------------------------------------

  puts $fid "ATTR_BEGIN"
  foreach line $attr_lines {
    puts $fid $line
  }
  puts $fid "ATTR_END"
  puts $fid ""

  ## -------------------------------------
  ## Print the FORMAT section
  ## -------------------------------------

  ## -------------------------------------
  ## Create the title information
  ## -------------------------------------

  set title "Tool License Report Summary"
  set subtitle "Created on [sproc_date]"

  ## -------------------------------------
  ## Print the FORMAT section
  ## -------------------------------------

  puts $fid "FORMAT_BEGIN"
  puts $fid "TITLE|$title"
  puts $fid "SUBTITLE|$subtitle"
  puts $fid "FORMAT_END"
  puts $fid ""

  ## -------------------------------------
  ## Print the TABLE_END statement
  ## -------------------------------------

  puts $fid "TABLE_END"
  puts $fid ""

  ## -------------------------------------
  ## Print the LYNX_END statement
  ## -------------------------------------

  puts $fid "LYNX_END"

  close $fid
}

## -----------------------------------------------------------------------------
## MAIN
## -----------------------------------------------------------------------------

sproc_config

sproc_gather_data

sproc_create_final_report

sproc_create_message_file

puts "Done!"

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
