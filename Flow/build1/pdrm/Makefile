
.PHONY: synth report

DESIGN=digital_top

CLK_PER=5
UTIL=0.5
MAXLYR=met5
MAXTRANS=0.5
CLKUNCERT=0.1

report: pnr
	python3 parse_reports.py $(CLK_PER) $(UTIL) $(MAXLYR) $(MAXTRANS) $(CLKUNCERT)

pnr: synth
	cd icc2rm && $(MAKE) DESIGN=$(DESIGN) clean
	python3 set_constraints.py $(DESIGN) $(CLK_PER) $(UTIL) $(MAXLYR) $(MAXTRANS) $(CLKUNCERT)
	$(MAKE) -C icc2rm chip_finish

synth:
	cd dcrm && $(MAKE) DESIGN=$(DESIGN) clean
	python3 set_constraints.py $(DESIGN) $(CLK_PER) $(UTIL) $(MAXLYR) $(MAXTRANS) $(CLKUNCERT)
	$(MAKE) -C dcrm

setup:
	echo synth__sched__date__begin,synth__sched__date__end,init_design__sched__date__begin,init_design__sched__date__end,place_opt__sched__date__begin,place_opt__sched__date__end,clock_opt_cts__sched__date__begin,clock_opt_cts__sched__date__end,clock_opt_opto__sched__date__begin,clock_opt_opto__sched__date__end,route_auto__sched__date__begin,route_auto__sched__date__end,route_opt__sched__date__begin,route_opt__sched__date__end,route_opt__sched__host__id,route_opt__sched__loadavg__end,synth__timing__clk_per__set,init_design__area__util__set,init_design__area__max_layer__set,place_opt__timing__clk_trans__set,clock_opt_cts__timing__hold_uncert__set,route_opt__timing__whs__worst,route_opt__timing__tnhs__tot,route_opt__timing__nhve__tot,route_opt__timing__ntv__tot,route_opt__timing__critpath__max,route_opt__timing__clk_trans__max,route_opt__area__cell__tot,route_opt__area__util__avg,route_opt__drc__viol__tot,route_opt__area__wirelength__tot > results.csv


clean:
	cd dcrm && $(MAKE) DESIGN=$(DESIGN) clean
	cd icc2rm && $(MAKE) clean

