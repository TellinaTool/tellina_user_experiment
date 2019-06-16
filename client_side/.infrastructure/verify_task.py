#!/usr/bin/env python3

"""
Determine whether the user's command has solved the task.

Parameters:
- args[1]: the current true task code.
- args[2]: the directory in which to run the given user command.
- args[3:]: the user's command.

This script has the following exit codes:
- 0: The verification is successful.
- 1: The file system does not match expected and the task is a file system task.
- 2: The file system has been changed and the task is a select task.
- 3: The output does not match expected and the task is a select task.

In addition, two files called "actual" and "expected" will be created
in /tmp/ if the verification fails.
"""

import sys
import os
import shutil
import subprocess
import filecmp
import tarfile

# Exit codes
VERIFICATION_SUCCESS = 0
FILE_SYSTEM_FAILURE  = 1
FILE_SYSTEM_MODIFIED = 2
STANDARD_OUT_FAILURE = 3
UNEXPECTED_FAILURE   = 4
SUBPROCESS_FAILURE   = 5

# Gets all the environment variables
FS_DIR = os.environ['FS_DIR']

USER_OUT_DIR = os.environ['USER_OUT']

# Establishes files for all the outputs
USER_STDERR = os.path.join(USER_OUT_DIR, 'std_err')

USER_FS_FILE = os.path.join(USER_OUT_DIR, 'fs_out')
USER_STDOUT_FILE = os.path.join(USER_OUT_DIR, 'std_out')

ACTUAL_FILE = os.path.join('/tmp', 'actual')
EXPECTED_FILE = os.path.join('/tmp', 'expected')

# There are two types of tasks: those that expect output, and
# those that expect a modification to the file system.
FILESYSTEM_TASKS = {'b', 'c', 'd', 'e', 'f', 'k', 'l', 'o', 'q', 't', 'v'}

def main():
    class cd:
        """Context manager for changing the current working directory"""
        def __init__(self, newPath):
            self.newPath = os.path.expanduser(newPath)

        def __enter__(self):
            self.savedPath = os.getcwd()
            os.chdir(self.newPath)

        def __exit__(self, etype, value, traceback):
            os.chdir(self.savedPath)

    # the true task code
    task_code = sys.argv[1]
    command_dir = sys.argv[2]
    # the current command
    command = ' '.join(sys.argv[3:])

    try:

        # Always:
        # - Get the current state of the file system and compare it to the expected
        #   file system for the current task.  (For a select task, this ensures that
        #   it was not changed).
        # If it is a "select" task and the file system was not modified, also:
        # - Re-execute the user command and capture the `stdout`.
        # - Check that the captured `stdout` of the user command matches the
        #   corresponding expected output.

        devnull = open(os.devnull, 'wb')

        with open(USER_FS_FILE, 'w') as user_out:
            with cd(FS_DIR):
                filesystem = subprocess.call('find .', shell=True, stderr=devnull, stdout=user_out)

        normalize_and_copy_output(USER_FS_FILE, ACTUAL_FILE)

        # Verify checks whether or not the file system state is as expected.
        fs_good = verify(ACTUAL_FILE, task_code, True)

        if not fs_good:
            if task_code in FILESYSTEM_TASKS:
                sys.exit(FILE_SYSTEM_FAILURE)
            else:
                sys.exit(FILE_SYSTEM_MODIFIED)
        else:
            if task_code in FILESYSTEM_TASKS:
                sys.exit(VERIFICATION_SUCCESS)
            else:
                with open(USER_STDOUT_FILE, 'w') as user_out:
                    with open(USER_STDERR, 'w') as user_err:
                        # shell=True is needed here for several reasons:
                        # 1. It preserves quoting for user commands given that
                        # the command argument passed to the call is a string.
                        # (see https://docs.python.org/3/library/subprocess.html#popen-constructor starting at "On POSIX with shell=True")
                        # 2. It reduces the need to replace shell piplines.
                        # (see https://docs.python.org/3/library/subprocess.html#replacing-shell-pipeline)
                        with cd(command_dir):
                            stdout = subprocess.call(command, shell=True, stderr=user_err, stdout=user_out)

                normalize_and_copy_output(USER_STDOUT_FILE, ACTUAL_FILE)

                if verify(ACTUAL_FILE, task_code, False):
                    sys.exit(VERIFICATION_SUCCESS)
                else:
                    sys.exit(STANDARD_OUT_FAILURE)
        print("This can't happen")
        sys.exit(UNEXPECTED_FAILURE)
    except (OSError, subprocess.CalledProcessError) as e:
        print(e)
        sys.exit(SUBPROCESS_FAILURE)

def normalize_and_copy_output(subprocess_output_file, normalized_output_file):
    """
    Normalizes the contents of file subprocess_output (sorts lines, removes
    leading './') and writes the result to file normalized_output.
    """
    with open(normalized_output_file, 'w') as normalized_output:
        with open(subprocess_output_file) as subprocess_output:
            lines = []
            for line in subprocess_output.read().splitlines():
                if line == './' or line == '.':
                    lines.append(line)
                else:
                    lines.append(line.lstrip('./'))

            lines = sorted(lines)
            for line in lines:
                print(line, file=normalized_output)

def verify(normalized_output_file, task_code, check_fs):
    """Returns true if verification succeeded, false if it failed."""
    task = "task_{}".format(task_code)

    task_verify_file = os.path.join(
        os.environ['TASKS_DIR'], "{task}/{task}.{out_type}.out"
            .format(task=task, out_type="fs" if check_fs else "select"))

    # special verification for task b
    if task_code == 'b':
        files_in_tar = set()
        try:
            tar = tarfile.open(os.path.join(os.environ['FS_DIR'], 'html.tar'))
            for member in tar.getmembers():
                files_in_tar.add(os.path.basename(member.name))
            if files_in_tar != {'index.html', 'home.html', 'labs.html',
                                'lesson.html', 'menu.html', 'navigation.html'}:
                print('-------------------------------------------')
                print('html.tar does not contain the correct files')
                print('contains: ' + str(files_in_tar))
                print('should be: ' + str({'index.html',
                                           'home.html',
                                           'labs.html',
                                           'lesson.html',
                                           'menu.html',
                                           'navigation.html'}))
                return False
        except tarfile.ReadError:
            # valid tar file does not exist on the target path
            print('--------------------------------')
            print('html.tar is not a valid tar file')
            return False
        except IOError:
            pass

    # compare normalized output file and task verification file
    files_match = filecmp.cmp(normalized_output_file, task_verify_file)
    if not files_match:
        shutil.copy(task_verify_file, EXPECTED_FILE)

    return files_match

if __name__ == '__main__':
    main()
