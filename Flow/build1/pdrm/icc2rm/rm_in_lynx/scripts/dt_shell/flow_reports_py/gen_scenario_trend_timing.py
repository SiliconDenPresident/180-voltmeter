#! /usr/bin/env python3
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

import argparse
import os
import util

from report_parsers import ReportQor


def parseArgs():

    parser = argparse.ArgumentParser(
        description='Example Design Tracker Report'
    )

    parser.add_argument('-config_list', dest='config_list', required=False, help='List specifying builds')
    parser.add_argument('-config_file', dest='config_file', required=False, help='File specifying builds')
    parser.add_argument('-report_file', dest='report_file', required=False, help='Report file to create')
    parser.add_argument('-message',     dest='message',     action='store_true', help='')
    parser.add_argument('-trend',       dest='trend',       action='store_true', help='')
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
    reports.append('report_qor')

    buildInfoObj.init(build_label, build_dir, reports)

    if garg.debug:
        buildInfoObj.debug(build_label, build_dir)

    # --------------------------------------
    # Gather metrics for each task
    # --------------------------------------

    metricInfoObj.display_name_add('setup,logic_levels', 'Levels of Logic')
    metricInfoObj.display_name_add('setup,path_length',  'Critical Path Length')
    metricInfoObj.display_name_add('setup,path_slack',   'Critical Path Slack')
    metricInfoObj.display_name_add('setup,path_period',  'Critical Path Clk Period')
    metricInfoObj.display_name_add('setup,tns',          'Total Negative Slack')
    metricInfoObj.display_name_add('setup,nvp',          'No. of Violating Paths')
    metricInfoObj.display_name_add('hold,path_slack',    'Worst Hold Violation')
    metricInfoObj.display_name_add('hold,tns',           'Total Hold Violation')
    metricInfoObj.display_name_add('hold,nvp',           'No. of Hold Violations')

    misc['scenario_name_list'] = []

    for task_id in buildInfoObj.get_rpt_task_id(build_label):
        task_step        = buildInfoObj.get_task_step(build_label, task_id)
        task_dst         = buildInfoObj.get_task_dst(build_label, task_id)
        task_tool        = buildInfoObj.get_task_tool(build_label, task_id)
        task_report_list = buildInfoObj.get_task_report_list(build_label, task_id)

        # -------------------------------------
        # Parse the reports for this task
        # -------------------------------------

        qor_dict = {}

        qor_file = task_report_list[0]

        parser = ReportQor.ReportQor()
        parser.set_synopsys_program_name(task_tool)
        parser.set_file(qor_file)
        parser.parse()
        qor_dict = parser.get_metrics()

        # Only include task if there are results

        if len(qor_dict['path_group_data,scenario_name_list']) == 0:
            buildInfoObj.delete_task_id(build_label, task_id)
            continue

        # -------------------------------------
        # Stuff results into metricInfoObj
        # -------------------------------------

        for scenario_name in qor_dict['path_group_data,scenario_name_list']:
            misc['scenario_name_list'].append(scenario_name)
            for path_group_name in qor_dict[f'path_group_data,path_group_name_list,{scenario_name}']:
                pgnlbs_key = f'path_group_name_list_by_scenario_name,{scenario_name}'
                if pgnlbs_key not in misc:
                    misc[pgnlbs_key] = []
                misc[pgnlbs_key].append(path_group_name)
                for name in metricInfoObj.display_name_list():
                    dict_key = f'path_group_data,{scenario_name},{path_group_name},{name}'
                    data = qor_dict[dict_key]
                    dict_key = f'path_group_data,{scenario_name},{path_group_name},{name},line_number'
                    line = qor_dict[dict_key]
                    key = f'{build_label},{task_id},{scenario_name},{path_group_name},{name}'
                    link = link = f'{qor_file}:{line}'
                    metricInfoObj.metric_add(key, data, link)

    misc['scenario_name_list'] = sorted( set(misc['scenario_name_list']) )

    for scenario_name in misc['scenario_name_list']:
        misc[f'path_group_name_list_by_scenario_name,{scenario_name}'] = sorted( set(misc[f'path_group_name_list_by_scenario_name,{scenario_name}']) )


