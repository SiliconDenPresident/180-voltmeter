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
set garg(var)         0
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
    -var {
      set garg(var) 1
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
  puts "Usage: gen_scenario_matrix.tcl"
  puts "         \[-config_list <build dirname pairs>\]"
  puts "         \[-config_file <config_file>\]"
  puts "         \[-report_file <report_file>\]"
  puts "         \[-flip\]"
  puts "         \[-var\]"
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

  sproc_build_info -cmd init -build_label $build_label -build_dir $build_dir -reports $reports

  if { $garg(debug) } {
    sproc_debug $build_label $build_dir
  }

  ## -------------------------------------
  ## Gather metrics for each task
  ## -------------------------------------

  sproc_metric -cmd add -metric_name {setup,logic_levels} -display_name {Levels of Logic}          
  sproc_metric -cmd add -metric_name {setup,path_length}  -display_name {Critical Path Length}     
  sproc_metric -cmd add -metric_name {setup,path_slack}   -display_name {Critical Path Slack}      
  sproc_metric -cmd add -metric_name {setup,path_period}  -display_name {Critical Path Clk Period} 
  sproc_metric -cmd add -metric_name {setup,tns}          -display_name {Total Negative Slack}     
  sproc_metric -cmd add -metric_name {setup,nvp}          -display_name {No. of Violating Paths}   
  sproc_metric -cmd add -metric_name {hold,path_slack}    -display_name {Worst Hold Violation}     
  sproc_metric -cmd add -metric_name {hold,tns}           -display_name {Total Hold Violation}     
  sproc_metric -cmd add -metric_name {hold,nvp}           -display_name {No. of Hold Violations}          

  set task_info_list [sproc_build_info -build_label $build_label -cmd get]
  foreach task_info $task_info_list {
    lassign $task_info task_flow_order task_step task_dst task_name task_id task_tool task_report_list

    ## -------------------------------------
    ## Parse the reports for this task
    ## -------------------------------------

    unset -nocomplain qor

    set qor_file [lindex $task_report_list 0]

    ## Create variables for all report files
    sproc_filevar -cmd add_file -file_name $qor_file

    array set qor [sproc_parse_report_qor -file $qor_file]

    ## Only include task if there are results

    if { ([llength $qor(path_group_data,scenario_name_list)] == 0) } {
      sproc_build_info -build_label $build_label -cmd del -task_id $task_id
      continue
    }

    ## -------------------------------------
    ## Stuff results into misc_status
    ## -------------------------------------

    set misc_status(scenario_name_list,$task_id) [list]
    set misc_status(path_group_name_list,$task_id) [list]

    foreach scenario_name [lsort -unique $qor(path_group_data,scenario_name_list)] {
      lappend misc_status(scenario_name_list,$task_id) $scenario_name
      foreach path_group_name $qor(path_group_data,path_group_name_list,$scenario_name) {
        lappend misc_status(path_group_name_list,$task_id) $path_group_name
        foreach metric_name [sproc_metric -cmd metrics] {
          set data $qor(path_group_data,$scenario_name,$path_group_name,$metric_name)
          set line_number $qor(path_group_data,$scenario_name,$path_group_name,$metric_name,line_number)
          if { $garg(var) } {
            set fileVar [sproc_filevar -cmd get_var -file_name $qor_file]
            set link "\$($fileVar):$line_number"
          } else {
            set link $qor_file:$line_number
          }

          set misc_status($build_label,$task_id,$scenario_name,$path_group_name,$metric_name,value) $data
          set misc_status($build_label,$task_id,$scenario_name,$path_group_name,$metric_name,link) $link
        }
      }
    }

  }

  foreach task_info [sproc_build_info -build_label $build_label -cmd get] {
    lassign $task_info task_flow_order task_step task_dst task_name task_id task_tool task_report_list
    set misc_status(scenario_name_list,$task_id)   [lsort -unique $misc_status(scenario_name_list,$task_id)]
    set misc_status(path_group_name_list,$task_id) [lsort -unique $misc_status(path_group_name_list,$task_id)]
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

  if { $garg(var) } {
    foreach fileName [lsort [sproc_filevar -cmd get_files]] {
      set fileVar [sproc_filevar -cmd get_var -file_name $fileName]
      puts $fid "VARIABLE|$fileVar|$fileName"
    }
  }

  puts $fid "TABLE_ID_FORMAT|Step|Dst|Task"
  puts $fid ""

  puts -nonewline $fid "CELL_ID_LIST"
  foreach metric_name [sproc_metric -cmd metrics] {
    puts -nonewline $fid "|[sproc_metric -cmd display -metric_name $metric_name]"
  }
  puts $fid ""
  puts $fid ""

  foreach task_info [sproc_build_info -build_label $build_label -cmd get] {
    lassign $task_info task_flow_order task_step task_dst task_name task_id task_tool task_report_list

    ## -------------------------------------
    ## Print the TABLE_BEGIN statement
    ## -------------------------------------

    puts $fid "TABLE_BEGIN"
    puts $fid ""

    puts $fid "TABLE_ID|$task_step|$task_dst|$task_name"
    puts $fid ""

    set color_array(white|darkBlue)  #ffffff:#000099
    set color_array(white|lightBlue) #ffffff:#3333ff
    set color_array(white|darkGray)  #ffffff:#303030

    foreach metric_name [sproc_metric -cmd metrics] {

      unset -nocomplain attr_lines
      unset -nocomplain link_lines

      ## -------------------------------------
      ## Print the DATA section
      ## -------------------------------------

      puts $fid "DATA_BEGIN"
      puts $fid "CELL_ID|[sproc_metric -cmd display -metric_name $metric_name]"

      ## -------------------------------------
      ## Print the HEADER lines
      ## While doing this, also:
      ## Create information for ATTR section (create $attr_lines, which is output later)
      ## Create information for LINK section (create $link_lines, which is output later)
      ## -------------------------------------

      if { $garg(flip) } {

        ## Print 1 row header
        ## In row 1, use path_group

        puts $fid "HEADER_COLS|1"

        set header_line "HEADER|Scenario"
        set attr_line   "HEADER|$color_array(white|darkBlue)"
        set link_line   "HEADER|"

        foreach path_group_name $misc_status(path_group_name_list,$task_id) {
          set header_line "$header_line|$path_group_name"
          set attr_line   "$attr_line|$color_array(white|lightBlue)"
          set link_line   "$link_line|"
        }

        puts $fid $header_line
        lappend attr_lines $attr_line
        lappend link_lines $link_line

      } else {

        ## Print 3 row headers
        ## In row 1, use scenario mode
        ## In row 2, use scenario oc_cond
        ## In row 3, use scenario rc_cond

        puts $fid "HEADER_COLS|1"

        for { set row 1 } { $row <= 3 } { incr row } {

          set header_line "HEADER|Path Groups"
          set attr_line   "HEADER|$color_array(white|darkBlue)"
          set link_line   "HEADER|"

          foreach scenario_name $misc_status(scenario_name_list,$task_id) {
            if { $misc_status(scenario_name_list,$task_id) == "None/non-MCMM" } {
              set mode    $misc_status(scenario_name_list,$task_id)
              set op_cond $misc_status(scenario_name_list,$task_id)
              set rc_cond $misc_status(scenario_name_list,$task_id)
            } else {
              set fields [split $scenario_name .]
              set mode    [lindex $fields 0]
              set op_cond [lindex $fields 1]
              set rc_cond [lindex $fields 2]
            }
            if { $row == 1 } {
              set header_line "$header_line|$mode"
            } elseif { $row == 2 } {
              set header_line "$header_line|$op_cond"
            } else {
              set header_line "$header_line|$rc_cond"
            }
            set attr_line   "$attr_line|$color_array(white|lightBlue)"
            set link_line   "$link_line|"
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

      if { $garg(flip) } {

        foreach scenario_name $misc_status(scenario_name_list,$task_id) {

          set value_line "VALUE|$scenario_name"
          set attr_line  "VALUE|$color_array(white|darkGray)"
          set link_line  "VALUE|"

          foreach path_group_name $misc_status(path_group_name_list,$task_id) {

            if { [info exists misc_status($build_label,$task_id,$scenario_name,$path_group_name,$metric_name,value)] } {
              set value $misc_status($build_label,$task_id,$scenario_name,$path_group_name,$metric_name,value)

              set attr ""
              switch $metric_name {
                setup,path_slack -
                setup,tns {
                  if { ($value != "") && ($value < 0) } {
                    set attr "#ffffff:#ff0000"
                  }
                }
                setup,nvp {
                  if { ($value != "") && ($value > 0) } {
                    set attr "#ffffff:#ff0000"
                  }
                }
                hold,path_slack -
                hold,tns {
                  if { ($value != "") && ($value < 0) } {
                    set attr "#ffffff:#ff00ff"
                  }
                }
                hold,nvp {
                  if { ($value != "") && ($value > 0) } {
                    set attr "#ffffff:#ff00ff"
                  }
                }
              }

              set link  $misc_status($build_label,$task_id,$scenario_name,$path_group_name,$metric_name,link)
            } else {
              set value ""
              set attr  ""
              set link  ""
            }

            set value_line "$value_line|$value"
            set attr_line  "$attr_line|$attr"
            set link_line  "$link_line|$link"
          }

          puts $fid $value_line
          lappend attr_lines $attr_line
          lappend link_lines $link_line
        }

      } else {

        foreach path_group_name $misc_status(path_group_name_list,$task_id) {

          set value_line "VALUE|$path_group_name"
          set attr_line  "VALUE|$color_array(white|darkGray)"
          set link_line  "VALUE|"

          foreach scenario_name $misc_status(scenario_name_list,$task_id) {

            if { [info exists misc_status($build_label,$task_id,$scenario_name,$path_group_name,$metric_name,value)] } {
              set value $misc_status($build_label,$task_id,$scenario_name,$path_group_name,$metric_name,value)

              set attr ""
              switch $metric_name {
                setup,path_slack -
                setup,tns {
                  if { ($value != "") && ($value < 0) } {
                    set attr "#ffffff:#ff0000"
                  }
                }
                setup,nvp {
                  if { ($value != "") && ($value > 0) } {
                    set attr "#ffffff:#ff0000"
                  }
                }
                hold,path_slack -
                hold,tns {
                  if { ($value != "") && ($value < 0) } {
                    set attr "#ffffff:#ff00ff"
                  }
                }
                hold,nvp {
                  if { ($value != "") && ($value > 0) } {
                    set attr "#ffffff:#ff00ff"
                  }
                }
              }

              set link  $misc_status($build_label,$task_id,$scenario_name,$path_group_name,$metric_name,link)
            } else {
              set value ""
              set attr  ""
              set link  ""
            }

            set value_line "$value_line|$value"
            set attr_line  "$attr_line|$attr"
            set link_line  "$link_line|$link"
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
      puts $fid "CELL_ID|[sproc_metric -cmd display -metric_name $metric_name]"
      foreach line $attr_lines {
        puts $fid $line
      }
      puts $fid "ATTR_END"
      puts $fid ""

      ## -------------------------------------
      ## Print the LINK section
      ## -------------------------------------

      puts $fid "LINK_BEGIN"
      puts $fid "CELL_ID|[sproc_metric -cmd display -metric_name $metric_name]"
      foreach line $link_lines {
        puts $fid $line
      }
      puts $fid "LINK_END"
      puts $fid ""

    }

    ## -------------------------------------
    ## Print the FORMAT section
    ## -------------------------------------

    ## -------------------------------------
    ## Create the title information
    ## -------------------------------------

    set title "Scenario Matrix Timing : $build_label : $task_id"
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
