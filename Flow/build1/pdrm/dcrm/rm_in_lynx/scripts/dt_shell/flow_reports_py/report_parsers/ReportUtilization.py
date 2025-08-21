## -----------------------------------------------------------------------------
## HEADER_MSG  Lynx Design System: Baseline Flow
## HEADER_MSG  Version 2019.03-SP2
## HEADER_MSG  Copyright (c) 2019 Synopsys
## HEADER_MSG  Perforce Label: lynx_flow_2019.03-SP2
## -----------------------------------------------------------------------------

import os
import re
from report_parsers.ReportBase import ReportBase

class ReportUtilization(ReportBase):

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

        self._rval['cell2core_ratio'] = -1
        self._rval['chip_area']       = -1

        self._rval['cell2core_ratio,line_number'] = 1
        self._rval['chip_area,line_number']       = 1

        ## -------------------------------------
        ## Parse lines for dc_shell/icc2_shell
        ## -------------------------------------

        count_error_types = 0
        line_is_error_type = False

        line_number = 0
        for line in lines:
            line_number += 1

            match = re.match('^Utilization Ratio:\s+([\d\.]+)', line)
            if match:
                self._rval['cell2core_ratio'] = match.group(1)
                self._rval['cell2core_ratio,line_number'] = line_number

            match = re.match('^Total Area:\s+([\d\.]+)', line)
            if match:
                self._rval['chip_area'] = match.group(1)
                self._rval['chip_area,line_number'] = line_number


## -----------------------------------------------------------------------------
## End of File
## -----------------------------------------------------------------------------
