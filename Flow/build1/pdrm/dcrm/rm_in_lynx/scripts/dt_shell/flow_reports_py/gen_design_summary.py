#! /usr/bin/env python3
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

import argparse
import os
import re
import util

from report_parsers import ReportQor
from report_parsers import ReportUnits
from report_parsers import ReportPower
from report_parsers import ReportThresholdVoltageGroup
from report_parsers import ReportDesign
from report_parsers import ReportUtilization
from report_parsers import ReportAppOptions


def parseArgs():

    parser = argparse.ArgumentParser(
        description='Example Design Tracker Report'
    )

    parser.add_argument('-config_list', dest='config_list', required=False, help='List specifying builds')
    parser.add_argument('-config_file', dest='config_file', required=False, help='File specifying builds')
    parser.add_argument('-report_file', dest='report_file', required=False, help='Report file to create')
    parser.add_argument('-message',     dest='message', action='store_true', help='')
    parser.add_argument('-debug',       dest='debug',   action='store_true', help='')

    args = parser.parse_args()

    if args.config_file:
        if not os.path.isfile(args.config_file):
            print(f'Error: The -config_file does not exist: {args.config_file}')
            exit()

    return args


def gather_report_data():

    for build_item in configObj.get_build_item_list():
        build_label, build_dir = build_item
        gather_build_data(build_label, build_dir)


