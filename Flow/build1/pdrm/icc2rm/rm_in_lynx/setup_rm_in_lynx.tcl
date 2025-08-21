#! /usr/bin/env tclsh
################################################################################
## Running RM in Lynx Installation Utility script
## Script:  setup_rm_in_lynx.tcl
## Version: P-2019.03-SP2
## Copyright (C) 2019 Synopsys, Inc.  All rights reserved.
################################################################################
## DESCRIPTION:
## * This TCL-based utility is designed to setup RM scripts and run it in 
## * Lynx-RTM environment.  
## *  - Setup RM scripts as normal - (ie. all files in rm_setup/ directory)
## *  - Run this utility on the UNIX command line
## *  - Run the flow with Lynx-RTM
## *
## * The utility runs on the UNIX command line.
## * Use -help for more details.
## -----------------------------------------------------------------------------

## -----------------------------------------------------------------------------
## Parse arguments
## -----------------------------------------------------------------------------

set gvar(build) ""
set gvar(flow_xml) ""
set gvar(help) 0
set gvar(error) 0

for {set i 0} { $i < [llength $argv] } { incr i } {
  set arg [lindex $argv $i]
  switch -exact -- $arg {
    -build {
      incr i
      set gvar(build) [lindex $argv $i]
    }
    -flow_xml {
      incr i
      set gvar(flow_xml) [lindex $argv $i]
    }
    -help {
      set gvar(help) 1
    }
    default {
      puts "ERROR: Unrecognized option: $arg"
      set gvar(error) 1
    }
  }
}

## -----------------------------------------------------------------------------
## Some Checking
## -----------------------------------------------------------------------------

## Check to see what RM is installed in the cwd
set check(RM_INSTALL) ""
proc check_RM_install {dir} {
  set RM_install [glob -nocomplain rm_*scripts]
  if {[llength $RM_install] != 0} {
    foreach ind_RM $RM_install {
      lappend check(RM_INSTALL) [lindex [split $ind_RM _] 1]
    }
      set check(RM_INSTALL) [lsort -unique $check(RM_INSTALL)]
    return $check(RM_INSTALL)
  } else {
    return 0
  }
}

