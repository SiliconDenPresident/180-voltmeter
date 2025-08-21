#! /usr/bin/env python3
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

import argparse
import os
import glob
import util

from report_parsers import ReportQor
from report_parsers import ReportUtilization


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

    qor_dict = {}
    phy_dict = {}
    progress_step = None
    progress_dst  = None

    fileNameList = glob.glob(f'{build_dir}/*/*/rpts/*/icc2.report_qor')

    if len(fileNameList) > 0:

        latest_mtime = -1
        for fileName in fileNameList:
            mtime = os.path.getmtime(fileName)
            if mtime > latest_mtime:
                latest_mtime = mtime
                qor_file = fileName

        phy_file = f'{util.file_rootname(qor_file)}.report_utilization'

        tool_name = 'icc2_shell'

        if util.file_isfile(qor_file):
            parser = ReportQor.ReportQor()
            parser.set_synopsys_program_name(tool_name)
            parser.set_file(qor_file)
            parser.parse()
            qor_dict = parser.get_metrics()

            pieces = qor_file.split('/')
            progress_step = pieces[len(pieces) - 5]
            progress_dst  = pieces[len(pieces) - 4]

        if util.file_isfile(phy_file):
            parser = ReportUtilization.ReportUtilization()
            parser.set_synopsys_program_name(tool_name)
            parser.set_file(phy_file)
            parser.parse()
            phy_dict = parser.get_metrics()

    # --------------------------------------
    # Stuff results into metricInfoObj
    # --------------------------------------

    index = 'User'
    key = f'{build_label},{index}'
    pieces = build_dir.split('/')
    data = pieces[len(pieces) - 3]
    link = ''
    metricInfoObj.metric_add(key, data, link)

    index = 'Tag'
    key = f'{build_label},{index}'
    pieces = build_dir.split('/')
    data = pieces[len(pieces) - 2]
    link = ''
    metricInfoObj.metric_add(key, data, link)

    index = 'Snapshot'
    key = f'{build_label},{index}'
    pieces = build_dir.split('/')
    data = pieces[len(pieces) - 1]
    link = ''
    metricInfoObj.metric_add(key, data, link)

    index = 'Progress Step'
    key = f'{build_label},{index}'
    data = progress_step
    link = ''
    metricInfoObj.metric_add(key, data, link)

    index = 'Progress Dst'
    key = f'{build_label},{index}'
    data = progress_dst
    link = ''
    metricInfoObj.metric_add(key, data, link)

    index = 'Setup WNS'
    key = f'{build_label},{index}'
    dict_key = 'summary_data,_ms,setup,path_slack'
    if dict_key in qor_dict:
        data = util.format_value('{0:.2f}', qor_dict[dict_key])
        line = qor_dict[f'{dict_key},line_number']
        link = f'{qor_file}:{line}'
        metricInfoObj.metric_add(key, data, link)

    index = 'Setup TNS'
    key = f'{build_label},{index}'
    dict_key = 'summary_data,_ms,setup,tns'
    if dict_key in qor_dict:
        data = "{0:.2f}".format(float(qor_dict[dict_key]))
        line = qor_dict[f'{dict_key},line_number']
        link = f'{qor_file}:{line}'
        metricInfoObj.metric_add(key, data, link)

    index = 'Setup NVP'
    key = f'{build_label},{index}'
    dict_key = 'summary_data,_ms,setup,nvp'
    if dict_key in qor_dict:
        data = qor_dict[dict_key]
        line = qor_dict[f'{dict_key},line_number']
        link = f'{qor_file}:{line}'
        metricInfoObj.metric_add(key, data, link)

    index = 'Hold WNS'
    key = f'{build_label},{index}'
    dict_key = 'summary_data,_ms,hold,path_slack'
    if dict_key in qor_dict:
        data = util.format_value('{0:.2f}', qor_dict[dict_key])
        line = qor_dict[f'{dict_key},line_number']
        link = f'{qor_file}:{line}'
        metricInfoObj.metric_add(key, data, link)

    index = 'Hold TNS'
    key = f'{build_label},{index}'
    dict_key = 'summary_data,_ms,hold,tns'
    if dict_key in qor_dict:
        data = "{0:.2f}".format(float(qor_dict[dict_key]))
        line = qor_dict[f'{dict_key},line_number']
        link = f'{qor_file}:{line}'
        metricInfoObj.metric_add(key, data, link)

    index = 'Hold NVP'
    key = f'{build_label},{index}'
    dict_key = 'summary_data,_ms,hold,nvp'
    if dict_key in qor_dict:
        data = qor_dict[dict_key]
        line = qor_dict[f'{dict_key},line_number']
        link = f'{qor_file}:{line}'
        metricInfoObj.metric_add(key, data, link)

    index = 'Area'
    key = f'{build_label},{index}'
    dict_key = 'design_data,design_area'
    if dict_key in qor_dict:
        data = "{0:.0f}".format(float(qor_dict[dict_key]))
        line = qor_dict[f'{dict_key},line_number']
        link = f'{qor_file}:{line}'
        metricInfoObj.metric_add(key, data, link)

    index = 'Cell Count'
    key = f'{build_label},{index}'
    dict_key = 'design_data,leaf_cell_count'
    if dict_key in qor_dict:
        data = qor_dict[dict_key]
        line = qor_dict[f'{dict_key},line_number']
        link = f'{qor_file}:{line}'
        metricInfoObj.metric_add(key, data, link)

    index = 'Flop Count'
    key = f'{build_label},{index}'
    dict_key = 'design_data,seq_cell_count'
    if dict_key in qor_dict:
        data = qor_dict[dict_key]
        line = qor_dict[f'{dict_key},line_number']
        link = f'{qor_file}:{line}'
        metricInfoObj.metric_add(key, data, link)

    index = 'Utilization'
    key = f'{build_label},{index}'
    dict_key = 'cell2core_ratio'
    if dict_key in phy_dict:
        data = phy_dict[dict_key]
        line = phy_dict[f'{dict_key},line_number']
        link = f'{phy_file}:{line}'
        metricInfoObj.metric_add(key, data, link)


