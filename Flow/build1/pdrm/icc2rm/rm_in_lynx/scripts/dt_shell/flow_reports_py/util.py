# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------

import os
import sys
import datetime
import re
import glob
import operator

# ------------------------------------------------------------------------------
# Tcl-ish file operations
# ------------------------------------------------------------------------------

def file_dirname(name):
    return os.path.dirname(name)


def file_tail(name):
    return os.path.basename(name)


def file_rootname(name):
    return os.path.splitext(name)[0]


def file_extension(name):
    baseName = os.path.basename(name)
    return os.path.splitext(baseName)[1]


def file_normalize(name):
    return os.path.abspath(name)


def file_isfile(name):
    return os.path.isfile(name)


def file_isdirectory(name):
    return os.path.isdir(name)


def file_mkdir(name):
    if not os.path.exists(name):
        try:
            os.mkdir(name)
        except:
            pass
    if os.path.isdir(name):
        return True
    else:
        print(f'Error: Unable to mkdir: {name}')
        return False


# ------------------------------------------------------------------------------
# Misc functions
# ------------------------------------------------------------------------------

def is_number(s):
    try:
        float(s)
        return True
    except ValueError:
        return False


def format_value(formatString, potentialNumber):
    if is_number(potentialNumber):
      return formatString.format(float(potentialNumber))
    else:
      return potentialNumber


def get_user_name():
    if 'LYNX_CRON' in os.environ:
        user_name = 'CRON'
    else:
        if 'LYNX_USER' in os.environ:
            user_name = os.environ['LYNX_USER']
        else:
            user_name = os.getlogin()

    return user_name


def get_date():
    t = datetime.datetime.now()
    return t.strftime('%Y_%m_%d')


def get_long_date():
    t = datetime.datetime.now()
    captime = t.strftime('%a %b %d %I:%M:%S %Y')
    return captime


# ------------------------------------------------------------------------------
# Config
# ------------------------------------------------------------------------------

class Config():

    def __init__(self):
        super().__init__()
        self.build_item_list = []
        self.report_file = ""
        self.message_file = ""
        self.publish_dir = ""
        self.this_script = sys.argv[0]

    def script_dir(self):
        return file_dirname(self.this_script)

    def init(self, garg):

        reBlank   = re.compile('^\s*$')
        reComment = re.compile('^\s*#')

        # --------------------------------------
        # Read config_common
        # --------------------------------------

        config_common = f'{self.script_dir()}/config_common.txt'

        if not file_isfile(config_common):
            print(f'Error: Config file is missing: {config_common}')
            exit()

        try:
            f = open(config_common, 'r')
        except IOError:
            print(f'Error: Unable to read file: {config_common}')
            exit()
        else:
            lines = f.readlines()
            f.close()

        for line in lines:
            if reBlank.match(line) or reComment.match(line):
                continue

            fields = [x.strip() for x in line.split('|')]
            name  = fields[0].strip()
            value = fields[1].strip()

            if name == 'publish_dir':
                self.publish_dir = value
            else:
                print(f'Error: Undefined name in {config_common}: {name}')
                exit()

        if not self.publish_dir:
            print(f'Error: publish_dir not defined in {config_common}')
            exit()

        # --------------------------------------
        # Develop self.build_item_list
        # --------------------------------------

        if garg.config_list:

            config_list = [x.strip() for x in garg.config_list.split(' ')]
            config_list_length = len(config_list)

            if config_list_length != 0:
                if (config_list_length % 2) != 0:
                    print(f'Error: The argument for -config_list must contain a even number of entries')
                    exit()
                for i in range(0, config_list_length, 2):
                    build_label = config_list[i]
                    build_dir   = config_list[i + 1]
                    build_item = ( build_label , build_dir )
                    self.build_item_list.append(build_item)

        if garg.config_file and file_isfile(garg.config_file):
            try:
                f = open(garg.config_file, 'r')
            except IOError:
                print(f'Error: Unable to read file: {garg.config_file}')
                exit()
            else:
                lines = f.readlines()
                f.close()

            for line in lines:
                if reBlank.match(line) or reComment.match(line):
                    continue

                fields = [x.strip() for x in line.split('|')]
                build_label = fields[0]
                build_dir   = fields[1]

                if file_isdirectory(build_dir):
                    build_item = ( build_label , build_dir )
                    self.build_item_list.append(build_item)
                else:
                    print(f'Error: Build directory does not exist: {build_dir}')

        for build_item in self.build_item_list:
            build_label, build_dir = build_item
            print(f'Build item : {build_label} : {build_dir}')

        # --------------------------------------
        # Develop self.report_file
        # Develop self.message_file
        # --------------------------------------

        if garg.report_file:
            if re.match('^/', garg.report_file):
                # Absolute file specified; No defaults used
                self.report_file = garg.report_file
            else:
                # Relative path specified; Default report directory
                seq = []
                seq.append(publish_dir)
                seq.append('users')
                seq.append(get_user_name())
                seq.append(get_date())
                seq.append(garg.report_file)
                self.report_file = '/'.join(seq)
        else:
            # Default report directory & report name
            seq = []
            seq.append(publish_dir)
            seq.append('users')
            seq.append(get_user_name())
            seq.append(get_date())
            seq.append(f'{file_rootname(file_tail(self.this_script))}.lynx_dt')
            self.report_file = '/'.join(seq)

        if garg.message:
            file_part_org = file_tail(self.report_file)
            dir_part_org  = file_dirname(self.report_file)
            file_part_new = f'.{file_rootname(file_part_org)}.message'
            self.message_file = f'{dir_part_org}/{file_part_new}'

        print(f'Report file  : {self.report_file}')
        print(f'Message file : {self.message_file}')

        if not file_isdirectory( file_dirname(self.report_file) ):
            print(f'Creating directory: {file_dirname(self.report_file)}')
            file_mkdir( file_dirname(self.report_file) )

        if not file_isdirectory( file_dirname(self.report_file) ):
            print(f'Error: Unable to create directory: {file_dirname(self.report_file)}')
            exit()

    def get_build_item_list(self):
        return self.build_item_list

    def create_message_file(self):

        if self.message_file:
            file_obj = open(self.message_file, "w")

            file_obj.write('<html>\n')
            file_obj.write('<body>"\n')
            file_obj.write('<h1>New Report Available</h1>\n')
            file_obj.write('<a href=\"%%DT%%:' + file_normalize(self.report_file) + '\">The New Report</a>\n')
            file_obj.write('</body>\n')
            file_obj.write('</html>\n')
            file_obj.close()

            print("Info: Message file created")