def gather_build_data(build_label, build_dir):

    # --------------------------------------
    # Get tasks and reports
    # --------------------------------------

    reports = []
    reports.append('report_qor')
    reports.append('report_units')
    reports.append('report_power')
    reports.append('report_threshold_voltage_groups')
    reports.append('report_design')
    reports.append('report_utilization')

    buildInfoObj.init(build_label, build_dir, reports)

    if garg.debug:
        buildInfoObj.debug(build_label, build_dir)

    # --------------------------------------
    # Gather metrics for each task
    # --------------------------------------

    theTimeUnit = 'UNDEFINED'

    metricInfoObj.display_name_add('design_setup_wns',     'Design Setup WNS (TIME_UNIT)')
    metricInfoObj.display_name_add('design_setup_tns',     'Design Setup TNS (TIME_UNIT)')
    metricInfoObj.display_name_add('design_setup_nvp',     'Design Setup Violations')
    metricInfoObj.display_name_add('design_hold_wns',      'Design Hold WNS (TIME_UNIT)')
    metricInfoObj.display_name_add('design_hold_tns',      'Design Hold TNS (TIME_UNIT)')
    metricInfoObj.display_name_add('design_hold_nvp',      'Design Hold Violations')
    metricInfoObj.display_name_add('leaf_cell_count',      'Leaf Cell Count')
    metricInfoObj.display_name_add('bufinv_cell_count',    'Buf/Inv Cell Count')
    metricInfoObj.display_name_add('ctbufinv_cell_count',  'CT Buf/Inv Cell Count')
    metricInfoObj.display_name_add('comb_cell_count',      'Comb Cell Count')
    metricInfoObj.display_name_add('seq_cell_count',       'Seq Cell Count')
    metricInfoObj.display_name_add('macro_cell_count',     'Macro Cell Count')
    metricInfoObj.display_name_add('cell_area',            'Cell Area')
    metricInfoObj.display_name_add('design_area',          'Design Area')
    metricInfoObj.display_name_add('net_length',           'Net Length')
    metricInfoObj.display_name_add('net_count',            'Net Count')
    metricInfoObj.display_name_add('ldrc_total',           'Net Violations Total')
    metricInfoObj.display_name_add('ldrc_trans',           'Net Violations Trans')
    metricInfoObj.display_name_add('ldrc_cap',             'Net Violations MaxCap')
    metricInfoObj.display_name_add('ldrc_fanout',          'Net Violations MaxFanout')
    metricInfoObj.display_name_add('cell2core_ratio',      'Utilization')
    metricInfoObj.display_name_add('num_drc_errors',       'DRC Errors Total')
    metricInfoObj.display_name_add('num_drc_errors_types', 'DRC Errors Types')
    metricInfoObj.display_name_add('total_power_max',      'Power Total (mW)')
    metricInfoObj.display_name_add('leakage_power_max',    'Power Leakage (mW)')

    for task_id in buildInfoObj.get_rpt_task_id(build_label):
        task_step        = buildInfoObj.get_task_step(build_label, task_id)
        task_dst         = buildInfoObj.get_task_dst(build_label, task_id)
        task_tool        = buildInfoObj.get_task_tool(build_label, task_id)
        task_report_list = buildInfoObj.get_task_report_list(build_label, task_id)

        # -------------------------------------
        # Parse the reports for this task
        # -------------------------------------

        units_dict = {}
        qor_dict = {}
        power_dict = {}
        vth_dict = {}
        phy_dict = {}
        util_dict = {}
        app_dict = {}

        for task_report in task_report_list:

            if util.file_extension(task_report) == '.report_units':
                parser = ReportUnits.ReportUnits()
                parser.set_synopsys_program_name(task_tool)
                parser.set_file(task_report)
                parser.parse()
                units_dict = parser.get_metrics()
                unit_file = task_report

            if util.file_extension(task_report) == '.report_qor':
                parser = ReportQor.ReportQor()
                parser.set_synopsys_program_name(task_tool)
                parser.set_file(task_report)
                parser.parse()
                qor_dict = parser.get_metrics()
                qor_file = task_report

            if util.file_extension(task_report) == '.report_power':
                parser = ReportPower.ReportPower()
                parser.set_synopsys_program_name(task_tool)
                parser.set_file(task_report)
                parser.parse()
                power_dict = parser.get_metrics()
                power_file = task_report

            if util.file_extension(task_report) == '.report_threshold_voltage_groups':
                parser = ReportThresholdVoltageGroup.ReportThresholdVoltageGroup()
                parser.set_synopsys_program_name(task_tool)
                parser.set_file(task_report)
                parser.parse()
                vth_dict = parser.get_metrics()
                vth_file = task_report

            if util.file_extension(task_report) == '.report_design':
                parser = ReportDesign.ReportDesign()
                parser.set_synopsys_program_name(task_tool)
                parser.set_file(task_report)
                parser.parse()
                phy_dict = parser.get_metrics()
                phy_file = task_report

            if util.file_extension(task_report) == '.report_utilization':
                parser = ReportUtilization.ReportUtilization()
                parser.set_synopsys_program_name(task_tool)
                parser.set_file(task_report)
                parser.parse()
                util_dict = parser.get_metrics()
                util_file = task_report

            if util.file_extension(task_report) == '.report_app_options':
                parser = ReportAppOptions.ReportAppOptions()
                parser.set_synopsys_program_name(task_tool)
                parser.set_file(task_report)
                parser.parse()
                app_dict = parser.get_metrics()
                app_file = task_report

        # -------------------------------------
        # Stuff results into metricInfoObj
        # -------------------------------------

        # -------------------------------------
        # units_dict
        # -------------------------------------

        if units_dict:
            if units_dict['Time_unit']:
                if theTimeUnit == 'UNDEFINED':
                    theTimeUnit = units_dict['Time_unit']

        # -------------------------------------
        # qor_dict
        # -------------------------------------

        if qor_dict:

            dict_key = 'summary_data,_ms,setup,path_slack'
            key = f'{build_label},{task_id},design_setup_wns'
            if dict_key in qor_dict:
                data = util.format_value('{0:.2f}', qor_dict[dict_key])
                link = f'{qor_file}:{qor_dict[f"{dict_key},line_number"]}'
                metricInfoObj.metric_add(key, data, link)

            dict_key = 'summary_data,_ms,setup,tns'
            key = f'{build_label},{task_id},design_setup_tns'
            if dict_key in qor_dict:
                data = '{0:.2f}'.format(float(qor_dict[dict_key]))
                link = f'{qor_file}:{qor_dict[f"{dict_key},line_number"]}'
                metricInfoObj.metric_add(key, data, link)

            dict_key = 'summary_data,_ms,setup,nvp'
            key = f'{build_label},{task_id},design_setup_nvp'
            if dict_key in qor_dict:
                data = qor_dict[dict_key]
                link = f'{qor_file}:{qor_dict[f"{dict_key},line_number"]}'
                metricInfoObj.metric_add(key, data, link)

            dict_key = 'summary_data,_ms,hold,path_slack'
            key = f'{build_label},{task_id},design_hold_wns'
            if dict_key in qor_dict:
                data = util.format_value('{0:.2f}', qor_dict[dict_key])
                link = f'{qor_file}:{qor_dict[f"{dict_key},line_number"]}'
                metricInfoObj.metric_add(key, data, link)

            dict_key = 'summary_data,_ms,hold,tns'
            key = f'{build_label},{task_id},design_hold_tns'
            if dict_key in qor_dict:
                data = '{0:.2f}'.format(float(qor_dict[dict_key]))
                link = f'{qor_file}:{qor_dict[f"{dict_key},line_number"]}'
                metricInfoObj.metric_add(key, data, link)

            dict_key = 'summary_data,_ms,hold,nvp'
            key = f'{build_label},{task_id},design_hold_nvp'
            if dict_key in qor_dict:
                data = qor_dict[dict_key]
                link = f'{qor_file}:{qor_dict[f"{dict_key},line_number"]}'
                metricInfoObj.metric_add(key, data, link)

            dict_key = 'design_data,leaf_cell_count'
            key = f'{build_label},{task_id},leaf_cell_count'
            if dict_key in qor_dict:
                data = qor_dict[dict_key]
                link = f'{qor_file}:{qor_dict[f"{dict_key},line_number"]}'
                metricInfoObj.metric_add(key, data, link)

            dict_key = 'design_data,bufinv_cell_count'
            key = f'{build_label},{task_id},bufinv_cell_count'
            if dict_key in qor_dict:
                data = qor_dict[dict_key]
                link = f'{qor_file}:{qor_dict[f"{dict_key},line_number"]}'
                metricInfoObj.metric_add(key, data, link)

            dict_key = 'design_data,ctbufinv_cell_count'
            key = f'{build_label},{task_id},ctbufinv_cell_count'
            if dict_key in qor_dict:
                data = qor_dict[dict_key]
                link = f'{qor_file}:{qor_dict[f"{dict_key},line_number"]}'
                metricInfoObj.metric_add(key, data, link)

            dict_key = 'design_data,comb_cell_count'
            key = f'{build_label},{task_id},comb_cell_count'
            if dict_key in qor_dict:
                data = qor_dict[dict_key]
                link = f'{qor_file}:{qor_dict[f"{dict_key},line_number"]}'
                metricInfoObj.metric_add(key, data, link)

            dict_key = 'design_data,seq_cell_count'
            key = f'{build_label},{task_id},seq_cell_count'
            if dict_key in qor_dict:
                data = qor_dict[dict_key]
                link = f'{qor_file}:{qor_dict[f"{dict_key},line_number"]}'
                metricInfoObj.metric_add(key, data, link)

            dict_key = 'design_data,macro_cell_count'
            key = f'{build_label},{task_id},macro_cell_count'
            if dict_key in qor_dict:
                data = qor_dict[dict_key]
                link = f'{qor_file}:{qor_dict[f"{dict_key},line_number"]}'
                metricInfoObj.metric_add(key, data, link)

            dict_key = 'design_data,cell_area'
            key = f'{build_label},{task_id},cell_area'
            if dict_key in qor_dict:
                data = '{0:.2f}'.format(float(qor_dict[dict_key]))
                link = f'{qor_file}:{qor_dict[f"{dict_key},line_number"]}'
                metricInfoObj.metric_add(key, data, link)

            dict_key = 'design_data,design_area'
            key = f'{build_label},{task_id},design_area'
            if dict_key in qor_dict:
                data = '{0:.2f}'.format(float(qor_dict[dict_key]))
                link = f'{qor_file}:{qor_dict[f"{dict_key},line_number"]}'
                metricInfoObj.metric_add(key, data, link)

            dict_key = 'design_data,net_length'
            key = f'{build_label},{task_id},net_length'
            if dict_key in qor_dict:
                data = '{0:.2f}'.format(float(qor_dict[dict_key]))
                link = f'{qor_file}:{qor_dict[f"{dict_key},line_number"]}'
                metricInfoObj.metric_add(key, data, link)

            dict_key = 'design_data,net_count'
            key = f'{build_label},{task_id},net_count'
            if dict_key in qor_dict:
                data = qor_dict[dict_key]
                link = f'{qor_file}:{qor_dict[f"{dict_key},line_number"]}'
                metricInfoObj.metric_add(key, data, link)

            dict_key = 'design_data,ldrc_total'
            key = f'{build_label},{task_id},ldrc_total'
            if dict_key in qor_dict:
                data = qor_dict[dict_key]
                link = f'{qor_file}:{qor_dict[f"{dict_key},line_number"]}'
                metricInfoObj.metric_add(key, data, link)

            dict_key = 'design_data,ldrc_trans'
            key = f'{build_label},{task_id},ldrc_trans'
            if dict_key in qor_dict:
                data = qor_dict[dict_key]
                link = f'{qor_file}:{qor_dict[f"{dict_key},line_number"]}'
                metricInfoObj.metric_add(key, data, link)

            dict_key = 'design_data,ldrc_cap'
            key = f'{build_label},{task_id},ldrc_cap'
            if dict_key in qor_dict:
                data = qor_dict[dict_key]
                link = f'{qor_file}:{qor_dict[f"{dict_key},line_number"]}'
                metricInfoObj.metric_add(key, data, link)

            dict_key = 'design_data,ldrc_fanout'
            key = f'{build_label},{task_id},ldrc_fanout'
            if dict_key in qor_dict:
                data = qor_dict[dict_key]
                link = f'{qor_file}:{qor_dict[f"{dict_key},line_number"]}'
                metricInfoObj.metric_add(key, data, link)

        # -------------------------------------
        # power_dict
        # -------------------------------------

        if power_dict:
            total_power_max = None
            total_power_units = None
            total_power_line_number = None
            leakage_power_max = None
            leakage_power_units = None
            leakage_power_line_number = None

            for scenario_name in power_dict['scenario_name_list']:
                total_power_units = power_dict[f'{scenario_name},total_power_units']
                leakage_power_units = power_dict[f'{scenario_name},leakage_power_units']

                total_power = power_dict[f'{scenario_name},total_power']
                if util.is_number(total_power):
                    total_power = float(total_power)
                    if (total_power_max is None) or (total_power > total_power_max):
                        total_power_max = total_power
                        total_power_line_number = power_dict[f'{scenario_name},total_power,line_number']

                leakage_power = power_dict[f'{scenario_name},leakage_power']
                if util.is_number(leakage_power):
                    leakage_power = float(leakage_power)
                    if (leakage_power_max is None) or (leakage_power > leakage_power_max):
                        leakage_power_max = leakage_power
                        leakage_power_line_number = power_dict[f'{scenario_name},leakage_power,line_number']

                if total_power_max is not None:
                    data = '{0:.2f} {1}'.format(total_power_max, total_power_units)
                    link = f'{power_file}:{total_power_line_number}'
                    key = f'{build_label},{task_id},total_power_max'
                    metricInfoObj.metric_add(key, data, link)

                if leakage_power_max is not None:
                    data = '{0:.2f} {1}'.format(leakage_power_max, leakage_power_units)
                    link = f'{power_file}:{leakage_power_line_number}'
                    key = f'{build_label},{task_id},leakage_power_max'
                    metricInfoObj.metric_add(key, data, link)

        # -------------------------------------
        # vth_dict
        # -------------------------------------

        if vth_dict:

            for vth_name in vth_dict['vth,vth_names']:

                dict_key = f'cell_percentage,{vth_name}'
                key = f'{build_label},{task_id},vth_percent_{vth_name}'
                if dict_key in vth_dict:
                    data = vth_dict[dict_key]
                    link = f'{vth_file}:{vth_dict[f"{dict_key},line_number"]}'
                    metricInfoObj.metric_add(key, data, link)

                    name = f'vth_percent_{vth_name}'
                    display = f'Vth Percent ({vth_name})'
                    metricInfoObj.display_name_add(name, display)

                dict_key = f'cell_count,{vth_name}'
                key = f'{build_label},{task_id},vth_count_{vth_name}'
                if dict_key in vth_dict:
                    data = vth_dict[dict_key]
                    link = f'{vth_file}:{vth_dict[f"{dict_key},line_number"]}'
                    metricInfoObj.metric_add(key, data, link)

                    name = f'vth_count_{vth_name}'
                    display = f'Vth Count ({vth_name})'
                    metricInfoObj.display_name_add(name, display)

        # -------------------------------------
        # util_dict
        # -------------------------------------

        if util_dict:

            dict_key = 'cell2core_ratio'
            key = f'{build_label},{task_id},cell2core_ratio'
            if dict_key in util_dict:
                data = '{0:.2f}'.format(float(util_dict[dict_key]))
                link = f'{util_file}:{util_dict[f"{dict_key},line_number"]}'
                metricInfoObj.metric_add(key, data, link)

        # -------------------------------------
        # phy_dict
        # -------------------------------------

        if phy_dict:

            dict_key = 'num_drc_errors'
            key = f'{build_label},{task_id},num_drc_errors'
            if dict_key in phy_dict:
                data = phy_dict[dict_key]
                link = f'{phy_file}:{phy_dict[f"{dict_key},line_number"]}'
                metricInfoObj.metric_add(key, data, link)

            dict_key = 'num_drc_errors_types'
            key = f'{build_label},{task_id},num_drc_errors_types'
            if dict_key in phy_dict:
                data = phy_dict[dict_key]
                link = f'{phy_file}:{phy_dict[f"{dict_key},line_number"]}'
                metricInfoObj.metric_add(key, data, link)

    # Factor the time unit back into the metric display names
    for name in metricInfoObj.display_name_list():
        display = metricInfoObj.display_name_get(name)
        display = re.sub('TIME_UNIT', theTimeUnit, display)
        display = metricInfoObj.display_name_set(name, display)


