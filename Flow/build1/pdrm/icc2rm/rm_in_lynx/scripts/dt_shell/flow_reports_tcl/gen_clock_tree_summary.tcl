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
set garg(flip)        0
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
    -flip {
      set garg(flip) 1
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
  puts "Usage: gen_clock_tree_summary.tcl"
  puts "         \[-config_list <config_list>\]"
  puts "         \[-config_file <config_file>\]"
  puts "         \[-report_file <report_file>\]"
  puts "         \[-flip\]"
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
  lappend reports "summary"

  sproc_build_info -cmd init -build_label $build_label -build_dir $build_dir -reports $reports

  if { $garg(debug) } {
    sproc_debug $build_label $build_dir
  }

  ## -------------------------------------
  ## Gather metrics for each task
  ## -------------------------------------

  sproc_metric -cmd add -metric_name {Sinks}                -display_name {Sinks}
  sproc_metric -cmd add -metric_name {Levels}               -display_name {Levels}
  sproc_metric -cmd add -metric_name {Clock_Repeater_Count} -display_name {Clock Repeater Count}
  sproc_metric -cmd add -metric_name {Clock_Repeater_Area}  -display_name {Clock Repeater Area}
  sproc_metric -cmd add -metric_name {Clock_Stdcell_Area}   -display_name {Clock Stdcell Area}
  sproc_metric -cmd add -metric_name {Max_Latency}          -display_name {Max Latency}
  sproc_metric -cmd add -metric_name {Global_Skew}          -display_name {Global Skew}
  sproc_metric -cmd add -metric_name {Trans_DRC_Count}      -display_name {Trans DRC Count}
  sproc_metric -cmd add -metric_name {Cap_DRC_Count}        -display_name {Cap DRC Count}

  set task_info_list [sproc_build_info -build_label $build_label -cmd get]
  foreach task_info $task_info_list {
    lassign $task_info task_flow_order task_step task_dst task_name task_id task_tool task_report_list

    ## -------------------------------------
    ## Parse the reports for this task
    ## -------------------------------------

    unset -nocomplain cts

    set cts_file [lindex $task_report_list 0]

    array set cts [sproc_parse_report_clock_qor -file $cts_file]

    ## Only include task if there are results

    if { ([llength $cts(scenario_list)] == 0) || ([llength $cts(clock_list)] == 0) } {
      sproc_build_info -build_label $build_label -cmd del -task_id $task_id
      continue
    }

    ## -------------------------------------
    ## Stuff results into misc_status
    ## -------------------------------------

    foreach scenario $cts(scenario_list) {
      lappend misc_status(scenario_list,$task_id) $scenario
      foreach clock $cts(clock_list) {
        lappend misc_status(clock_list,$task_id) $clock
        foreach metric_name [sproc_metric -cmd metrics] {
          if { [info exists cts($scenario,$clock,$metric_name,value)] } {
            set data $cts($scenario,$clock,$metric_name,value)
            set link $cts_file:$cts($scenario,$clock,$metric_name,line)
          } else {
            set data "-"
            set link ""
          }
          set misc_status($build_label,$task_id,$scenario,$clock,$metric_name,value) $data
          set misc_status($build_label,$task_id,$scenario,$clock,$metric_name,link) $link
        }
      }
    }


  }

  foreach task_info [sproc_build_info -build_label $build_label -cmd get] {
    lassign $task_info task_flow_order task_step task_dst task_name task_id task_tool task_report_list
    set misc_status(scenario_list,$task_id) [lsort -unique $misc_status(scenario_list,$task_id)]
    set misc_status(clock_list,$task_id)    [lsort -unique $misc_status(clock_list,$task_id)]
  }

  if { [llength [sproc_build_info -build_label $build_label -cmd get]] == 0 } {
    puts "Error: No tasks identified with the required reports."
  }

}

## -----------------------------------------------------------------------------
## sproc_create_final_report:
## -----------------------------------------------------------------------------

