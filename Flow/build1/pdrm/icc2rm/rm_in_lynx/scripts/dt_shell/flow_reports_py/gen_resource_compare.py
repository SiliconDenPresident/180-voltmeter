#! /usr/bin/env python3
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

import argparse
import os
import re
import shutil
import util


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

    buildInfoObj.init(build_label, build_dir, reports)

    if garg.debug:
        buildInfoObj.debug(build_label, build_dir)

    # --------------------------------------
    # Gather metrics for each task
    # --------------------------------------

    metricInfoObj.display_name_add('Host',           'Host')
    metricInfoObj.display_name_add('Tool',           'Tool')
    metricInfoObj.display_name_add('Version',        'Version')
    metricInfoObj.display_name_add('Cores',          'Cores')
    metricInfoObj.display_name_add('Wall Time',      'Wall Time')
    metricInfoObj.display_name_add('CPU Time',       'CPU Time')
    metricInfoObj.display_name_add('CPU Efficiency', 'CPU Efficiency')
    metricInfoObj.display_name_add('Mem',            'Mem')

    for task_id in buildInfoObj.get_all_task_id(build_label):
        task_step        = buildInfoObj.get_task_step(build_label, task_id)
        task_dst         = buildInfoObj.get_task_dst(build_label, task_id)
        task_name        = buildInfoObj.get_task_name(build_label, task_id)

        # -------------------------------------
        # Parse the reports for this task
        # -------------------------------------

        resource_file = f'{build_dir}/{task_step}/{task_dst}/rpts/{task_name}/.{task_name}.lynx_task'

        rval = {}

        f = open(resource_file, 'r')
        lines = f.readlines()
        f.close()

        line_number = 0
        for line in lines:
            line_number += 1
            for name in metricInfoObj.display_name_list():
                match = re.match(f'^{name}\|(.+)$', line)
                if match:
                    rval[name] = match.group(1)
                    rval[f'{name},line'] = line_number

        # -------------------------------------
        # Stuff results into reportMetrics
        # -------------------------------------

        for name in metricInfoObj.display_name_list():
            if name in rval:
                key = f'{build_label},{task_id},{name}'
                data = rval[name]
                link = f'{resource_file}:{str(rval[f"{name},line"])}'
                metricInfoObj.metric_add(key, data, link)

    if garg.debug:
        for name in metricInfoObj.display_name_list():
            display = metricInfoObj.display_name_get(name)
            print(f'DEBUG: {name} | {display}')


def create_final_report():

    template_dir = f'{configObj.script_dir()}/compare_template/'
    data_dir     = f'{configObj.script_dir()}/gen_resource_compare.data'

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

        for task_id in buildInfoObj.get_all_task_id(build_label):
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
