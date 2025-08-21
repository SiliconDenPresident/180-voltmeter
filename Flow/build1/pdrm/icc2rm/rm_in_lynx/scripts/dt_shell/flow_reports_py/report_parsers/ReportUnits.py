## -----------------------------------------------------------------------------
## HEADER_MSG  Lynx Design System: Baseline Flow
## HEADER_MSG  Version 2019.03-SP2
## HEADER_MSG  Copyright (c) 2019 Synopsys
## HEADER_MSG  Perforce Label: lynx_flow_2019.03-SP2
## -----------------------------------------------------------------------------

import os
import re
from report_parsers.ReportBase import ReportBase

class ReportUnits(ReportBase):

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
        ## Parse lines for unit info
        ## -------------------------------------

        self._rval['Time_unit']            = None
        self._rval['Capacitive_load_unit'] = None
        self._rval['Resistance_unit']      = None
        self._rval['Current_unit']         = None
        self._rval['Voltage_unit']         = None
        self._rval['Internal_power_unit']  = None
        self._rval['Leakage_power_unit']   = None

        line_number = 0
        for line in lines:
            line_number += 1

            match = re.match('^Time_unit\s+:\s+(\S+)', line)
            if match:
                value = match.group(1)
                value = re.sub('1\.0e', '1e', value)
                if   value == '1e-00':
                    self._rval['Time_unit'] = 's'
                elif value == '1e-03':
                    self._rval['Time_unit'] = 'ms'
                elif value == '1e-06':
                    self._rval['Time_unit'] = 'us'
                elif value == '1e-09':
                    self._rval['Time_unit'] = 'ns'
                elif value == '1e-12':
                    self._rval['Time_unit'] = 'ps'
                elif value == '1e-15':
                    self._rval['Time_unit'] = 'fs'
                else:
                    print(f'Error: Unrecognized value (Time_unit): {value}')

            match = re.match('^Capacitive_load_unit\s+:\s+(\S+)', line)
            if match:
                value = match.group(1)
                value = re.sub('1\.0e', '1e', value)
                if value == '1e-09':
                    self._rval['Capacitive_load_unit'] = 'nF'
                elif value == '1e-12':
                    self._rval['Capacitive_load_unit'] = 'pF'
                elif value == '1e-15':
                    self._rval['Capacitive_load_unit'] = 'fF'
                else:
                    print(f'Error: Unrecognized value (Capacitive_load_unit): {value}')

            match = re.match('^Resistance_unit\s+:\s+(\S+)', line)
            if match:
                value = match.group(1)
                if   value == '1000':
                    self._rval['Resistance_unit'] = 'KOhm'
                else:
                    print(f'Error: Unrecognized value (Resistance_unit): {value}')

            match = re.match('^Current_unit\s+:\s+(\S+)', line)
            if match:
                value = match.group(1)
                value = re.sub('1\.0e', '1e', value)
                if   value == '0.001':
                    self._rval['Current_unit'] = 'mA'
                elif value == '1e-03':
                    self._rval['Current_unit'] = 'mA'
                else:
                    print(f'Error: Unrecognized value (Current_unit): {value}')

            match = re.match('^Voltage_unit\s+:\s+(\S+)', line)
            if match:
                value = match.group(1)
                if   value == '1':
                    self._rval['Voltage_unit'] = 'V'
                else:
                    print(f'Error: Unrecognized value (Voltage_unit): {value}')

            match = re.match('^Internal_power_unit\s+:\s+(\S+)', line)
            if match:
                value = match.group(1)
                if   value == '0.001':
                    self._rval['Internal_power_unit'] = 'mW'
                else:
                    print(f'Error: Unrecognized value (Internal_power_unit): {value}')

            match = re.match('^Leakage_power_unit\s+:\s+(\S+)', line)
            if match:
                value = match.group(1)
                if   value == '1e-03':
                    self._rval['Leakage_power_unit'] = 'mW'
                elif value == '1e-06':
                    self._rval['Leakage_power_unit'] = 'uW'
                elif value == '1e-09':
                    self._rval['Leakage_power_unit'] = 'nW'
                else:
                    print(f'Error: Unrecognized value (Leakage_power_unit): {value}')


## -----------------------------------------------------------------------------
## End of File
## -----------------------------------------------------------------------------
