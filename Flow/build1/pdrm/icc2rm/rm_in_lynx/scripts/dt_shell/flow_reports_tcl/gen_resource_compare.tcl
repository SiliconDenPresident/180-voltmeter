#! /usr/bin/env tclsh
## -----------------------------------------------------------------------------
## HEADER_MSG  Lynx Design System: Baseline Flow
## HEADER_MSG  Version 2019.03-SP2
## HEADER_MSG  Copyright (c) 2019 Synopsys
## HEADER_MSG  Perforce Label: lynx_flow_2019.03-SP2
## -----------------------------------------------------------------------------

## -----------------------------------------------------------------------------
## Parse arguments
## -----------------------------------------------------------------------------

set garg(config_list) ""
set garg(config_file) ""
set garg(report_file) ""
set garg(category)    "DEFAULT"
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
    -category {
      incr i
      set garg(category) [lindex $argv $i]
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
  puts "Usage: gen_resource_compare.tcl"
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

set gvar(template_dir) $gvar(prog_path)/compare_template
set gvar(data_dir)     $gvar(prog_path)/gen_resource_compare.data

## -----------------------------------------------------------------------------
## sproc_gather_data:
## -----------------------------------------------------------------------------

proc sproc_gather_data {} {

  global garg gvar
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

  global garg gvar
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

  sproc_metric -cmd add -metric_name "Host"           -display_name "Host"
  sproc_metric -cmd add -metric_name "Tool"           -display_name "Tool"
  sproc_metric -cmd add -metric_name "Version"        -display_name "Version"
  sproc_metric -cmd add -metric_name "Cores"          -display_name "Cores"
  sproc_metric -cmd add -metric_name "Wall Time"      -display_name "Wall Time"
  sproc_metric -cmd add -metric_name "CPU Time"       -display_name "CPU Time"
  sproc_metric -cmd add -metric_name "CPU Efficiency" -display_name "CPU Efficiency"
  sproc_metric -cmd add -metric_name "Mem"            -display_name "Mem"

  set task_info_list [sproc_build_info -build_label $build_label -cmd get_all]
  foreach task_info $task_info_list {
    lassign $task_info task_flow_order task_step task_dst task_name task_id task_tool task_report_list

    ## -------------------------------------
    ## Parse the reports for this task
    ## -------------------------------------

    set resource_file $build_dir/$task_step/$task_dst/rpts/$task_name/.$task_name.lynx_task

    unset -nocomplain rval

    set fid [open $resource_file r]
    set string_file [read $fid]
    close $fid
    set lines [split $string_file \n]

    set line_number 0
    foreach line $lines {
      incr line_number

      foreach name [sproc_metric -cmd metrics] {
        if { [regexp "^$name\\|(.+)\$" $line matchVar value] } {
          set rval($name) $value
          set rval($name,line) $line_number
        }
      }

    }

    ## -------------------------------------
    ## Stuff results into misc_status
    ## -------------------------------------

    foreach name [sproc_metric -cmd metrics] {

      if { [info exists rval($name)] } {
        set data $rval($name)
        set link $resource_file:$rval($name,line)
        set misc_status($build_label,$task_id,$name,value) $data
        set misc_status($build_label,$task_id,$name,link) $link
      }

    }

  }

}

## -----------------------------------------------------------------------------
## sproc_create_final_report:
## -----------------------------------------------------------------------------

proc sproc_create_final_report {} {

  global garg gvar
  global misc_status

  ## Note: garg(report_file) is a directory. Using report_dir for clarity.

  ## Create report_dir

  set report_dir $garg(report_file)

  if { [file exists $report_dir] } {
    if { [file exists      $report_dir/index.html] &&
         [file isdirectory $report_dir/include] &&
         [file isdirectory $report_dir/data]
    } {
      puts "Using existing report directory: $report_dir"
    } else {
      puts "Error: Invalid report directory: $report_dir"
      exit
    }
  } else {
    puts "Creating new report directory: $report_dir"
    file copy $gvar(template_dir) $report_dir
    file copy $gvar(data_dir)/data $report_dir/data
  }

  if { ![file exists $report_dir] } {
    puts "Error: Unable to create report directory: $report_dir"
    exit
  }

  ## Polulate report_dir

  ## Create list of file(s): data/category/*.tbl

  set list_file $report_dir/data/tbl.cfg
  set fid [open $list_file w]
  foreach build_item $gvar(build_item_list) {
    lassign $build_item build_label build_dir
    set build_file $garg(category)/$build_label.tbl
    puts $fid $build_file
  }
  close $fid

  ## Create file(s): data/category/*.tbl

  foreach build_item $gvar(build_item_list) {
    lassign $build_item build_label build_dir

    set build_file $report_dir/data/$garg(category)/$build_label.tbl

    file mkdir [file dirname $build_file]
    set fid [open $build_file w]

    ## Create HEADER line

    set header_line "HEADER"
    foreach metric_name [sproc_metric -cmd metrics] {
      set header_line "$header_line|[sproc_metric -cmd display -metric_name $metric_name]"
    }
    puts $fid $header_line

    ## Create VALUE lines

    foreach task_info [sproc_build_info -build_label $build_label -cmd get_all] {
      lassign $task_info task_flow_order task_step task_dst task_name task_id task_tool task_report_list

      set value_line "$task_id"

      foreach metric_name [sproc_metric -cmd metrics] {
        if { [info exists misc_status($build_label,$task_id,$metric_name,value)] } {
          set value $misc_status($build_label,$task_id,$metric_name,value)
        } else {
          set value ""
        }
        set value_line "$value_line|$value"
      }

      puts $fid $value_line
    }

    close $fid

  }

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
