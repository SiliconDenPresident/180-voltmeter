## -----------------------------------------------------------------------------
## HEADER_MSG  Lynx Design System: Baseline Flow
## HEADER_MSG  Version 2019.03-SP2
## HEADER_MSG  Copyright (c) 2019 Synopsys
## HEADER_MSG  Perforce Label: lynx_flow_2019.03-SP2
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This script provides a Tk widget for build directory selection.
## -----------------------------------------------------------------------------

lappend auto_path $env(SYNOPSYS_DT)/auxx/dt/tcl/tablelist5.16
lappend auto_path $env(SYNOPSYS_DT)/auxx/dt/tcl/tooltip1.4.4

package require tablelist 5.16
package require tooltip 1.4.4

## -----------------------------------------------------------------------------
## -----------------------------------------------------------------------------
## BuildSelectWidget::
## -----------------------------------------------------------------------------
## -----------------------------------------------------------------------------

namespace eval BuildSelectWidget {
  variable gvar
}

## -----------------------------------------------------------------------------
## BuildSelectWidget::newWidget
## -----------------------------------------------------------------------------

proc BuildSelectWidget::newWidget { argReportType argModeSingleBuild } {
  variable gvar

  ## -------------------------------------
  ## Variable definitions
  ## -------------------------------------

  set gvar(dtShellDir) $::env(HOME)/.dt_shell
  set gvar(buildFile) $gvar(dtShellDir)/buildFile
  set gvar(reportType) $argReportType
  set gvar(modeSingleBuild) $argModeSingleBuild
  if { ![info exists gvar(initialChooseDirectory)] } {
    set gvar(initialChooseDirectory) ""
  }

  set gvar(COLUMN_LABEL)  0
  set gvar(COLUMN_RPTS)   1
  set gvar(COLUMN_DIR)    2

  ## -------------------------------------
  ## Widget hierarchy
  ## -------------------------------------
  ## instMain
  ##   instTabFrame      Frame
  ##     instTable       Tabellist
  ##     instVsb         Scrollbar
  ##     instHsb         Scrollbar
  ##   instButFrame      Frame
  ##     instButtonX ... Buttons
  ## -------------------------------------

  set gvar(instMain) .buildSelectWidgetTop

  set gvar(instTabFrame) $gvar(instMain).theTabFrame
  set gvar(instTable) $gvar(instTabFrame).theTable
  set gvar(instVsb) $gvar(instTabFrame).theVsb
  set gvar(instHsb) $gvar(instTabFrame).theHsb

  set gvar(instButFrame)      $gvar(instMain).theButFrame
  set gvar(instButtonAdd)     $gvar(instButFrame).theB1
  set gvar(instButtonDelete)  $gvar(instButFrame).theB2
  set gvar(instButtonSave)    $gvar(instButFrame).theB3
  set gvar(instButtonRun)     $gvar(instButFrame).theB4
  set gvar(instButtonDismiss) $gvar(instButFrame).theB5

  set gvar(colorYellowNormal) #ffff00
  set gvar(colorYellowActive) #dddd00 ;# A little darker
  set gvar(colorGrayNormal)   #e9e7e3
  set gvar(colorGrayActive)   #d9d7d3 ;# A little darker

  ## -------------------------------------
  ## Add entries to the Tk option database
  ## -------------------------------------

  catch {font create TkDefaultFont -family "bitstream vera sans" -size -10}

  option add *BuildSelectWidget*Font                                     TkDefaultFont
  option add *BuildSelectWidget*foreground                               black
  option add *BuildSelectWidget*background                               $gvar(colorGrayNormal)
  option add *BuildSelectWidget.theTabFrame.theTable.background          white
  ## option add *BuildSelectWidget.theTabFrame.theTable.stripeBackground    $gvar(colorGrayNormal)
  ## option add *BuildSelectWidget.theTabFrame.theTable.selectBackground    #00ffff
  ## option add *BuildSelectWidget.theTabFrame.theTable.selectForeground    black
  option add *BuildSelectWidget.theTabFrame.theTable.setGrid             yes
  option add *BuildSelectWidget.theTabFrame.theTable*Entry.background    white
  option add *BuildSelectWidget.theButFrame.Button.width                 10
  option add *BuildSelectWidget.theButFrame.Button.activeBackground      $gvar(colorGrayActive)

  ## -------------------------------------
  ## Ensure that gvar(dtShellDir) directory is available
  ## -------------------------------------

  file mkdir $gvar(dtShellDir)
  if { ![file isdirectory $gvar(dtShellDir)] } {
    puts "Error: Unable to create directory $gvar(dtShellDir)"
    return
  }

  ## -------------------------------------
  ## Setup the widget
  ## -------------------------------------

  BuildSelectWidget::buildWidget

  BuildSelectWidget::initWidget

}

