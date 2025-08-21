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
  puts "Usage: gen_status.tcl"
  puts "         \[-config_list <config_list>\]"
  puts "         \[-config_file <config_file>\]"
  puts "         \[-report_file <report_file>\]"
  puts "         \[-debug\]"
  puts "         \[-message\]"

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
  ## Determine the most recent build report_qor file
  ## -------------------------------------

  unset -nocomplain qor
  unset -nocomplain phy
  set progress_step undefined
  set progress_dst  undefined

  set file_list [glob -nocomplain $build_dir/*/*/rpts/*/icc2.report_qor]

  if { [llength $file_list] > 0 } {

    set file_item_list [list]
    foreach file $file_list {
      set mtime [file mtime $file]
      set file_item [list $file $mtime]
      lappend file_item_list $file_item
    }
    set file_item_list [lsort -decreasing -index 1 $file_item_list]

    set qor_file [lindex [lindex $file_item_list 0] 0]
    set phy_file [regsub {\.report_qor} $qor_file {.report_utilization}]

    if { [file exists $qor_file] } {
      set progress_step [lindex [split $qor_file /] end-4]
      set progress_dst  [lindex [split $qor_file /] end-3]
      array set qor [sproc_parse_report_qor -file $qor_file]
    }

    if { [file exists $phy_file] } {
      array set phy [sproc_parse_report_utilization -file $phy_file]
    }

  }

  ## -------------------------------------
  ## Stuff results into misc_status
  ## -------------------------------------

  set index User
  set value [lindex [split $build_dir /] end-2]
  set misc_status($build_label,value,$index) $value
  set misc_status($build_label,link,$index) ""

  set index Tag
  set value [lindex [split $build_dir /] end-1]
  set misc_status($build_label,value,$index) $value
  set misc_status($build_label,link,$index) ""

  set index Snapshot
  set value [lindex [split $build_dir /] end-0]
  set misc_status($build_label,value,$index) $value
  set misc_status($build_label,link,$index) ""

  set index "Progress Step"
  set value $progress_step
  set misc_status($build_label,value,$index) $value
  set misc_status($build_label,link,$index) ""

  set index "Progress Dst"
  set value $progress_dst
  set misc_status($build_label,value,$index) $value
  set misc_status($build_label,link,$index) ""

  set index "Setup WNS"
  if { [info exists qor(summary_data,_ms,setup,path_slack)] } {
    set value [format_value "%.2f" $qor(summary_data,_ms,setup,path_slack)]
    set misc_status($build_label,value,$index) [format "%.2f" $value]
    set misc_status($build_label,link,$index) $qor_file:$qor(summary_data,_ms,setup,path_slack,line_number)
  } else {
    set misc_status($build_label,value,$index) ""
    set misc_status($build_label,link,$index) ""
  }
  set index "Setup TNS"
  if { [info exists qor(summary_data,_ms,setup,tns)] } {
    set value $qor(summary_data,_ms,setup,tns)
    set misc_status($build_label,value,$index) [format "%.2f" $value]
    set misc_status($build_label,link,$index) $qor_file:$qor(summary_data,_ms,setup,tns,line_number)
  } else {
    set misc_status($build_label,value,$index) ""
    set misc_status($build_label,link,$index) ""
  }
  set index "Setup NVP"
  if { [info exists qor(summary_data,_ms,setup,nvp)] } {
    set value $qor(summary_data,_ms,setup,nvp)
    set misc_status($build_label,value,$index) $value
    set misc_status($build_label,link,$index) $qor_file:$qor(summary_data,_ms,setup,nvp,line_number)
  } else {
    set misc_status($build_label,value,$index) ""
    set misc_status($build_label,link,$index) ""
  }

  set index "Hold WNS"
  if { [info exists qor(summary_data,_ms,hold,path_slack)] } {
    set value [format_value "%.2f" $qor(summary_data,_ms,hold,path_slack)]
    set misc_status($build_label,value,$index) [format "%.2f" $value]
    set misc_status($build_label,link,$index) $qor_file:$qor(summary_data,_ms,hold,path_slack,line_number)
  } else {
    set misc_status($build_label,value,$index) ""
    set misc_status($build_label,link,$index) ""
  }
  set index "Hold TNS"
  if { [info exists qor(summary_data,_ms,hold,tns)] } {
    set value $qor(summary_data,_ms,hold,tns)
    set misc_status($build_label,value,$index) [format "%.2f" $value]
    set misc_status($build_label,link,$index) $qor_file:$qor(summary_data,_ms,hold,tns,line_number)
  } else {
    set misc_status($build_label,value,$index) ""
    set misc_status($build_label,link,$index) ""
  }
  set index "Hold NVP"
  if { [info exists qor(summary_data,_ms,hold,nvp)] } {
    set value $qor(summary_data,_ms,hold,nvp)
    set misc_status($build_label,value,$index) $value
    set misc_status($build_label,link,$index) $qor_file:$qor(summary_data,_ms,hold,nvp,line_number)
  } else {
    set misc_status($build_label,value,$index) ""
    set misc_status($build_label,link,$index) ""
  }

  set index "Area"
  if { [info exists qor(design_data,design_area)] } {
    set value $qor(design_data,design_area)
    set misc_status($build_label,value,$index) [format "%.0f" $value]
    set misc_status($build_label,link,$index) $qor_file:$qor(design_data,design_area,line_number)
  } else {
    set misc_status($build_label,value,$index) ""
    set misc_status($build_label,link,$index) ""
  }

  set index "Cell Count"
  if { [info exists qor(design_data,leaf_cell_count)] } {
    set value $qor(design_data,leaf_cell_count)
    set misc_status($build_label,value,$index) $value
    set misc_status($build_label,link,$index) $qor_file:$qor(design_data,leaf_cell_count,line_number)
  } else {
    set misc_status($build_label,value,$index) ""
    set misc_status($build_label,link,$index) ""
  }

  set index "Flop Count"
  if { [info exists qor(design_data,seq_cell_count)] } {
    set value $qor(design_data,seq_cell_count)
    set misc_status($build_label,value,$index) $value
    set misc_status($build_label,link,$index) $qor_file:$qor(design_data,seq_cell_count,line_number)
  } else {
    set misc_status($build_label,value,$index) ""
    set misc_status($build_label,link,$index) ""
  }

  set index "Utilization"
  if { [info exists phy(cell2core_ratio)] } {
    set value $phy(cell2core_ratio)
    set misc_status($build_label,value,$index) $value
    set misc_status($build_label,link,$index) $phy_file:$phy(cell2core_ratio,line_number)
  } else {
    set misc_status($build_label,value,$index) ""
    set misc_status($build_label,link,$index) ""
  }

}

## -----------------------------------------------------------------------------
## Metric colors
## -----------------------------------------------------------------------------

proc headerColor { name } {

  set color(white)     "#ffffff"
  set color(black)     "#000000"
  set color(red)       "#f7384a"
  set color(green)     "#00ff00"
  set color(blue)      "#29516d"
  set color(yellow)    "#daf959"
  set color(brown_2)   "#695538"
  set color(brown_1)   "#d7c7b1"
  set color(brown_0)   "#fff6e8"
  set color(green_3)   "#25463b"
  set color(green_2)   "#3f6156"
  set color(green_1)   "#768f87"
  set color(green_0)   "#9eaea9"
  set color(gray)      "#e0e0e0"
  set color(darkblue)  "#000099"
  set color(lightblue) "#3333ff"

  set color_h_first   $color(white):$color(darkblue)
  set color_h_other   $color(white):$color(lightblue)
  set color_r_first   $color(black):$color(gray)
  set color_r_normal  $color(black):$color(white)
  set color_r_warning $color(black):$color(yellow)
  set color_r_error   $color(black):$color(red)
  set color_r_undef   $color(white):$color(lightblue)

  set set1 [list "Tag" "Area" "Cell Count"]
  set set2 [list "User" "Snapshot" "Utilization" "Flop Count"]
  set set3 [list "Progress Step" "Setup NVP" "Setup WNS" "Hold TNS"]
  set set4 [list "Progress Dst" "Setup TNS" "Hold NVP" "Hold WNS"]
  set set5 [list "Lineage"]
  set set6 [list "Progress"]
  set set7 [list "Content"]
  set set8 [list "Timing" "Setup" "Hold"]
  set set9 [list "Design Name"]

  if { [lsearch $set1 $name] >= 0 } {
    set attr $color(black):$color(brown_1)
  } elseif { [lsearch $set2 $name] >= 0 } {
    set attr $color(black):$color(brown_0)
  } elseif { [lsearch $set3 $name] >= 0 } {
    set attr $color(black):$color(green_1)
  } elseif { [lsearch $set4 $name] >= 0 } {
    set attr $color(black):$color(green_0)
  } elseif { [lsearch $set5 $name] >= 0 } {
    set attr $color(white):$color(brown_2)
  } elseif { [lsearch $set6 $name] >= 0 } {
    set attr $color(white):$color(green_3)
  } elseif { [lsearch $set7 $name] >= 0 } {
    set attr $color(white):$color(brown_2)
  } elseif { [lsearch $set8 $name] >= 0 } {
    set attr $color(white):$color(green_2)
  } elseif { [lsearch $set9 $name] >= 0 } {
    set attr $color(black):$color(brown_1)
  } else {
    set attr $color(white):$color(red)
  }

  return $attr

}

proc attrColor { name value } {

  set color(white)     "#ffffff"
  set color(black)     "#000000"
  set color(red)       "#f7384a"
  set color(green)     "#00ff00"
  set color(blue)      "#29516d"
  set color(yellow)    "#daf959"
  set color(brown_2)   "#695538"
  set color(brown_1)   "#d7c7b1"
  set color(brown_0)   "#fff6e8"
  set color(green_3)   "#25463b"
  set color(green_2)   "#3f6156"
  set color(green_1)   "#768f87"
  set color(green_0)   "#9eaea9"
  set color(gray)      "#e0e0e0"
  set color(darkblue)  "#000099"
  set color(lightblue) "#3333ff"

  set color_h_first   $color(white):$color(darkblue)
  set color_h_other   $color(white):$color(lightblue)
  set color_r_first   $color(black):$color(gray)
  set color_r_normal  $color(black):$color(white)
  set color_r_warning $color(black):$color(yellow)
  set color_r_error   $color(black):$color(red)
  set color_r_undef   $color(white):$color(lightblue)

  set set1 [list "Progress Step" "Progress Dst"]
  set set2 [list "Setup NVP" "Hold NVP"]
  set set3 [list "Setup TNS" "Setup WNS" "Hold TNS" "Hold WNS"]
  set set4 [list "Utilization"]
  set set5 [list "build_label"]

  set attr ""

  if { [lsearch $set1 $name] >= 0 } {
    if { $value == "undefined" } {
      set attr $color_r_undef
    }
  } elseif { [lsearch $set2 $name] >= 0 } {
    if { [string is double -strict $value] } {
      if { $value > 0 } {
        set attr $color_r_error
      }
    }
  } elseif { [lsearch $set3 $name] >= 0 } {
    if { [string is double -strict $value] } {
      if { $value < 0 } {
        set attr $color_r_error
      }
    }
  } elseif { [lsearch $set4 $name] >= 0 } {
    if { [string is double -strict $value] } {
      if { $value > 60 } {
        set attr $color_r_warning
      }
    }
  } elseif { [lsearch $set5 $name] >= 0 } {
    set attr $color_r_first
  }

  return $attr

}

## -----------------------------------------------------------------------------
## sproc_create_final_report:
## -----------------------------------------------------------------------------

proc sproc_create_final_report {} {

  global env garg gvar
  global misc_status

  set item_list [list \
    "User" \
    "Tag"  \
    "Snapshot" \
    "Progress Step" \
    "Progress Dst" \
    "Area" \
    "Utilization" \
    "Cell Count" \
    "Flop Count" \
    "Setup NVP" \
    "Setup TNS" \
    "Setup WNS" \
    "Hold NVP" \
    "Hold TNS" \
    "Hold WNS" \
    ]

  set fid [open $gvar(report_file) w]

  ## -------------------------------------
  ## Print the LYNX_BEGIN statement
  ## -------------------------------------

  puts $fid "LYNX_BEGIN|lynx_table_merge|my_table_merge"
  puts $fid ""

  ## -------------------------------------
  ## Print the TABLE_BEGIN statement
  ## -------------------------------------

  puts $fid "TABLE_BEGIN"
  puts $fid ""

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

  ## -------------------------------------
  ## Print the HEADER lines (merge style)
  ## -------------------------------------

  ## Line #1

  set header_line "HEADER"
  set header_line "$header_line[string repeat {|Lineage} 4]"
  set header_line "$header_line[string repeat {|Progress} 2]"
  set header_line "$header_line[string repeat {|Content} 4]"
  set header_line "$header_line[string repeat {|Timing} 6]"

  set attr_line "HEADER"
  set attr_line "$attr_line[string repeat "|[headerColor {Lineage}]" 4]"
  set attr_line "$attr_line[string repeat "|[headerColor {Progress}]" 2]"
  set attr_line "$attr_line[string repeat "|[headerColor {Content}]" 4]"
  set attr_line "$attr_line[string repeat "|[headerColor {Timing}]" 6]"

  set link_line "HEADER"
  set link_line "$link_line[string repeat "|" 4]"
  set link_line "$link_line[string repeat "|" 2]"
  set link_line "$link_line[string repeat "|" 4]"
  set link_line "$link_line[string repeat "|" 6]"

  puts $fid $header_line
  lappend attr_lines $attr_line
  lappend link_lines $link_line

  ## Line #2

  set header_line "HEADER"
  set header_line "$header_line[string repeat {|Lineage} 4]"
  set header_line "$header_line[string repeat {|Progress} 2]"
  set header_line "$header_line[string repeat {|Content} 4]"
  set header_line "$header_line[string repeat {|Setup} 3]"
  set header_line "$header_line[string repeat {|Hold} 3]"

  set attr_line "HEADER"
  set attr_line "$attr_line[string repeat "|[headerColor {Lineage}]" 4]"
  set attr_line "$attr_line[string repeat "|[headerColor {Progress}]" 2]"
  set attr_line "$attr_line[string repeat "|[headerColor {Content}]" 4]"
  set attr_line "$attr_line[string repeat "|[headerColor {Setup}]" 3]"
  set attr_line "$attr_line[string repeat "|[headerColor {Hold}]" 3]"

  set link_line "HEADER"
  set link_line "$link_line[string repeat "|" 4]"
  set link_line "$link_line[string repeat "|" 2]"
  set link_line "$link_line[string repeat "|" 4]"
  set link_line "$link_line[string repeat "|" 3]"
  set link_line "$link_line[string repeat "|" 3]"

  puts $fid $header_line
  lappend attr_lines $attr_line
  lappend link_lines $link_line

  ## Line #3

  set header_line "HEADER"
  set attr_line "HEADER"
  set link_line "HEADER"

  set header_line "$header_line|Design Name"
  set attr_line "$attr_line|[headerColor {Design Name}]"
  set link_line "$link_line|"

  foreach item $item_list {
    set header_line "$header_line|$item"
    set attr_line "$attr_line|[headerColor $item]"
    set link_line "$link_line|"
  }

  puts $fid $header_line
  lappend attr_lines $attr_line
  lappend link_lines $link_line

  ## -------------------------------------
  ## Print the VALUE lines
  ## While doing this, also:
  ## Create information for ATTR section (create $attr_lines, which is output later)
  ## Create information for LINK section (create $link_lines, which is output later)
  ## -------------------------------------

  foreach build_item $gvar(build_item_list) {

    set build_label [lindex $build_item 0]

    set value_line "VALUE"
    set value_line "$value_line|$build_label"

    set attr_line "VALUE"
    set attr_line "$attr_line|[attrColor build_label {}]"

    set link_line "VALUE"
    set link_line "$link_line|"

    foreach item $item_list {
      if { [info exists misc_status($build_label,value,$item)] } {
        set value $misc_status($build_label,value,$item)
        set link  $misc_status($build_label,link,$item)
        set value_line "$value_line|$value"
        set link_line "$link_line|$link"
        set attr_line "$attr_line|[attrColor $item $value]"
      } else {
        set value_line "$value_line|"
        set link_line "$link_line|"
        set attr_line "$attr_line|"
      }
    }

    puts $fid $value_line
    lappend attr_lines $attr_line
    lappend link_lines $link_line

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

  set title "Project 'Lynx' Status Report"
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
