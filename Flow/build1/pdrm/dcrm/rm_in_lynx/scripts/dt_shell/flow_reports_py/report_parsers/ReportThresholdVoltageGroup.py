## -----------------------------------------------------------------------------
## HEADER_MSG  Lynx Design System: Baseline Flow
## HEADER_MSG  Version 2019.03-SP2
## HEADER_MSG  Copyright (c) 2019 Synopsys
## HEADER_MSG  Perforce Label: lynx_flow_2019.03-SP2
## -----------------------------------------------------------------------------

import os
import re
from report_parsers.ReportBase import ReportBase

class ReportThresholdVoltageGroup(ReportBase):

    def __init__(self):
      super().__init__()

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

        self._rval['vth,vth_names'] = []

        ## -------------------------------------
        ## Parse lines for dc_shell/icc2_shell
        ## -------------------------------------

        line_number = 0
        for line in lines:
            line_number += 1

            match = re.match('^Total', line)
            if match:
                break

            ## stdcell_hvt 33747.84000 (68.76%) 0.00000 (0.00%) 33747.84000 (68.76%)

            match = re.match('^(\S+)\s+(\S+)\s+\(\s*(\S+)\%\)\s+(\S+)\s+\(\s*(\S+)\%\)\s+(\S+)\s+\(\s*(\S+)\%\).*', line)
            if match:
                vth_name    = match.group(1)
                vth_count   = match.group(2)
                vth_percent = match.group(3)

                if vth_name not in self._rval['vth,vth_names']:
                    self._rval['vth,vth_names'].append(vth_name)

                self._rval[f'cell_count,{vth_name}'] = vth_count
                self._rval[f'cell_percentage,{vth_name}'] = vth_percent
                self._rval[f'cell_count,{vth_name},line_number'] = line_number
                self._rval[f'cell_percentage,{vth_name},line_number'] = line_number


## -----------------------------------------------------------------------------
## End of File
## -----------------------------------------------------------------------------
