## -----------------------------------------------------------------------------
## HEADER_MSG  Lynx Design System: Baseline Flow
## HEADER_MSG  Version 2019.03-SP2
## HEADER_MSG  Copyright (c) 2019 Synopsys
## HEADER_MSG  Perforce Label: lynx_flow_2019.03-SP2
## -----------------------------------------------------------------------------

import os
import re
from report_parsers.ReportBase import ReportBase

class ReportAppOptions(ReportBase):

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
        ## Parse lines
        ## -------------------------------------

        self._rval['app_option_list'] = []

        inside_app_option_section = False

        line_number = 0
        for line in lines:
            line_number += 1

            match = re.match('^\-\-\-\-\-\-\-\-', line)
            if match:
                inside_app_option_section = False
                inside_app_option_section = not inside_app_option_section
                continue

            match = re.match('^(\S+)\s+\S+\s+(\S+)', line)
            if match:
                app_option = match.group(1)
                app_value  = match.group(2)
                if app_option not in self._rval['app_option_list']:
                    self._rval['app_option_list'].append(app_option)
                self._rval[app_option] = app_option


## -----------------------------------------------------------------------------
## End of File
## -----------------------------------------------------------------------------
