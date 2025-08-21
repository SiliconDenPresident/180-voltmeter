## -----------------------------------------------------------------------------
## HEADER_MSG  Lynx Design System: Baseline Flow
## HEADER_MSG  Version 2019.03-SP2
## HEADER_MSG  Copyright (c) 2019 Synopsys
## HEADER_MSG  Perforce Label: lynx_flow_2019.03-SP2
## -----------------------------------------------------------------------------

import os

class ReportBase:
    """Base class for report parsers"""

    def __init__(self):
        self._file = ""
        self._synopsys_program_name = ""
        self._rval = {}


    def set_file(self, fileName):
        success = True

        if os.path.isfile(fileName):
            self._file = fileName
        else:
            print(f'Error: File does not exist: {fileName}')
            success = False

        return success


    def get_file(self):
        return self._file


    def set_synopsys_program_name(self, progName):
        self._synopsys_program_name = progName


    def get_synopsys_program_name(self):
        return self._synopsys_program_name


    def parse(self):
        ## This method must re-implemented in derived-class
        success = True
        return success


    def get_metrics(self):
        return self._rval


## -----------------------------------------------------------------------------
## End of File
## -----------------------------------------------------------------------------