# ------------------------------------------------------------------------------
# BuildInfo (uses TaskInfo)
# ------------------------------------------------------------------------------

class TaskInfo():

    def __init__(self):
        super().__init__()
        self.task_id          = ''
        self.task_flow_order  = 0
        self.task_step        = ''
        self.task_dst         = ''
        self.task_name        = ''
        self.task_tool        = ''
        self.task_report_list = []


class BuildInfo():

    def __init__(self):
        super().__init__()
        self.id2info = {}
        self.id_list = {}

    def init(self, build_label, build_dir, reports):

        task_info_list = []

        resourceFileList = glob.glob(f'{build_dir}/*/*/rpts/*/.*.lynx_task')

        for resourceFile in resourceFileList:
            fields = resourceFile.split('/')
            task_step = fields[len(fields) - 5]
            task_dst  = fields[len(fields) - 4]
            task_name = fields[len(fields) - 1]
            task_name = file_rootname(task_name) # Remove file suffix
            task_name = task_name[1:]            # Remove leading period

            # Read resourceFile
            try:
                f = open(resourceFile, 'r')
            except IOError:
                print(f'Error: Unable to read file: {resourceFile}')
                exit()
            else:
                lines = f.readlines()
                f.close()

            # Develop task_id
            task_id = f'{task_step}/{task_dst}/{task_name}'

            # Develop task_flow_order & task_tool
            task_flow_order = 0
            task_tool = 'UNDEFINED'
            for line in lines:
                match = re.match('^flow_order\|(\d+)', line)
                if match:
                    task_flow_order = match.group(1)
                match = re.match('^Tool\|(\S+)', line)
                if match:
                    task_tool = match.group(1)


            # Develop task_report_list

            task_report_list = []

            reportFileList = glob.glob(f'{build_dir}/{task_step}/{task_dst}/rpts/{task_name}/*')
            reportFileList = sorted(reportFileList)

            reportTypeFound = {}

            for reportFile in reportFileList:
                reportType = file_extension(reportFile)
                reportType = reportType[1:]
                if reportType in reports:
                    if reportType not in reportTypeFound:
                        reportTypeFound[reportType] = True
                        task_report_list.append(reportFile)

            # Develop and save task_info

            task_info = TaskInfo()
            task_info.task_id          = task_id
            task_info.task_flow_order  = task_flow_order
            task_info.task_step        = task_step
            task_info.task_dst         = task_dst
            task_info.task_name        = task_name
            task_info.task_tool        = task_tool
            task_info.task_report_list = task_report_list

            task_info_list.append(task_info)

        # Sort by task_flow_order, task_dst, task_step
        task_info_list = sorted( task_info_list, key = lambda x: int(x.task_flow_order) ) # HERE
        #task_info_list = sorted( task_info_list, key=operator.attrgetter('task_dst') )
        #task_info_list = sorted( task_info_list, key=operator.attrgetter('task_step') )

        # Develop class data model
        self.id2info[build_label] = {}
        self.id_list[build_label] = []

        for task_info in task_info_list:
            self.id2info[build_label][task_info.task_id] = task_info
            self.id_list[build_label].append(task_info.task_id)

    def debug(self, build_label, build_dir):
        print(f'DEBUG: {build_label} : {build_dir}')
        for task_id in self.get_all_task_id(build_label):
            print(f'DEBUG:   {task_id}')
            for reportFile in self.get_task_report_list(build_label, task_id):
                removeDir = f'{file_dirname(build_dir)}/'
                displayReport = re.sub(removeDir, '', reportFile)
                print(f'DEBUG:     {displayReport}')

    def get_all_task_id(self, build_label):
        return self.id_list[build_label]

    def get_rpt_task_id(self, build_label):
        id_list = []
        for task_id in self.id_list[build_label]:
            if len(self.get_task_report_list(build_label, task_id)) > 0:
                id_list.append(task_id)
        return id_list

    def delete_task_id(self, build_label, task_id):
        self.id2info[build_label].pop(task_id)
        self.id_list[build_label].remove(task_id)

    def get_task_flow_order(self, build_label, task_id):
        return self.id2info[build_label][task_id].task_flow_order

    def get_task_step(self, build_label, task_id):
        return self.id2info[build_label][task_id].task_step

    def get_task_dst(self, build_label, task_id):
        return self.id2info[build_label][task_id].task_dst

    def get_task_name(self, build_label, task_id):
        return self.id2info[build_label][task_id].task_name

    def get_task_tool(self, build_label, task_id):
        return self.id2info[build_label][task_id].task_tool

    def get_task_report_list(self, build_label, task_id):
        return self.id2info[build_label][task_id].task_report_list

