## -----------------------------------------------------------------------------
## HEADER_MSG  Lynx Design System: Baseline Flow
## HEADER_MSG  Version 2019.03-SP2
## HEADER_MSG  Copyright (c) 2019 Synopsys
## HEADER_MSG  Perforce Label: lynx_flow_2019.03-SP2
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This file contains Lynx procedure definitions.
## -----------------------------------------------------------------------------

## -----------------------------------------------------------------------------
## Define some base variables & procedures
## -----------------------------------------------------------------------------

if { [info command parse_proc_arguments] != "parse_proc_arguments" } {

  proc parse_proc_arguments { required_switch args options_ref } {

    global define_proc_attributes_booleans
    global define_proc_attributes_args

    upvar $options_ref options

    set parent_level [expr [info level] - 1]
    set parent_name [lindex [info level $parent_level] 0]
    set parent_name [regsub {^::} $parent_name {}]

    if { $required_switch == "-args" } {
      for { set i 0 } { $i < [llength $args] } { incr i } {
        set arg [lindex $args $i]
        if { [lsearch $define_proc_attributes_args($parent_name) $arg] >= 0 } {
          ## This is a defined option
          if { [lsearch $define_proc_attributes_booleans($parent_name) $arg] >= 0 } {
            ## This is a boolean switch
            set options($arg) 1
          } else {
            ## This is not a boolean switch
            incr i
            set options($arg) [lindex $args $i]
          }
        } else {
          return -code error "Error: unknown option '$arg'"
        }
      }
    }
  }

}

if { [info command define_proc_attributes] != "define_proc_attributes" } {

  unset -nocomplain define_proc_attributes_booleans
  unset -nocomplain define_proc_attributes_args

  proc define_proc_attributes args {

    global define_proc_attributes_booleans
    global define_proc_attributes_args

    set proc_name ""
    set proc_args [list]

    for { set i 0 } { $i < [llength $args] } { incr i } {
      set arg [lindex $args $i]
      if { $i == 0 } {
        set proc_name $arg
        continue
      }
      switch -- $arg {
        -info {
          incr i
          continue
        }
        -hidden {
          continue
        }
        -define_args {
          incr i
          set proc_args [lindex $args $i]
        }
        default {
          puts stderr "Error: define_proc_attributes: Unrecognized argument: $arg"
        }
      }
    }

    if { $proc_name != "" } {
      set define_proc_attributes_booleans($proc_name) [list]
      set define_proc_attributes_args($proc_name) [list]
      foreach proc_arg $proc_args {
        set switch_name [lindex $proc_arg 0]
        set switch_type [lindex $proc_arg end-1]
        if { $switch_type == "boolean" } {
          lappend define_proc_attributes_booleans($proc_name) $switch_name
        }
        lappend define_proc_attributes_args($proc_name) $switch_name
      }
    } else {
      puts stderr "Error: define_proc_attributes: Procedure name not defined."
    }

  }

}

## -----------------------------------------------------------------------------
## sproc_msg:
## -----------------------------------------------------------------------------

proc sproc_msg { args } {

  ## Assigning default value of "bell" since that is never used.

  set options(-info)    "\b"
  set options(-warning) "\b"
  set options(-error)   "\b"
  set options(-setup)   "\b"
  set options(-issue)   "\b"
  set options(-note)    "\b"
  set options(-header)  0
  parse_proc_arguments -args $args options

  if       { $options(-info)   != "\b" } {
    puts "SNPS_INFO   : $options(-info)"
  } elseif { $options(-warning) != "\b" } {
    puts "SNPS_WARNING: $options(-warning)"
  } elseif { $options(-error)  != "\b" } {
    puts "SNPS_ERROR  : $options(-error)"
  } elseif { $options(-setup)  != "\b" } {
    puts "SNPS_SETUP  : $options(-setup)"
  } elseif { $options(-issue)  != "\b" } {
    puts "SNPS_ISSUE  : $options(-issue)"
  } elseif { $options(-note)  != "\b" } {
    puts "SNPS_NOTE  : $options(-note)"
  } elseif { $options(-header) } {
    puts "SNPS_HEADER : ## ------------------------------------- "
  } else {
    puts "SNPS_ERROR  : Unrecognized arguments for sproc_msg : $args"
  }
}

