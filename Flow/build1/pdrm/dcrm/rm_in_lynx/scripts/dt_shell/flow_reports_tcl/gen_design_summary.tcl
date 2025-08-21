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
  puts "Usage: gen_design_summary.tcl"
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
  lappend reports "report_qor"
  lappend reports "report_units"
  lappend reports "report_power"
  lappend reports "report_threshold_voltage_groups"
  lappend reports "report_design"
  lappend reports "report_utilization"

  sproc_build_info -cmd init -build_label $build_label -build_dir $build_dir -reports $reports

  if { $garg(debug) } {
    sproc_debug $build_label $build_dir
  }

  ## -------------------------------------
  ## Gather metrics for each task
  ## -------------------------------------

  set theTimeUnit ""

  sproc_metric -cmd add -metric_name design_setup_wns     -display_name "Design Setup WNS (TIME_UNIT)"
  sproc_metric -cmd add -metric_name design_setup_tns     -display_name "Design Setup TNS (TIME_UNIT)"
  sproc_metric -cmd add -metric_name design_setup_nvp     -display_name "Design Setup Violations"
  sproc_metric -cmd add -metric_name design_hold_wns      -display_name "Design Hold WNS (TIME_UNIT)"
  sproc_metric -cmd add -metric_name design_hold_tns      -display_name "Design Hold TNS (TIME_UNIT)"
  sproc_metric -cmd add -metric_name design_hold_nvp      -display_name "Design Hold Violations"
  sproc_metric -cmd add -metric_name leaf_cell_count      -display_name "Leaf Cell Count"
  sproc_metric -cmd add -metric_name bufinv_cell_count    -display_name "Buf/Inv Cell Count"
  sproc_metric -cmd add -metric_name ctbufinv_cell_count  -display_name "CT Buf/Inv Cell Count"
  sproc_metric -cmd add -metric_name comb_cell_count      -display_name "Comb Cell Count"
  sproc_metric -cmd add -metric_name seq_cell_count       -display_name "Seq Cell Count"
  sproc_metric -cmd add -metric_name macro_cell_count     -display_name "Macro Cell Count"
  sproc_metric -cmd add -metric_name cell_area            -display_name "Cell Area"
  sproc_metric -cmd add -metric_name design_area          -display_name "Design Area"
  sproc_metric -cmd add -metric_name net_length           -display_name "Net Length"
  sproc_metric -cmd add -metric_name net_count            -display_name "Net Count"
  sproc_metric -cmd add -metric_name ldrc_total           -display_name "Net Violations Total"
  sproc_metric -cmd add -metric_name ldrc_trans           -display_name "Net Violations Trans"
  sproc_metric -cmd add -metric_name ldrc_cap             -display_name "Net Violations MaxCap"
  sproc_metric -cmd add -metric_name ldrc_fanout          -display_name "Net Violations MaxFanout"
  sproc_metric -cmd add -metric_name cell2core_ratio      -display_name "Utilization"
  sproc_metric -cmd add -metric_name num_drc_errors       -display_name "DRC Errors Total"
  sproc_metric -cmd add -metric_name num_drc_errors_types -display_name "DRC Errors Types"
  sproc_metric -cmd add -metric_name total_power_max      -display_name "Power Total (mW)"
  sproc_metric -cmd add -metric_name leakage_power_max    -display_name "Power Leakage (mW)"

  set task_info_list [sproc_build_info -build_label $build_label -cmd get]
  foreach task_info $task_info_list {
    lassign $task_info task_flow_order task_step task_dst task_name task_id task_tool task_report_list

    ## -------------------------------------
    ## Parse the reports for this task
    ## -------------------------------------

    unset -nocomplain qor
    unset -nocomplain units
    unset -nocomplain power
    unset -nocomplain vth
    unset -nocomplain phy
    unset -nocomplain util

    foreach file $task_report_list {

      if { [file extension $file] == ".report_qor" } {
        array set qor [sproc_parse_report_qor -file $file]
        set qor_file $file
      }

      if { [file extension $file] == ".report_units" } {
        array set units [sproc_parse_report_units -file $file]
        set unit_file $file
      }

      if { [file extension $file] == ".report_power" } {
        array set power [sproc_parse_report_power -file $file -synopsys_program_name $task_tool]
        set power_file $file
      }

      if { [file extension $file] == ".report_threshold_voltage_groups" } {
        array set vth [sproc_parse_report_threshold_voltage_group -file $file]
        set vth_file $file
      }

      if { [file extension $file] == ".report_design" } {
        array set phy [sproc_parse_report_design -file $file]
        set phy_file $file
      }

      if { [file extension $file] == ".report_utilization" } {
        array set util [sproc_parse_report_utilization -file $file]
        set util_file $file
      }

    }

    ## -------------------------------------
    ## Stuff results into misc_status
    ## -------------------------------------

    if { [info exists units] } {
      if { [info exists units(time_unit)] } {
        if { $theTimeUnit == "" } {
          set theTimeUnit $units(time_unit)
        }
      }
    }

    if { [info exists qor] } {

      if { [info exists qor(summary_data,_ms,setup,path_slack)] } {
        set data [format_value "%.2f" $qor(summary_data,_ms,setup,path_slack)]
        set link $qor_file:$qor(summary_data,_ms,setup,path_slack,line_number)
        set misc_status($build_label,$task_id,design_setup_wns,value) $data
        set misc_status($build_label,$task_id,design_setup_wns,link) $link
      }

      if { [info exists qor(summary_data,_ms,setup,tns)] } {
        set data [format "%.2f" $qor(summary_data,_ms,setup,tns)]
        set link $qor_file:$qor(summary_data,_ms,setup,tns,line_number)
        set misc_status($build_label,$task_id,design_setup_tns,value) $data
        set misc_status($build_label,$task_id,design_setup_tns,link) $link
      }

      if { [info exists qor(summary_data,_ms,setup,nvp)] } {
        set data $qor(summary_data,_ms,setup,nvp)
        set link $qor_file:$qor(summary_data,_ms,setup,nvp,line_number)
        set misc_status($build_label,$task_id,design_setup_nvp,value) $data
        set misc_status($build_label,$task_id,design_setup_nvp,link) $link
      }

      if { [info exists qor(summary_data,_ms,hold,path_slack)] } {
        set data [format_value "%.2f" $qor(summary_data,_ms,hold,path_slack)]
        set link $qor_file:$qor(summary_data,_ms,hold,path_slack,line_number)
        set misc_status($build_label,$task_id,design_hold_wns,value) $data
        set misc_status($build_label,$task_id,design_hold_wns,link) $link
      }

      if { [info exists qor(summary_data,_ms,hold,tns)] } {
        set data [format "%.2f" $qor(summary_data,_ms,hold,tns)]
        set link $qor_file:$qor(summary_data,_ms,hold,tns,line_number)
        set misc_status($build_label,$task_id,design_hold_tns,value) $data
        set misc_status($build_label,$task_id,design_hold_tns,link) $link
      }

      if { [info exists qor(summary_data,_ms,hold,nvp)] } {
        set data $qor(summary_data,_ms,hold,nvp)
        set link $qor_file:$qor(summary_data,_ms,hold,nvp,line_number)
        set misc_status($build_label,$task_id,design_hold_nvp,value) $data
        set misc_status($build_label,$task_id,design_hold_nvp,link) $link
      }

      if { [info exists qor(design_data,leaf_cell_count)] } {
        set data $qor(design_data,leaf_cell_count)
        set link $qor_file:$qor(design_data,leaf_cell_count,line_number)
        set misc_status($build_label,$task_id,leaf_cell_count,value) $data
        set misc_status($build_label,$task_id,leaf_cell_count,link) $link
      }

      if { [info exists qor(design_data,bufinv_cell_count)] } {
        set data $qor(design_data,bufinv_cell_count)
        set link $qor_file:$qor(design_data,bufinv_cell_count,line_number)
        set misc_status($build_label,$task_id,bufinv_cell_count,value) $data
        set misc_status($build_label,$task_id,bufinv_cell_count,link) $link
      }

      if { [info exists qor(design_data,ctbufinv_cell_count)] } {
        set data $qor(design_data,ctbufinv_cell_count)
        set link $qor_file:$qor(design_data,ctbufinv_cell_count,line_number)
        set misc_status($build_label,$task_id,ctbufinv_cell_count,value) $data
        set misc_status($build_label,$task_id,ctbufinv_cell_count,link) $link
      }

      if { [info exists qor(design_data,comb_cell_count)] } {
        set data $qor(design_data,comb_cell_count)
        set link $qor_file:$qor(design_data,comb_cell_count,line_number)
        set misc_status($build_label,$task_id,comb_cell_count,value) $data
        set misc_status($build_label,$task_id,comb_cell_count,link) $link
      }

      if { [info exists qor(design_data,seq_cell_count)] } {
        set data $qor(design_data,seq_cell_count)
        set link $qor_file:$qor(design_data,seq_cell_count,line_number)
        set misc_status($build_label,$task_id,seq_cell_count,value) $data
        set misc_status($build_label,$task_id,seq_cell_count,link) $link
      }

      if { [info exists qor(design_data,macro_cell_count)] } {
        set data $qor(design_data,macro_cell_count)
        set link $qor_file:$qor(design_data,macro_cell_count,line_number)
        set misc_status($build_label,$task_id,macro_cell_count,value) $data
        set misc_status($build_label,$task_id,macro_cell_count,link) $link
      }

      if { [info exists qor(design_data,cell_area)] } {
        set data [format "%.2f" $qor(design_data,cell_area)]
        set link $qor_file:$qor(design_data,cell_area,line_number)
        set misc_status($build_label,$task_id,cell_area,value) $data
        set misc_status($build_label,$task_id,cell_area,link) $link
      }

      if { [info exists qor(design_data,design_area)] } {
        set data [format "%.2f" $qor(design_data,design_area)]
        set link $qor_file:$qor(design_data,design_area,line_number)
        set misc_status($build_label,$task_id,design_area,value) $data
        set misc_status($build_label,$task_id,design_area,link) $link
      }

      if { [info exists qor(design_data,net_length)] } {
        set data [format "%.2f" $qor(design_data,net_length)]
        set link $qor_file:$qor(design_data,net_length,line_number)
        set misc_status($build_label,$task_id,net_length,value) $data
        set misc_status($build_label,$task_id,net_length,link) $link
      }

      if { [info exists qor(design_data,net_count)] } {
        set data $qor(design_data,net_count)
        set link $qor_file:$qor(design_data,net_count,line_number)
        set misc_status($build_label,$task_id,net_count,value) $data
        set misc_status($build_label,$task_id,net_count,link) $link
      }

      if { [info exists qor(design_data,ldrc_total)] } {
        set data $qor(design_data,ldrc_total)
        set link $qor_file:$qor(design_data,ldrc_total,line_number)
        set misc_status($build_label,$task_id,ldrc_total,value) $data
        set misc_status($build_label,$task_id,ldrc_total,link) $link
      }

      if { [info exists qor(design_data,ldrc_trans)] } {
        set data $qor(design_data,ldrc_trans)
        set link $qor_file:$qor(design_data,ldrc_trans,line_number)
        set misc_status($build_label,$task_id,ldrc_trans,value) $data
        set misc_status($build_label,$task_id,ldrc_trans,link) $link
      }

      if { [info exists qor(design_data,ldrc_cap)] } {
        set data $qor(design_data,ldrc_cap)
        set link $qor_file:$qor(design_data,ldrc_cap,line_number)
        set misc_status($build_label,$task_id,ldrc_cap,value) $data
        set misc_status($build_label,$task_id,ldrc_cap,link) $link
      }
      if { [info exists qor(design_data,ldrc_fanout)] } {
        set data $qor(design_data,ldrc_fanout)
        set link $qor_file:$qor(design_data,ldrc_fanout,line_number)
        set misc_status($build_label,$task_id,ldrc_fanout,value) $data
        set misc_status($build_label,$task_id,ldrc_fanout,link) $link
      }

    }

    if { [info exists util] } {

      if { [info exists util(cell2core_ratio)] } {
        set data [format "%.2f" $util(cell2core_ratio)]
        set link $util_file:$util(cell2core_ratio,line_number)
        set misc_status($build_label,$task_id,cell2core_ratio,value) $data
        set misc_status($build_label,$task_id,cell2core_ratio,link) $link
      }

    }

    if { [info exists phy] } {

      if { [info exists phy(num_drc_errors)] } {
        set data $phy(num_drc_errors)
        set link $phy_file:$phy(num_drc_errors,line_number)
        set misc_status($build_label,$task_id,num_drc_errors,value) $data
        set misc_status($build_label,$task_id,num_drc_errors,link) $link
      }

      if { [info exists phy(num_drc_errors_types)] } {
        set data $phy(num_drc_errors_types)
        set link $phy_file:$phy(num_drc_errors_types,line_number)
        set misc_status($build_label,$task_id,num_drc_errors_types,value) $data
        set misc_status($build_label,$task_id,num_drc_errors_types,link) $link
      }

    }

    if { [info exists vth] } {
      foreach vth_name $vth(vth,vth_names) {

        set metric_display "Vth Percent ($vth_name)"
        set metric_name vth_percent_$vth_name
        sproc_metric -cmd add -metric_name $metric_name -display_name $metric_display

        if { [info exists vth(cell_percentage,$vth_name)] } {
          set data $vth(cell_percentage,$vth_name)
          set link $vth_file:$vth(cell_percentage,$vth_name,line_number)
          set misc_status($build_label,$task_id,$metric_name,value) $data
          set misc_status($build_label,$task_id,$metric_name,link) $link
        }

        set metric_display "Vth Count ($vth_name)"
        set metric_name vth_count_$vth_name
        sproc_metric -cmd add -metric_name $metric_name -display_name $metric_display

        if { [info exists vth(cell_count,$vth_name)] } {
          set data $vth(cell_count,$vth_name)
          set link $vth_file:$vth(cell_count,$vth_name,line_number)
          set misc_status($build_label,$task_id,$metric_name,value) $data
          set misc_status($build_label,$task_id,$metric_name,link) $link
        }

      }
    }

    if { [info exists power] } {
      set total_power_max ""
      set total_power_units ""
      set total_power_line_number ""
      set leakage_power_max ""
      set leakage_power_units ""
      set leakage_power_line_number ""

      foreach scenario_name $power(scenario_name_list) {
        set total_power_units   $power($scenario_name,total_power_units)
        set leakage_power_units $power($scenario_name,leakage_power_units)

        if { [string is double -strict $power($scenario_name,total_power)] } {
          if { ($total_power_max == "") || ($power($scenario_name,total_power) > $total_power_max) } {
            set total_power_max         $power($scenario_name,total_power)
            set total_power_line_number $power($scenario_name,total_power,line_number)
          }
        }

        if { [string is double -strict $power($scenario_name,leakage_power)] } {
          if { ($leakage_power_max == "") || ($power($scenario_name,leakage_power) > $leakage_power_max) } {
            set leakage_power_max         $power($scenario_name,leakage_power)
            set leakage_power_line_number $power($scenario_name,leakage_power,line_number)
          }
        }
      }

      if { [string is double -strict $total_power_max] } {
        set data [format "%.2f %s" $total_power_max $total_power_units]
        set link $power_file:$total_power_line_number
        set misc_status($build_label,$task_id,total_power_max,value) $data
        set misc_status($build_label,$task_id,total_power_max,link) $link
      }

      if { [string is double -strict $leakage_power_max] } {
        set data [format "%.2f %s" $leakage_power_max $leakage_power_units]
        set link $power_file:$leakage_power_line_number
        set misc_status($build_label,$task_id,leakage_power_max,value) $data
        set misc_status($build_label,$task_id,leakage_power_max,link) $link
      }
    }

  }

  ## Factor the time unit back into the metric display names

  foreach metric_name [sproc_metric -cmd metrics] {
    set display_name [sproc_metric -cmd display -metric_name $metric_name]
    set display_name [regsub {TIME_UNIT} $display_name $theTimeUnit]
    sproc_metric -cmd add -metric_name $metric_name -display_name $display_name
  }

}

