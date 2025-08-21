## -----------------------------------------------------------------------------
## HEADER_MSG  Lynx Design System: Baseline Flow
## HEADER_MSG  Version 2019.03-SP2
## HEADER_MSG  Copyright (c) 2019 Synopsys
## HEADER_MSG  Perforce Label: lynx_flow_2019.03-SP2
## -----------------------------------------------------------------------------
import os
import re
from report_package.parsers.ReportBase import ReportBase

class TaskLog(ReportBase):
  """Parser for task_log"""

  ## class attributes


  ## constructor / instance attributes
  def __init__(self):
    super().__init__()
    self._metric_dict = {}

  def harvest(self):
    if not os.path.isfile(self._file):
      print('Missing file')
      return

    ## Read file contents
    lines = self.read_file()

    ## Define regexp
    re_Error       = re.compile("^Error:")
    re_Warning     = re.compile("^Warning:")
    re_ElapsedTime = re.compile("^Elapsed time for this session:\s+(\S+)")

    count_error = 0
    count_warning = 0

    for line in lines:
      match = re_Error.match(line)
      if match:
        count_error += 1
        continue

      match = re_Warning.match(line)
      if match:
        count_warning += 1
        continue

      match = re_ElapsedTime.match(line)
      if match:
        self._metric_dict["Duration"]  = ( "INT", match.group(1), "s" )
        continue

    self._metric_dict["Err"]  = ( "INT", str(count_error) )
    self._metric_dict["Warn"] = ( "INT", str(count_warning) )


  def metrics(self):
    """ Expected format is <name>|<type>|<value>|{attribute} """

    entry_list = []

    for key in self._metric_dict.keys():
      data = self._metric_dict[key]
      metric = key
      entry = metric + "|" + "|".join(data)
      entry_list.append(entry)

    return entry_list

## -----------------------------------------------------------------------------
## End of File
## -----------------------------------------------------------------------------
