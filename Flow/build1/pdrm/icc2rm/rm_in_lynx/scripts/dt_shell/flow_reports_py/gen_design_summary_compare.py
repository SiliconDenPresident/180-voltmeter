#! /usr/bin/env python3
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

import argparse
import os
import sys
import re
import shutil
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
    parser.add_argument('-category',    dest='category',    required=False, help='Report category', default='DEFAULT')
    parser.add_argument('-message',     dest='message',  action='store_true', help='')
    parser.add_argument('-debug',       dest='debug',    action='store_true', help='')

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


def create_final_report():

    template_dir = f'{configObj.script_dir()}/compare_template/'
    data_dir     = f'{configObj.script_dir()}/gen_design_summary_compare.data'
    
    # Note: configObj.report_file is a directory. Using report_dir for clarity.

    # Create report_dir

    report_dir = configObj.report_file

    if util.file_isdirectory(report_dir):
        if util.file_isfile(f'{report_dir}/index.html') and util.file_isdirectory(f'{report_dir}/include') and util.file_isdirectory(f'{report_dir}/data'):
            print(f'Using existing report directory: {report_dir}')
        else:
            print(f'Invalid report directory: {report_dir}')
            exit()
    else:
        print(f'Creating new report directory: {report_dir}')
        shutil.copytree(template_dir, report_dir)
        shutil.copytree(f'{data_dir}/data', f'{report_dir}/data')

    if not util.file_isdirectory(report_dir):
        print(f'Error: Unable to create report directory: {report_dir}')
        exit()

    # Polulate report_dir

    # Create list of file(s): data/category/*.tbl

    list_file = f'{report_dir}/data/tbl.cfg'
    file_obj = open(list_file, 'w')
    for build_item in configObj.get_build_item_list():
        build_label, build_dir = build_item
        build_file = f'{garg.category}/{build_label}.tbl'
        file_obj.write(f'{build_file}\n')
    file_obj.close()

    # Create file(s): data/category/*.tbl

    for build_item in configObj.get_build_item_list():
        build_label, build_dir = build_item

        build_file = f'{report_dir}/data/{garg.category}/{build_label}.tbl'

        util.file_mkdir(util.file_dirname(build_file))

        file_obj = open(build_file, 'w')

        
	

	
	
	
	# Create HEADER line

        data_line = 'HEADER'

        for name in metricInfoObj.display_name_list():
            data_line += f'|{metricInfoObj.display_name_get(name)}'

        file_obj.write(f'{data_line}\n')

        # Create VALUE lines

        for task_id in buildInfoObj.get_rpt_task_id(build_label):
            task_step        = buildInfoObj.get_task_step(build_label, task_id)
            task_dst         = buildInfoObj.get_task_dst(build_label, task_id)
            task_name        = buildInfoObj.get_task_name(build_label, task_id)

            data_line = f'{task_id}'
            for name in metricInfoObj.display_name_list():
                key = f'{build_label},{task_id},{name}'
                if metricInfoObj.metric_exists(key):
                    data = metricInfoObj.metric_get_data(key)
                else:
                    data = ''
                data_line += f'|{data}'

            file_obj.write(f'{data_line}\n')

        file_obj.close()

    # configure format.cfg
    format_config_file = f'{report_dir}/data/format.cfg'
    if os.path.exists(format_config_file + '.orig'): os.remove(format_config_file + '.orig')
    shutil.copyfile(format_config_file, format_config_file + '.orig')
    if os.path.exists(format_config_file): os.remove(format_config_file)
    in_id = open(format_config_file + '.orig', 'r')
    out_id = open(format_config_file, 'w')
    format_config_lines = in_id.readlines()
    found_first_format = 0
    for format_config_line in format_config_lines:
        if not found_first_format:
            if re.match('^#OVERRIDES', format_config_line):
                for metric_name in metricInfoObj.display_name_list():
                    out_id.write(f'FORMAT|{metricInfoObj.display_name_get(metric_name)}|STD_RULE_S\n')
                found_first_format = 1
        out_id.write(format_config_line)
    in_id.close()
    os.remove(format_config_file + '.orig')
    out_id.close()	


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
