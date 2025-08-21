## -----------------------------------------------------------------------------
## HEADER_MSG  Lynx Design System: Baseline Flow
## HEADER_MSG  Version 2019.03-SP2
## HEADER_MSG  Copyright (c) 2019 Synopsys
## HEADER_MSG  Perforce Label: lynx_flow_2019.03-SP2
## -----------------------------------------------------------------------------

import os
import re
from report_parsers.ReportBase import ReportBase

class ReportQor(ReportBase):

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
        ## Parse lines for scenario/pathgroup metrics
        ## -------------------------------------

        scenario_name = 'None/non-MCMM'
        path_group_name = 'NO_PATH_GROUP'
        path_group_metric_list = []
        path_group_metric_list.append('setup,logic_levels')
        path_group_metric_list.append('setup,path_length')
        path_group_metric_list.append('setup,path_slack')
        path_group_metric_list.append('setup,path_period')
        path_group_metric_list.append('setup,tns')
        path_group_metric_list.append('setup,nvp')
        path_group_metric_list.append('hold,path_slack')
        path_group_metric_list.append('hold,tns')
        path_group_metric_list.append('hold,nvp')

        self._rval['path_group_data,scenario_name_list'] = []

        line_number = 0
        for line in lines:
            line_number += 1

            ## Grab scenario
            match = re.match('^\s*Scenario\s+\'(.*)\'', line)
            if match:
                scenario_name = match.group(1)

            ## Grab pathgroup
            match = re.match('^\s*Timing Path Group\s+\'(\S+)\'', line)
            if match:
                path_group_name = match.group(1)

                ## Initialize new scenario/pathgroup metrics
                index = f'path_group_data,scenario_name_list'
                if scenario_name not in self._rval[index]:
                    self._rval[index].append(scenario_name)

                index = f'path_group_data,path_group_name_list,{scenario_name}'
                if index not in self._rval:
                    self._rval[index] = []
                if path_group_name not in self._rval[index]:
                    self._rval[index].append(path_group_name)

                for path_group_metric in path_group_metric_list:
                    index = f'path_group_data,{scenario_name},{path_group_name},{path_group_metric}'
                    self._rval[index] = 'NA'
                    index = f'path_group_data,{scenario_name},{path_group_name},{path_group_metric},line_number'
                    self._rval[index] = 1

            ## Look for specific entries for each scenario/pathgroup

            match = re.match('^\s*Levels of Logic:\s+([\-\d\.]+)', line)
            if match:
                index = f'path_group_data,{scenario_name},{path_group_name},setup,logic_levels'
                self._rval[index] = match.group(1)
                self._rval[f'{index},line_number'] = line_number

            match = re.match('^\s*Critical Path Length:\s+([\-\d\.]+)', line)
            if match:
                index = f'path_group_data,{scenario_name},{path_group_name},setup,path_length'
                self._rval[index] = match.group(1)
                self._rval[f'{index},line_number'] = line_number

            match = re.match('^\s*Critical Path Slack:\s+([\-\d\.]+)', line)
            if match:
                index = f'path_group_data,{scenario_name},{path_group_name},setup,path_slack'
                self._rval[index] = match.group(1)
                self._rval[f'{index},line_number'] = line_number

            match = re.match('^\s*Critical Path Clk Period:\s+(\S+)', line)
            if match:
                index = f'path_group_data,{scenario_name},{path_group_name},setup,path_period'
                self._rval[index] = match.group(1)
                self._rval[f'{index},line_number'] = line_number

            match = re.match('^\s*Total Negative Slack:\s+([\-\d\.]+)', line)
            if match:
                index = f'path_group_data,{scenario_name},{path_group_name},setup,tns'
                self._rval[index] = match.group(1)
                self._rval[f'{index},line_number'] = line_number

            match = re.match('^\s*No. of Violating Paths:\s+([\-\d\.]+)', line)
            if match:
                index = f'path_group_data,{scenario_name},{path_group_name},setup,nvp'
                self._rval[index] = match.group(1)
                self._rval[f'{index},line_number'] = line_number

            match = re.match('^\s*Worst Hold Violation:\s+([\-\d\.]+)', line)
            if match:
                index = f'path_group_data,{scenario_name},{path_group_name},hold,path_slack'
                self._rval[index] = match.group(1)
                self._rval[f'{index},line_number'] = line_number

            match = re.match('^\s*Total Hold Violation:\s+([\-\d\.]+)', line)
            if match:
                index = f'path_group_data,{scenario_name},{path_group_name},hold,tns'
                self._rval[index] = match.group(1)
                self._rval[f'{index},line_number'] = line_number

            match = re.match('^\s*No. of Hold Violations:\s+([\-\d\.]+)', line)
            if match:
                index = f'path_group_data,{scenario_name},{path_group_name},hold,nvp'
                self._rval[index] = match.group(1)
                self._rval[f'{index},line_number'] = line_number

        ## Sort scenarios
        index = f'path_group_data,scenario_name_list'
        self._rval[index] = sorted(self._rval[index])
        scenario_name_list = self._rval[index]

        ## Sort pathgroups for each scenario
        for scenario_name in scenario_name_list:
            index = f'path_group_data,path_group_name_list,{scenario_name}'
            self._rval[index] = sorted(self._rval[index])

        ## -------------------------------------
        ## Parse lines for design metrics
        ## -------------------------------------

        design_metric_list = []
        design_metric_list.append('design_data,leaf_cell_count')
        design_metric_list.append('design_data,bufinv_cell_count')
        design_metric_list.append('design_data,ctbufinv_cell_count')
        design_metric_list.append('design_data,comb_cell_count')
        design_metric_list.append('design_data,seq_cell_count')
        design_metric_list.append('design_data,macro_cell_count')
        design_metric_list.append('design_data,cell_area')
        design_metric_list.append('design_data,design_area')
        design_metric_list.append('design_data,net_length')
        design_metric_list.append('design_data,net_count')
        design_metric_list.append('design_data,ldrc_total')
        design_metric_list.append('design_data,ldrc_trans')
        design_metric_list.append('design_data,ldrc_cap')
        design_metric_list.append('design_data,ldrc_fanout')

        for design_metric in design_metric_list:
            index = f'design_metric'
            self._rval[index] = None
            index = f'design_metric,line_number'
            self._rval[index] = 1

        line_number = 0
        for line in lines:
            line_number += 1

            ## Cell counts

            match = re.match('^\s*Leaf Cell Count:\s+([\d\.]+)', line)
            if match:
                index = f'design_data,leaf_cell_count'
                self._rval[index] = match.group(1)
                self._rval[f'{index},line_number'] = line_number

            match = re.match('^\s*Buf/Inv Cell Count:\s+([\d\.]+)', line)
            if match:
                index = f'design_data,bufinv_cell_count'
                self._rval[index] = match.group(1)
                self._rval[f'{index},line_number'] = line_number

            match = re.match('^\s*CT Buf/Inv Cell Count:\s+([\d\.]+)', line)
            if match:
                index = f'design_data,ctbufinv_cell_count'
                self._rval[index] = match.group(1)
                self._rval[f'{index},line_number'] = line_number

            match = re.match('^\s*Combinational Cell Count:\s+([\d\.]+)', line)
            if match:
                index = f'design_data,comb_cell_count'
                self._rval[index] = match.group(1)
                self._rval[f'{index},line_number'] = line_number

            match = re.match('^\s*Sequential Cell Count:\s+([\d\.]+)', line)
            if match:
                index = f'design_data,seq_cell_count'
                self._rval[index] = match.group(1)
                self._rval[f'{index},line_number'] = line_number

            match = re.match('^\s*Macro Count:\s+([\d\.]+)', line)
            if match:
                index = f'design_data,macro_cell_count'
                self._rval[index] = match.group(1)
                self._rval[f'{index},line_number'] = line_number

            ## Area

            match = re.match('^\s*Cell Area:\s+([\d\.]+)', line)
            if match:
                index = f'design_data,cell_area'
                self._rval[index] = match.group(1)
                self._rval[f'{index},line_number'] = line_number

            match = re.match('^\s*Cell Area\s+\(netlist\):\s+([\d\.]+)', line)
            if match:
                index = f'design_data,cell_area'
                self._rval[index] = match.group(1)
                self._rval[f'{index},line_number'] = line_number

            match = re.match('^\s*Design Area:\s+([\d\.]+)', line)
            if match:
                index = f'design_data,design_area'
                self._rval[index] = match.group(1)
                self._rval[f'{index},line_number'] = line_number

            match = re.match('^\s*Cell Area\s+\(netlist and physical only\):\s+([\d\.]+)', line)
            if match:
                index = f'design_data,design_area'
                self._rval[index] = match.group(1)
                self._rval[f'{index},line_number'] = line_number

            ## Net

            match = re.match('^\s*Net Length\s*:\s+([\d\.]+)', line)
            if match:
                index = f'design_data,net_length'
                self._rval[index] = match.group(1)
                self._rval[f'{index},line_number'] = line_number

            match = re.match('^\s*Total Number of Nets:\s+([\d\.]+)', line)
            if match:
                index = f'design_data,net_count'
                self._rval[index] = match.group(1)
                self._rval[f'{index},line_number'] = line_number

            match = re.match('^\s*Nets With Violations:\s+([\d]+)', line)
            if match:
                index = f'design_data,ldrc_total'
                self._rval[index] = match.group(1)
                self._rval[f'{index},line_number'] = line_number

            match = re.match('^\s*Nets with Violations:\s+([\d]+)', line)
            if match:
                index = f'design_data,ldrc_total'
                self._rval[index] = match.group(1)
                self._rval[f'{index},line_number'] = line_number

            match = re.match('^\s*Max Trans Violations:\s+([\d]+)', line)
            if match:
                index = f'design_data,ldrc_trans'
                self._rval[index] = match.group(1)
                self._rval[f'{index},line_number'] = line_number

            match = re.match('^\s*Max Cap Violations:\s+([\d]+)', line)
            if match:
                index = f'design_data,ldrc_cap'
                self._rval[index] = match.group(1)
                self._rval[f'{index},line_number'] = line_number

            match = re.match('^\s*Max Fanout Violations:\s+([\d]+)', line)
            if match:
                index = f'design_data,ldrc_fanout'
                self._rval[index] = match.group(1)
                self._rval[f'{index},line_number'] = line_number

        ## -------------------------------------
        ## Parse lines for summary metrics
        ## -------------------------------------

        self._rval['summary_data,_ss,scenario_name_list'] = []

        line_number = 0
        for line in lines:
            line_number += 1

            ## -------------------------------------
            ## Per-scenario / Per-design setup (ICC2)
            ## -------------------------------------

            match = re.match('^(\S+)\s+\(Setup\)\s+(\S+)\s+(\S+)\s+(\S+)', line)
            if match:
                scenario_name = match.group(1)
                wns = match.group(2)
                tns = match.group(3)
                nvp = match.group(4)

                if scenario_name != 'Design':

                    if scenario_name not in self._rval['summary_data,_ss,scenario_name_list']:
                        self._rval['summary_data,_ss,scenario_name_list'].append(scenario_name)

                    self._rval[f'summary_data,_ss,{scenario_name},setup,path_slack'] = wns
                    self._rval[f'summary_data,_ss,{scenario_name},setup,tns']        = tns
                    self._rval[f'summary_data,_ss,{scenario_name},setup,nvp']        = nvp

                    self._rval[f'summary_data,_ss,{scenario_name},setup,path_slack,line_number'] = line_number
                    self._rval[f'summary_data,_ss,{scenario_name},setup,tns,line_number']        = line_number
                    self._rval[f'summary_data,_ss,{scenario_name},setup,nvp,line_number']        = line_number

                else:
                    self._rval[f'summary_data,_ms,setup,path_slack'] = wns
                    self._rval[f'summary_data,_ms,setup,tns']        = tns
                    self._rval[f'summary_data,_ms,setup,nvp']        = nvp

                    self._rval[f'summary_data,_ms,setup,path_slack,line_number'] = line_number
                    self._rval[f'summary_data,_ms,setup,tns,line_number']        = line_number
                    self._rval[f'summary_data,_ms,setup,nvp,line_number']        = line_number

            ## -------------------------------------
            ## Per-scenario setup (not ICC2)
            ## -------------------------------------

            match = re.match('^\s*Scenario:\s+(\S+)\s+WNS:\s+(\S+)\s+TNS:\s+(\S+)\s+Number of Violating Paths:\s+(\S+)', line)
            if match:
                scenario_name = match.group(1)
                wns = match.group(2)
                tns = match.group(3)
                nvp = match.group(4)

                if scenario_name not in self._rval['summary_data,_ss,scenario_name_list']:
                    self._rval['summary_data,_ss,scenario_name_list'].append(scenario_name)

                self._rval[f'summary_data,_ss,{scenario_name},setup,path_slack'] = wns
                self._rval[f'summary_data,_ss,{scenario_name},setup,tns']        = tns
                self._rval[f'summary_data,_ss,{scenario_name},setup,nvp']        = nvp
                
                self._rval[f'summary_data,_ss,{scenario_name},setup,path_slack,line_number'] = line_number
                self._rval[f'summary_data,_ss,{scenario_name},setup,tns,line_number']        = line_number
                self._rval[f'summary_data,_ss,{scenario_name},setup,nvp,line_number']        = line_number

            ## -------------------------------------
            ## Per-design setup (not ICC2)
            ## -------------------------------------

            match = re.match('^\s*Design\s+WNS:\s+(\S+)\s+TNS:\s+(\S+)\s+Number of Violating Paths:\s+(\S+)', line)
            if match:
                wns = match.group(1)
                tns = match.group(2)
                nvp = match.group(3)

                self._rval[f'summary_data,_ms,setup,path_slack'] = wns
                self._rval[f'summary_data,_ms,setup,tns']        = tns
                self._rval[f'summary_data,_ms,setup,nvp']        = nvp
                
                self._rval[f'summary_data,_ms,setup,path_slack,line_number'] = line_number
                self._rval[f'summary_data,_ms,setup,tns,line_number']        = line_number
                self._rval[f'summary_data,_ms,setup,nvp,line_number']        = line_number

            ## -------------------------------------
            ## Per-scenario / Per-design hold (ICC2)
            ## -------------------------------------

            match = re.match('^(\S+)\s+\(Hold\)\s+(\S+)\s+(\S+)\s+(\S+)', line)
            if match:
                scenario_name = match.group(1)
                wns = match.group(2)
                tns = match.group(3)
                nvp = match.group(4)

                if scenario_name != 'Design':

                    if scenario_name not in self._rval['summary_data,_ss,scenario_name_list']:
                        self._rval['summary_data,_ss,scenario_name_list'].append(scenario_name)

                    self._rval[f'summary_data,_ss,{scenario_name},hold,path_slack'] = wns
                    self._rval[f'summary_data,_ss,{scenario_name},hold,tns']        = tns
                    self._rval[f'summary_data,_ss,{scenario_name},hold,nvp']        = nvp

                    self._rval[f'summary_data,_ss,{scenario_name},hold,path_slack,line_number'] = line_number
                    self._rval[f'summary_data,_ss,{scenario_name},hold,tns,line_number']        = line_number
                    self._rval[f'summary_data,_ss,{scenario_name},hold,nvp,line_number']        = line_number

                else:
                    self._rval[f'summary_data,_ms,hold,path_slack'] = wns
                    self._rval[f'summary_data,_ms,hold,tns']        = tns
                    self._rval[f'summary_data,_ms,hold,nvp']        = nvp

                    self._rval[f'summary_data,_ms,hold,path_slack,line_number'] = line_number
                    self._rval[f'summary_data,_ms,hold,tns,line_number']        = line_number
                    self._rval[f'summary_data,_ms,hold,nvp,line_number']        = line_number

            ## -------------------------------------
            ## Per-scenario hold (not ICC2)
            ## -------------------------------------

            match = re.match('^\s*Scenario:\s+\s+\(Hold\)\s+(\S+)\s+WNS:\s+(\S+)\s+TNS:\s+(\S+)\s+Number of Violating Paths:\s+(\S+)', line)
            if match:
                scenario_name = match.group(1)
                wns = match.group(2)
                tns = match.group(3)
                nvp = match.group(4)

                if scenario_name not in self._rval['summary_data,_ss,scenario_name_list']:
                    self._rval['summary_data,_ss,scenario_name_list'].append(scenario_name)

                self._rval[f'summary_data,_ss,{scenario_name},hold,path_slack'] = wns
                self._rval[f'summary_data,_ss,{scenario_name},hold,tns']        = tns
                self._rval[f'summary_data,_ss,{scenario_name},hold,nvp']        = nvp

                self._rval[f'summary_data,_ss,{scenario_name},hold,path_slack,line_number'] = line_number
                self._rval[f'summary_data,_ss,{scenario_name},hold,tns,line_number']        = line_number
                self._rval[f'summary_data,_ss,{scenario_name},hold,nvp,line_number']        = line_number

            ## -------------------------------------
            ## Per-design hold (not ICC2)
            ## -------------------------------------

            match = re.match('^\s*Design\s+\(Hold\)\s+WNS:\s+(\S+)\s+TNS:\s+(\S+)\s+Number of Violating Paths:\s+(\S+)', line)
            if match:
                wns = match.group(1)
                tns = match.group(2)
                nvp = match.group(3)

                self._rval[f'summary_data,_ms,hold,path_slack'] = wns
                self._rval[f'summary_data,_ms,hold,tns']        = tns
                self._rval[f'summary_data,_ms,hold,nvp']        = nvp

                self._rval[f'summary_data,_ms,hold,path_slack,line_number'] = line_number
                self._rval[f'summary_data,_ms,hold,tns,line_number']        = line_number
                self._rval[f'summary_data,_ms,hold,nvp,line_number']        = line_number

        ## Sort scenarios
        self._rval['summary_data,_ss,scenario_name_list'] = sorted(self._rval['summary_data,_ss,scenario_name_list'])

        ## -------------------------------------
        ## A "pt_concat.report_qor" file is generated after DMSA processing and is simply
        ## a concatenation of the "report_qor" files for each scenario (generated by the PT slaves),
        ## and the "pt_master.report_global_timing" file (generated by the PT master).
        ## The per-design metrics are extracted from the "pt_master.report_global_timing" content.
        ## -------------------------------------

        if os.path.basename(self._file) != 'pt_concat.report_qor':
            return

        line_number = 0
        for line in lines:
            line_number += 1

            if re.match('^Setup violations', line):
                type = 'setup'
            if re.match('^Hold violations', line):
                type = 'hold'

            match = re.match('^WNS\s+(\S+)', line)
            if match:
                self._rval[f'summary_data,_ms,{type},path_slack'] = match.group(1)
                self._rval[f'summary_data,_ms,{type},path_slack,line_number'] = line_number

            match = re.match('^TNS\s+(\S+)', line)
            if match:
                self._rval[f'summary_data,_ms,{type},tns'] = match.group(1)
                self._rval[f'summary_data,_ms,{type},tns,line_number'] = line_number

            match = re.match('^NUM\s+(\S+)', line)
            if match:
                self._rval[f'summary_data,_ms,{type},nvp'] = match.group(1)
                self._rval[f'summary_data,_ms,{type},nvp,line_number'] = line_number

            match = re.match('^No (\S+) violations found', line)
            if match:
                type = match.group(1)
                self._rval[f'summary_data,_ms,{type},path_slack'] = 0
                self._rval[f'summary_data,_ms,{type},tns'] = 0
                self._rval[f'summary_data,_ms,{type},nvp'] = 0
                self._rval[f'summary_data,_ms,{type},path_slack,line_number'] = line_number
                self._rval[f'summary_data,_ms,{type},tns,line_number'] = line_number
                self._rval[f'summary_data,_ms,{type},nvp,line_number'] = line_number

## -----------------------------------------------------------------------------
## End of File
## -----------------------------------------------------------------------------