## -----------------------------------------------------------------------------
## BuildSelectWidget::buildWidget
## -----------------------------------------------------------------------------

proc BuildSelectWidget::buildWidget {} {
  variable gvar

  ## -------------------------------------
  ## The widget does exist, so return
  ## -------------------------------------

  if { [winfo exists $gvar(instMain)] } {
    raise $gvar(instMain)
    return
  }

  ## -------------------------------------
  ## The widget does not exist, so build it
  ## -------------------------------------

  toplevel $gvar(instMain) -class BuildSelectWidget

  ## -------------------------------------
  ## Create a scrolled tablelist widget with 2 dynamic-width
  ## columns and interactive sort capability within the top-level
  ## -------------------------------------

  frame $gvar(instTabFrame)

  tablelist::tablelist $gvar(instTable) \
    -columns { \
      0 "Label" \
      0 "Reports" \
      0 "Directory" } \
    -height 10 -width 100 -stretch all \
    -showeditcursor false \
    -editendcommand BuildSelectWidget::applyValue \
    -xscrollcommand [list $gvar(instHsb) set] \
    -yscrollcommand [list $gvar(instVsb) set] \
    -selectmode extended \
    -instanttoggle true \
    -tooltipaddcommand BuildSelectWidget::tooltipAdd \
    -tooltipdelcommand BuildSelectWidget::tooltipDel

  ## -labelcommand tablelist::sortByColumn \

  if { [$gvar(instTable) cget -selectborderwidth] == 0 } {
    $gvar(instTable) configure -spacing 1
  }
  $gvar(instTable) columnconfigure $gvar(COLUMN_LABEL) -editable yes -editwindow entry
  $gvar(instTable) columnconfigure $gvar(COLUMN_RPTS)
  $gvar(instTable) columnconfigure $gvar(COLUMN_DIR)
  scrollbar $gvar(instVsb) -orient vertical   -command [list $gvar(instTable) yview]
  scrollbar $gvar(instHsb) -orient horizontal -command [list $gvar(instTable) xview]

  ## -------------------------------------
  ## Create three buttons within a child frame of the top-level widget
  ## -------------------------------------

  frame $gvar(instButFrame)
  button $gvar(instButtonAdd)     -text "Add Build"      -command [list BuildSelectWidget::buttonAdd]
  button $gvar(instButtonDelete)  -text "Delete Build"   -command [list BuildSelectWidget::buttonDelete]
  button $gvar(instButtonSave)    -text "Save Builds"    -command [list BuildSelectWidget::buttonSave]
  button $gvar(instButtonRun)     -text "Run Report"     -command [list BuildSelectWidget::buttonRun]
  button $gvar(instButtonDismiss) -text "Close"          -command [list BuildSelectWidget::buttonDismiss]

  ## -------------------------------------
  ## Manage the widgets
  ## -------------------------------------

  grid $gvar(instTable) -row 0 -rowspan 2 -column 0 -sticky news
  grid $gvar(instVsb) -row 0 -rowspan 2 -column 1 -sticky ns
  grid $gvar(instHsb) -row 2 -column 0 -sticky ew
  grid rowconfigure    $gvar(instTabFrame) 1 -weight 1
  grid columnconfigure $gvar(instTabFrame) 0 -weight 1
  pack \
    $gvar(instButtonAdd) \
    $gvar(instButtonDelete) \
    $gvar(instButtonSave) \
    $gvar(instButtonRun) \
    $gvar(instButtonDismiss) \
    -side left -expand yes -pady 10
  pack $gvar(instButFrame) -side bottom -fill x
  pack $gvar(instTabFrame) -side top -expand yes -fill both

}

## -----------------------------------------------------------------------------
## BuildSelectWidget::resolveBuildDir
## -----------------------------------------------------------------------------

proc BuildSelectWidget::resolveBuildDir { buildDir } {
  variable gvar

  if { [regexp {^Local : (\S+)} $buildDir matchVar buildName] } {
    set result $::SEV(workarea_dir)/builds/$buildName
  } else {
    set result $buildDir
  }

  return $result

}