# ------------------------------------------------------------------------------
# FileVars
# ------------------------------------------------------------------------------

class FileVars():

    def __init__(self):
        super().__init__()
        self.file2var_dict = {}
        self.counter = 0;

    def add_file(self, fileName):
        if fileName not in self.file2var_dict:
            self.counter = self.counter + 1
            varName = f'f{self.counter}'
            self.file2var_dict[fileName] = varName

    def get_var(self, fileName):
        if fileName in self.file2var_dict:
            return self.file2var_dict[fileName]
        else:
            print(f'Error: No file variable defined for file: {fileName}')
            return None

    def get_files(self):
        return self.file2var_dict.keys()



# ------------------------------------------------------------------------------
# MetricInfo (uses Metric)
# ------------------------------------------------------------------------------

class Metric():
    def __init__(self):
        super().__init__()
        self.data = ''
        self.link = ''


class MetricInfo():

    def __init__(self):
        super().__init__()
        self.name_list = []
        self.name2display = {}
        self.key2metric = {}

    def display_name_add(self, name, display):
        if name not in self.name_list:
            self.name_list.append(name)
            self.name2display[name] = display

    def display_name_exists(self, name):
        if name in self.name_list:
            return True
        else:
            return False

    def display_name_list(self):
        return self.name_list

    def display_name_set(self, name, display):
        if name in self.name_list:
            self.name2display[name] = display
        else:
            print(f'Error: display_name_set: Name not defined: {name}')

    def display_name_get(self, name):
        if name in self.name_list:
            return self.name2display[name]
        else:
            print(f'Error: display_name_get: Name not defined: {name}')
            return None

    def metric_add(self, key, data, link):
        metric = Metric()
        metric.data = data
        metric.link = link
        self.key2metric[key] = metric

    def metric_exists(self, key):
        if key in self.key2metric:
            return True
        else:
            return False

    def metric_list(self):
        return self.key2metric.keys()

    def metric_set_data(self, key, data):
        if key in self.key2metric:
            self.key2metric[key].data = data
        else:
            print(f'Error: metric_set_data: Key not defined: {key}')

    def metric_get_data(self, key):
        if key in self.key2metric:
            return self.key2metric[key].data
        else:
            print(f'Error: metric_get_data: Key not defined: {key}')
            return None

    def metric_set_link(self, key, link):
        if key in self.key2metric:
            self.key2metric[key].link = link
        else:
            print(f'Error: metric_set_link: Key not defined: {key}')

    def metric_get_link(self, key):
        if key in self.key2metric:
            return self.key2metric[key].link
        else:
            print(f'Error: metric_get_link: Key not defined: {key}')
            return None


# ------------------------------------------------------------------------------
# End of File
# ------------------------------------------------------------------------------
