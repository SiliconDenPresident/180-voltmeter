DESIGN = counter

PNR_TARGETS = all setup init_design place_opt clock_opt_cts clock_opt_opto route_auto route_opt chip_finish icv_in_design

$(PNR_TARGETS):
	$(MAKE) -f rm_setup/Makefile_pnr $@

dp:
	$(MAKE) -f rm_setup/Makefile_dp_flat all

gui:
	icc2_shell -gui

clean:
	-rm *.log
	-rm *.ems
	-rm icc2_output.txt
	-rm setup init_design place_opt clock_opt_cts clock_opt_opto route_auto route_opt chip_finish icv_in_design write_data all redhawk_in_design_pnr pt_eco pt_eco_incremental_1 pt_eco_incremental_2 fm vc_lp summary
	-rm *.begin
	-rm hostname loadavg
	-rm clock_auto_exceptions*
	-rm -rf legalizer_debug_plots/
	-rm -rf logs_icc2
	-rm -rf rpts_icc2
	-rm -rf $(DESIGN)
	-rm create_power init_dp place_io place_pins placement pre_shaping pre_timing shaping timing_estimation
	-rm -rf work
	-rm -rf work_dir
	-rm -rf write_data_dir
	-rm -rf default-*.svf