## -----------------------------------------------------------------------------
## BuildSelectWidget::initWidget
## -----------------------------------------------------------------------------

proc BuildSelectWidget::initWidget {} {
  variable gvar

  wm title $gvar(instMain) "Build Select for $gvar(reportType)"

  ## -------------------------------------
  ## Develop state information
  ## -------------------------------------

  ## -------------------------------------
  ## Information about builds inside workarea
  ## -------------------------------------

  set bfiles ""

  set bfiles [concat $bfiles [glob -type f -nocomplain $::SEV(workarea_dir)/builds/*/scripts_build/conf/sev_values.tcl]]

  set buildItemList [list]

  foreach bfile $bfiles {

    set buildDir [file dirname [file dirname [file dirname $bfile]]]
    set buildLabel [file tail $buildDir]

    ## Redefine buildDir for builds within the workarea
    set buildDir "Local : $buildLabel"

    set buildItem [list $buildDir $buildLabel]
    if { [lsearch $buildItemList $buildItem] == -1 } {
      lappend buildItemList $buildItem
    }

  }

  ## -------------------------------------
  ## Information about builds outside workarea
  ## -------------------------------------

  if { [file exists $gvar(buildFile)] } {
    set fid [open $gvar(buildFile) r]
    set string_file [read $fid]
    close $fid
    set lines [split $string_file \n]
    foreach line $lines {
      if { ![regexp {^\s*$} $line] } {
        set fields [split $line]
        set buildDir    [lindex $fields 0]
        set buildLabel  [lindex $fields 1]
        set buildItem [list $buildDir $buildLabel]
        if { [lsearch $buildItemList $buildItem] == -1 } { 
          lappend buildItemList $buildItem
        } 
      } 
    }
  }

  ## -------------------------------------
  ## Apply state information to widget
  ## -------------------------------------

  $gvar(instTable) delete 0 end

  foreach buildItem $buildItemList {
    set buildDir    [lindex $buildItem 0]
    set buildLabel  [lindex $buildItem 1]
    set rowItem [list $buildLabel "No" $buildDir]
    $gvar(instTable) insert end $rowItem
  }

  $gvar(instTable) activate 0

  BuildSelectWidget::updateBuildReports

  BuildSelectWidget::checkForDuplicates

}

## -----------------------------------------------------------------------------
## BuildSelectWidget::buttonSave
## -----------------------------------------------------------------------------

proc BuildSelectWidget::buttonSave {} {
  variable gvar

  puts "Information: Saving build information to file: $gvar(buildFile)"

  set fid [open $gvar(buildFile) w]

  set rowCount [$gvar(instTable) size]
  for { set row 0 } { $row < $rowCount } { incr row } {
    set buildDir    [$gvar(instTable) cellcget $row,$gvar(COLUMN_DIR) -text]
    set buildLabel  [$gvar(instTable) cellcget $row,$gvar(COLUMN_LABEL) -text]

    if { ![regexp {Local :} $buildDir] } {
      puts $fid "$buildDir $buildLabel"
    }
  }

  close $fid

  BuildSelectWidget::setWarningButtonSave 0

}

## -----------------------------------------------------------------------------
## BuildSelectWidget::buttonAdd
## -----------------------------------------------------------------------------

proc BuildSelectWidget::buttonAdd {} {
  variable gvar

  set rowCount [$gvar(instTable) size]

  if { $gvar(initialChooseDirectory) == "" } {
    if { [info exists ::SEV(snapshot_dir)] } {
      set gvar(initialChooseDirectory) $::SEV(snapshot_dir)
    } else {
      set gvar(initialChooseDirectory) [pwd]
    }
  }

  set dir [tk_chooseDirectory \
    -initialdir $gvar(initialChooseDirectory) \
    -title "Choose a Directory" \
    -parent $gvar(instMain) \
  ]

  if { $dir == "" } {
    return
  } else {
    set gvar(initialChooseDirectory) [file dirname $dir]
  }

  set newBuildDir   $dir
  set newBuildLabel [file tail $dir]
  set newSelect     0
  set newBuildItem [list $newBuildDir $newBuildLabel $newSelect]

  set buildDir    [lindex $newBuildItem 0]
  set buildLabel  [lindex $newBuildItem 1]
  set rowItem [list $buildLabel "No" $buildDir]
  $gvar(instTable) insert end $rowItem

  $gvar(instTable) activate end

  BuildSelectWidget::updateBuildReports

  BuildSelectWidget::checkForDuplicates

  BuildSelectWidget::setWarningButtonSave 1

}

## -----------------------------------------------------------------------------
## BuildSelectWidget::buttonDelete
## -----------------------------------------------------------------------------

proc BuildSelectWidget::buttonDelete {} {
  variable gvar

  set indexList [$gvar(instTable) curselection]

  set deleteList [list]

  foreach index $indexList {

    set buildDir [$gvar(instTable) cellcget $index,$gvar(COLUMN_DIR) -text]

    if { [regexp {^Local :} $buildDir] } {
      puts "Information: Not available for delete: $buildDir"
    } else {
      BuildSelectWidget::setWarningButtonSave 1
      lappend deleteList $index
    }

  }

  $gvar(instTable) delete $deleteList

}

## -----------------------------------------------------------------------------
## BuildSelectWidget::buttonRun
## -----------------------------------------------------------------------------

proc BuildSelectWidget::buttonRun {} {
  variable gvar

  set config_list ""

  set indexList [$gvar(instTable) curselection]

  foreach index $indexList {
    set buildDir    [$gvar(instTable) cellcget $index,$gvar(COLUMN_DIR) -text]
    set buildLabel  [$gvar(instTable) cellcget $index,$gvar(COLUMN_LABEL) -text]
    lappend config_list $buildLabel
    lappend config_list [BuildSelectWidget::resolveBuildDir $buildDir]
  }

  if { [llength $config_list] == 0 } {
    set msg "You must select at least one build"
    tk_messageBox -message $msg -type ok -parent $gvar(instMain)
    return
  }

  if {($gvar(reportType)== "DesignSummaryComparison") || ($gvar(reportType)== "ResourceSummaryComparison") } {
    set reportFile $gvar(dtShellDir)/$gvar(reportType)/index.html
    file delete -force [file dirname $reportFile]
  } else {
    set reportFile $gvar(dtShellDir)/$gvar(reportType).lynx_dt
    file delete -force $reportFile
  }
    
  set usePython false
  if { $usePython } {
    set script_dir $::SEV(scripts_dir)/flow_reports_py
    set script_suffix py
  } else {
    set script_dir $::SEV(scripts_dir)/flow_reports_tcl
    set script_suffix tcl
  }

  set scriptToUse(DesignSummary)             $script_dir/gen_design_summary.$script_suffix
  set scriptToUse(DesignSummaryComparison)   $script_dir/gen_design_summary_compare.$script_suffix
  set scriptToUse(ResourceSummary)           $script_dir/gen_resource_summary.$script_suffix
  set scriptToUse(ResourceSummaryComparison) $script_dir/gen_resource_compare.$script_suffix
  set scriptToUse(TimingMatrix)              $script_dir/gen_scenario_matrix_timing.$script_suffix
  set scriptToUse(PowerMatrix)               $script_dir/gen_scenario_matrix_power.$script_suffix
  set scriptToUse(ClockTreeSummary)          $script_dir/gen_clock_tree_summary.$script_suffix
  set scriptToUse(ToolLicenseSummary)        $script_dir/gen_tool_license_summary.$script_suffix
  set scriptToUse(ClockTreeMatrix)           $script_dir/gen_clock_tree_matrix.$script_suffix
  set scriptToUse(ScenarioTrend)             $script_dir/gen_scenario_trend_timing.$script_suffix
  set scriptToUse(Status)                    $script_dir/gen_status.$script_suffix

  set error 0

  set cmd "$scriptToUse($gvar(reportType))"

  switch $gvar(reportType) {
    DesignSummary {
      set cmd "$cmd -report_file $reportFile"
      set cmd "$cmd -config_list \"$config_list\""
    }
    DesignSummaryComparison {
      set cmd "$cmd -report_file [file dirname $reportFile]"
      set cmd "$cmd -config_list \"$config_list\""
    }
    ResourceSummary {
      set cmd "$cmd -report_file $reportFile"
      set cmd "$cmd -config_list \"$config_list\""
    }
    ResourceSummaryComparison {
      set cmd "$cmd -report_file [file dirname $reportFile]"
      set cmd "$cmd -config_list \"$config_list\""
    }
    TimingMatrix {
      set cmd "$cmd -report_file $reportFile"
      set cmd "$cmd -config_list \"$config_list\""
    }
    PowerMatrix {
      set cmd "$cmd -report_file $reportFile"
      set cmd "$cmd -config_list \"$config_list\""
    }
    ClockTreeSummary {
      set cmd "$cmd -report_file $reportFile"
      set cmd "$cmd -config_list \"$config_list\""
    }
    ToolLicenseSummary {
      set cmd "$cmd -report_file $reportFile"
      set cmd "$cmd -config_list \"$config_list\""
    }
    ClockTreeMatrix {
      set cmd "$cmd -report_file $reportFile"
      set cmd "$cmd -config_list \"$config_list\""
    }
    ScenarioTrend {
      set cmd "$cmd -report_file $reportFile"
      set cmd "$cmd -config_list \"$config_list\""
    }
    Status {
      set cmd "$cmd -report_file $reportFile"
      set cmd "$cmd -config_list \"$config_list\""
    }
    default {
      puts "Error: BuildSelectWidget::buttonRun unrecognized value for gvar(reportType): '$gvar(reportType)'"
      set error 1
    }
  }

  if { !$error } {
    puts $cmd
    catch { eval exec $cmd } results
    puts $results
    puts "Information: The script command was: $cmd"
    if { [file exists $reportFile] } {
      if {[file tail $reportFile] == "index.html"} {
        puts "open_report -format html -file $reportFile -name $gvar(reportType)"
        open_report -format html -file $reportFile -name $gvar(reportType)
      } else {
        puts "open_report -format dt -file $reportFile -name $gvar(reportType)"
        open_report -format dt -file $reportFile -name $gvar(reportType)
      }
    } else {
      puts "Error: Report file does not exist: '$reportFile'"
    }
  }

}

## -----------------------------------------------------------------------------
## BuildSelectWidget::buttonDismiss
## -----------------------------------------------------------------------------

proc BuildSelectWidget::buttonDismiss { } {
  variable gvar

  destroy $gvar(instMain)

}

## -----------------------------------------------------------------------------
## BuildSelectWidget::checkForDuplicates
## -----------------------------------------------------------------------------

proc BuildSelectWidget::checkForDuplicates {} {
  variable gvar

  set rowCount [$gvar(instTable) size]

  ## -------------------------------------
  ## Develop list of the duplicate buildLabel's
  ## -------------------------------------

  set duplicateBuildLabelList [list]

  unset -nocomplain buildLabelArray

  for { set row 0 } { $row < $rowCount } { incr row } {
    set buildLabel [$gvar(instTable) cellcget $row,$gvar(COLUMN_LABEL) -text]

    if { [info exists buildLabelArray($buildLabel)] } {
      lappend duplicateBuildLabelList $buildLabel
    } else {
      set buildLabelArray($buildLabel) 1
    }
  }

  set duplicateBuildLabelList [lsort -unique $duplicateBuildLabelList]

  set buildLabelConflict 0
  if { [llength $duplicateBuildLabelList] > 0 } {
    set buildLabelConflict 1
  }

  ## -------------------------------------
  ## Highlight all buildLabel's that occur more than once
  ## -------------------------------------

  for { set row 0 } { $row < $rowCount } { incr row } {

    set buildLabel [$gvar(instTable) cellcget $row,$gvar(COLUMN_LABEL) -text]

    if { [lsearch $duplicateBuildLabelList $buildLabel] >= 0 } {
      $gvar(instTable) cellconfigure $row,$gvar(COLUMN_LABEL) -fg #ffffff
      $gvar(instTable) cellconfigure $row,$gvar(COLUMN_LABEL) -bg #ff0000
    } else {
      $gvar(instTable) cellconfigure $row,$gvar(COLUMN_LABEL) -fg ""
      $gvar(instTable) cellconfigure $row,$gvar(COLUMN_LABEL) -bg ""
    }

  }

  if { $buildLabelConflict } {
    set msg "There is a least one duplicate build label"
    tk_messageBox -message $msg -type ok -parent $gvar(instMain)
  }

}

## -----------------------------------------------------------------------------
## BuildSelectWidget::applyValue
## -----------------------------------------------------------------------------

proc BuildSelectWidget::applyValue { theTable theRow theCol theText } {
  variable gvar

  ## -------------------------------------
  ## gvar(COLUMN_LABEL)
  ## -------------------------------------

  if { $theCol == $gvar(COLUMN_LABEL) } {

    set buildLabel [$gvar(instTable) cellcget $theRow,$gvar(COLUMN_LABEL) -text]

    if { $buildLabel != $theText } {

      ## The user has altered the value

      $theTable cellconfigure $theRow,$gvar(COLUMN_LABEL) -text $theText
      $theTable cellconfigure $theRow,$gvar(COLUMN_LABEL) -fg ""
      $theTable cellconfigure $theRow,$gvar(COLUMN_LABEL) -bg ""

      ## If entry is not Local, then set Save warning

      set buildDir [$gvar(instTable) cellcget $theRow,$gvar(COLUMN_DIR) -text]

      if { ![regexp {^Local :} $buildDir] } {
        BuildSelectWidget::setWarningButtonSave 1
      }

    }

  }

  ## -------------------------------------
  ## Flag the duplicate buildLabel's
  ## -------------------------------------

  BuildSelectWidget::checkForDuplicates

  return $theText

}

## -----------------------------------------------------------------------------
## BuildSelectWidget::updateBuildReports
## -----------------------------------------------------------------------------

proc BuildSelectWidget::updateBuildReports {} {
  variable gvar

  set rowCount [$gvar(instTable) size]
  for { set row 0 } { $row < $rowCount } { incr row } {
    set buildDir [$gvar(instTable) cellcget $row,$gvar(COLUMN_DIR) -text]
    set buildDir [BuildSelectWidget::resolveBuildDir $buildDir]

    set reportFiles ""

    switch $gvar(reportType) {
      DesignSummary -
      DesignSummaryComparison -
      TimingMatrix -
      ScenarioTrend -
      Status {
        set reportFiles [concat $reportFiles [glob -nocomplain $buildDir/*/*/rpts/*/*.report_qor]]
      }
      ResourceSummary -
      ResourceSummaryComparison {
        set reportFiles [concat $reportFiles [glob -nocomplain $buildDir/*/*/rpts/*/.*.lynx_task]]
      }
      PowerMatrix {
        set reportFiles [concat $reportFiles [glob -nocomplain $buildDir/*/*/rpts/*/*.report_power]]
      }
      ClockTreeSummary -
      ClockTreeMatrix {
        set reportFiles [concat $reportFiles [glob -nocomplain $buildDir/*/*/rpts/*/*.report_clock_qor.summary]]
      }
      ToolLicenseSummary {
        set reportFiles [concat $reportFiles [glob -nocomplain $buildDir/*/*/rpts/*/.*.lynx_task]]
      }
    }

    if { [llength $reportFiles] > 0 } {
      set reportsText Yes
    } else {
      set reportsText No
    }

    $gvar(instTable) cellconfigure $row,$gvar(COLUMN_RPTS) -text $reportsText
  }

}

## -----------------------------------------------------------------------------
## Misc
## -----------------------------------------------------------------------------

proc BuildSelectWidget::setWarningButtonSave { enableWarning } {
  variable gvar

  if { $enableWarning } {
    $gvar(instButtonSave) configure -background       $gvar(colorYellowNormal)
    $gvar(instButtonSave) configure -activebackground $gvar(colorYellowActive)
  } else {
    $gvar(instButtonSave) configure -background       $gvar(colorGrayNormal)
    $gvar(instButtonSave) configure -activebackground $gvar(colorGrayActive)
  }

}

proc BuildSelectWidget::emptyStr val { return "" }

proc BuildSelectWidget::tooltipAdd { theTable theRow theCol } {
  variable gvar

  if { $theCol == $gvar(COLUMN_DIR) } {

    if { $theRow == "-1" } {
      set theMessage "Absolute path to build directory"
    } else {
      set buildDir [$theTable cellcget $theRow,$theCol -text]
      set buildDir [BuildSelectWidget::resolveBuildDir $buildDir]
      set theMessage $buildDir
    }

  } elseif { $theCol == $gvar(COLUMN_LABEL) } {

    set theMessage "Label associated with build directory"

  } elseif { $theCol == $gvar(COLUMN_RPTS) } {

    set theMessage "Indicates data is available for reporting"

  }

  tooltip::tooltip $theTable $theMessage

}

proc BuildSelectWidget::tooltipDel {} {
  tooltip::tooltip clear
}

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
