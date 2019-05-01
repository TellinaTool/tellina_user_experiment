#!/usr/bin/env python3

"""
Determine whether the user's command has solved the task.

The first input is the current true task code. The remaining inputs are the
user's command.

This script has the following exit status
- Prints `success` to `stdout` if the actual output matches expected. Exit code
  is `0`.
- Prints `incomplete` to `stdout` if the actual output does not match expected.
  - If the task is a file system task, exit code is `1`.
  - If the task is a select task:
    - If the file system has been changed, exit code is `2`.
    - Otherwise, exit code is `3`.
In addition, two files called "task_actual" and "task_expected" will be created
in /tmp/ if the verification fails.
"""

import sys
import os
import shutil
import subprocess
import filecmp
import tarfile

# Gets all the environment variables and sets up the user output directory
FS_DIR = os.environ['FS_DIR']

USER_OUT_DIR = os.environ['USER_OUT']
if not os.path.exists(USER_OUT_DIR):
    os.mkdir(USER_OUT_DIR)

# Establishes files for all the outputs
USER_STDERR = os.path.join(USER_OUT_DIR, 'std_err')

USER_FS_FILE = os.path.join(USER_OUT_DIR, 'fs_out')
USER_STDOUT_FILE = os.path.join(USER_OUT_DIR, 'std_out')

ACT_FILE = os.path.join('/tmp', 'task_actual')
EXP_FILE = os.path.join('/tmp', 'task_expected')

# There are two types of tasks: those that expect output, and
# those that expect a modification to the file system.
FILESYSTEM_TASKS = {'b', 'c', 'd', 'e', 'f', 'k', 'l', 'o', 'p', 't', 'v'}

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

    # the current task number, as a str
    task_code = sys.argv[1]
    # the current command
    command = ' '.join(sys.argv[2:])

    try:
        devnull = open(os.devnull, 'wb')

        with open(USER_FS_FILE, 'w') as user_out:
            with cd(FS_DIR):
                filesystem = subprocess.run('find .'.format(FS_DIR), shell=True, stderr=devnull, stdout=user_out)

        normalize_output(USER_FS_FILE, ACT_FILE)

        # Verify checks whether or not the changes made to the file system is
        # expected
        fs_good = verify(ACT_FILE, task_code, True)

        # If it is a "file system" task, the script will:
        # - Get the current state of the file system and compares it to the expected
        #   file system for the current task.
        # Else if it is a "select" task, the script will:
        # - Get the current state of the file system and compares it to the original
        #   state to make sure that it was not changed.
        # - If the file system was not modified:
        #   - Re-execute the user command and capture the `stdout`.
        #   - Check that the captured `stdout` of the user command matches the
        #     corresponding expected output.
        # - If the file system was modified then the task failed.
        exit = 0
        if not fs_good:
            if task_code in FILESYSTEM_TASKS:
                print("incomplete")
                exit = 1
            else:
                print("incomplete")
                exit = 2
        else:
            if task_code not in FILESYSTEM_TASKS:
                with open(USER_STDOUT_FILE, 'w') as user_out:
                    with open(USER_STDERR, 'w') as user_err:
                        stdout = subprocess.run(command, shell=True, stderr=user_err, stdout=user_out)

                normalize_output(USER_STDOUT_FILE, ACT_FILE)

                if not verify(ACT_FILE, task_code, False):
                    print("incomplete")
                    exit = 3
            else:
                exit = 0

        if exit == 0:
            print("success")
        sys.exit(exit)
    except (OSError, subprocess.CalledProcessError) as e:
        print(e)
        sys.exit(1)

def normalize_output(out_file, norm_file):
    """
    Reads file output_path, normalizes its contents, and writes the result
    to file norm_out_path.
    """
    norm_out = open(norm_file, 'w')
    output = open(out_file)

    lines = sorted(output.read().splitlines())
    for line in lines:
        if line == './' or line == '.':
            p_line = line
        else:
            p_line = line.lstrip('./')

        print(p_line, file=norm_out)

    norm_out.close()
    output.close()


def verify(norm_out_path, task_code, check_fs):
    """Returns 0 if verification succeeded, non-zero if it failed."""
    task = "task_{}".format(task_code)

    task_verify_path = os.path.join(
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
    files_match = filecmp.cmp(norm_out_path, task_verify_path)
    if not files_match:
        shutil.copy(task_verify_path, EXP_FILE)

    return files_match

if __name__ == '__main__':
    main()
