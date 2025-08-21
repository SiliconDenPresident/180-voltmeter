#! /usr/bin/env python3
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

import argparse
import os
import util

from report_parsers import ReportClockQor


def parseArgs():

    parser = argparse.ArgumentParser(
        description='Example Design Tracker Report'
    )

    parser.add_argument('-config_list', dest='config_list', required=False, help='List specifying builds')
    parser.add_argument('-config_file', dest='config_file', required=False, help='File specifying builds')
    parser.add_argument('-report_file', dest='report_file', required=False, help='Report file to create')
    parser.add_argument('-message',     dest='message',     action='store_true', help='')
    parser.add_argument('-flip',        dest='flip',        action='store_true', help='')
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
    reports.append('summary')

    buildInfoObj.init(build_label, build_dir, reports)

    if garg.debug:
        buildInfoObj.debug(build_label, build_dir)

    # --------------------------------------
    # Gather metrics for each task
    # --------------------------------------

    metricInfoObj.display_name_add('Sinks',                'Sinks' )
    metricInfoObj.display_name_add('Levels',               'Levels' )
    metricInfoObj.display_name_add('Clock_Repeater_Count', 'Clock Repeater Count' )
    metricInfoObj.display_name_add('Clock_Repeater_Area',  'Clock Repeater Area' )
    metricInfoObj.display_name_add('Clock_Stdcell_Area',   'Clock Stdcell Area' )
    metricInfoObj.display_name_add('Max_Latency',          'Max Latency' )
    metricInfoObj.display_name_add('Global_Skew',          'Global Skew' )
    metricInfoObj.display_name_add('Trans_DRC_Count',      'Trans DRC Count' )
    metricInfoObj.display_name_add('Cap_DRC_Count',        'Cap DRC Count' )

    for task_id in buildInfoObj.get_rpt_task_id(build_label):
        task_step        = buildInfoObj.get_task_step(build_label, task_id)
        task_dst         = buildInfoObj.get_task_dst(build_label, task_id)
        task_tool        = buildInfoObj.get_task_tool(build_label, task_id)
        task_report_list = buildInfoObj.get_task_report_list(build_label, task_id)

        # --------------------------------------
        # Parse the reports for this task
        # --------------------------------------

        cts_dict = {}

        cts_file = task_report_list[0]

        parser = ReportClockQor.ReportClockQor()
        parser.set_synopsys_program_name(task_tool)
        parser.set_file(cts_file)
        parser.parse()
        cts_dict = parser.get_metrics()

        # Only include task if there are results

        if len(cts_dict['scenario_list'] ) == 0 or len(cts_dict['clock_list'] ) == 0:
            buildInfoObj.delete_task_id(build_label, task_id)
            continue

        # --------------------------------------
        # Stuff results into metricInfoObj
        # --------------------------------------

        misc[f'scenario_list,{task_id}'] = []
        misc[f'clock_list,{task_id}'] = []

        for scenario in cts_dict['scenario_list']:
            misc[f'scenario_list,{task_id}'].append(scenario)
            for clock in cts_dict['clock_list']:
                misc[f'clock_list,{task_id}'].append(clock)
                for name in metricInfoObj.display_name_list():
                    dict_key = f'{scenario},{clock},{name},value'
                    if dict_key in cts_dict:
                        data = cts_dict[dict_key]
                        dict_key = f'{scenario},{clock},{name},line'
                        link  = f'{cts_file}:{cts_dict[dict_key]}'
                    else:
                        data = '-'
                        link = ''
                    key = f'{build_label},{task_id},{scenario},{clock},{name}'
                    metricInfoObj.metric_add(key, data, link)

    for task_id in buildInfoObj.get_rpt_task_id(build_label):
        misc[f'scenario_list,{task_id}'] = sorted( set(misc[f'scenario_list,{task_id}']) )
        misc[f'clock_list,{task_id}'] = sorted( set(misc[f'clock_list,{task_id}']) )

    if len( buildInfoObj.get_rpt_task_id(build_label) ) == 0:
        print(f'Error: No tasks found with the required reports.')
        exit()


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

    file_obj.write(f'TABLE_ID_FORMAT|Task\n\n')

    if len( buildInfoObj.get_rpt_task_id(build_label) ) == 0:
        task_id  = f'NoTask'
        title    = f'Clock Tree Summary : {build_label} : {task_id}'
        subtitle = f'Created on {util.get_long_date()}'

        file_obj.write(f'TABLE_BEGIN\n')
        file_obj.write(f'TABLE_ID|{task_id}\n')
        file_obj.write(f'DATA_BEGIN\n')
        file_obj.write(f'HEADER|No available reports\n')
        file_obj.write(f'DATA_END\n')
        file_obj.write(f'FORMAT_BEGIN\n')
        file_obj.write(f'TITLE|{title}\n')
        file_obj.write(f'SUBTITLE|{subtitle}\n')
        file_obj.write(f'FORMAT_END\n')
        file_obj.write(f'TABLE_END\n')

    for task_id in buildInfoObj.get_rpt_task_id(build_label):
        task_step        = buildInfoObj.get_task_step(build_label, task_id)
        task_dst         = buildInfoObj.get_task_dst(build_label, task_id)
        task_name        = buildInfoObj.get_task_name(build_label, task_id)

        # --------------------------------------
        # Print the TABLE_BEGIN statement
        # --------------------------------------

        file_obj.write(f'TABLE_BEGIN\n\n')

        file_obj.write(f'TABLE_ID|{task_id}\n\n')

        color_array = {}
        color_array['white|darkBlue']  = '#ffffff:#000099'
        color_array['white|lightBlue'] = '#ffffff:#3333ff'
        color_array['white|darkGray']  = '#ffffff:#303030'

        attr_lines = []
        link_lines = []

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

        if garg.flip:

            # Print 2 row headers
            # Row 1: "Metric", then clk1 ... clk1 clkN ... clkN
            # Row 2: "Metric", then scn1 ... scnN scn1 ... scnN

            file_obj.write(f'HEADER_COLS|1\n')

            for row in range(1, 3):

                data_line = f'HEADER|Metric'
                attr_line = f'HEADER|{color_array["white|darkBlue"]}'
                link_line = f'HEADER|'

                for clock in misc[f'clock_list,{task_id}']:
                    for scenario in misc[f'scenario_list,{task_id}']:
                        if row == 1:
                            data_line += f'|{clock}'
                        else:
                            data_line += f'|{scenario}'
                        attr_line += f'|{color_array["white|lightBlue"]}'
                        link_line += f'|'

                file_obj.write(f'{data_line}\n')
                attr_lines.append(attr_line)
                link_lines.append(link_line)

        else:

            # Print 1 row header
            # Row 1: "Clock", "Scenario", then each metric

            file_obj.write(f'HEADER_COLS|2\n')

            data_line = f'HEADER|Clock|Scenario'
            attr_line = f'HEADER|{color_array["white|darkBlue"]}|{color_array["white|darkBlue"]}'
            link_line = f'HEADER||'

            for name in metricInfoObj.display_name_list():
                data_line += f'|{metricInfoObj.display_name_get(name)}'
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
            for name in metricInfoObj.display_name_list():

                data_line = f'VALUE|{metricInfoObj.display_name_get(name)}'
                attr_line = f'VALUE|{color_array["white|darkGray"]}'
                link_line = f'VALUE|'

                for clock in misc[f'clock_list,{task_id}']:
                    for scenario in misc[f'scenario_list,{task_id}']:
                        key = f'{build_label},{task_id},{scenario},{clock},{name}'
                        if metricInfoObj.metric_exists(key):
                            data = metricInfoObj.metric_get_data(key)
                            link = metricInfoObj.metric_get_link(key)
                            attr = ''
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

            for clock in misc[f'clock_list,{task_id}']:
                for scenario in misc[f'scenario_list,{task_id}']:

                    data_line = f'VALUE|{clock}|{scenario}'
                    attr_line = f'VALUE|{color_array["white|darkGray"]}|{color_array["white|darkGray"]}'
                    link_line = f'VALUE||'

                    for name in metricInfoObj.display_name_list():
                        key = f'{build_label},{task_id},{scenario},{clock},{name}'
                        if metricInfoObj.metric_exists(key):
                            data = metricInfoObj.metric_get_data(key)
                            link = metricInfoObj.metric_get_link(key)
                            attr = ''
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

        file_obj.write(f'DATA_END\n')
        file_obj.write(f'\n')

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

        title = f'Clock Tree Summary : {build_label} : {task_id}'
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