def attrColor( name, value ):

    grp1 = ['setup,path_slack', 'setup,tns']
    grp2 = ['setup,nvp']
    grp3 = ['hold,path_slack', 'hold,tns']
    grp4 = ['hold,nvp']

    attr = ''

    if name in grp1:
        if (value != '') and (float(value) < 0):
            attr = '#ffffff:#ff0000'
    elif name in grp2:
        if (value != '') and (float(value) > 0):
            attr = '#ffffff:#ff0000'
    elif name in grp3:
        if (value != '') and (float(value) < 0):
            attr = '#ffffff:#ff00ff'
    elif name in grp4:
        if (value != '') and (float(value) > 0):
            attr = '#ffffff:#ff00ff'

    return attr


def create_final_report():

    file_obj = open(configObj.report_file, 'w')

    # --------------------------------------
    # This code only here to set build_label
    # --------------------------------------

    build_label_list = []
    for build_item in configObj.get_build_item_list():
        build_label, build_dir = build_item
        build_label_list.append(build_label)

    hasSingleBlock = (len(build_label_list) == 1)

    if garg.trend:
        tableStyle = 'TrendFocus'
    else:
        tableStyle = 'TaskFocus'

    # --------------------------------------
    # Print the LYNX_BEGIN statement
    # --------------------------------------

    file_obj.write(f'LYNX_BEGIN|lynx_table_merge|my_table_merge\n\n')

    file_obj.write(f'TABLE_ID_FORMAT|Scenario\n\n')

    line = f'CELL_ID_LIST'
    for name in metricInfoObj.display_name_list():
        line += f'|{metricInfoObj.display_name_get(name)}'
    file_obj.write(f'{line}\n\n')

    for scenario_name in misc['scenario_name_list']:

        # --------------------------------------
        # Print the TABLE_BEGIN statement
        # --------------------------------------

        file_obj.write(f'TABLE_BEGIN\n\n')

        file_obj.write(f'TABLE_ID|{scenario_name}\n\n')

        color_array = {}
        color_array['white|darkBlue']  = '#ffffff:#000099'
        color_array['white|lightBlue'] = '#ffffff:#3333ff'
        color_array['white|darkGray']  = '#ffffff:#303030'

        for name in metricInfoObj.display_name_list():

            attr_lines = []
            link_lines = []

            # --------------------------------------
            # Print the DATA section
            # --------------------------------------

            file_obj.write(f'DATA_BEGIN\n')

            file_obj.write(f'CELL_ID|{metricInfoObj.display_name_get(name)}\n')

            # --------------------------------------
            # Print the HEADER lines
            # While doing this, also:
            # Create information for ATTR section (create $attr_lines, which is output later)
            # Create information for LINK section (create $link_lines, which is output later)
            # --------------------------------------

            if tableStyle == 'TaskFocus':

                # Tasks across top (and builds if multi-build), PathGroups down left
                # Row 0: task_step
                # Row 1: task_dst
                # Row 2: task_name
                # Row 3: build_label (if multi-build)

                # Single frozen col for PathGroups
                file_obj.write(f'HEADER_COLS|1\n')

                if hasSingleBlock == True:
                    ## step, dst, task
                    headerRows = 3
                else:
                    ## step, dst, task, build
                    headerRows = 4

                for row in range(0, headerRows):

                    data_line = f'HEADER|Path Groups'
                    attr_line = f'HEADER|{color_array["white|darkBlue"]}'
                    link_line = f'HEADER|'

                    for task_id in buildInfoObj.get_rpt_task_id(build_label):
                        task_step = buildInfoObj.get_task_step(build_label, task_id)
                        task_dst  = buildInfoObj.get_task_dst(build_label, task_id)
                        task_name = buildInfoObj.get_task_name(build_label, task_id)

                        for build_label in build_label_list:
                            if row == 0:
                                data_line += f'|{task_step}'
                                attr_line += f'|{color_array["white|lightBlue"]}'
                                link_line += f'|'
                            elif row == 1:
                                data_line += f'|{task_dst}'
                                attr_line += f'|{color_array["white|lightBlue"]}'
                                link_line += f'|'
                            elif row == 2:
                                data_line += f'|{task_name}'
                                attr_line += f'|{color_array["white|lightBlue"]}'
                                link_line += f'|'
                            elif row == 3:
                                data_line += f'|{build_label}'
                                attr_line += f'|{color_array["white|lightBlue"]}'
                                link_line += f'|'

                    file_obj.write(f'{data_line}\n')
                    attr_lines.append(attr_line)
                    link_lines.append(link_line)

            else:

                # PathGroups across top (and builds if multi-build), Tasks down left
                # Row 0: path_group
                # Row 1: build_label (if multi-build)

                # Three frozen col for Tasks (step/dst/task)
                file_obj.write(f'HEADER_COLS|3\n')

                if hasSingleBlock is True:
                    # path_group
                    headerRows = 1
                else:
                    # path_group, build
                    headerRows = 2

                for row in range(0, headerRows):
                    data_line = f'HEADER|Step|Dst|Task'
                    attr_line = f'HEADER|{color_array["white|darkBlue"]}|{color_array["white|darkBlue"]}|{color_array["white|darkBlue"]}'
                    link_line = f'HEADER|||'

                for path_group_name in misc[f'path_group_name_list_by_scenario_name,{scenario_name}']:
                    for build_label in build_label_list:
                        if row == 0:
                            data_line += f'|{path_group_name}'
                            attr_line += f'|{color_array["white|lightBlue"]}'
                            link_line += f'|'
                        elif row == 1:
                            data_line += f'|{task_dst}'
                            attr_line += f'|{color_array["white|lightBlue"]}'
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

                # Tasks across top (and builds if multi-build), PathGroups down left

                for path_group_name in misc[f'path_group_name_list_by_scenario_name,{scenario_name}']:

                    data_line = f'VALUE|{path_group_name}'
                    attr_line = f'VALUE|{color_array["white|darkGray"]}'
                    link_line = f'VALUE|'

                    for task_id in buildInfoObj.get_rpt_task_id(build_label):
                        task_step = buildInfoObj.get_task_step(build_label, task_id)
                        task_dst  = buildInfoObj.get_task_dst(build_label, task_id)
                        task_name = buildInfoObj.get_task_name(build_label, task_id)

                        for build_label in build_label_list:
                            key = f'{build_label},{task_id},{scenario_name},{path_group_name},{name}'
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

                # PathGroups across top (and builds if multi-build), Tasks down left

                for task_id in buildInfoObj.get_rpt_task_id(build_label):
                    task_step = buildInfoObj.get_task_step(build_label, task_id)
                    task_dst  = buildInfoObj.get_task_dst(build_label, task_id)
                    task_name = buildInfoObj.get_task_name(build_label, task_id)

                    data_line = f'VALUE|{task_step}|{task_dst}|{task_name}'
                    attr_line = f'VALUE|{color_array["white|darkGray"]}|{color_array["white|darkGray"]}|{color_array["white|darkGray"]}'
                    link_line = f'VALUE|||'

                    for path_group_name in misc[f'path_group_name_list_by_scenario_name,{scenario_name}']:
                        for build_label in build_label_list:
                            key = f'{build_label},{task_id},{scenario_name},{path_group_name},{name}'
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
            file_obj.write(f'CELL_ID|{metricInfoObj.display_name_get(name)}\n')
            for attr_line in attr_lines:
                file_obj.write(f'{attr_line}\n')
            file_obj.write(f'ATTR_END\n\n')

            # --------------------------------------
            # Print the LINK section
            # --------------------------------------

            file_obj.write(f'LINK_BEGIN\n')
            file_obj.write(f'CELL_ID|{metricInfoObj.display_name_get(name)}\n')
            for link_line in link_lines:
                file_obj.write(f'{link_line}\n')
            file_obj.write(f'LINK_END\n\n')

        # --------------------------------------
        # Print the FORMAT section
        # --------------------------------------

        # --------------------------------------
        # Create the title information
        # --------------------------------------

        title = f'Scenario Trend Timing ({tableStyle}) : {scenario_name}'

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

    file_obj.write(f'LYNX_END\n')

    file_obj.close()


# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------

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