## Check RM version
set check(RM_VERSION) ""
proc check_RM_version {flow_xml} {
  set rm [string range [file rootname [file tail $flow_xml]] 3 end]
  if [regexp dp $rm] { set rm [string range $rm 0 end-5] }
  set file [lindex [glob rm_${rm}_scripts/*] 0]
  set fin [open $file r]
  while {[gets $fin line] >= 0} {
    if {[regexp Version $line]} {
      set check(RM_VERSION) [scan [lindex [split $line :] 1] %s]
    }
  }
  close $fin
  return $check(RM_VERSION)
}

## Check to see if scripts_global is installed in this directory
set check(SG) "0"
proc check_SG_install {dir} {
  set check(SG) [file isdirectory scripts_global]
  return $check(SG)
}

## Check to see if the build_name is already used in this directory
set check(BUILD) ""
proc check_build_install {dir} {
  if {[file isdirectory builds]} { 
    set build_names [glob -nocomplain -type d builds/*]    
    if {[llength $build_names] != 0} {
      foreach build $build_names {
        lappend check(BUILD) [string range $build 7 end]
      }
      return $check(BUILD)
    } else {
      return 0
    }
  }
}

## -----------------------------------------------------------------------------
## Help Info
## -----------------------------------------------------------------------------

proc setup_rm_in_lynx_help {} {
  global env argv0
  puts stderr \n[string repeat # 90]
  puts stderr "## This script will setup RM scripts and run it in Lynx Environment"
  puts stderr "## Steps to setup RM-in-Lynx"
  puts stderr "##---------------------------"
  puts stderr "## (1) Make sure Lynx is loaded in your environment"
  puts stderr "## (2) cd to your RM workarea"
  puts stderr "## (3) Run RM-in-Lynx Setup utility"
  puts stderr "##     Unix% ./rm_in_lynx/setup_rm_in_lynx.tcl -build \<my_build\> -flow_xml \<top_flow\>"
  puts stderr "##     Specify <my_build> as \"top-level block name\"_\"flow name\".  Eg. dhm_DCRM"
  puts stderr "##     <top_flow> can be your own flow or use one of the flow_xml listed below:-"
  ## When environment variable DISABLE_VER_CHECK is present - Display all flows
  ## Otherwise, only display Flow XML that were installed
  if [info exists env(DISABLE_VER_CHECK)] {
    foreach ind_xml [glob rm_in_lynx/flows/*] {
      puts stderr "##       o $ind_xml"
    }
  } else {
    foreach rm_dir [check_RM_install .] {
      foreach ind_xml [glob -nocomplain rm_in_lynx/flows/rm_${rm_dir}*.xml] {
        puts stderr "##       o $ind_xml"
      }
    }
  }
  puts stderr "## (4) Launch Lynx Automation GUI"
  puts stderr "##     Unix% rtm_shell -gui"
  puts stderr [string repeat # 90]\n
}

## -----------------------------------------------------------------------------
## Custom printing proc
## -----------------------------------------------------------------------------
proc cprint {arg} {
  puts \n[string repeat # 90]
  puts "$arg"  
  puts [string repeat # 90]
}

## -----------------------------------------------------------------------------
## Main Script
## -----------------------------------------------------------------------------
if { $argv == "" || $gvar(help) == 1 || $gvar(error) == 1 } {
  setup_rm_in_lynx_help
  return
}

proc setup_rm_in_lynx {arg} {
    global env gvar check
    set build $gvar(build)

    ## RM_dir and Lynx_dir is cwd for now
    ## Set up this way - just in case we need to support different RM_dir 
    ## and Lynx_dir in the future
    set RM_dir .
    set Lynx_dir .

    if {[info exists env(LYNX_HOME)] == 0} { 
      cprint "Error:  Need to make sure Lynx is loaded in your environment first"
      return
    } 

    if {$build == ""} {
      cprint "Error:  Must specify -build \<my_build\>"
      return
    } elseif {[lsearch -exact [check_build_install $Lynx_dir] $build] != -1 } {
      puts \n[string repeat # 90]
      puts "Error:  Build $build already exists, please use another name."
      puts "See solvnet 3000048 for more details on running multiple RMs"
      puts [string repeat # 90]
      return
    }

    if {$gvar(flow_xml) == ""} {
      cprint "Error:  Must specify -flow_xml \<default_flow\> \[Note: Use -help to see available flow_xml\]"
      return
    } elseif {![string equal xml [string range [file ext $gvar(flow_xml)] 1 end]] } {
      cprint "Error:  $gvar(flow_xml) is not an xml file. \[Note: Use -help to see available flow_xml\]"
      return
    } else {
      ## When environment variable DISABLE_VER_CHECK is present - skip checking RM version
      ## Otherwise check to make sure it is 2018.06-SP4 or later version
      if ![info exists env(DISABLE_VER_CHECK)] {
	set rm [string range [file rootname [file tail $gvar(flow_xml)]] 3 end]
        set split_rm_version [split [check_RM_version $gvar(flow_xml)] -]
        set platform [lindex $split_rm_version 0]
        set rel [lindex $split_rm_version 1]
        set sp [lindex $split_rm_version 2]
        ## -1 for older release; 0 for 2018.06; 1 for newer release
        set gd_rel [string compare $rel 2018.06]
        ## 1 when SP4; 0 otherwise
        set gd_sp [string match $sp SP4]
        set rel_sp_status "${gd_rel}_${gd_sp}"
        switch -glob $rel_sp_status {
          -1_* {set gen_error 1}
	  0_0 {set gen_error 1}
	  default {set gen_error 0}    
        }
        if $gen_error {
	  puts \n[string repeat # 90]
          puts "Error: RM-in-Lynx is setup for 2018.06-SP4 or newer release only."
          puts "       [string toupper $rm] version installed in this dir is $platform-$rel-$sp"
	  puts [string repeat # 90]
          return
	}  
      }
    }

    ## Perform actual work
    puts \n[string repeat # 90]
    set Lynx_ver [file tail [file dir [file dir [exec which rtm_shell]]]]
    regsub -all "rtm" $Lynx_ver "flow" Lynx_ver

    puts "## Setting up RM scripts to run in Lynx Automation GUI"
    puts "## ..."
    ## Only copy three directories from Intallation - demo, conf, procs
    if {[check_SG_install $Lynx_dir]} {
      puts "## scripts_global already exists - not copying from \$LYNX_HOME"
    } else {
      puts "## Copying scripts_global from $Lynx_ver"
      file mkdir $Lynx_dir/scripts_global
      set dlist [list demo conf procs]
      foreach dir $dlist {
        file copy $env(LYNX_HOME)/flow/$Lynx_ver/scripts_global/$dir $Lynx_dir/scripts_global
      }
      ## remove config_flow.xml from scripts_global/conf
      ## use config_flow.xml in build dir instead
      file delete $Lynx_dir/scripts_global/conf/config_flow.xml
      cd scripts_global
      exec ln -s ../rm_in_lynx/scripts/dt_shell
      exec ln -s ../rm_in_lynx/scripts/view
      cd ../
    }
    ## Check to see if directory $Lynx_dir/scripts_global/rm_in_lynx exists or not.
    ## If not exists - then copy it, otherwise skip 
    if {![file isdirectory $Lynx_dir/scripts_global/rm_in_lynx]} {
      set grm_dir $Lynx_dir/scripts_global/rm_in_lynx
      file mkdir $grm_dir; cd $grm_dir
      exec ln -s ../../rm_in_lynx/flows
      file mkdir scripts; cd scripts
      foreach ind_tcl [glob ../../../rm_in_lynx/scripts/*tcl] {
        exec ln -s $ind_tcl
      }
      cd ../../..
    }
    ## Modify some SEV variables
    set sevfile $Lynx_dir/scripts_global/conf/sev_values.tcl
    file delete -force $sevfile.org
    file copy $sevfile $sevfile.org
    set fin  [open $sevfile.org r]
    set fout [open $sevfile w]
    while {[gets $fin line] >= 0} {
      if {[regexp {^set} $line] && [regexp {rc_method} [lindex $line 1]]} {
	  puts $fout "set SEV(config,rc_method) none"
      } elseif {[regexp {^set} $line] && [regexp {enable,job} [lindex $line 1]]} {
	  puts $fout "set SEV(enable,job) 0"
      } elseif {[regexp {^set} $line] && [regexp {verbosity} [lindex $line 1]]} {
	  puts $fout "set SEV(config,verbosity) min"
      } else {
	  puts $fout $line
      }
    }

    puts "## Copying scripts_build for $build"
    set bconf_dir $Lynx_dir/builds/$build/scripts_build/conf 
    file mkdir $bconf_dir
    ## Setup Top_flow and Flow_goal in config_flow.xml according to specified flow_xml
    puts "## Setting up config_flow.xml"
    set fout [open $bconf_dir/config_flow.xml w]
    puts $fout "\<file type=\"flow_config\"\>"
    if {[lsearch -exact [glob rm_in_lynx/flows/*] $gvar(flow_xml)] || \
        [lsearch -exact [glob ./rm_in_lynx/flows/*] $gvar(flow_xml)]} {
      set top_flow "\$SEV(gscript_dir)/$gvar(flow_xml)"
      set flow_goal [file root [file tail $gvar(flow_xml)]]/all
      puts "##   Top_flow  = $gvar(flow_xml)" 
      puts "##   Flow_goal = $flow_goal"
      puts $fout "  \<attribute name=\"top_flow\" value=\"$top_flow\"/\>"
      puts $fout "  \<attribute name=\"flow_goal\" value=\"$flow_goal\"/\>"
    } else {
      set top_flow $gvar(flow_xml)
      puts "##   Top_flow  = Custom flow - $gvar(flow_xml)" 
      puts "##   Flow_goal = Not set"
      puts $fout "  \<attribute name=\"top_flow\" value=\"$top_flow\"/\>"
    }
    puts $fout "\</file\>"
    close $fout
    foreach indfile "setup.tcl sev_values.tcl svar_values.tcl" {open $bconf_dir/$indfile w}
    puts "## ... Done!"
    puts "## User can invoke rtm_shell and run RM flow with Lynx Automation"
    puts "##"
    puts "## Unix% rtm_shell -gui"
    puts [string repeat # 90]\n
}

setup_rm_in_lynx $argv