## -----------------------------------------------------------------------------
## Metric colors
## -----------------------------------------------------------------------------

proc attrColor { metric_name metric_value } {

  set attr ""

  if { [string is double -strict $metric_value] } {

    switch $metric_name {
      design_setup_wns -
      design_setup_tns -
      design_setup_nvp -
      design_hold_wns -
      design_hold_tns -
      design_hold_nvp {
        if { $metric_value < 0 } {
          set attr "#ffffff:#ff0000"
        }
      }
      ldrc_total -
      ldrc_trans -
      ldrc_cap -
      ldrc_fanout {
        if { $metric_value > 0 } {
          set attr "#ffffff:#0000ff"
        }
      }
      num_drc_errors {
        if { $metric_value > 0 } {
          set attr "#ffffff:#ff00ff"
        }
      }
    }

  }

  return $attr

}

## -----------------------------------------------------------------------------
## sproc_create_final_report:
## -----------------------------------------------------------------------------

proc sproc_create_final_report {} {

  global env garg gvar
  global misc_status

  set fid [open $gvar(report_file) w]

  ## -------------------------------------
  ## Determine all available builds
  ## -------------------------------------

  set build_label_list [list]
  foreach build_item $gvar(build_item_list) {
    lassign $build_item build_label build_dir
    lappend build_label_list $build_label
  }

  set hasSingleBlock 0
  if { [llength $build_label_list] == 1 } {
    set hasSingleBlock 1
  }

  ## -------------------------------------
  ## Print the LYNX_BEGIN statement
  ## -------------------------------------

  puts $fid "LYNX_BEGIN|lynx_table_merge|my_table_merge"
  puts $fid ""

  puts $fid "TABLE_ID_FORMAT|TableStyle"
  puts $fid ""

  set tableStyleList [list TaskFocus TrendFocus]

  foreach tableStyle $tableStyleList {

    ## -------------------------------------
    ## Print the TABLE_BEGIN statement
    ## -------------------------------------

    puts $fid "TABLE_BEGIN"
    puts $fid ""

    puts $fid "TABLE_ID|$tableStyle"
    puts $fid ""

    ## -------------------------------------
    ## Print the DATA section
    ## -------------------------------------

    unset -nocomplain attr_lines
    unset -nocomplain link_lines

    set attr_array(rowHeader1) #ffffff:#000099:L
    set attr_array(rowHeader2) #ffffff:#3333ff:C
    set attr_array(colHeader1) #ffffff:#303030:L

    puts $fid "DATA_BEGIN"

    ## -------------------------------------
    ## Print the HEADER lines
    ## While doing this, also:
    ## Create information for ATTR section (create $attr_lines, which is output later)
    ## Create information for LINK section (create $link_lines, which is output later)
    ## -------------------------------------

    if { $tableStyle == "TaskFocus" } {

      ## Tasks across top (and builds if multi-build), Metrics down left
      ## Row 0: task_step
      ## Row 1: task_dst
      ## Row 2: task_name
      ## Row 3: build_label (if multi-build)

      ## Single frozen col for metrics
      puts $fid "HEADER_COLS|1"

      if { $hasSingleBlock } {
        ## step, dst, task
        set headerRows 3
      } else {
        ## step, dst, task, build
        set headerRows 4
      }

      for { set row 0 } { $row < $headerRows } { incr row } {

        set header_line "HEADER"
        set attr_line   "HEADER"
        set link_line   "HEADER"

        set header_line "$header_line|Metric"
        set attr_line   "$attr_line|$attr_array(rowHeader1)"
        set link_line   "$link_line|"

        foreach task_info [sproc_build_info -build_label $build_label -cmd get] {
          lassign $task_info task_flow_order task_step task_dst task_name task_id task_tool task_report_list

          foreach build_label $build_label_list {
            switch $row {
              0 {
                set header_line "$header_line|$task_step"
                set attr_line   "$attr_line|$attr_array(rowHeader2)"
                set link_line   "$link_line|"
              }
              1 {
                set header_line "$header_line|$task_dst"
                set attr_line   "$attr_line|$attr_array(rowHeader2)"
                set link_line   "$link_line|"
              }
              2 {
                set header_line "$header_line|$task_name"
                set attr_line   "$attr_line|$attr_array(rowHeader2)"
                set link_line   "$link_line|"
              }
              3 {
                set header_line "$header_line|$build_label"
                set attr_line   "$attr_line|$attr_array(rowHeader2)"
                set link_line   "$link_line|"
              }
            }
          }
        }

        puts $fid $header_line
        lappend attr_lines $attr_line
        lappend link_lines $link_line

      }

    } else {

      ## Metrics across top (and builds if multi-build), tasks down left

      if { $hasSingleBlock } {

        ## Print 1 row headers
        ## Row 0: metrics

        puts $fid "HEADER_COLS|3"

        set header_line "HEADER"
        set attr_line   "HEADER"
        set link_line   "HEADER"

        set header_line "$header_line|Step|Dst|Task"
        set attr_line   "$attr_line|$attr_array(rowHeader1)|$attr_array(rowHeader1)|$attr_array(rowHeader1)"
        set link_line   "$link_line|||"

        foreach metric_name [sproc_metric -cmd metrics] {
          set header_line "$header_line|[sproc_metric -cmd display -metric_name $metric_name]"
          set attr_line   "$attr_line|$attr_array(rowHeader2)"
          set link_line   "$link_line|"
        }

        puts $fid $header_line
        lappend attr_lines $attr_line
        lappend link_lines $link_line

      } else {

        ## Print 2 row headers
        ## Row 0: metrics (replicate each column of metrics per number of builds)
        ## Row 1: builds (cycle through builds for each metric)

        puts $fid "HEADER_COLS|3"

        ## Row 0:

        set header_line "HEADER"
        set attr_line   "HEADER"
        set link_line   "HEADER"

        set header_line "$header_line|Step|Dst|Task"
        set attr_line   "$attr_line|$attr_array(rowHeader1)|$attr_array(rowHeader1)|$attr_array(rowHeader1)"
        set link_line   "$link_line|||"

        foreach metric_name [sproc_metric -cmd metrics] {
          foreach build_label $build_label_list {
            set header_line "$header_line|[sproc_metric -cmd display -metric_name $metric_name]"
            set attr_line   "$attr_line|$attr_array(rowHeader2)"
            set link_line   "$link_line|"
          }
        }

        puts $fid $header_line
        lappend attr_lines $attr_line
        lappend link_lines $link_line

        ## Row 1:

        set header_line "HEADER"
        set attr_line   "HEADER"
        set link_line   "HEADER"

        set header_line "$header_line|Step|Dst|Task"
        set attr_line   "$attr_line|$attr_array(rowHeader1)|$attr_array(rowHeader1)|$attr_array(rowHeader1)"
        set link_line   "$link_line|||"

        foreach metric_name [sproc_metric -cmd metrics] {
          foreach build_label $build_label_list {
            set header_line "$header_line|$build_label"
            set attr_line   "$attr_line|$attr_array(rowHeader2)"
            set link_line   "$link_line|"
          }
        }

        puts $fid $header_line
        lappend attr_lines $attr_line
        lappend link_lines $link_line

      }

    }

    ## -------------------------------------
    ## Print the VALUE lines
    ## While doing this, also:
    ## Create information for ATTR section (create $attr_lines, which is output later)
    ## Create information for LINK section (create $link_lines, which is output later)
    ## -------------------------------------

    if { $tableStyle == "TaskFocus" } {

      ## Tasks across top (and builds if multi-build), Metrics down left

      foreach metric_name [sproc_metric -cmd metrics] {

        set value_line "VALUE"
        set attr_line  "VALUE"
        set link_line  "VALUE"

        set value_line "$value_line|[sproc_metric -cmd display -metric_name $metric_name]"
        set attr_line  "$attr_line|$attr_array(colHeader1)"
        set link_line  "$link_line|"

        foreach task_info [sproc_build_info -build_label $build_label -cmd get] {
          lassign $task_info task_flow_order task_step task_dst task_name task_id task_tool task_report_list

          foreach build_label $build_label_list {

            if { [info exists misc_status($build_label,$task_id,$metric_name,value)] } {
              set value $misc_status($build_label,$task_id,$metric_name,value)
            } else {
              set value ""
            }
            set attr [attrColor $metric_name $value]

            if { [info exists misc_status($build_label,$task_id,$metric_name,link)] } {
              set link $misc_status($build_label,$task_id,$metric_name,link)
            } else {
              set link ""
            }

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

      foreach task_info [sproc_build_info -build_label $build_label -cmd get] {
        lassign $task_info task_flow_order task_step task_dst task_name task_id task_tool task_report_list

        set value_line "VALUE|$task_step|$task_dst|$task_name"
        set attr_line  "VALUE|$attr_array(colHeader1)|$attr_array(colHeader1)|$attr_array(colHeader1)"
        set link_line  "VALUE|||"

        foreach metric_name [sproc_metric -cmd metrics] {
          foreach build_label $build_label_list {

            if { [info exists misc_status($build_label,$task_id,$metric_name,value)] } {
              set value $misc_status($build_label,$task_id,$metric_name,value)
            } else {
              set value ""
            }
            set attr [attrColor $metric_name $value]

            if { [info exists misc_status($build_label,$task_id,$metric_name,link)] } {
              set link $misc_status($build_label,$task_id,$metric_name,link)
            } else {
              set link ""
            }

            set value_line "$value_line|$value"
            set attr_line  "$attr_line|$attr"
            set link_line  "$link_line|$link"

          }
        }

        puts $fid $value_line
        lappend attr_lines $attr_line
        lappend link_lines $link_line
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

    set title "Design Summary ($tableStyle) : "

    foreach build_label $build_label_list {
      set title "$title $build_label"
    }

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
