
DESIGN=counter

synth: results/$(DESIGN).mapped.v
results/$(DESIGN).mapped.v:
	date +%s > synth.begin
	dc_shell -topographical_mode -f rm_dc_scripts/dc.tcl |& tee dc.log
	date +%s > synth


gui:
	dc_shell -topographical_mode -gui -f rm_dc_scripts/dc_interactive.tcl

clean:
	-rm -rf WORK
	-rm -rf *_LIB
	-rm -rf reports
	-rm -rf results
	-rm *.log
	-rm *.svf
	-rm synth synth.begin

