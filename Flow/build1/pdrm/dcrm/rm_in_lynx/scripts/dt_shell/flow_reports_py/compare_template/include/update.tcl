#! /usr/bin/env tclsh
## -----------------------------------------------------------------------------
## HEADER_MSG  Lynx Design System: Baseline Flow
## HEADER_MSG  Version 2019.03-SP2
## HEADER_MSG  Copyright (c) 2019 Synopsys
## HEADER_MSG  Perforce Label: lynx_flow_2019.03-SP2
## -----------------------------------------------------------------------------

set gvar(prog_path) [file dirname [file normalize $argv0]]
set gvar(data_path) [file dirname $gvar(prog_path)]/data

set absFileList [glob -nocomplain $gvar(data_path)/*/*.tbl]
set relFileList [list]

foreach absFile $absFileList {
  set relFile [join [lrange [split $absFile "/"] end-1 end] "/"]
  lappend relFileList $relFile
}

set relFileList [lsort $relFileList]

set tbl_cfg_file $gvar(data_path)/tbl.cfg
puts "Updating $tbl_cfg_file ..."

set fid [open $tbl_cfg_file w]
foreach relFile $relFileList {
  puts "  $relFile"
  puts $fid $relFile
}
close $fid

puts "Done!"

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
