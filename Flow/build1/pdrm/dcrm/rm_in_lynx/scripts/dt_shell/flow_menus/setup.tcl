## -----------------------------------------------------------------------------
## HEADER_MSG  Lynx Design System: Baseline Flow
## HEADER_MSG  Version 2019.03-SP2
## HEADER_MSG  Copyright (c) 2019 Synopsys
## HEADER_MSG  Perforce Label: lynx_flow_2019.03-SP2
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * Flow menu setup
## -----------------------------------------------------------------------------

source $SEV(scripts_dir)/flow_menus/BuildSelectWidget.tcl

gui_create_menu -menu "R2G Menu->DesignSummary" \
  -anchor_item "Help" \
  -anchor_offset -1 \
  -window_type $window_type \
  -help_string {Create DesignSummary report} \
  -tcl_cmd "BuildSelectWidget::newWidget DesignSummary 0"

gui_create_menu -menu "R2G Menu->ResourceSummary" \
  -window_type $window_type \
  -help_string {Create ResourceSummary report} \
  -tcl_cmd "BuildSelectWidget::newWidget ResourceSummary 0"

gui_create_menu -menu "R2G Menu->ClockTreeSummary" \
  -window_type $window_type \
  -help_string {Create ClockTreeSummary report} \
  -tcl_cmd "BuildSelectWidget::newWidget ClockTreeSummary 1"

gui_create_menu -menu "R2G Menu->ToolLicenseSummary" \
  -window_type $window_type \
  -help_string {Create ToolLicenseSummary report} \
  -tcl_cmd "BuildSelectWidget::newWidget ToolLicenseSummary 0"

gui_create_menu -menu "R2G Menu->foo" -window_type $window_type -separator

gui_create_menu -menu "R2G Menu->TimingMatrix" \
  -window_type $window_type \
  -help_string {Create TimingMatrix report} \
  -tcl_cmd "BuildSelectWidget::newWidget TimingMatrix 1"

gui_create_menu -menu "R2G Menu->PowerMatrix" \
  -window_type $window_type \
  -help_string {Create PowerMatrix report} \
  -tcl_cmd "BuildSelectWidget::newWidget PowerMatrix 1"

gui_create_menu -menu "R2G Menu->ClockTreeMatrix" \
  -window_type $window_type \
  -help_string {Create ClockTreeMatrix report} \
  -tcl_cmd "BuildSelectWidget::newWidget ClockTreeMatrix 1"

gui_create_menu -menu "R2G Menu->ScenarioTrend" \
  -window_type $window_type \
  -help_string {Create ScenarioTrend report} \
  -tcl_cmd "BuildSelectWidget::newWidget ScenarioTrend 0"

gui_create_menu -menu "R2G Menu->foo" -window_type $window_type -separator

gui_create_menu -menu "R2G Menu->DesignSummaryComparison" \
  -window_type $window_type \
  -help_string {Create DesignSummaryComparison report} \
  -tcl_cmd "BuildSelectWidget::newWidget DesignSummaryComparison 0"
  
gui_create_menu -menu "R2G Menu->ResourceSummaryComparison" \
  -window_type $window_type \
  -help_string {Create ResourceSummaryComparison report} \
  -tcl_cmd "BuildSelectWidget::newWidget ResourceSummaryComparison 0"
  
## gui_create_menu -menu "R2G Menu->foo" -window_type $window_type -separator
## gui_create_menu -menu "R2G Menu->Status" \
##   -window_type $window_type \
##   -help_string {Create Status report} \
##   -tcl_cmd "BuildSelectWidget::newWidget Status 0"

set regHtml /global/lynx_home/PUBLISH/Lynx/users/lynxreg/check_top.html

if { [file exists $regHtml] } {
  gui_create_menu -menu "R2G Menu->regFoo1" -window_type $window_type -separator
  gui_create_menu -menu "R2G Menu->Regressions" \
    -window_type $window_type \
    -help_string {Regression Results} \
    -tcl_cmd "open_report -format html -file $regHtml -name Regressions"
}

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
