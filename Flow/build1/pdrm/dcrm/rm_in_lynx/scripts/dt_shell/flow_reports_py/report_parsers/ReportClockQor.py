# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
import re
from report_parsers.ReportBase import ReportBase


class ReportClockQor(ReportBase):
    def __init__(self):
        super().__init__()


    def parse(self):
        self._rval["clock_list"] = []
        # Do not put scenario_list in dict yet.  Stricrly mimic tcl code by putting it at end

        # Read lines to be parsed
        try:
            f = open(self._file, 'r')
        except IOError:
            lines = []
            print(f'Error: Unable to read file: {self._file}')
        else:
            lines = f.readlines()
            f.close()

        # will need to fill self._metric_dict["scenario_list"] and ["clock_list"]
        current_scenario = ''
        # current_mode = ''
        clock_list = []
        scenario_list = []

        line_number = 0
        for line in lines:
            line_number += 1
            match = re.match("^### Mode: (\S+), Scenario: (\S+)", line)
            if match:
                # current_mode = match.group(1)
                current_scenario = match.group(2)
                scenario_list.append(current_scenario)
                continue
            match = re.match("^--------", line)  # scenario begin
            if match:
                current_scenario = ''
            if current_scenario != '':
                match = re.match("^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*$", line)
                if match:
                    clock                = match.group(1)
                    # attrs              = match.group(2)
                    sinks                = match.group(3)
                    levels               = match.group(4)
                    clock_repeater_count = match.group(5)
                    clock_repeater_area  = match.group(6)
                    clock_stdcell_area   = match.group(7)
                    max_latency          = match.group(8)
                    global_skew          = match.group(9)
                    trans_drc_count      = match.group(10)
                    cap_drc_count        = match.group(11)
                    clock_list.append(clock)
                    # now stuff all this into a series of generated keys
                    kee = f'{current_scenario},{clock},Cap_DRC_Count,line'
                    self._rval[kee] = line_number
                    kee = f'{current_scenario},{clock},Cap_DRC_Count,value'
                    self._rval[kee] = cap_drc_count
                    kee = f'{current_scenario},{clock},Clock_Repeater_Area,line'
                    self._rval[kee] = line_number
                    kee = f'{current_scenario},{clock},Clock_Repeater_Area,value'
                    self._rval[kee] = clock_repeater_area
                    kee = f'{current_scenario},{clock},Clock_Repeater_Count,line'
                    self._rval[kee] = line_number
                    kee = f'{current_scenario},{clock},Clock_Repeater_Count,value'
                    self._rval[kee] = clock_repeater_count
                    kee = f'{current_scenario},{clock},Clock_Stdcell_Area,line'
                    self._rval[kee] = line_number
                    kee = f'{current_scenario},{clock},Clock_Stdcell_Area,value'
                    self._rval[kee] = clock_stdcell_area
                    kee = f'{current_scenario},{clock},Global_Skew,line'
                    self._rval[kee] = line_number
                    kee = f'{current_scenario},{clock},Global_Skew,value'
                    self._rval[kee] = global_skew
                    kee = f'{current_scenario},{clock},Levels,line'
                    self._rval[kee] = line_number
                    kee = f'{current_scenario},{clock},Levels,value'
                    self._rval[kee] = levels
                    kee = f'{current_scenario},{clock},Max_Latency,line'
                    self._rval[kee] = line_number
                    kee = f'{current_scenario},{clock},Max_Latency,value'
                    self._rval[kee] = max_latency
                    kee = f'{current_scenario},{clock},Sinks,line'
                    self._rval[kee] = line_number
                    kee = f'{current_scenario},{clock},Sinks,value'
                    self._rval[kee] = sinks
                    kee = f'{current_scenario},{clock},Trans_DRC_Count,line'
                    self._rval[kee] = line_number
                    kee = f'{current_scenario},{clock},Trans_DRC_Count,value'
                    self._rval[kee] = trans_drc_count

        # Clean up the lists and put them in the metrics payload
        clock_list = list(set(clock_list))
        clock_list.sort()
        scenario_list = list(set(scenario_list))
        scenario_list.sort()
        self._rval['clock_list'] = clock_list
        self._rval['scenario_list'] = scenario_list
