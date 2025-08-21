## -----------------------------------------------------------------------------
## HEADER_MSG  Lynx Design System: Baseline Flow
## HEADER_MSG  Version 2019.03-SP2
## HEADER_MSG  Copyright (c) 2019 Synopsys
## HEADER_MSG  Perforce Label: lynx_flow_2019.03-SP2
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * Menu setup file
## -----------------------------------------------------------------------------

## -----------------------------------------------------------------------------
## Setup defaults for colors & fonts
## -----------------------------------------------------------------------------

set color(background) #efebe7

set classList {
  Frame
  Label Text Message Entry
  Button Checkbutton Radiobutton
  Menu Menubutton
  Listbox Spinbox
}

option clear

foreach class $classList {
  catch { font delete fontFor$class }
  font create fontFor$class -family "bitstream vera sans" -size 10
  option add *$class.font fontFor$class widgetDefault
  option add *$class.background $color(background) widgetDefault
}

## -----------------------------------------------------------------------------
## Menu references
## -----------------------------------------------------------------------------

## foreach type [gui_get_window_types] { puts $type }
## puts gui_default_window_type
set window_type TopLevel

## -----------------------------------------------------------------------------
## Add shortcut for SEV(publish_dir) if available
## -----------------------------------------------------------------------------

if { [info exists SEV(publish_dir)] } {
  if { [file isdirectory $SEV(publish_dir)] } {
    add_shortcut -name "Publish" -dir [file normalize $SEV(publish_dir)]
  }
}

if { [info exists SEV(workarea_dir)] } {
  if { [file isdirectory $SEV(workarea_dir)] } {
    add_shortcut -name "Workarea" -dir [file normalize $SEV(workarea_dir)]
  }
}

## -----------------------------------------------------------------------------
## Example Menu
## -----------------------------------------------------------------------------

set targetFile $env(SYNOPSYS_DT)/auxx/dt_shell/example_menus/setup.tcl
if { [file exists $targetFile] } {
  puts "Loading $targetFile"
  source $targetFile
}

## -----------------------------------------------------------------------------
## R2G Menu
## -----------------------------------------------------------------------------

set targetFile $SEV(scripts_dir)/flow_menus/setup.tcl
if { [file exists $targetFile] } {
  puts "Loading $targetFile"
  source $targetFile
}

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
