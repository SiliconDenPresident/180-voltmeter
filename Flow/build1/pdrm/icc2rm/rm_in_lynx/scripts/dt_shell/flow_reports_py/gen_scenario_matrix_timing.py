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
    parser.add_argument('-flip',        dest='flip',        action='store_true', help='')
    parser.add_argument('-var',         dest='var',         action='store_true', help='')
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
        fileVarsObj.add_file(qor_file)

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

        misc[f'scenario_name_list,{task_id}'] = []
        misc[f'path_group_name_list,{task_id}'] = []

        for scenario_name in sorted( set(qor_dict[f'path_group_data,scenario_name_list']) ):
            misc[f'scenario_name_list,{task_id}'].append(scenario_name)
            for path_group_name in qor_dict[f'path_group_data,path_group_name_list,{scenario_name}']:
                misc[f'path_group_name_list,{task_id}'].append(path_group_name)
                for name in metricInfoObj.display_name_list():
                    dict_key = f'path_group_data,{scenario_name},{path_group_name},{name}'
                    data = qor_dict[dict_key]
                    dict_key = f'path_group_data,{scenario_name},{path_group_name},{name},line_number'
                    line = qor_dict[dict_key]
                    if garg.var:
                        link = f'$({fileVarsObj.get_var(qor_file)}):{line}'
                    else:
                        link = f'{qor_file}:{line}'
                    key = f'{build_label},{task_id},{scenario_name},{path_group_name},{name}'
                    metricInfoObj.metric_add(key, data, link)

    for task_id in buildInfoObj.get_rpt_task_id(build_label):
        misc[f'scenario_name_list,{task_id}'] = sorted( set(misc[f'scenario_name_list,{task_id}']) )
        misc[f'path_group_name_list,{task_id}'] = sorted( set(misc[f'path_group_name_list,{task_id}']) )

    if len( buildInfoObj.get_rpt_task_id(build_label) ) == 0:
        print(f'Error: No tasks identified with the required reports.')
        exit()


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

    # --------------------------------------
    # Print the LYNX_BEGIN statement
    # --------------------------------------

    file_obj.write(f'LYNX_BEGIN|lynx_table_merge|my_table_merge\n\n')

    if garg.var:
        for fileName in sorted(fileVarsObj.get_files()):
            fileVar = f'{fileVarsObj.get_var(fileName)}'
            file_obj.write(f'VARIABLE|{fileVar}|{fileName}\n')

    file_obj.write(f'TABLE_ID_FORMAT|Step|Dst|Task\n\n')

    line = f'CELL_ID_LIST'
    for name in metricInfoObj.display_name_list():
        line += f'|{metricInfoObj.display_name_get(name)}'
    file_obj.write(f'{line}\n\n')

    for task_id in buildInfoObj.get_rpt_task_id(build_label):
        task_step        = buildInfoObj.get_task_step(build_label, task_id)
        task_dst         = buildInfoObj.get_task_dst(build_label, task_id)
        task_name        = buildInfoObj.get_task_name(build_label, task_id)

        # --------------------------------------
        # Print the TABLE_BEGIN statement
        # --------------------------------------

        file_obj.write(f'TABLE_BEGIN\n\n')

        file_obj.write(f'TABLE_ID|{task_step}|{task_dst}|{task_name}\n\n')

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

            if garg.flip:

                # Print 1 row header
                # In row 1, use path_group

                file_obj.write(f'HEADER_COLS|1\n')

                data_line = f'HEADER|Scenario'
                attr_line = f'HEADER|{color_array["white|darkBlue"]}'
                link_line = f'HEADER|'

                for path_group_name in misc[f'path_group_name_list,{task_id}']:
                    data_line += f'|{path_group_name}'
                    attr_line += f'|{color_array["white|lightBlue"]}'
                    link_line += f'|'

                file_obj.write(f'{data_line}\n')
                attr_lines.append(attr_line)
                link_lines.append(link_line)

            else:

                # Print 3 row headers
                # In row 1, use scenario mode
                # In row 2, use scenario oc_cond
                # In row 3, use scenario rc_cond

                file_obj.write(f'HEADER_COLS|1\n')

                for row in range(1, 4):
                    data_line = f'HEADER|Path Groups'
                    attr_line = f'HEADER|{color_array["white|darkBlue"]}'
                    link_line = f'HEADER|'

                    for scenario_name in misc[f'scenario_name_list,{task_id}']:
                        if scenario_name == 'None/non-MCMM':
                            mode, op_cond, rc_cond = [scenario_name, scenario_name, scenario_name]
                        else:
                            mode, op_cond, rc_cond = scenario_name.split('.')

                        if row == 1:
                            data_line += f'|{mode}'
                        elif row == 2:
                            data_line += f'|{op_cond}'
                        else:
                            data_line += f'|{rc_cond}'

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

            if garg.flip:

                for scenario_name in misc[f'scenario_name_list,{task_id}']:

                    data_line = f'VALUE|{scenario_name}'
                    attr_line = f'VALUE|{color_array["white|darkGray"]}'
                    link_line = f'VALUE|'

                    for path_group_name in misc[f'path_group_name_list,{task_id}']:
                        key = f'{build_label},{task_id},{scenario_name},{path_group_name},{name}'
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

                for path_group_name in misc[f'path_group_name_list,{task_id}']:
                    data_line = f'VALUE|{path_group_name}'
                    attr_line = f'VALUE|{color_array["white|darkGray"]}'
                    link_line = f'VALUE|'

                    for scenario_name in misc[f'scenario_name_list,{task_id}']:
                        key = f'{build_label},{task_id},{scenario_name},{path_group_name},{name}'
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

        title = f'Scenario Matrix Timing : {build_label} : {task_id}'
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
