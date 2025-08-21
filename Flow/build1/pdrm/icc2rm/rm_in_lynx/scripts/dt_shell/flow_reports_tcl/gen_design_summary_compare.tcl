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
  puts "Usage: gen_design_summary_compare.tcl"
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
set gvar(data_dir)     $gvar(prog_path)/gen_design_summary_compare.data

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
## sproc_create_final_report:
## -----------------------------------------------------------------------------

proc sproc_create_final_report {} {

  global garg gvar
  global misc_status
  global argv0

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

    foreach task_info [sproc_build_info -build_label $build_label -cmd get] {
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

  ## configure format.cfg
  set format_config_file $report_dir/data/format.cfg
  exec chmod u+w $format_config_file
  file delete -force $format_config_file.orig
  file copy $format_config_file $format_config_file.orig
  set in_id [open $format_config_file.orig r]
  set out_id [open $format_config_file w]
  set found_first_format 0
  while { [gets $in_id line] >= 0 } {
    if {!$found_first_format} {
      if {[regexp {^#OVERRIDES} $line]} {
        # add line to format.cfg to apply default rule to each metric
        foreach metric_name [sproc_metric -cmd metrics] {
          puts $out_id "FORMAT|[sproc_metric -cmd display -metric_name $metric_name]|STD_RULE_S"
        }
	set found_first_format 1
      }
    } 
    puts $out_id $line
  }
  close $in_id
  file delete -force $format_config_file.orig
  close $out_id

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
