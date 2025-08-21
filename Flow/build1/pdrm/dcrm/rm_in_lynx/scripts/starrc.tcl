## -----------------------------------------
## Create output directories
## -----------------------------------------

file mkdir results
file mkdir reports

## -----------------------------------------------
## Run StarRC using command file, star_cmd_gate
## -----------------------------------------------

set command_file ./rm_starrc_scripts/star_cmd_gate
set cmd "StarXtract -clean $command_file"

sproc_msg -info "RM-Info: The command is: $cmd"

catch {exec sh -c "$cmd" } tmp_log
puts $tmp_log

set fin [open $command_file r]
while {[gets $fin line] >= 0} {
  if { [regexp {STAR_DIRECTORY} $line] } {
      set dir [lindex [split $line] 1]
      puts $dir
  }
}
sproc_refresh_file_system -dir $dir
if {![file exists ./reports/star/.starrc_complete]} {
  puts "Error: No success file present after extraction"
} else {
  puts "RM-Info: Extraction completed with a success file"
}