proc sproc_create_final_report {} {

  global env garg gvar
  global misc_status

  ## This code only here to set build_label
  foreach build_item $gvar(build_item_list) {
    lassign $build_item build_label build_dir
  }

  set fid [open $gvar(report_file) w]

  ## -------------------------------------
  ## Print the LYNX_BEGIN statement
  ## -------------------------------------

  puts $fid "LYNX_BEGIN|lynx_table_merge|my_table_merge"
  puts $fid ""

  puts $fid "TABLE_ID_FORMAT|Task"
  puts $fid ""

  if { [llength [sproc_build_info -build_label $build_label -cmd get]] == 0 } {
    ## There is no data, so generate an empty table
    set task_id NoTask
    set title "Clock Tree Summary : $build_label : $task_id"
    set subtitle "Created on [sproc_date]"

    puts $fid "TABLE_BEGIN"
    puts $fid "TABLE_ID|$task_id"
    puts $fid "DATA_BEGIN"
    puts $fid "HEADER|No available reports";
    puts $fid "DATA_END"
    puts $fid "FORMAT_BEGIN"
    puts $fid "TITLE|$title"
    puts $fid "SUBTITLE|$subtitle"
    puts $fid "FORMAT_END"
    puts $fid "TABLE_END"
  }

  foreach task_info [sproc_build_info -build_label $build_label -cmd get] {
    lassign $task_info task_flow_order task_step task_dst task_name task_id task_tool task_report_list

    ## -------------------------------------
    ## Print the TABLE_BEGIN statement
    ## -------------------------------------

    puts $fid "TABLE_BEGIN"
    puts $fid ""

    puts $fid "TABLE_ID|$task_id"
    puts $fid ""

    set color_array(white|darkBlue)  #ffffff:#000099
    set color_array(white|lightBlue) #ffffff:#3333ff
    set color_array(white|darkGray)  #ffffff:#303030

    unset -nocomplain attr_lines
    unset -nocomplain link_lines

    ## -------------------------------------
    ## Print the DATA section
    ## -------------------------------------

    puts $fid "DATA_BEGIN"

    ## -------------------------------------
    ## Print the HEADER lines
    ## While doing this, also:
    ## Create information for ATTR section (create $attr_lines, which is output later)
    ## Create information for LINK section (create $link_lines, which is output later)
    ## -------------------------------------

    if { $garg(flip) } {

      ## Print 2 row headers
      ## Row 1: "Metric", then clk1 ... clk1 clkN ... clkN
      ## Row 2: "Metric", then scn1 ... scnN scn1 ... scnN

      puts $fid "HEADER_COLS|1"

      for { set row 1 } { $row <= 2 } { incr row } {

        set header_line "HEADER|Metric"
        set attr_line   "HEADER|$color_array(white|darkBlue)"
        set link_line   "HEADER|"

        foreach clock $misc_status(clock_list,$task_id) {
          foreach scenario $misc_status(scenario_list,$task_id) {
            if { $row == 1 } {
              set header_line "$header_line|$clock"
            } else {
              set header_line "$header_line|$scenario"
            }
            set attr_line   "$attr_line|$color_array(white|lightBlue)"
            set link_line   "$link_line|"
          }
        }

        puts $fid $header_line
        lappend attr_lines $attr_line
        lappend link_lines $link_line

      }

    } else {

      ## Print 1 row header
      ## Row 1: "Clock", "Scenario", then each metric

      puts $fid "HEADER_COLS|2"

      set header_line "HEADER|Clock|Scenario"
      set attr_line   "HEADER|$color_array(white|darkBlue)|$color_array(white|darkBlue)"
      set link_line   "HEADER||"

      foreach metric_name [sproc_metric -cmd metrics] {
        set header_line "$header_line|[sproc_metric -cmd display -metric_name $metric_name]"
        set attr_line   "$attr_line|$color_array(white|lightBlue)"
        set link_line   "$link_line|"
      }

      puts $fid $header_line
      lappend attr_lines $attr_line
      lappend link_lines $link_line

    }

    ## -------------------------------------
    ## Print the VALUE lines
    ## While doing this, also:
    ## Create information for ATTR section (create $attr_lines, which is output later)
    ## Create information for LINK section (create $link_lines, which is output later)
    ## -------------------------------------

    if { $garg(flip) } {

      foreach metric_name [sproc_metric -cmd metrics] {

        set value_line "VALUE|[sproc_metric -cmd display -metric_name $metric_name]"
        set attr_line  "VALUE|$color_array(white|darkGray)"
        set link_line  "VALUE|"

        foreach clock $misc_status(clock_list,$task_id) {
          foreach scenario $misc_status(scenario_list,$task_id) {
            set value $misc_status($build_label,$task_id,$scenario,$clock,$metric_name,value)
            set attr  ""
            set link  $misc_status($build_label,$task_id,$scenario,$clock,$metric_name,link)

            set value_line "$value_line|$value"
            set attr_line  "$attr_line|$attr"
            set link_line  "$link_line|$link"
          }
        }

        puts $fid $value_line
        lappend attr_lines $attr_line
        lappend link_lines $link_line

      }

    } else {

      foreach clock $misc_status(clock_list,$task_id) {
        foreach scenario $misc_status(scenario_list,$task_id) {

          set value_line "VALUE|$clock|$scenario"
          set attr_line  "VALUE|$color_array(white|darkGray)|$color_array(white|darkGray)"
          set link_line  "VALUE||"

          foreach metric_name [sproc_metric -cmd metrics] {
            set value $misc_status($build_label,$task_id,$scenario,$clock,$metric_name,value)
            set attr  ""
            set link  $misc_status($build_label,$task_id,$scenario,$clock,$metric_name,link)

            set value_line "$value_line|$value"
            set attr_line  "$attr_line|$attr"
            set link_line  "$link_line|$link"
          }

          puts $fid $value_line
          lappend attr_lines $attr_line
          lappend link_lines $link_line

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
    ## Print the LINK section
    ## -------------------------------------

    puts $fid "LINK_BEGIN"
    foreach line $link_lines {
      puts $fid $line
    }
    puts $fid "LINK_END"
    puts $fid ""

    ## -------------------------------------
    ## Print the FORMAT section
    ## -------------------------------------

    ## -------------------------------------
    ## Create the title information
    ## -------------------------------------

    set title "Clock Tree Summary : $build_label : $task_id"
    set subtitle "Created on [sproc_date]"

    ## -------------------------------------
    ## Output the section information
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

  }

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