def headerColor(name):

    color = {}
    color["white"]     = '#ffffff'
    color["black"]     = '#000000'
    color["red"]       = '#f7384a'
    color["green"]     = '#00ff00'
    color["blue"]      = '#29516d'
    color["yellow"]    = '#daf959'
    color["brown_2"]   = '#695538'
    color["brown_1"]   = '#d7c7b1'
    color["brown_0"]   = '#fff6e8'
    color["green_3"]   = '#25463b'
    color["green_2"]   = '#3f6156'
    color["green_1"]   = '#768f87'
    color["green_0"]   = '#9eaea9'
    color["gray"]      = '#e0e0e0'
    color["darkblue"]  = '#000099'
    color["lightblue"] = '#3333ff'

    color_h_first   = f'{color["white"]}:{color["darkblue"]}'
    color_h_other   = f'{color["white"]}:{color["lightblue"]}'
    color_r_first   = f'{color["black"]}:{color["gray"]}'
    color_r_normal  = f'{color["black"]}:{color["white"]}'
    color_r_warning = f'{color["black"]}:{color["yellow"]}'
    color_r_error   = f'{color["black"]}:{color["red"]}'
    color_r_undef   = f'{color["white"]}:{color["lightblue"]}'

    set1 = ['Tag', 'Area', 'Cell Count']
    set2 = ['User', 'Snapshot', 'Utilization', 'Flop Count']
    set3 = ['Progress Step', 'Setup NVP', 'Setup WNS', 'Hold TNS']
    set4 = ['Progress Dst', 'Setup TNS', 'Hold NVP', 'Hold WNS']
    set5 = ['Lineage']
    set6 = ['Progress']
    set7 = ['Content']
    set8 = ['Timing', 'Setup', 'Hold']
    set9 = ['Design Name']

    if name in set1:
        attr = f'{color["black"]}:{color["brown_1"]}'
    elif name in set2:
        attr = f'{color["black"]}:{color["brown_0"]}'
    elif name in set3:
        attr = f'{color["black"]}:{color["green_1"]}'
    elif name in set4:
        attr = f'{color["black"]}:{color["green_0"]}'
    elif name in set5:
        attr = f'{color["white"]}:{color["brown_2"]}'
    elif name in set6:
        attr = f'{color["white"]}:{color["green_3"]}'
    elif name in set7:
        attr = f'{color["white"]}:{color["brown_2"]}'
    elif name in set8:
        attr = f'{color["white"]}:{color["green_2"]}'
    elif name in set9:
        attr = f'{color["black"]}:{color["brown_1"]}'
    else:
        attr = f'{color["white"]}:{color["red"]}'

    return attr