define_proc_attributes sproc_msg \
  -info "Standard message printing procedure." \
  -define_args {
  {-info    "Info message"    AString string optional}
  {-warning "Warning message" AString string optional}
  {-error   "Error message"   AString string optional}
  {-setup   "Setup message"   AString string optional}
  {-issue   "Issue message"   AString string optional}
  {-note    "Note  message"   AString string optional}
  {-header  "Header flag"     ""      boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_date:
## -----------------------------------------------------------------------------

proc sproc_date {} {
  return [clock format [clock seconds] -format {%a %b %e %H:%M:%S %Y}]
}

## -----------------------------------------------------------------------------
## sproc_config:
## -----------------------------------------------------------------------------

proc sproc_config { args } {

  global argv0
  global env garg gvar

  ## -------------------------------------
  ## Read config_common
  ## -------------------------------------

  set prog_path [file dirname [file normalize $argv0]]
  set prog_name [file rootname [file tail [file normalize $argv0]]]

  set config_common $prog_path/config_common.txt

  if { ![file exists $config_common] } {
    puts "Error: Config file is missing: $config_common"
    exit
  }

  set fid [open $config_common r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  foreach line $lines {
    if { [regexp {^\s*$} $line] || [regexp {^\s*#} $line] } {
      continue
    }

    set fields [split $line "|"]
    set name  [string trim [lindex $fields 0]]
    set value [string trim [lindex $fields 1]]

    switch $name {
      publish_dir {
        set publish_dir $value
      }
      default {
        puts "Error: Undefined name in $config_common: $name"
        exit
      }
    }
  }

  if { ![info exists publish_dir] } {
    puts "Error: publish_dir not defined in $config_common"
    exit
  }

  ## -------------------------------------
  ## Develop gvar(build_item_list)
  ## -------------------------------------

  set config_list_length [llength $garg(config_list)]
  if { $config_list_length != 0 } {
    if { [expr $config_list_length % 2] != 0 } {
      puts "Error: The argument for -config_list must contain a even number of entries"
    } else {
      for { set i 0 } { $i < $config_list_length } { set i [expr $i + 2] } {
        set j [expr $i + 1]
        set build_label [lindex $garg(config_list) $i]
        set build_dir   [lindex $garg(config_list) $j]
        set build_item [list $build_label $build_dir]
        lappend gvar(build_item_list) $build_item
      }
    }
  }

  set config_build $garg(config_file)

  if { [file exists $config_build] } {

    set fid [open $config_build r]
    set string_file [read $fid]
    close $fid
    set lines [split $string_file \n]

    foreach line $lines {
      if { [regexp {^\s*$} $line] || [regexp {^\s*#} $line] } {
        continue
      }

      set fields [split $line "|"]
      set build_label [string trim [lindex $fields 0]]
      set build_dir   [string trim [lindex $fields 1]]
      set build_item [list $build_label $build_dir]
      lappend gvar(build_item_list) $build_item
    }

  }

  foreach build_item $gvar(build_item_list) {
    set build_label [lindex $build_item 0]
    set build_dir   [lindex $build_item 1]
    puts "Build item : $build_label : $build_dir"
    if { ![file exists $build_dir] || ![file isdirectory $build_dir] } {
      puts "Error: Build directory does not exist: $build_dir"
    }
  }

  ## -------------------------------------
  ## Develop gvar(report_file) & gvar(message_file)
  ## -------------------------------------

  set lynx_date [clock format [clock seconds] -format "%Y_%m_%d"]

  if { [info exists env(LYNX_CRON)] } {
    set lynx_cron $env(LYNX_CRON)
  } else {
    set lynx_cron 0
  }

  if { $lynx_cron } {
    set lynx_user CRON
  } else {
    if { [info exists env(LYNX_USER)] } {
      set lynx_user $env(LYNX_USER)
    } else {
      set lynx_user [exec whoami]
    }
  }

  if { $garg(report_file) == "" } {
    ## Default report directory & report name
    set gvar(report_file) $publish_dir/users/$lynx_user/$lynx_date/$prog_name.lynx_dt
  } else {

    if { [regexp {^/} $garg(report_file)] } {
      ## Absolute file specified; No defaults used
      set gvar(report_file) $garg(report_file)
    } else {
      ## Relative path specified; Default report directory
      set gvar(report_file) $publish_dir/users/$lynx_user/$lynx_date/$garg(report_file)
    }

  }

  if { $garg(message) } {
    set file_part_org [file tail $gvar(report_file)]
    set dir_part_org  [file dirname $gvar(report_file)]
    set file_part_new .[file rootname $file_part_org].message
    set gvar(message_file) $dir_part_org/$file_part_new
  }

  puts "Report file  : $gvar(report_file)"
  puts "Message file : $gvar(message_file)"

  file mkdir [file dirname $gvar(report_file)]

}

## -----------------------------------------------------------------------------
## sproc_build_info:
## -----------------------------------------------------------------------------

proc sproc_build_info { args } {
  global _task_info_list

  set options(-cmd)         ""
  set options(-build_label) ""
  set options(-build_dir)   ""
  set options(-reports)     ""
  set options(-task_id)     ""
  parse_proc_arguments -args $args options

  if { ![info exists _task_info_list($options(-build_label))] } {
    set _task_info_list($options(-build_label)) [list]
  }

  switch $options(-cmd) {

    init {

      set resourceFileList [glob -nocomplain $options(-build_dir)/*/*/rpts/*/.*.lynx_task]

      foreach resourceFile $resourceFileList {

        set task_step [lindex [split $resourceFile /] end-4]
        set task_dst  [lindex [split $resourceFile /] end-3]
        set task_name [string range [file rootname [file tail $resourceFile]] 1 end]


        ## Read resourceFile
        set fid [open $resourceFile r]
        set string_file [read $fid]
        close $fid
        set lines [split $string_file \n]

        ## Develop task_id
        set task_id $task_step/$task_dst/$task_name

        ## Develop task_flow_order & task_tool
        set task_flow_order 0
        set task_tool "UNDEFINED"
        foreach line $lines {
          if { [regexp {^flow_order\|(\d+)} $line match value] } { set task_flow_order $value }
          if { [regexp {^Tool\|(\S+)}       $line match value] } { set task_tool       $value }
        }

        ## Develop task_report_list

        set task_report_list [list]

        set reportFileList [glob -nocomplain -types { f } $options(-build_dir)/$task_step/$task_dst/rpts/$task_name/*]
        set reportFileList [lsort $reportFileList]

        unset -nocomplain reportTypeFound

        foreach reportFile $reportFileList {
          set reportType [file extension $reportFile]
          set reportType [string range $reportType 1 end]
          if { [lsearch $options(-reports) $reportType] >= 0 } {
            if { ![info exists reportTypeFound($reportType)] } {
              set reportTypeFound($reportType) true
              lappend task_report_list $reportFile
            }
          }
        }

        ## Save task_info
        set task_info [list $task_flow_order $task_step $task_dst $task_name $task_id $task_tool $task_report_list]
        lappend _task_info_list($options(-build_label)) $task_info
      }

      ## Sort task_flow_order
      set _task_info_list($options(-build_label)) [lsort -index 0 -increasing -integer $_task_info_list($options(-build_label))]

      ## Sort task_name
      ## set _task_info_list($options(-build_label)) [lsort -index 3 -increasing -ascii   $_task_info_list($options(-build_label))]

      ## Sort task_dst
      #set _task_info_list($options(-build_label)) [lsort -index 2 -increasing -ascii   $_task_info_list($options(-build_label))]

      ## Sort task_step
      #set _task_info_list($options(-build_label)) [lsort -index 1 -increasing -ascii   $_task_info_list($options(-build_label))]

    }

    get {
      set tmp_task_info_list [list]
      foreach task_info $_task_info_list($options(-build_label)) {
        lassign $task_info task_flow_order task_step task_dst task_name task_id task_tool task_report_list
        if { [llength $task_report_list] > 0 } {
          lappend tmp_task_info_list $task_info
        }
      }
      return $tmp_task_info_list
    }

    get_all {
      set tmp_task_info_list $_task_info_list($options(-build_label))
      return $tmp_task_info_list
    }

    del {
      set tmp_task_info_list [list]
      foreach task_info $_task_info_list($options(-build_label)) {
        lassign $task_info task_flow_order task_step task_dst task_name task_id task_tool task_report_list
        if { $task_id == $options(-task_id) } {
          continue
        } else {
          lappend tmp_task_info_list $task_info
        }
      }
      set _task_info_list($options(-build_label)) $tmp_task_info_list
    }

  }

}

define_proc_attributes sproc_build_info \
  -info "Interact with task definitions" \
  -define_args {
  {-cmd "Task info command" AnOos one_of_string
    {required value_help {values {init get get_all del}}}
  }
  {-build_label "Build label"     AString string required}
  {-build_dir   "Build dir"       AString string optional}
  {-reports     "Report suffixes" AString string optional}
  {-task_id     "Task ID"         AString string optional}
}

## -----------------------------------------------------------------------------
## sproc_debug:
## -----------------------------------------------------------------------------

proc sproc_debug { build_label build_dir } {

  global env garg gvar

  if { $garg(debug) } {
    puts "DEBUG: $build_label : $build_dir"
    foreach task_info [sproc_build_info -build_label $build_label -cmd get_all] {
      lassign $task_info task_flow_order task_step task_dst task_name task_id task_tool task_report_list
      puts "DEBUG:   $task_id"
      foreach task_report $task_report_list {
        set remove_dir [file dirname $build_dir]/
        set display_report [regsub $remove_dir $task_report {}]
        puts "DEBUG:     $display_report"
      }
    }
  }

}

## -----------------------------------------------------------------------------
## sproc_create_message_file:
## -----------------------------------------------------------------------------

proc sproc_create_message_file {} {

  global env garg gvar

  if { $gvar(message_file) == "" } {
    return
  }

  set fid [open $gvar(message_file) w]

  puts $fid "<html>"
  puts $fid "<body>"
  puts $fid "<h1>New Report Available</h1>"
  puts $fid "<a href=\"%%DT%%:[file normalize $gvar(report_file)]\">The New Report</a>"
  puts $fid "</body>"
  puts $fid "</html>"

  close $fid

  puts "Information: Message file created"

}

## -----------------------------------------------------------------------------
## sproc_metric:
## -----------------------------------------------------------------------------

proc sproc_metric { args } {
  global misc_metric_name_list
  global misc_metric_name2display

  set options(-cmd) ""
  set options(-metric_name) ""
  set options(-display_name) ""
  parse_proc_arguments -args $args options

  if { ![info exists misc_metric_name_list] } {
    set misc_metric_name_list [list]
    array set misc_metric_name2display {}
  }

  switch $options(-cmd) {
    add {
      if { [lsearch $misc_metric_name_list $options(-metric_name)] == -1 } {
        lappend misc_metric_name_list $options(-metric_name)
      }
      set misc_metric_name2display($options(-metric_name)) $options(-display_name)
    }
    metrics {
      return $misc_metric_name_list
    }
    display {
      if { [lsearch $misc_metric_name_list $options(-metric_name)] == -1 } {
        puts "Error: sproc_metric: Metric not defined for -metric_name: '$options(-metric_name)'"
        return "UNDEFINED"
      } else {
        return $misc_metric_name2display($options(-metric_name))
      }
    }
  }
}

define_proc_attributes sproc_metric \
  -info "Interact with metric definitions" \
  -define_args {
  {-cmd "Metric command" AnOos one_of_string
    {required value_help {values {add metrics display}}}
  }
  {-metric_name  "Metric name"   AString string optional}
  {-display_name "Dispplay name" AString string optional}
}

## -----------------------------------------------------------------------------
## sproc_filevar:
## -----------------------------------------------------------------------------

proc sproc_filevar { args } {
  global misc_file2var_hash
  global misc_file2var_counter

  set options(-cmd) ""
  set options(-file_name) ""
  parse_proc_arguments -args $args options

  if { ![info exists misc_file2var_hash] } {
    array set misc_file2var_hash {}
    set misc_file2var_counter 0
  }

  switch $options(-cmd) {
    add_file {
      if { ![info exists misc_file2var_hash($options(-file_name))] } {
        incr misc_file2var_counter
        set var "f$misc_file2var_counter"
        set misc_file2var_hash($options(-file_name)) $var
      }
    }
    get_var {
      if { [info exists misc_file2var_hash($options(-file_name))] } {
        return $misc_file2var_hash($options(-file_name))
      } else {
        puts "Error: sproc_filevar: Var not defined for -file_name: '$options(-file_name)'"
        return "UNDEFINED"
      }
    }
    get_files {
      return [array names misc_file2var_hash]
    }
  }
}

define_proc_attributes sproc_filevar \
  -info "Interact with file variable definitions" \
  -define_args {
  {-cmd "File variable command" AnOos one_of_string
    {required value_help {values {add_file get_var get_files}}}
  }
  {-file_name  "File name"   AString string optional}
}

## -----------------------------------------------------------------------------
## format_value:
## -----------------------------------------------------------------------------

proc format_value { formatString potentialNumber } {

  if { [string is double -strict $potentialNumber] } {
    return [format $formatString $potentialNumber]
  } else {
    return $potentialNumber
  }

}

## -----------------------------------------------------------------------------
## sproc_unicode:
## -----------------------------------------------------------------------------

proc sproc_unicode {} {
  global gvar

  if { $gvar(unicode) } {
    set str " [encoding convertfrom utf-8 "\xe5\xae\x9f\xe8\xa1\x8c\xe7\x9b\xae\xe7\x9a\x84"]"
  } else {
    set str ""
  }

  return $str
}

## -----------------------------------------------------------------------------
## sproc_parse_report_qor:
## -----------------------------------------------------------------------------

proc sproc_parse_report_qor { args } {

  global env SVAR

  set options(-file) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag) 0

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { ![file exists $options(-file)] } {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report for path group information.
  ## -------------------------------------

  set rval(path_group_data,scenario_name_list) [list]

  set scenario_name None/non-MCMM

  set path_group_name NO_PATH_GROUP

  set line_number 0
  foreach line $lines {
    incr line_number

    regexp {^\s*Scenario\s+\'(.*)\'} $line matchVar scenario_name

    if { [regexp {^\s*Timing Path Group\s+'(\S+)'} $line matchVar path_group_name] } {

      lappend rval(path_group_data,scenario_name_list) $scenario_name
      lappend rval(path_group_data,path_group_name_list,$scenario_name) $path_group_name

      set rval(path_group_data,$scenario_name,$path_group_name,setup,logic_levels) NA
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_length)  NA
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_slack)   NA
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_period)  NA
      set rval(path_group_data,$scenario_name,$path_group_name,setup,tns)          NA
      set rval(path_group_data,$scenario_name,$path_group_name,setup,nvp)          NA
      set rval(path_group_data,$scenario_name,$path_group_name,hold,path_slack)    NA
      set rval(path_group_data,$scenario_name,$path_group_name,hold,tns)           NA
      set rval(path_group_data,$scenario_name,$path_group_name,hold,nvp)           NA

      set rval(path_group_data,$scenario_name,$path_group_name,line_number) $line_number

      set rval(path_group_data,$scenario_name,$path_group_name,setup,logic_levels,line_number) 1
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_length,line_number)  1
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_slack,line_number)   1
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_period,line_number)  1
      set rval(path_group_data,$scenario_name,$path_group_name,setup,tns,line_number)          1
      set rval(path_group_data,$scenario_name,$path_group_name,setup,nvp,line_number)          1
      set rval(path_group_data,$scenario_name,$path_group_name,hold,path_slack,line_number)    1
      set rval(path_group_data,$scenario_name,$path_group_name,hold,tns,line_number)           1
      set rval(path_group_data,$scenario_name,$path_group_name,hold,nvp,line_number)           1

    }

    if { [regexp {^\s*Levels of Logic:\s+([\-\d\.]+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,setup,logic_levels) $data
      set rval(path_group_data,$scenario_name,$path_group_name,setup,logic_levels,line_number) $line_number
    }
    if { [regexp {^\s*Critical Path Length:\s+([\-\d\.]+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_length) $data
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_length,line_number) $line_number
    }
    if { [regexp {^\s*Critical Path Slack:\s+([\-\d\.]+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_slack) $data
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_slack,line_number) $line_number
    }
    if { [regexp {^\s*Critical Path Clk Period:\s+(\S+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_period) $data
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_period,line_number) $line_number
    }
    if { [regexp {^\s*Total Negative Slack:\s+([\-\d\.]+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,setup,tns) $data
      set rval(path_group_data,$scenario_name,$path_group_name,setup,tns,line_number) $line_number
    }
    if { [regexp {^\s*No. of Violating Paths:\s+([\-\d\.]+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,setup,nvp) $data
      set rval(path_group_data,$scenario_name,$path_group_name,setup,nvp,line_number) $line_number
    }
    if { [regexp {^\s*Worst Hold Violation:\s+([\-\d\.]+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,hold,path_slack) $data
      set rval(path_group_data,$scenario_name,$path_group_name,hold,path_slack,line_number) $line_number
    }
    if { [regexp {^\s*Total Hold Violation:\s+([\-\d\.]+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,hold,tns) $data
      set rval(path_group_data,$scenario_name,$path_group_name,hold,tns,line_number) $line_number
    }
    if { [regexp {^\s*No. of Hold Violations:\s+([\-\d\.]+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,hold,nvp) $data
      set rval(path_group_data,$scenario_name,$path_group_name,hold,nvp,line_number) $line_number
    }
  }

  set rval(path_group_data,scenario_name_list) [lsort -unique $rval(path_group_data,scenario_name_list)]
  foreach scenario_name $rval(path_group_data,scenario_name_list) {
    set rval(path_group_data,path_group_name_list,$scenario_name) [lsort -unique $rval(path_group_data,path_group_name_list,$scenario_name)]
  }

  ## -------------------------------------
  ## Parse the report for summary information.
  ## -------------------------------------

  set rval(summary_data,_ss,scenario_name_list) [list]
  ## rval(summary_data,_ss,$scenario_name,setup,path_slack)
  ## rval(summary_data,_ss,$scenario_name,setup,tns)
  ## rval(summary_data,_ss,$scenario_name,setup,nvp)
  ## rval(summary_data,_ss,$scenario_name,hold,path_slack)
  ## rval(summary_data,_ss,$scenario_name,hold,tns)
  ## rval(summary_data,_ss,$scenario_name,hold,nvp)

  ## rval(summary_data,_ms,setup,path_slack)
  ## rval(summary_data,_ms,setup,tns)
  ## rval(summary_data,_ms,setup,nvp)
  ## rval(summary_data,_ms,hold,path_slack)
  ## rval(summary_data,_ms,hold,tns)
  ## rval(summary_data,_ms,hold,nvp)

  set line_number 0
  foreach line $lines {
    incr line_number

    ## -------------------------------------
    ## Per-scenario / Per-design setup (ICC2)
    ## -------------------------------------

    if { [regexp {^(\S+)\s+\(Setup\)\s+(\S+)\s+(\S+)\s+(\S+)} $line matchVar scenario_name wns tns nvp] } {

      if { $scenario_name != "Design" } {
        lappend rval(summary_data,_ss,scenario_name_list) $scenario_name
        set rval(summary_data,_ss,$scenario_name,setup,path_slack)             $wns
        set rval(summary_data,_ss,$scenario_name,setup,tns)                    $tns
        set rval(summary_data,_ss,$scenario_name,setup,nvp)                    $nvp

        set rval(summary_data,_ss,$scenario_name,setup,path_slack,line_number) $line_number
        set rval(summary_data,_ss,$scenario_name,setup,tns,line_number)        $line_number
        set rval(summary_data,_ss,$scenario_name,setup,nvp,line_number)        $line_number
      } else {
        set rval(summary_data,_ms,setup,path_slack)             $wns
        set rval(summary_data,_ms,setup,tns)                    $tns
        set rval(summary_data,_ms,setup,nvp)                    $nvp

        set rval(summary_data,_ms,setup,path_slack,line_number) $line_number
        set rval(summary_data,_ms,setup,tns,line_number)        $line_number
        set rval(summary_data,_ms,setup,nvp,line_number)        $line_number
      }
    }

    ## -------------------------------------
    ## Per-scenario setup (not ICC2)
    ## -------------------------------------

    if { [regexp {^\s*Scenario:\s+(\S+)\s+WNS:\s+(\S+)\s+TNS:\s+(\S+)\s+Number of Violating Paths:\s+(\S+)} $line matchVar scenario_name wns tns nvp] } {
      lappend rval(summary_data,_ss,scenario_name_list) $scenario_name
      set rval(summary_data,_ss,$scenario_name,setup,path_slack)             $wns
      set rval(summary_data,_ss,$scenario_name,setup,tns)                    $tns
      set rval(summary_data,_ss,$scenario_name,setup,nvp)                    $nvp

      set rval(summary_data,_ss,$scenario_name,setup,path_slack,line_number) $line_number
      set rval(summary_data,_ss,$scenario_name,setup,tns,line_number)        $line_number
      set rval(summary_data,_ss,$scenario_name,setup,nvp,line_number)        $line_number
    }

    ## -------------------------------------
    ## Per-design setup (not ICC2)
    ## -------------------------------------

    if { [regexp {^\s*Design\s+WNS:\s+(\S+)\s+TNS:\s+(\S+)\s+Number of Violating Paths:\s+(\S+)} $line matchVar wns tns nvp] } {
      set rval(summary_data,_ms,setup,path_slack)             $wns
      set rval(summary_data,_ms,setup,tns)                    $tns
      set rval(summary_data,_ms,setup,nvp)                    $nvp

      set rval(summary_data,_ms,setup,path_slack,line_number) $line_number
      set rval(summary_data,_ms,setup,tns,line_number)        $line_number
      set rval(summary_data,_ms,setup,nvp,line_number)        $line_number
    }

    ## -------------------------------------
    ## Per-scenario / Per-design hold (ICC2)
    ## -------------------------------------

    if { [regexp {^(\S+)\s+\(Hold\)\s+(\S+)\s+(\S+)\s+(\S+)} $line matchVar scenario_name wns tns nvp] } {
      if { $scenario_name != "Design" } {
        lappend rval(summary_data,_ss,scenario_name_list) $scenario_name
        set rval(summary_data,_ss,$scenario_name,hold,path_slack)             $wns
        set rval(summary_data,_ss,$scenario_name,hold,tns)                    $tns
        set rval(summary_data,_ss,$scenario_name,hold,nvp)                    $nvp

        set rval(summary_data,_ss,$scenario_name,hold,path_slack,line_number) $line_number
        set rval(summary_data,_ss,$scenario_name,hold,tns,line_number)        $line_number
        set rval(summary_data,_ss,$scenario_name,hold,nvp,line_number)        $line_number
      } else {
        set rval(summary_data,_ms,hold,path_slack)             $wns
        set rval(summary_data,_ms,hold,tns)                    $tns
        set rval(summary_data,_ms,hold,nvp)                    $nvp

        set rval(summary_data,_ms,hold,path_slack,line_number) $line_number
        set rval(summary_data,_ms,hold,tns,line_number)        $line_number
        set rval(summary_data,_ms,hold,nvp,line_number)        $line_number
      }
    }

    ## -------------------------------------
    ## Per-scenario hold (not ICC2)
    ## -------------------------------------

    if { [regexp {^\s*Scenario:\s+\s+\(Hold\)\s+(\S+)\s+WNS:\s+(\S+)\s+TNS:\s+(\S+)\s+Number of Violating Paths:\s+(\S+)} $line matchVar scenario_name wns tns nvp] } {
      lappend rval(summary_data,_ss,scenario_name_list) $scenario_name
      set rval(summary_data,_ss,$scenario_name,hold,path_slack)             $wns
      set rval(summary_data,_ss,$scenario_name,hold,tns)                    $tns
      set rval(summary_data,_ss,$scenario_name,hold,nvp)                    $nvp

      set rval(summary_data,_ss,$scenario_name,hold,path_slack,line_number) $line_number
      set rval(summary_data,_ss,$scenario_name,hold,tns,line_number)        $line_number
      set rval(summary_data,_ss,$scenario_name,hold,nvp,line_number)        $line_number
    }

    ## -------------------------------------
    ## Per-design hold (not ICC2)
    ## -------------------------------------

    if { [regexp {^\s*Design\s+\(Hold\)\s+WNS:\s+(\S+)\s+TNS:\s+(\S+)\s+Number of Violating Paths:\s+(\S+)} $line matchVar wns tns nvp] } {
      set rval(summary_data,_ms,hold,path_slack)             $wns
      set rval(summary_data,_ms,hold,tns)                    $tns
      set rval(summary_data,_ms,hold,nvp)                    $nvp

      set rval(summary_data,_ms,hold,path_slack,line_number) $line_number
      set rval(summary_data,_ms,hold,tns,line_number)        $line_number
      set rval(summary_data,_ms,hold,nvp,line_number)        $line_number
    }

  }

  set rval(summary_data,_ss,scenario_name_list) [lsort -unique $rval(summary_data,_ss,scenario_name_list)]

  ## -------------------------------------
  ## A "pt_concat.report_qor" file is generated after DMSA processing and is simply
  ## a concatenation of the "report_qor" files for each scenario (generated by the PT slaves),
  ## and the "pt_master.report_global_timing" file (generated by the PT master).
  ## The per-design metrics are extracted from the "pt_master.report_global_timing" content.
  ## -------------------------------------

  if { [file tail $options(-file)] == "pt_concat.report_qor" } {

    unset -nocomplain rval(summary_data,_ms,setup,path_slack)
    unset -nocomplain rval(summary_data,_ms,setup,tns)
    unset -nocomplain rval(summary_data,_ms,setup,nvp)
    unset -nocomplain rval(summary_data,_ms,setup,path_slack,line_number)
    unset -nocomplain rval(summary_data,_ms,setup,tns,line_number)
    unset -nocomplain rval(summary_data,_ms,setup,nvp,line_number)

    unset -nocomplain rval(summary_data,_ms,hold,path_slack)
    unset -nocomplain rval(summary_data,_ms,hold,tns)
    unset -nocomplain rval(summary_data,_ms,hold,nvp)
    unset -nocomplain rval(summary_data,_ms,hold,path_slack,line_number)
    unset -nocomplain rval(summary_data,_ms,hold,tns,line_number)
    unset -nocomplain rval(summary_data,_ms,hold,nvp,line_number)

    set line_number 0
    foreach line $lines {
      incr line_number

      if { [regexp {^Setup violations} $line] } {
        set type setup
      }
      if { [regexp {^Hold violations} $line] } {
        set type hold
      }

      if { [regexp {^WNS} $line] } {
        set rval(summary_data,_ms,$type,path_slack) [lindex $line 1]
        set rval(summary_data,_ms,$type,path_slack,line_number) $line_number
      }
      if { [regexp {^TNS} $line] } {
        set rval(summary_data,_ms,$type,tns)        [lindex $line 1]
        set rval(summary_data,_ms,$type,tns,line_number)        $line_number
      }
      if { [regexp {^NUM} $line] } {
        set rval(summary_data,_ms,$type,nvp)        [lindex $line 1]
        set rval(summary_data,_ms,$type,nvp,line_number)        $line_number
      }

      if { [regexp {^No setup violations found} $line] } {
        set type setup
        set rval(summary_data,_ms,$type,path_slack) 0.0
        set rval(summary_data,_ms,$type,tns)        0.0
        set rval(summary_data,_ms,$type,nvp)        0
        set rval(summary_data,_ms,$type,tns,line_number)        $line_number
        set rval(summary_data,_ms,$type,path_slack,line_number) $line_number
        set rval(summary_data,_ms,$type,nvp,line_number)        $line_number
      }
      if { [regexp {^No hold violations found} $line] } {
        set type hold
        set rval(summary_data,_ms,$type,path_slack) 0.0
        set rval(summary_data,_ms,$type,tns)        0.0
        set rval(summary_data,_ms,$type,nvp)        0
        set rval(summary_data,_ms,$type,tns,line_number)        $line_number
        set rval(summary_data,_ms,$type,path_slack,line_number) $line_number
        set rval(summary_data,_ms,$type,nvp,line_number)        $line_number
      }

    }

  }

  ## -------------------------------------
  ## Parse the report for design information.
  ## -------------------------------------

  ## set rval(design_data,leaf_cell_count)     ""
  ## set rval(design_data,bufinv_cell_count)   ""
  ## set rval(design_data,ctbufinv_cell_count) ""

  ## set rval(design_data,comb_cell_count)     ""
  ## set rval(design_data,seq_cell_count)      ""
  ## set rval(design_data,macro_cell_count)    ""

  ## set rval(design_data,cell_area)           ""
  ## set rval(design_data,design_area)         ""
  ## set rval(design_data,net_length)          ""

  ## set rval(design_data,net_count)           ""
  ## set rval(design_data,ldrc_total)          ""
  ## set rval(design_data,ldrc_trans)          ""
  ## set rval(design_data,ldrc_cap)            ""
  ## set rval(design_data,ldrc_fanout)         ""

  ## -------------------------------------

  ## set rval(design_data,leaf_cell_count,line_number)     1
  ## set rval(design_data,bufinv_cell_count,line_number)   1
  ## set rval(design_data,ctbufinv_cell_count,line_number) 1

  ## set rval(design_data,comb_cell_count,line_number)     1
  ## set rval(design_data,seq_cell_count,line_number)      1
  ## set rval(design_data,macro_cell_count,line_number)    1

  ## set rval(design_data,cell_area,line_number)           1
  ## set rval(design_data,design_area,line_number)         1
  ## set rval(design_data,net_length,line_number)          1

  ## set rval(design_data,net_count,line_number)           1
  ## set rval(design_data,ldrc_total,line_number)          1
  ## set rval(design_data,ldrc_trans,line_number)          1
  ## set rval(design_data,ldrc_cap,line_number)            1
  ## set rval(design_data,ldrc_fanout,line_number)         1

  ## -------------------------------------

  set line_number 0
  foreach line $lines {
    incr line_number

    if { [regexp {Leaf Cell Count:\s+([\d\.]+)} $line matchVar data] } {
      set rval(design_data,leaf_cell_count) $data
      set rval(design_data,leaf_cell_count,line_number) $line_number
    }
    if { [regexp {^\s*Buf/Inv Cell Count:\s+([\d\.]+)} $line matchVar data] } {
      set rval(design_data,bufinv_cell_count) $data
      set rval(design_data,bufinv_cell_count,line_number) $line_number
    }
    if { [regexp {^\s*CT Buf/Inv Cell Count:\s+([\d\.]+)} $line matchVar data] } {
      set rval(design_data,ctbufinv_cell_count) $data
      set rval(design_data,ctbufinv_cell_count,line_number) $line_number
    }

    if { [regexp {Combinational Cell Count:\s+([\d\.]+)} $line matchVar data] } {
      set rval(design_data,comb_cell_count) $data
      set rval(design_data,comb_cell_count,line_number) $line_number
    }
    if { [regexp {Sequential Cell Count:\s+([\d\.]+)} $line matchVar data] } {
      set rval(design_data,seq_cell_count) $data
      set rval(design_data,seq_cell_count,line_number) $line_number
    }
    if { [regexp {Macro Count:\s+([\d\.]+)} $line matchVar data] } {
      set rval(design_data,macro_cell_count) $data
      set rval(design_data,macro_cell_count,line_number) $line_number
    }

    if { [regexp {Cell Area:\s+([\d\.]+)} $line matchVar data] } {
      set rval(design_data,cell_area) $data
      set rval(design_data,cell_area,line_number) $line_number
    }
    if { [regexp {Cell Area\s+\(netlist\):\s+([\d\.]+)} $line matchVar data] } {
      set rval(design_data,cell_area) $data
      set rval(design_data,cell_area,line_number) $line_number
    }
    if { [regexp {Design Area:\s+([\d\.]+)} $line matchVar data] } {
      set rval(design_data,design_area) $data
      set rval(design_data,design_area,line_number) $line_number
    }
    if { [regexp {Cell Area\s+\(netlist and physical only\):\s+([\d\.]+)} $line matchVar data] } {
      set rval(design_data,design_area) $data
      set rval(design_data,design_area,line_number) $line_number
    }
    if { [regexp {Net Length\s*:\s+([\d\.]+)} $line matchVar data] } {
      set rval(design_data,net_length) $data
      set rval(design_data,net_length,line_number) $line_number
    }

    if { [regexp {Total Number of Nets:\s+([\d\.]+)} $line matchVar data] } {
      set rval(design_data,net_count) $data
      set rval(design_data,net_count,line_number) $line_number
    }
    if { [regexp {Nets With Violations:\s+([\d]+)} $line matchVar data] } {
      set rval(design_data,ldrc_total) $data
      set rval(design_data,ldrc_total,line_number) $line_number
    }
    if { [regexp {Nets with Violations:\s+([\d]+)} $line matchVar data] } {
      set rval(design_data,ldrc_total) $data
      set rval(design_data,ldrc_total,line_number) $line_number
    }
    if { [regexp {Max Trans Violations:\s+([\d]+)} $line matchVar data] } {
      set rval(design_data,ldrc_trans) $data
      set rval(design_data,ldrc_trans,line_number) $line_number
    }
    if { [regexp {Max Cap Violations:\s+([\d]+)} $line matchVar data] } {
      set rval(design_data,ldrc_cap) $data
      set rval(design_data,ldrc_cap,line_number) $line_number
    }
    if { [regexp {Max Fanout Violations:\s+([\d]+)} $line matchVar data] } {
      set rval(design_data,ldrc_fanout) $data
      set rval(design_data,ldrc_fanout,line_number) $line_number
    }
  }

  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  return [array get rval]
}

define_proc_attributes sproc_parse_report_qor \
  -info "Parses information for report_qor." \
  -define_args {
  {-file "The report_qor file to parse." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_parse_report_power:
## -----------------------------------------------------------------------------

proc sproc_parse_report_power { args } {

  global env SVAR

  set options(-file) ""
  set options(-scenario) ""
  set options(-synopsys_program_name) "NOT_DEFINED"
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag) 0
  set rval(scenario_name_list) [list]

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { ![file exists $options(-file)] } {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report
  ## -------------------------------------

  set rval(scenario_name_list) [list]

  if { $options(-scenario) == "" } {
    set scenario_name None/non-MCMM
  } else {
    set scenario_name $options(-scenario)
  }

  switch $options(-synopsys_program_name) {

    other_shell -
    dc_shell -
    icc2_shell {

      set line_number 0
      foreach line $lines {
        incr line_number

        regexp {^Scenario(\(s\))?:\s+(\S+)} $line match optionalSubMatch scenario_name

        if { [regexp {^Total} $line] && ([lindex $line 1] != "Dynamic") } {

	  if { [lindex $line 1] == "N/A" } {
            set m1 N/A
	    set m2 N/A
            set m3 N/A
	    set m4 N/A
            set m5 [lindex $line 3]
	    set m6 [lindex $line 4]
            set m7 [lindex $line 5]
	    set m8 [lindex $line 6]
          } else {
            set m1 [lindex $line 1]
	    set m2 [lindex $line 2]
            set m3 [lindex $line 3]
	    set m4 [lindex $line 4]
            set m5 [lindex $line 5]
	    set m6 [lindex $line 6]
            set m7 [lindex $line 7]
	    set m8 [lindex $line 8]
	  }

          set rval($scenario_name,internal_power)        $m1
          set rval($scenario_name,internal_power_units)  $m2
          set rval($scenario_name,switching_power)       $m3
          set rval($scenario_name,switching_power_units) $m4
          set rval($scenario_name,leakage_power)         $m5
          set rval($scenario_name,leakage_power_units)   $m6
          set rval($scenario_name,total_power)           $m7
          set rval($scenario_name,total_power_units)     $m8

          set rval($scenario_name,internal_power,line_number)        $line_number
          set rval($scenario_name,internal_power_units,line_number)  $line_number
          set rval($scenario_name,switching_power,line_number)       $line_number
          set rval($scenario_name,switching_power_units,line_number) $line_number
          set rval($scenario_name,leakage_power,line_number)         $line_number
          set rval($scenario_name,leakage_power_units,line_number)   $line_number
          set rval($scenario_name,total_power,line_number)           $line_number
          set rval($scenario_name,total_power_units,line_number)     $line_number

          lappend rval(scenario_name_list) $scenario_name
        }
      }
      set rval(scenario_name_list) [lsort -unique $rval(scenario_name_list)]

    }

    pt_shell {

      set line_number 0
      foreach line $lines {
        incr line_number

        if { [regexp {^LYNX_SCENARIO:\s+(\S+)} $line match name] } {
          set scenario_name $name
        }

        if { [regexp {^\s*Net Switching Power\s+=\s+(\S+)} $line match value] } {
          set rval($scenario_name,switching_power)                   $value
          set rval($scenario_name,switching_power_units)             W

          set rval($scenario_name,switching_power,line_number)       $line_number
          set rval($scenario_name,switching_power_units,line_number) 1
        }
        if { [regexp {^\s*Cell Internal Power\s+=\s+(\S+)} $line match value] } {
          set rval($scenario_name,internal_power)                    $value
          set rval($scenario_name,internal_power_units)              W

          set rval($scenario_name,internal_power,line_number)        $line_number
          set rval($scenario_name,internal_power_units,line_number)  1
        }
        if { [regexp {^\s*Cell Leakage Power\s+=\s+(\S+)} $line match value] } {
          set rval($scenario_name,leakage_power)                     $value
          set rval($scenario_name,leakage_power_units)               W

          set rval($scenario_name,leakage_power,line_number)         $line_number
          set rval($scenario_name,leakage_power_units,line_number)   1
        }
        if { [regexp {^\s*Total Power\s+=\s+(\S+)} $line match value] } {
          set rval($scenario_name,total_power)                       $value
          set rval($scenario_name,total_power_units)                 W

          set rval($scenario_name,total_power,line_number)           $line_number
          set rval($scenario_name,total_power_units,line_number)     1

          lappend rval(scenario_name_list) $scenario_name
        }
      }
      set rval(scenario_name_list) [lsort -unique $rval(scenario_name_list)]

    }

    default {
      sproc_msg -error "Unrecognized value for options(-synopsys_program_name): '$options(-synopsys_program_name)'"
    }

  }

  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  return [array get rval]
}

define_proc_attributes sproc_parse_report_power \
  -info "Parses information for report_power." \
  -define_args {
  {-file "The report_power file to parse." AString string required}
  {-scenario "The scenario name." AString string optional}
  {-synopsys_program_name "The program name." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_parse_report_clock_qor:
## -----------------------------------------------------------------------------

proc sproc_parse_report_clock_qor { args } {

  global env SVAR

  set options(-file) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag) 0
  set rval(scenario_list) [list]
  set rval(clock_list)    [list]

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { ![file exists $options(-file)] } {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report
  ## -------------------------------------

  set rval(scenario_list) [list]
  set rval(clock_list) [list]
  ## set rval($scenario,$clock,<metric_name>,value)
  ## set rval($scenario,$clock,<metric_name>,line)

  set current_scenario ""

  set line_number 0
  foreach line $lines {
    incr line_number

    if { [regexp {^### Mode: (\S+), Scenario: (\S+)} $line match current_mode current_scenario] } {
      lappend rval(scenario_list) $current_scenario
    }
    if { [regexp {^--------} $line match] } {
      set current_scenario ""
    }

    if { $current_scenario != "" } {
      if { [scan $line {%s %s %s %s %s %s %s %s %s %s %s} clock Attrs Sinks Levels Clock_Repeater_Count Clock_Repeater_Area Clock_Stdcell_Area Max_Latency Global_Skew Trans_DRC_Count Cap_DRC_Count] == 11 } {
        lappend rval(clock_list) $clock
        set rval($current_scenario,$clock,Sinks,value)                $Sinks
        set rval($current_scenario,$clock,Sinks,line)                 $line_number
        set rval($current_scenario,$clock,Levels,value)               $Levels
        set rval($current_scenario,$clock,Levels,line)                $line_number
        set rval($current_scenario,$clock,Clock_Repeater_Count,value) $Clock_Repeater_Count
        set rval($current_scenario,$clock,Clock_Repeater_Count,line)  $line_number
        set rval($current_scenario,$clock,Clock_Repeater_Area,value)  $Clock_Repeater_Area
        set rval($current_scenario,$clock,Clock_Repeater_Area,line)   $line_number
        set rval($current_scenario,$clock,Clock_Stdcell_Area,value)   $Clock_Stdcell_Area
        set rval($current_scenario,$clock,Clock_Stdcell_Area,line)    $line_number
        set rval($current_scenario,$clock,Max_Latency,value)          $Max_Latency
        set rval($current_scenario,$clock,Max_Latency,line)           $line_number
        set rval($current_scenario,$clock,Global_Skew,value)          $Global_Skew
        set rval($current_scenario,$clock,Global_Skew,line)           $line_number
        set rval($current_scenario,$clock,Trans_DRC_Count,value)      $Trans_DRC_Count
        set rval($current_scenario,$clock,Trans_DRC_Count,line)       $line_number
        set rval($current_scenario,$clock,Cap_DRC_Count,value)        $Cap_DRC_Count
        set rval($current_scenario,$clock,Cap_DRC_Count,line)         $line_number
      }
    }

  }

  ## Clean up

  set rval(scenario_list) [lsort -unique $rval(scenario_list)]
  set rval(clock_list)    [lsort -unique $rval(clock_list)]

  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  return [array get rval]
}

define_proc_attributes sproc_parse_report_clock_qor \
  -info "Parses information for report_clock_qor." \
  -define_args {
  {-file "The report_clock_qor file to parse." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_parse_report_clock_tree:
## -----------------------------------------------------------------------------

proc sproc_parse_report_clock_tree { args } {

  global env SVAR

  set options(-file) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag) 0
  set rval(scenario_name_list) [list]
  set rval(clk_name_list) [list]

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { ![file exists $options(-file)] } {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report (for Clock Tree Summary info)
  ## This information used for reporting
  ## -------------------------------------

  set in_section 0

  set index 0

  set line_number 0
  foreach line $lines {
    incr line_number

    if { [regexp {\=\=Report for scenario \((\S+)\)\=\=} $line match value] } {
      set scenario_name $value
      lappend rval(scenario_name_list) $scenario_name
      continue
    }

    if { [regexp {\=\= Clock Tree Summary =\=} $line] } {
      set in_section 1
      continue
    }

    if { $in_section } {
      if { [regexp {Clock\s+Sinks\s+CTBuffers\s+ClkCells\s+Skew\s+LongestPath\s+TotalDRC\s+BufferArea} $line] } {
        ## This is header line
        continue
      } elseif { [regexp {^----} $line] } {
        ## This is seperator line
        continue
      } elseif { [scan $line {%s %s %s %s %s %s %s %s} clock_name sinks buffers cells skew path drc area] == 8 } {
        ## This is data line
        set rval($scenario_name,$clock_name,sinks) $sinks
        set rval($scenario_name,$clock_name,skew)  $skew
        set rval($scenario_name,$clock_name,path)  $path
        set rval($scenario_name,$clock_name,drc)   $drc
        set rval($scenario_name,$clock_name,sinks,line_number) $line_number
        set rval($scenario_name,$clock_name,skew,line_number)  $line_number
        set rval($scenario_name,$clock_name,path,line_number)  $line_number
        set rval($scenario_name,$clock_name,drc,line_number)   $line_number
        continue
      } else {
        ## No longer in summary
        set in_section 0
        continue
      }
    }

  }

  ## -------------------------------------
  ## Parse the report (for Global Skew Report info)
  ## This information used for QOR JSON files
  ## -------------------------------------

  set rval(name_list) [list \
    "Clock Period" \
    "Number of Levels" \
    "Number of Sinks" \
    "Number of CT Buffers" \
    "Number of CTS added gates" \
    "Number of Preexisting Gates" \
    "Number of Preexisting Buf/Inv" \
    "Total Number of Clock Cells" \
    "Total Area of CT Buffers" \
    "Total Area of CT cells" \
    "Max Global Skew" \
    "Number of MaxTran Violators" \
    "Number of MaxCap Violators" \
    "Number of MaxFanout Violators" \
    "Clock global Skew" \
    "Longest path delay" \
    "Shortest path delay" \
    ]

  set in_section 0

  set index 0

  set line_number 0
  foreach line $lines {
    incr line_number

    if { [regexp {\=\=Report for scenario \((\S+)\)\=\=} $line match value] } {
      set scenario_name $value
      lappend rval(scenario_name_list) $scenario_name
      continue
    }

    if { [regexp {\=\= Global Skew Report =\=} $line] } {
      set in_section 1
      continue
    }

    if { $in_section } {

      if { [regexp "^Clock Tree Name" $line] } {
        set clk_name [lindex [split [string trim $line]] end]
        set clk_name [regsub -all {\"} $clk_name {}]
        lappend rval(clk_name_list) $clk_name
        lappend rval($scenario_name,clk_name_list) $clk_name
        foreach name $rval(name_list) {
          set rval($scenario_name,$clk_name,$name,value) unknown
          set rval($scenario_name,$clk_name,$name,line_number) 1
        }
        continue
      }

      foreach name $rval(name_list) {
        if { [regexp "^$name\s*\:*\s*" $line] } {
          set value [lindex [split [string trim $line]] end]
          set rval($scenario_name,$clk_name,$name,value) $value
          set rval($scenario_name,$clk_name,$name,line_number) $line_number

          ## set value_line [list $value $line_number]
          ## lappend rval($clk_name,$name,value_line_list) $value_line

          continue
        }
      }

      if { [regexp {^Report} $line] } {
        set in_section 0
        continue
      }

    }
  }

  ## Clean up

  set rval(scenario_name_list) [lsort -unique $rval(scenario_name_list)]
  set rval(clk_name_list)      [lsort -unique $rval(clk_name_list)]

  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  return [array get rval]
}

define_proc_attributes sproc_parse_report_clock_tree \
  -info "Parses information for report_clock_tree." \
  -define_args {
  {-file "The report_clock_tree file to parse." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_parse_report_clock_gating:
## -----------------------------------------------------------------------------

proc sproc_parse_report_clock_gating { args } {

  global env SEV SVAR pt_shell_mode

  set options(-file) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag) 0

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { [file exists $options(-file)] } {
    sproc_msg -info "The specified report file is: '$options(-file)'"
  } else {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report (for Clock Tree Summary info)
  ## This information used for reporting
  ## -------------------------------------

  set in_section 0

  set index 0
  set line_number 0
  foreach line $lines {
    incr line_number
   
    regexp -line {.*Number of Clock gating elements.* +[\|] +(\S+) .*::(\S+)} ${line}::$line_number \
      match rval(design_data,gating_elements) rval(design_data,gating_elements,line_number)
    regexp -line {.*Number of Gated registers +[\|] +(\S+) +\((\S+)%\) .*::(\S+)} ${line}::$line_number \
      match rval(design_data,gated_registers) rval(design_data,gated_register_percentage) rval(design_data,gated_register_percentage,line_number)
    regexp -line {.*Number of Ungated registers +[\|] +(\S+) +\((\S+)%\) .*::(\S+)} ${line}::$line_number \
      match rval(design_data,ungated_registers) rval(design_data,ungated_register_percentage) rval(design_data,ungated_register_percentage,line_number)
    regexp -line {.*Total number of registers +[\|] +(\S+) .*::(\S+)} ${line}::$line_number \
      match rval(design_data,num_regs) rval(design_data,num_regs,line_number)
  }

  set rval(design_data,gated_registers,line_number) $rval(design_data,gated_register_percentage,line_number)
  set rval(design_data,ungated_registers,line_number) $rval(design_data,ungated_register_percentage,line_number)
  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  return [array get rval]
}

define_proc_attributes sproc_parse_report_clock_gating \
  -info "Parses information for report_clock_gating." \
  -define_args {
  {-file "The report_clock_gating file to parse." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_parse_report_threshold_voltage_group:
## -----------------------------------------------------------------------------

proc sproc_parse_report_threshold_voltage_group { args } {

  global env SVAR

  set options(-file) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag) 0

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { ![file exists $options(-file)] } {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report
  ## -------------------------------------

  set rval(vth,vth_names) [list]
  ## rval(cell_count,$vth_name)
  ## rval(cell_percentage,$vth_name)

  set line_number 0
  foreach line $lines {
    incr line_number

    if { [regexp {^Total} $line] } {
      break
    }

    ## stdcell_hvt 33747.84000 (68.76%) 0.00000 (0.00%) 33747.84000 (68.76%)

    if { [regexp {^(\S+)\s+(\S+)\s+\(\s*(\S+)\%\)\s+(\S+)\s+\(\s*(\S+)\%\)\s+(\S+)\s+\(\s*(\S+)\%\).*} $line match vth_name vth_count vth_percent n1 n2 n3 n4] } {

      lappend rval(vth,vth_names) $vth_name
      set rval(cell_count,$vth_name)                  $vth_count
      set rval(cell_percentage,$vth_name)             $vth_percent
      set rval(cell_count,$vth_name,line_number)      $line_number
      set rval(cell_percentage,$vth_name,line_number) $line_number
    }

  }

  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  return [array get rval]
}

define_proc_attributes sproc_parse_report_threshold_voltage_group \
  -info "Parses information for report_threshold_voltage_group." \
  -define_args {
  {-file "The report_threshold_voltage_group file to parse." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_parse_report_design:
## -----------------------------------------------------------------------------

proc sproc_parse_report_design { args } {

  global env SVAR

  set options(-file) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag) 0

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { ![file exists $options(-file)] } {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report
  ## -------------------------------------

  set rval(num_drc_errors)                  -1
  set rval(num_drc_errors_types)            -1
  set rval(num_drc_errors,line_number)       1
  set rval(num_drc_errors_types,line_number) 1

  set count_error_types 0
  set line_is_error_type false

  set line_number 0
  foreach line $lines {
    incr line_number

    if { [regexp {^.*TOTAL VIOLATIONS =\s+([\d]+)} $line match data] } {
      set rval(num_drc_errors)                   $data
      set rval(num_drc_errors,line_number)       $line_number
      set rval(num_drc_errors_types,line_number) $line_number
      set line_is_error_type true
      continue
    }

    if { [regexp {^Total number of nets =\s+([\d]+)} $line] } {
      set line_is_error_type false
      continue
    }

    if { $line_is_error_type } {
      incr count_error_types
    }
  }

  set rval(num_drc_errors_types) $count_error_types

  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  return [array get rval]
}

define_proc_attributes sproc_parse_report_design \
  -info "Parses information for report_design." \
  -define_args {
  {-file "The report_design file to parse." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_parse_report_utilization:
## -----------------------------------------------------------------------------

proc sproc_parse_report_utilization { args } {

  global env SVAR

  set options(-file) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag) 0

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { ![file exists $options(-file)] } {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report
  ## -------------------------------------

  set rval(cell2core_ratio)                -1
  set rval(chip_area)                      -1

  ## -------------------------------------

  set rval(cell2core_ratio,line_number)      1
  set rval(chip_area,line_number)            1

  ## -------------------------------------

  set line_number 0
  foreach line $lines {
    incr line_number

    if { [regexp {^Utilization Ratio:\s+([\d\.]+)} $line match value] } {
      set rval(cell2core_ratio)             $value
      set rval(cell2core_ratio,line_number) $line_number
    }
    if { [regexp {^Total Area:\s+([\d\.]+)} $line match value] } {
      set rval(chip_area)             $value
      set rval(chip_area,line_number) $line_number
    }

  }

  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  return [array get rval]
}

define_proc_attributes sproc_parse_report_utilization \
  -info "Parses information for report_utilization." \
  -define_args {
  {-file "The report_utilization file to parse." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_parse_report_congestion:
## -----------------------------------------------------------------------------

proc sproc_parse_report_congestion { args } {

  global env SVAR

  set options(-file) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag) 0

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { ![file exists $options(-file)] } {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report
  ## -------------------------------------

  set rval(grc_overflow) undefined

  foreach line $lines {
    regexp {Both Dirs: Overflow.*\(([\d\.]+)%\)} $line match rval(grc_overflow)
  }

  if { $rval(grc_overflow) == "undefined" } {
    sproc_msg -error "Unable to parse value for 'Both Dirs: Overflow'"
  }

  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  return [array get rval]
}

define_proc_attributes sproc_parse_report_congestion \
  -info "Parses information for report_congestion." \
  -define_args {
  {-file "The report_congestion file to parse." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_parse_report_units:
## -----------------------------------------------------------------------------

proc sproc_parse_report_units { args } {

  global env SVAR

  set options(-file) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag)       0
  set rval(time_unit)        "undefined"

  set rval(text_time)        "undefined"
  set rval(text_capacitance) "undefined"
  set rval(text_resistance)  "undefined"
  set rval(text_voltage)     "undefined"
  set rval(text_power)       "undefined"
  set rval(text_current)     "undefined"

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { ![file exists $options(-file)] } {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report
  ## -------------------------------------

  set time_unit undefined
  foreach line $lines {
    regexp {(e\-\S\S)\s+Second} $line match time_unit

    regexp {^Time_unit\s+:\s+(.*)\s*$} $line match rval(text_time)
    regexp {^Capacitive_load_unit\s+:\s+(.*)\s*$} $line match rval(text_capacitance)
    regexp {^Resistance_unit\s+:\s+(.*)\s*$} $line match rval(text_resistance)
    regexp {^Voltage_unit\s+:\s+(.*)\s*$} $line match rval(text_voltage)
    regexp {^Power_unit\s+:\s+(.*)\s*$} $line match rval(text_power)
    regexp {^Current_unit\s+:\s+(.*)\s*$} $line match rval(text_current)
  }

  switch $time_unit {
    e-00 {
      set rval(time_unit) s
    }
    e-03 {
      set rval(time_unit) ms
    }
    e-06 {
      set rval(time_unit) us
    }
    e-09 {
      set rval(time_unit) ns
    }
    e-12 {
      set rval(time_unit) ps
    }
    e-15 {
      set rval(time_unit) fs
    }
    default {
      sproc_msg -error "Unrecognized value for time units: $time_unit"
      set rval(error_flag) 1
    }
  }

  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  return [array get rval]
}

define_proc_attributes sproc_parse_report_units \
  -info "Parses information for report_units." \
  -define_args {
  {-file "The report_units file to parse." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_parse_report_timing:
## -----------------------------------------------------------------------------

proc sproc_parse_report_timing { args } {

  global env SVAR

  set options(-file) ""
  set options(-scenario) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag) 0
  set rval(items) [list]

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { ![file exists $options(-file)] } {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report
  ## -------------------------------------

  if { $options(-scenario) == "" } {
    set scenario_name None/non-MCMM
  } else {
    set scenario_name $options(-scenario)
  }

  set line_number 0
  foreach line $lines {
    incr line_number

    regexp {^\s+Startpoint:\s+(\S+)} $line match start_point
    regexp {^\s+Endpoint:\s+(\S+)}   $line match end_point
    regexp {^\s+Scenario:\s+(\S+)}   $line match scenario_name
    regexp {^\s+Path Group:\s+(\S+)} $line match path_group
    regexp {^\s+Path Type:\s+(\S+)}  $line match path_type
    if { [regexp {^\s+slack\s+\(\S+\)\s+([\d\.\-]+)} $line match value] } {
      set slack $value
      set line $line_number
      set path_item "$scenario_name $start_point $end_point $path_group $path_type $slack $line"
      lappend rval(items) $path_item
    }

  }

  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  return [array get rval]
}

define_proc_attributes sproc_parse_report_timing \
  -info "Parses information for report_timing." \
  -define_args {
  {-file     "The report_units file to parse." AString string required}
  {-scenario "The scenario name." AString string optional}
}

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
