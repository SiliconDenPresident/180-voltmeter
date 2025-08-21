## Below are app options set by the "set_qor_strategy -stage pnr -metric {area timing total_power congestion}" command.
#  If you need to adjust any of them, you can use this script as a template and uncomment the settings you want to modify.
#  App options settings for target metric(s) = area, congestion, timing, total_power

#################################
# App options for *All metrics* 
#################################

## Tool auto creates 3 IO path groups : in2reg_default, reg2out_default, and in2out_default
#	set_app_options -name time.enable_io_path_groups -value true

## clock-to-data analysis
#	set_app_options -name time.enable_clock_to_data_analysis -value true

## To ensure no Verilog assigns in the output netlist
#	set_app_options -name opt.port.eliminate_verilog_assign -value true

## Timing-driven global route
#	set_app_options -name route.global.timing_driven -value true

## CRPR
#	set_app_options -name time.remove_clock_reconvergence_pessimism -value true

## Enable on-disk operation for copy_block to save block to disk right away
#  Note: Not persistent. RM sets it in icc2_pnr_setup.tcl in every session.
#	set_app_options -name design.on_disk_operation -value true 

## Timing-driven track assignment
#	set_app_options -name route.track.timing_driven -value true

## Timing-driven detail route
#	set_app_options -name route.detail.timing_driven -value true

## Crosstalk driven
#	set_app_options -name route.track.crosstalk_driven -value true

## Enables crosstalk analysis during timing analysis. 
#  Not effective in preroute.
#	set_app_options -name time.si_enable_analysis -value true

## ECO route iterations 
#  route_opt default is 5. The following adds more S&R for each iteration of eco route in route_opt. 
#  This is useful for better DRC reduction and less calls to router
#	set_app_options -name route.detail.eco_max_number_of_iterations -value 10

#################################
# App options for Area 
#################################

## CCD route_opt buffer removal
#	set_app_options -name ccd.post_route_buffer_removal -value true

## Area recovery effort for preroute optimization 
#  Note that TNS degradation can occur when set to higher levels
#	set_app_options -name opt.area.effort -value high

## Buffer area reduction effort for preroute optimization
#  Note that QoR degradation can occur when set to higher levels
#	set_app_options -name opt.common.buffer_area_effort -value ultra

## GRLB - GR-based layer binning for preroute flows (set_qor_strategy default: >=20nm is true; <=16nm is false)
#  GR layer aware optimization during preroute to mitigate pre and post-route mis-correlation.
#  If enabled, remove_route_aware_estimation will be triggered before the route_auto command
#	set_app_options -name opt.common.use_route_aware_estimation -value xxx

#################################
# App options for Congestion 
#################################

## Detour detection during coarse placement
#	set_app_options -name place.coarse.detect_detours -value true

## Channel detect mode in coarse placement
#	set_app_options -name place.coarse.channel_detect_mode -value true

## GR-based HFS DRC 
#  Run global route based buffering during HFS/DRC fixing. Global routes are deleted after buffering. 
#  This is especially useful for fragmented and narrow-channelled floorplans.
#	set_app_options -name place_opt.initial_drc.global_route_based -value 1

## Final coarse placement effort level
#	set_app_options -name place_opt.final_place.effort -value high

## Effort level for congestion alleviation in place_opt
#  Expect a significant increase in run time at high effort
#	set_app_options -name place_opt.place.congestion_effort -value high

## Orientation optimization (enabled for designs with nodes <= 16nm)
#  Legalizer will consider flipping the orientations of cells in order to reduce displacements during legalization.
#	set_app_options -name place.legalize.optimize_orientations -value true

#################################
# App options for Timing 
#################################

## Timing optimization effort in preroute flows for better timing
#  Makes tool spend more efforts on timing optimization
#	set_app_options -name opt.timing.effort -value high

#  Enables concurrent clock and data optimization (CCD) during clock_opt
#  Note1: CCD by default enables local skew CTS/CTO under the hood.
#  Note2: CCD by default also enables the clock SI prevention feature in CTS
#  in order to minimize the impact of SI from/on clock nets at postroute.
#	set_app_options -name clock_opt.flow.enable_ccd -value true

#################################
# App options for Total_power 
#################################

## Power optimization mode
#	set_app_options -name opt.power.mode -value total

## Power optimization effort level
#	set_app_options -name opt.power.effort -value high

## Power optimization in route_opt
#  Note: Not persistent. RM sets it in route_auto.tcl & settings.route_opt.tcl
#	set_app_options -name route_opt.flow.enable_power -value true

## ECO route iterations 
#  route_opt default is 5. The following adds more S&R for each iteration of eco route in route_opt. 
#  This is useful at 20nm and below for better DRC reduction and less calls to router 
#	set_app_options -name route.detail.eco_max_number_of_iterations -value 10