def attrColor(name, value):

    color = {}
    color["white"]     = '#ffffff'
    color["black"]     = '#000000'
    color["red"]       = '#f7384a'
    color["green"]     = '#00ff00'
    color["blue"]      = '#29516d'
    color["yellow"]    = '#daf959'
    color["brown_2"]   = '#695538'
    color["brown_1"]   = '#d7c7b1'
    color["brown_0"]   = '#fff6e8'
    color["green_3"]   = '#25463b'
    color["green_2"]   = '#3f6156'
    color["green_1"]   = '#768f87'
    color["green_0"]   = '#9eaea9'
    color["gray"]      = '#e0e0e0'
    color["darkblue"]  = '#000099'
    color["lightblue"] = '#3333ff'

    color_h_first   = f'{color["white"]}:{color["darkblue"]}'
    color_h_other   = f'{color["white"]}:{color["lightblue"]}'
    color_r_first   = f'{color["black"]}:{color["gray"]}'
    color_r_normal  = f'{color["black"]}:{color["white"]}'
    color_r_warning = f'{color["black"]}:{color["yellow"]}'
    color_r_error   = f'{color["black"]}:{color["red"]}'
    color_r_undef   = f'{color["white"]}:{color["lightblue"]}'

    set1 = ['Progress Step', 'Progress Dst']
    set2 = ['Setup NVP', 'Hold NVP']
    set3 = ['Setup TNS', 'Setup WNS', 'Hold TNS', 'Hold WNS']
    set4 = ['Utilization']
    set5 = ['build_label']

    attr = ''

    if name in set1:
        if value == 'undefined':
            attr = color_r_undef
    elif name in set2:
        if util.is_number(value):
            if int(value) > 0:
                attr = color_r_error
    elif name in set3:
        if util.is_number(value):
            if float(value) < 0:
                attr = color_r_error
    elif name in set4:
        if util.is_number(value):
            if float(value) > 60:
                attr = color_r_warning
    elif name in set5:
        attr = color_r_first

    return attr


