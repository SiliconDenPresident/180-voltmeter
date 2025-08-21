#! /usr/bin/env python3
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

import argparse
import os
import re
import util


def parseArgs():

    parser = argparse.ArgumentParser(
        description='Example Design Tracker Report'
    )

    parser.add_argument('-config_list', dest='config_list', required=False, help='List specifying builds')
    parser.add_argument('-config_file', dest='config_file', required=False, help='File specifying builds')
    parser.add_argument('-report_file', dest='report_file', required=False, help='Report file to create')
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


def attrColor(name, value):
    attr = ''
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

    attr_array = {}
    attr_array['rowHeader1'] = '#ffffff:#000099:L'
    attr_array['rowHeader2'] = '#ffffff:#3333ff:C'
    attr_array['colHeader1'] = '#ffffff:#303030:L'

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

        file_obj.write(f'DATA_BEGIN\n')

        # --------------------------------------
        # Print the HEADER lines
        # While doing this, also:
        # Create information for ATTR section (create $attr_lines, which is output later)
        # Create information for LINK section (create $link_lines, which is output later)
        # --------------------------------------

        if tableStyle == 'TaskFocus':

            # Tasks across top (and builds if multi-build), Metrics down left
            # Print 3 row headers
            # Row 0: task_step
            # Row 1: task_dst
            # Row 2: task_name
            # Row 3: build_label (if multi-build)

            # Single frozen col for metrics
            file_obj.write(f'HEADER_COLS|1\n')

            if hasSingleBlock:
                # step, dst, task
                headerRows = 3
            else:
                # step, dst, task, build
                headerRows = 4

            for row in range(headerRows):

                data_line = 'HEADER'
                attr_line = 'HEADER'
                link_line = 'HEADER'

                data_line += f'|Metric'
                attr_line += f'|{attr_array["rowHeader1"]}'
                link_line += f'|'

                for task_id in buildInfoObj.get_all_task_id(build_label):
                    task_step = buildInfoObj.get_task_step(build_label, task_id)
                    task_dst  = buildInfoObj.get_task_dst(build_label, task_id)
                    task_name = buildInfoObj.get_task_name(build_label, task_id)

                    for build_label in build_label_list:
                        if row == 0:
                            data_line += f'|{task_step}'
                            attr_line += f'|{attr_array["rowHeader2"]}'
                            link_line += f'|'
                        if row == 1:
                            data_line += f'|{task_dst}'
                            attr_line += f'|{attr_array["rowHeader2"]}'
                            link_line += f'|'
                        if row == 2:
                            data_line += f'|{task_name}'
                            attr_line += f'|{attr_array["rowHeader2"]}'
                            link_line += f'|'
                        if row == 3:
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

                # Row 1

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

                for task_id in buildInfoObj.get_all_task_id(build_label):
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

                        data_line += f'|{data}'
                        attr_line += f'|{attr}'
                        link_line += f'|{link}'

                file_obj.write(f'{data_line}\n')
                attr_lines.append(attr_line)
                link_lines.append(link_line)

        else:

            for task_id in buildInfoObj.get_all_task_id(build_label):
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

                        data_line += f'|{data}'
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

        title = f'Resource Summary ({tableStyle}) : '

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
