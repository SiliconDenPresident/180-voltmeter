## -----------------------------------------------------------------------------
## HEADER_MSG  Lynx Design System: Baseline Flow
## HEADER_MSG  Version 2019.03-SP2
## HEADER_MSG  Copyright (c) 2019 Synopsys
## HEADER_MSG  Perforce Label: lynx_flow_2019.03-SP2
## -----------------------------------------------------------------------------
import os
import re
from report_parsers.ReportBase import ReportBase

class ReportDesignPhysical(ReportBase):

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

        num_drc_errors_types = -1
        capture_error_types = False

        line_number = 0
        for line in lines:
            line_number += 1
            match = re.match("^Cell/Core Ratio\s+:\s+([\d\.]+)\%", line)
            if match:
                self._rval["cell2core_ratio"] = match.group(1)
                self._rval["cell2core_ratio,line_number"] = line_number

            match = re.match("^Chip\s+([\d\.]+)\s+([\d\.]+)\s+([\d\.]+)", line)
            if match:
                self._rval["chip_width"] = match.group(1)
                self._rval["chip_height"] = match.group(2)
                self._rval["chip_area"] = match.group(3)
                self._rval["chip_width,line_number"] = line_number
                self._rval["chip_height,line_number"] = line_number
                self._rval["chip_area,line_number"] = line_number

            match = re.match("^DRC information:\s*$", line)
            if match:
                num_drc_errors_types = 0
                capture_error_types = True
                continue

            if capture_error_types == True:
                match = re.match("^\s+Total error number:\s+([\d\.]+)", line)
                if match:
                    self._rval["num_drc_errors"] = match.group(1)
                    self._rval["num_drc_errors_types"] = num_drc_errors_types
                    self._rval["num_drc_errors,line_number"] = line_number
                    self._rval["num_drc_errors_types,line_number"] = line_number
                    capture_error_types = False
                    continue
            else:
                num_drc_errors_types += 1
