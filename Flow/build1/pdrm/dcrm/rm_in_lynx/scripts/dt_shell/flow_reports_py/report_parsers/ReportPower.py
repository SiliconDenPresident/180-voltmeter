## -----------------------------------------------------------------------------
## HEADER_MSG  Lynx Design System: Baseline Flow
## HEADER_MSG  Version 2019.03-SP2
## HEADER_MSG  Copyright (c) 2019 Synopsys
## HEADER_MSG  Perforce Label: lynx_flow_2019.03-SP2
## -----------------------------------------------------------------------------

import os
import re
from report_parsers.ReportBase import ReportBase

class ReportPower(ReportBase):

    def __init__(self):
      super().__init__()
      self._scenario_dict = {}
      self._scenario_name = 'None/non-MCMM'

    def set_scenario_name(self, name):
        self._scenario_name = name;

    def get_scenario_name(self):
        return self._scenario_name

    def parse(self):

        ## Read lines to be parsed
        try:
            f = open(self._file, 'r')
        except IOError:
            lines = []
            print(f'Error: Unable to read file: {self._file}')
        else:
            lines = f.readlines()
            f.close()

        ## -------------------------------------
        ## Init return data
        ## -------------------------------------

        self._rval['scenario_name_list'] = []

        scenario_name = self._scenario_name

        ## -------------------------------------
        ## Parse lines for dc_shell/icc2_shell
        ## -------------------------------------

        if self.get_synopsys_program_name() == 'dc_shell' or self.get_synopsys_program_name() == 'icc2_shell' or self.get_synopsys_program_name() == 'other_shell':

            line_number = 0
            for line in lines:
                line_number += 1

                match = re.match('^Scenario(\(s\))?:\s+(\S+)', line)
                if match:
                    scenario_name = match.group(2)

                if re.match('^Total', line) and not re.match('.*Power', line):
                    if scenario_name not in self._rval['scenario_name_list']:
                        self._rval['scenario_name_list'].append(scenario_name)

                    fields = line.split()

                    self._rval[f'{scenario_name},internal_power']        = fields[1]
                    self._rval[f'{scenario_name},internal_power_units']  = fields[2]
                    self._rval[f'{scenario_name},switching_power']       = fields[3]
                    self._rval[f'{scenario_name},switching_power_units'] = fields[4]
                    self._rval[f'{scenario_name},leakage_power']         = fields[5]
                    self._rval[f'{scenario_name},leakage_power_units']   = fields[6]
                    self._rval[f'{scenario_name},total_power']           = fields[7]
                    self._rval[f'{scenario_name},total_power_units']     = fields[8]

                    self._rval[f'{scenario_name},internal_power,line_number']        = line_number
                    self._rval[f'{scenario_name},internal_power_units,line_number']  = line_number
                    self._rval[f'{scenario_name},switching_power,line_number']       = line_number
                    self._rval[f'{scenario_name},switching_power_units,line_number'] = line_number
                    self._rval[f'{scenario_name},leakage_power,line_number']         = line_number
                    self._rval[f'{scenario_name},leakage_power_units,line_number']   = line_number
                    self._rval[f'{scenario_name},total_power,line_number']           = line_number
                    self._rval[f'{scenario_name},total_power_units,line_number']     = line_number

        ## -------------------------------------
        ## Parse lines for dc_shell/icc2_shell
        ## -------------------------------------

        if self.get_synopsys_program_name() == 'pt_shell':

            line_number = 0
            for line in lines:
                line_number += 1

                match = re.match('^LYNX_SCENARIO:\s+(\S+)', line)
                if match:
                    scenario_name = match.group(1)

                match = re.match('^\s*Cell Internal Power\s+=\s+(\S+)', line)
                if match:
                    self._rval[f'{scenario_name},internal_power'] = match.group(1)
                    self._rval[f'{scenario_name},internal_power_units'] = 'W'
                    self._rval[f'{scenario_name},internal_power,line_number'] = line_number
                    self._rval[f'{scenario_name},internal_power_units,line_number'] = 1

                match = re.match('^\s*Net Switching Power\s+=\s+(\S+)', line)
                if match:
                    self._rval[f'{scenario_name},switching_power'] = match.group(1)
                    self._rval[f'{scenario_name},switching_power_units'] = 'W'
                    self._rval[f'{scenario_name},switching_power,line_number'] = line_number
                    self._rval[f'{scenario_name},switching_power_units,line_number'] = 1

                match = re.match('^\s*Cell Leakage Power\s+=\s+(\S+)', line)
                if match:
                    self._rval[f'{scenario_name},leakage_power'] = match.group(1)
                    self._rval[f'{scenario_name},leakage_power_units'] = 'W'
                    self._rval[f'{scenario_name},leakage_power,line_number'] = line_number
                    self._rval[f'{scenario_name},leakage_power_units,line_number']   = 1

                match = re.match('^Total Power\s+=\s+(\S+)', line)
                if match:
                    self._rval[f'{scenario_name},total_power'] = match.group(1)
                    self._rval[f'{scenario_name},total_power_units'] = 'W'
                    self._rval[f'{scenario_name},total_power,line_number'] = line_number
                    self._rval[f'{scenario_name},total_power_units,line_number']     = 1

                    if scenario_name not in self._rval['scenario_name_list']:
                        self._rval['scenario_name_list'].append(scenario_name)

        ## -------------------------------------
        ## Sort scenarios
        ## -------------------------------------
        self._rval['scenario_name_list'] = sorted(self._rval['scenario_name_list'])


## -----------------------------------------------------------------------------
## End of File
## -----------------------------------------------------------------------------
