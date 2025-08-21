import re, os, sys

clk_per=sys.argv[1]
init_util=sys.argv[2]
max_layer=sys.argv[3]
max_trans=sys.argv[4]
hold_uncert=sys.argv[5]

results=open('results.csv','a')

# synth__sched__date__begin
results.write(open('dcrm/synth.begin').readlines()[0].strip()+',')
# synth__sched__date__end
results.write(open('dcrm/synth').readlines()[0].strip()+',')
# init_design__sched__date__begin
results.write(open('icc2rm/init_design.begin').readlines()[0].strip()+',')
# init_design__sched__date__end
results.write(open('icc2rm/init_design').readlines()[0].strip()+',')
# place_opt__sched__date__begin
results.write(open('icc2rm/place_opt.begin').readlines()[0].strip()+',')
# place_opt__sched__date__end
results.write(open('icc2rm/place_opt').readlines()[0].strip()+',')
# clock_opt_cts__sched__date__begin
results.write(open('icc2rm/clock_opt_cts.begin').readlines()[0].strip()+',')
# clock_opt_cts__sched__date__end
results.write(open('icc2rm/clock_opt_cts').readlines()[0].strip()+',')
# clock_opt_opto__sched__date__begin
results.write(open('icc2rm/clock_opt_opto.begin').readlines()[0].strip()+',')
# clock_opt_opto__sched__date__end
results.write(open('icc2rm/clock_opt_opto').readlines()[0].strip()+',')
# route_auto__sched__date__begin
results.write(open('icc2rm/route_auto.begin').readlines()[0].strip()+',')
# route_auto__sched__date__end
results.write(open('icc2rm/route_auto').readlines()[0].strip()+',')
# route_opt__sched__date__begin
results.write(open('icc2rm/route_opt.begin').readlines()[0].strip()+',')
# route_opt__sched__date__end
results.write(open('icc2rm/route_opt').readlines()[0].strip()+',')
# route_opt__sched__host__id
results.write(open('icc2rm/hostname').readlines()[0].strip()+',')
# route_opt__sched__loadavg__end
results.write(open('icc2rm/loadavg').readlines()[0].split()[2]+',')
# synth__timing__clk_per__set
results.write(clk_per+',')
# init_design__area__util__set
results.write(init_util+',')
# init_design__area__max_layer__set
results.write(max_layer+',')
# place_opt__timing__clk_trans__set
results.write(max_trans+',')
# clock_opt_cts__timing__hold_uncert__set
results.write(hold_uncert+',')

scenario=None
group=None
f=open('icc2rm/rpts_icc2/route_opt.report_timing.min')
for line in f:
  m=re.search(r"^\s*Scenario:\s+(\S+)",line)
  if m:
    scenario=m.group(1)
    continue
  m=re.search(r"^\s*Path Group:\s+(\S+)",line)
  if m:
    group=m.group(1)
    continue
  m=re.search(r'^\s*slack\s+\([A-Z]+\)\s+([-+0-9\.]+)',line)
  if m:
    if scenario=='mode_norm.fast.RCmin_bc' and group=='clock':
      whs=m.group(1)
      break
f.close()

# route_opt__timing__whs__worst
results.write(whs+',')

scenario=None
group=None
f=open('icc2rm/rpts_icc2/route_opt.report_qor')
for line in f:
  m=re.search(r"^Scenario\s+'(\S+)'",line)
  if m:
    scenario=m.group(1)
    continue
  m=re.search(r"^Timing Path Group\s+'(\S+)'",line)
  if m:
    group=m.group(1)
    continue
  m=re.search(r"^Critical Path Length:\s+([0-9\.\-]+)",line)
  if m:
    if scenario=='mode_norm.slow.RCmax' and group=='clock':
      crit_path_len=m.group(1)
    continue
  m=re.search(r"^Total Hold Violation:\s+([0-9\.\-]+)",line)
  if m:
    if scenario=='mode_norm.fast.RCmin_bc' and group=='clock':
      tnhs=m.group(1)
    continue
  m=re.search(r"^No. of Hold Violations:\s+([0-9]+)",line)
  if m:
    if scenario=='mode_norm.fast.RCmin_bc' and group=='clock':
      nhve=m.group(1)
    continue
  m=re.search(r'Max Trans Violations:\s+(\d+)',line)
  if m:
    ntv=m.group(1)
    break
f.close()

# route_opt__timing__tnhs__tot
results.write(tnhs+',')
# route_opt__timing__nhve__tot
results.write(nhve+',')
# route_opt__timing__ntv__tot
results.write(ntv+',')
# route_opt__timing__critpath__max
results.write(crit_path_len+',')

mode=None
route_opt_max_trans=None
f=open('icc2rm/rpts_icc2/route_opt.report_clock_timing')
for line in f:
  m=re.search(r'Mode: (\S+)',line)
  if m:
    mode=m.group(1)
  m=re.search(r'Maximum active transition',line)
  if m:
    line=f.readline()
    m=re.search(r'^\s*\S+\s+([0-9\.]+)',line)
    if m:
      if mode=='mode_norm.fast.RCmin_bc':
        max_trans=m.group(1)
      continue
f.close()

# route_opt__timing__clk_trans__max
results.write(max_trans+',')

f=open('icc2rm/rpts_icc2/route_opt.report_utilization')
for line in f:
  m=re.search(r'^Utilization Ratio:\s+([0-9\.]+)',line)
  if m:
    util=m.group(1)
    continue
  m=re.search(r'^Total Area of cells:\s+([0-9\.]+)',line)
  if m:
    cell_area=m.group(1)
    break
f.close()

# route_opt__area__cell__tot
results.write(cell_area+',')
# route_opt__area__util__avg
results.write(util+',')

route_opt_bnd_viol=0
f=open('icc2rm/rpts_icc2/route_opt.check_routes')
for line in f:
  m=re.search(r'TOTAL VIOLATIONS =\s+(\d+)',line)
  if m:
    viol=m.group(1)
    continue
  m=re.search(r'Total Routed Wire Length =\s+(\d+)',line)
  if m:
    wire_len=m.group(1)
    break
f.close()

# route_opt__drc__viol__tot
results.write(viol+',')
# route_opt__area__wirelength__tot
results.write(wire_len+'\n')


results.close()

