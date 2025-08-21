import re, sys

design=sys.argv[1]
clk_per=sys.argv[2]
util=sys.argv[3]
max_lyr=sys.argv[4]
max_trans=sys.argv[5]
clk_uncert=sys.argv[6]



src=open(f'template/{design}.constraints.tcl')
dest=open(f'src/rtl/{design}/{design}.constraints.tcl','w')
for line in src:
  m=re.search(r'set CLK_PER',line)
  if m:
    dest.write('set CLK_PER '+clk_per+'\n')
  else:
    dest.write(line)
src.close()
dest.close()

src=open('template/floorplan.tcl')
dest=open('icc2rm/rm_setup/floorplan.tcl','w')
for line in src:
  m=re.search(r'^set CORE_UTILIZATION',line)
  if m:
    dest.write('set CORE_UTILIZATION '+util+'\n')
  else:
    dest.write(line)
src.close()
dest.close()

src=open('template/icc2_common_setup.tcl')
dest=open('icc2rm/rm_setup/icc2_common_setup.tcl','w')
for line in src:
  m=re.search(r'^set MAX_ROUTING_LAYER',line)
  if m:
    dest.write('set MAX_ROUTING_LAYER "'+max_lyr+'" ;\n')
  else:
    dest.write(line)
src.close()
dest.close()

src=open('template/settings.place_opt.tcl')
dest=open('icc2rm/rm_icc2_pnr_scripts/settings.place_opt.tcl','w')
for line in src:
  m=re.search(r'^  set_max_transition',line)
  if m:
    dest.write('  set_max_transition -clock_path '+max_trans+' [get_clocks -mode $m] -scenarios [get_scenarios -mode $m]\n')
  else:
    dest.write(line)
src.close()
dest.close()

src=open('template/clock_opt_cts.tcl')
dest=open('icc2rm/rm_icc2_pnr_scripts/clock_opt_cts.tcl','w')
for line in src:
  m=re.search(r'^\s+set_clock_uncertainty -hold',line)
  if m:
    dest.write('    set_clock_uncertainty -hold '+clk_uncert+' -from [get_clocks -mode $mode] -to [get_clocks -mode $mode] -scenarios [get_scenarios -of $mode]\n')
  else:
    dest.write(line)
src.close()
dest.close()

