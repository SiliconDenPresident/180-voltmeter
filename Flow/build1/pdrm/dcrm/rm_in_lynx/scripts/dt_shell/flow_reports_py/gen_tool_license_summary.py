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
    parser.add_argument('-message',     dest='message',     action='store_true', help='')
    parser.add_argument('-debug',       dest='debug',       action='store_true', help='')

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
    metricInfoObj.display_name_add('License',        'License')
    metricInfoObj.display_name_add('Cores',          'Cores')
    metricInfoObj.display_name_add('Wall Time',      'Wall Time')
    metricInfoObj.display_name_add('CPU Time',       'CPU Time')
    metricInfoObj.display_name_add('CPU Efficiency', 'CPU Efficiency')
    metricInfoObj.display_name_add('Mem',            'Mem')

    for task_id in buildInfoObj.get_all_task_id(build_label):
        task_step = buildInfoObj.get_task_step(build_label, task_id)
        task_dst  = buildInfoObj.get_task_dst(build_label, task_id)
        task_name = buildInfoObj.get_task_name(build_label, task_id)

        # --------------------------------------
        # Parse the reports for this task
        # --------------------------------------

        resource_file = f'{build_dir}/{task_step}/{task_dst}/rpts/{task_name}/.{task_name}.lynx_task'

        rval = {}

        f = open(resource_file, 'r')
        lines = f.readlines()
        f.close()

        tool_name    = 'undefined'
        tool_version = ''
        license_list = []

        for line in lines:
            match = re.match('^Tool\|(.*)', line)
            if match:
                tool_name = match.group(1)
            match = re.match('^Version\|(.*)', line)
            if match:
                tool_version = match.group(1)
            match = re.match('^License\|(.*)', line)
            if match:
                license_list = match.group(1).split()

        # --------------------------------------
        # Stuff results into misc
        # --------------------------------------

        if f'tool_name_list' not in misc:
            misc[f'tool_name_list'] = []

        if tool_name not in misc['tool_name_list']:
            misc[f'tool_name_list'].append(tool_name)
            misc[f'count,{tool_name}'] = 0
            misc[f'tool_version_list,{tool_name}'] = []

        misc[f'count,{tool_name}'] += 1

        if tool_version not in misc[f'tool_version_list,{tool_name}']:
            misc[f'tool_version_list,{tool_name}'].append(tool_version)
            misc[f'count,{tool_name},{tool_version}'] = 0
            misc[f'license_list,{tool_name},{tool_version}'] = []

        misc[f'count,{tool_name},{tool_version}'] += 1

        for license in license_list:
            if license not in misc[f'license_list,{tool_name},{tool_version}']:
                misc[f'license_list,{tool_name},{tool_version}'].append(license)
                misc[f'count,{tool_name},{tool_version},{license}'] = 0

            misc[f'count,{tool_name},{tool_version},{license}'] += 1

    # --------------------------------------
    # Sort results
    # --------------------------------------

    misc['tool_name_list'] = sorted( misc['tool_name_list'] )

    for tool_name in misc['tool_name_list']:
        misc[f'tool_version_list,{tool_name}'] = sorted( misc[f'tool_version_list,{tool_name}'] )
        for tool_version in misc[f'tool_version_list,{tool_name}']:
            misc[f'license_list,{tool_name},{tool_version}'] = sorted( misc[f'license_list,{tool_name},{tool_version}'] )


def create_final_report():

    file_obj = open(configObj.report_file, 'w')

    # --------------------------------------
    # Print the LYNX_BEGIN statement
    # --------------------------------------

    file_obj.write(f'LYNX_BEGIN|lynx_table_merge|license_report\n\n')

    # --------------------------------------
    # Print the TABLE_BEGIN statement
    # --------------------------------------

    file_obj.write(f'TABLE_BEGIN\n\n')

    # --------------------------------------
    # Print the DATA section
    # --------------------------------------

    attr_lines = []

    rowHeader = '#ffffff:#3333ff:L'
    rowValue  = '#000000:#ffffff:A'

    file_obj.write(f'DATA_BEGIN\n\n')

    file_obj.write(f'HEADER|Tool Name|Tool version|License Feature|Number of Invocations\n')
    attr_lines.append(f'HEADER|{rowHeader}|{rowHeader}|{rowHeader}|{rowHeader}')

    for tool_name in misc['tool_name_list']:
        count = misc[f'count,{tool_name}']
        file_obj.write(f'VALUE|{tool_name}|||{count}\n')
        attr_lines.append(f'VALUE|{rowValue}|{rowValue}|{rowValue}|{rowValue}')
        for tool_version in misc[f'tool_version_list,{tool_name}']:
            count = misc[f'count,{tool_name},{tool_version}']
            file_obj.write(f'VALUE||{tool_version}||{count}\n')
            attr_lines.append(f'VALUE|{rowValue}|{rowValue}|{rowValue}|{rowValue}')
            for license in misc[f'license_list,{tool_name},{tool_version}']:
                count = misc[f'count,{tool_name},{tool_version},{license}']
                file_obj.write(f'VALUE|||{license}|{count}\n')
                attr_lines.append(f'VALUE|{rowValue}|{rowValue}|{rowValue}|{rowValue}')

    file_obj.write(f'DATA_END\n\n')

    # --------------------------------------
    # Print the ATTR section
    # --------------------------------------

    file_obj.write(f'ATTR_BEGIN\n')
    for attr_line in attr_lines:
        file_obj.write(f'{attr_line}\n')
    file_obj.write(f'ATTR_END\n\n')

    # --------------------------------------
    # Print the FORMAT section
    # --------------------------------------

    # --------------------------------------
    # Create the title information
    # --------------------------------------

    title = f'Tool License Report Summary'
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