def attrColor(name, value):

    set1 = []
    set1.append('design_setup_wns')
    set1.append('design_setup_tns')
    set1.append('design_setup_nvp')
    set1.append('design_hold_wns')
    set1.append('design_hold_tns')
    set1.append('design_hold_nvp')

    set2 = []
    set2.append('ldrc_total')
    set2.append('ldrc_trans')
    set2.append('ldrc_cap')
    set2.append('ldrc_fanout')

    set3 = []
    set3.append('num_drc_errors')

    attr = ''

    if util.is_number(value):
        if name in set1:
            if (float(value) < 0):
                attr = '#ffffff:#ff0000'
        elif name in set2:
            if (float(value) > 0):
                attr = '#ffffff:#0000ff'
        elif name in set3:
            if (float(value) > 0):
                attr = '#ffffff:#ff00ff'

    return attr


def create_final_report():

    file_obj = open(configObj.report_file, 'w')

    # --------------------------------------
    # Determine all available builds
    # --------------------------------------

    build_label_list = []
    for build_item in configObj.get_build_item_list():
        build_label, build_dir = build_item
        build_label_list.append(build_label)

    hasSingleBlock = (len(build_label_list) == 1)

    # --------------------------------------
    # Print the LYNX_BEGIN statement
    # --------------------------------------

    file_obj.write(f'LYNX_BEGIN|lynx_table_merge|my_table_merge\n\n')

    file_obj.write(f'TABLE_ID_FORMAT|TableStyle\n\n')

    tableStyleList = ['TaskFocus', 'TrendFocus']

    for tableStyle in tableStyleList:

        # --------------------------------------
        # Print the TABLE_BEGIN statement
        # --------------------------------------

        file_obj.write(f'TABLE_BEGIN\n\n')

        file_obj.write(f'TABLE_ID|{tableStyle}\n\n')

        # --------------------------------------
        # Print the DATA section
        # --------------------------------------

        attr_lines = []
        link_lines = []

        attr_array = {}
        attr_array['rowHeader1'] = '#ffffff:#000099:L'
        attr_array['rowHeader2'] = '#ffffff:#3333ff:C'
        attr_array['colHeader1'] = '#ffffff:#303030:L'

        file_obj.write(f'DATA_BEGIN\n')

        # --------------------------------------
        # Print the HEADER lines
        # While doing this, also:
        # Create information for ATTR section (create $attr_lines, which is output later)
        # Create information for LINK section (create $link_lines, which is output later)
        # --------------------------------------

        if tableStyle == 'TaskFocus':

            # Tasks across top (and builds if multi-build), Metrics down left
            # Row 0: task_step
            # Row 1: task_dst
            # Row 2: task_name
            # Row 3: build_label (if multi-build)

            # Single frozen col for metrics
            file_obj.write(f'HEADER_COLS|1\n')

            if hasSingleBlock == True:
                # step, dst, task
                headerRows = 3
            else:
                # step, dst, task, build
                headerRows = 4

            for row in range(0, headerRows):

                data_line = 'HEADER'
                attr_line = 'HEADER'
                link_line = 'HEADER'

                data_line += f'|Metric'
                attr_line += f'|{attr_array["rowHeader1"]}'
                link_line += f'|'

                for task_id in buildInfoObj.get_rpt_task_id(build_label):
                    task_step = buildInfoObj.get_task_step(build_label, task_id)
                    task_dst  = buildInfoObj.get_task_dst(build_label, task_id)
                    task_name = buildInfoObj.get_task_name(build_label, task_id)

                    for build_label in build_label_list:
                        if row == 0:
                            data_line += f'|{task_step}'
                            attr_line += f'|{attr_array["rowHeader2"]}'
                            link_line += f'|'
                        elif row == 1:
                            data_line += f'|{task_dst}'
                            attr_line += f'|{attr_array["rowHeader2"]}'
                            link_line += f'|'
                        elif row == 2:
                            data_line += f'|{task_name}'
                            attr_line += f'|{attr_array["rowHeader2"]}'
                            link_line += f'|'
                        elif row == 3:
                            data_line += f'|{build_label}'
                            attr_line += f'|{attr_array["rowHeader2"]}'
                            link_line += f'|'

                file_obj.write(f'{data_line}\n')
                attr_lines.append(attr_line)
                link_lines.append(link_line)

        else:

            # Metrics across top (and builds if multi-build), tasks down left

            if hasSingleBlock:

                # Print 1 row headers
                # Row 0: metrics

                file_obj.write(f'HEADER_COLS|3\n')

                data_line = 'HEADER'
                attr_line = 'HEADER'
                link_line = 'HEADER'

                data_line += f'|Step|Dst|Task'
                attr_line += f'|{attr_array["rowHeader1"]}|{attr_array["rowHeader1"]}|{attr_array["rowHeader1"]}'
                link_line += f'|||'

                for name in metricInfoObj.display_name_list():
                    data_line += f'|{metricInfoObj.display_name_get(name)}'
                    attr_line += f'|{attr_array["rowHeader2"]}'
                    link_line += f'|'

                file_obj.write(f'{data_line}\n')
                attr_lines.append(attr_line)
                link_lines.append(link_line)

            else:

                # Print 2 row headers
                # Row 0: metrics (replicate each column of metrics per number of builds)
                # Row 1: builds (cycle through builds for each metric)

                file_obj.write(f'HEADER_COLS|3\n')

                # Row 0:

                data_line = 'HEADER'
                attr_line = 'HEADER'
                link_line = 'HEADER'

                data_line += f'|Step|Dst|Task'
                attr_line += f'|{attr_array["rowHeader1"]}|{attr_array["rowHeader1"]}|{attr_array["rowHeader1"]}'
                link_line += f'|||'
                for name in metricInfoObj.display_name_list():
                    for build_label in build_label_list:
                        data_line += f'|{metricInfoObj.display_name_get(name)}'
                        attr_line += f'|{attr_array["rowHeader2"]}'
                        link_line += f'|'

                file_obj.write(f'{data_line}\n')
                attr_lines.append(attr_line)
                link_lines.append(link_line)

                # Row 1:

                data_line = 'HEADER'
                attr_line = 'HEADER'
                link_line = 'HEADER'

                data_line += f'|Step|Dst|Task'
                attr_line += f'|{attr_array["rowHeader1"]}|{attr_array["rowHeader1"]}|{attr_array["rowHeader1"]}'
                link_line += f'|||'
                for name in metricInfoObj.display_name_list():
                    for build_label in build_label_list:
                        data_line += f'|{build_label}'
                        attr_line += f'|{attr_array["rowHeader2"]}'
                        link_line += f'|'

                file_obj.write(f'{data_line}\n')
                attr_lines.append(attr_line)
                link_lines.append(link_line)

        # --------------------------------------
        # Print the VALUE lines
        # While doing this, also:
        # Create information for ATTR section (create $attr_lines, which is output later)
        # Create information for LINK section (create $link_lines, which is output later)
        # --------------------------------------

        if tableStyle == 'TaskFocus':

            # Tasks across top (and builds if multi-build), Metrics down left

            for name in metricInfoObj.display_name_list():

                data_line = 'VALUE'
                attr_line = 'VALUE'
                link_line = 'VALUE'

                data_line += f'|{metricInfoObj.display_name_get(name)}'
                attr_line += f'|{attr_array["colHeader1"]}'
                link_line += f'|'

                for task_id in buildInfoObj.get_rpt_task_id(build_label):
                    task_step = buildInfoObj.get_task_step(build_label, task_id)
                    task_dst  = buildInfoObj.get_task_dst(build_label, task_id)
                    task_name = buildInfoObj.get_task_name(build_label, task_id)

                    for build_label in build_label_list:
                        key = f'{build_label},{task_id},{name}'
                        if metricInfoObj.metric_exists(key):
                            data = metricInfoObj.metric_get_data(key)
                            link = metricInfoObj.metric_get_link(key)
                            attr = attrColor(name, data)
                        else:
                            data = ''
                            link = ''
                            attr = ''

                        data_line += f'|{str(data)}'
                        attr_line += f'|{attr}'
                        link_line += f'|{link}'

                file_obj.write(f'{data_line}\n')
                attr_lines.append(attr_line)
                link_lines.append(link_line)

        else:

            for task_id in buildInfoObj.get_rpt_task_id(build_label):
                task_step = buildInfoObj.get_task_step(build_label, task_id)
                task_dst  = buildInfoObj.get_task_dst(build_label, task_id)
                task_name = buildInfoObj.get_task_name(build_label, task_id)

                data_line = f'VALUE|{task_step}|{task_dst}|{task_name}'
                attr_line = f'VALUE|{attr_array["colHeader1"]}|{attr_array["colHeader1"]}|{attr_array["colHeader1"]}'
                link_line = f'VALUE|||'

                for name in metricInfoObj.display_name_list():
                    for build_label in build_label_list:
                        key = f'{build_label},{task_id},{name}'
                        if metricInfoObj.metric_exists(key):
                            data = metricInfoObj.metric_get_data(key)
                            link = metricInfoObj.metric_get_link(key)
                            attr = attrColor(name, data)
                        else:
                            data = ''
                            link = ''
                            attr = ''

                        data_line += f'|{str(data)}'
                        attr_line += f'|{attr}'
                        link_line += f'|{link}'

                file_obj.write(f'{data_line}\n')
                attr_lines.append(attr_line)
                link_lines.append(link_line)

        file_obj.write(f'DATA_END\n\n')

        # --------------------------------------
        # Print the ATTR section
        # --------------------------------------

        file_obj.write(f'ATTR_BEGIN\n')
        for attr_line in attr_lines:
            file_obj.write(f'{attr_line}\n')
        file_obj.write(f'ATTR_END\n\n')

        # --------------------------------------
        # Print the LINK section
        # --------------------------------------

        file_obj.write(f'LINK_BEGIN\n')
        for link_line in link_lines:
            file_obj.write(f'{link_line}\n')
        file_obj.write(f'LINK_END\n\n')

        # --------------------------------------
        # Print the FORMAT section
        # --------------------------------------

        # --------------------------------------
        # Create the title information
        # --------------------------------------

        title = f'Design Summary ({tableStyle}) : '

        for build_label in build_label_list:
            title += f' {build_label}'

        subtitle = f'Created on {util.get_long_date()}'

        # --------------------------------------
        # Output the section information
        # --------------------------------------

        file_obj.write(f'FORMAT_BEGIN\n')
        file_obj.write(f'TITLE|{title}\n')
        file_obj.write(f'SUBTITLE|{subtitle}\n')
        file_obj.write(f'FORMAT_END\n\n')

        # --------------------------------------
        # Print the TABLE_END statement
        # --------------------------------------

        file_obj.write(f'TABLE_END\n\n')

    # --------------------------------------
    # Print the LYNX_END statement
    # --------------------------------------

    file_obj.write(f'LYNX_END\n')

    file_obj.close()


# ------------------------------------------------------------------------------
# MAIN
# ------------------------------------------------------------------------------

if __name__ == '__main__':

    garg = parseArgs()

    misc = {}
    configObj = util.Config()
    fileVarsObj = util.FileVars()
    buildInfoObj = util.BuildInfo()
    metricInfoObj = util.MetricInfo()

    configObj.init(garg)

    gather_report_data()

    create_final_report()

    configObj.create_message_file()

    print(f'Done!')


# ------------------------------------------------------------------------------
# End Of File
# ------------------------------------------------------------------------------