def create_final_report():

    attr_lines = []
    link_lines = []

    item_list = [
        'User',
        'Tag',
        'Snapshot',
        'Progress Step',
        'Progress Dst',
        'Area',
        'Utilization',
        'Cell Count',
        'Flop Count',
        'Setup NVP',
        'Setup TNS',
        'Setup WNS',
        'Hold NVP',
        'Hold TNS',
        'Hold WNS'
    ]

    file_obj = open(configObj.report_file, 'w')

    # --------------------------------------
    # Print the LYNX_BEGIN statement
    # --------------------------------------

    file_obj.write(f'LYNX_BEGIN|lynx_table_merge|my_table_merge\n\n')

    # --------------------------------------
    # Print the TABLE_BEGIN statement
    # --------------------------------------

    file_obj.write(f'TABLE_BEGIN\n\n')

    # --------------------------------------
    # Print the DATA section
    # --------------------------------------

    file_obj.write(f'DATA_BEGIN\n')

    # --------------------------------------
    # Print the HEADER lines
    # While doing this, also:
    # Create information for ATTR section (create $attr_lines, which is output later)
    # Create information for LINK section (create $link_lines, which is output later)
    # --------------------------------------

    # --------------------------------------
    # Print the HEADER lines (merge style)
    # --------------------------------------

    # Line #1

    data_line = 'HEADER'
    data_line += (f'|Lineage' * 4)
    data_line += (f'|Progress' * 2)
    data_line += (f'|Content' * 4)
    data_line += (f'|Timing' * 6)

    attr_line = 'HEADER'
    attr_line += (f'|{headerColor("Lineage")}' * 4)
    attr_line += (f'|{headerColor("Progress")}' * 2)
    attr_line += (f'|{headerColor("Content")}' * 4)
    attr_line += (f'|{headerColor("Timing")}' * 6)

    link_line = 'HEADER'
    link_line += (f'|' * 4)
    link_line += (f'|' * 2)
    link_line += (f'|' * 4)
    link_line += (f'|' * 6)

    file_obj.write(f'{data_line}\n')
    attr_lines.append(attr_line)
    link_lines.append(link_line)

    # Line #2
    data_line = 'HEADER'
    data_line += (f'|Lineage' * 4)
    data_line += (f'|Progress' * 2)
    data_line += (f'|Content' * 4)
    data_line += (f'|Setup' * 3)
    data_line += (f'|Hold' * 3)

    attr_line = 'HEADER'
    attr_line += (f'|{headerColor("Lineage")}' * 4)
    attr_line += (f'|{headerColor("Progress")}' * 2)
    attr_line += (f'|{headerColor("Content")}' * 4)
    attr_line += (f'|{headerColor("Setup")}' * 3)
    attr_line += (f'|{headerColor("Hold")}' * 3)

    link_line = 'HEADER'
    link_line += (f'|' * 4)
    link_line += (f'|' * 2)
    link_line += (f'|' * 4)
    link_line += (f'|' * 3)
    link_line += (f'|' * 3)

    file_obj.write(f'{data_line}\n')
    attr_lines.append(attr_line)
    link_lines.append(link_line)

    # Line #3

    data_line = 'HEADER'
    attr_line = 'HEADER'
    link_line = 'HEADER'

    data_line += f'|Design Name'
    attr_line += f'|{headerColor("Design Name")}'
    link_line += f'|'

    for item in item_list:
        data_line += f'|{item}'
        attr_line += f'|{headerColor(item)}'
        link_line += f'|'

    file_obj.write(f'{data_line}\n')
    attr_lines.append(attr_line)
    link_lines.append(link_line)

    # --------------------------------------
    # Print the VALUE lines
    # While doing this, also:
    # Create information for ATTR section (create $color_lines, which is output later)
    # Create information for LINK section (create $link_lines, which is output later)
    # --------------------------------------

    list1 = ['Progress Step', 'Progress Dst']
    list2 = ['Setup NVP', 'Hold NVP']
    list3 = ['Setup TNS', 'Setup WNS', 'Hold TNS', 'Hold WNS']
    list4 = ['Utilization']

    for build_item in configObj.get_build_item_list():
        build_label, build_dir = build_item

        data_line = f'VALUE|{build_label}'
        link_line = f'VALUE|'
        attr_line = f'VALUE|{attrColor("build_label", "")}'

        for item in item_list:

            key = f'{build_label},{item}'

            if metricInfoObj.metric_exists(key):
                data = metricInfoObj.metric_get_data(key)
                link = metricInfoObj.metric_get_link(key)
                attr = attrColor(item, data)
            else:
                print(f'X: {key}')
                data = ''
                link  = ''
                attr = ''

            data_line += f'|{data}'
            link_line += f'|{link}'
            attr_line += f'|{attr}'

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

    title = f"Project 'Lynx' Status Report"
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
