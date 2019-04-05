#!/usr/bin/env python

"""
Determine whether the user's command has solved the task.

The first two inputs are the current task number and the time elapsed
since starting the task.  The remaining inputs are the user's command.

There are three exit codes returned from this script.
 * If the user has passed the task, returns 1.
 * If the user has not passed the task and has run out of time for the current
   task, returns 2.
 * If the user does not pass the task but has time remaining, returns 0.
"""

from __future__ import print_function
import sys
import os
import subprocess
import filecmp
import tarfile

# There are two types of tasks: those that expect output, and
# those that expect a modification to the file system.
FILESYSTEM_TASKS = {2, 3, 4, 5, 6, 11, 12, 15, 17, 20, 22}
# Task time limit in minutes.
TASK_TIME_LIMIT = 5.0


def main():
    # the current task number, as a str
    task_num = sys.argv[1]
    # the number of seconds elapsed since the beginning of the task, as a str
    seconds = sys.argv[2]
    # the current command
    command = ' '.join(sys.argv[3:])
    try:
        filesystem_path = os.environ['REPO_DIR'] + '/user_output/filesystem'
        filesystem_file = open(filesystem_path, 'w')

        stdout_path = os.environ['REPO_DIR'] + '/user_output/stdout'
        stdout_file = open(stdout_path, 'w')

        devnull = open(os.devnull, 'wb')

        # get the files in the current filesystem
        filesystem = subprocess.call('find .', shell=True, stderr=devnull, stdout=filesystem_file)
        # get the stdout of the command
        stdout = subprocess.call(command, shell=True, stderr=devnull, stdout=stdout_file)

        # close output file for normalization
        filesystem_file.close()
        stdout_file.close()

        norm_filesystem_path = os.environ['REPO_DIR'] + '/user_output/norm_filesystem'
        normalize_output(filesystem_path, norm_filesystem_path, task_num, True)

        norm_stdout_path = os.environ['REPO_DIR'] + '/user_output/norm_stdout'
        normalize_output(stdout_path, norm_stdout_path, task_num, False)

        verify_fs = verify(norm_filesystem_path, task_num, True)
        if int(task_num) not in FILESYSTEM_TASKS:
            verify_stdout = verify(norm_stdout_path, task_num, False)
        else:
            verify_stdout = False

        # if the task was passed
        if (int(task_num) in FILESYSTEM_TASKS and verify_fs) or verify_stdout:
            #to_next_task(task_num)
            # return exit code 1
            sys.exit(1)
        else:
            # return exit code 0 if the current task has not been passed
            # but there is still time on the task
            if task_has_time_left(seconds):
                if int(task_num) not in FILESYSTEM_TASKS and not verify_fs:
                    print('-----------------------------------------------------------------------------------------------')
                    print('WARNING: you have either changed directories or have modified the task filesystem; please reset')
                sys.exit(0)
            else:
                # if there is no time left, return 2
                sys.exit(2)
    except (OSError, subprocess.CalledProcessError):
        sys.exit(0)


def task_has_time_left(seconds):
    mins_elapsed = int(seconds) / 60.0
    return mins_elapsed < TASK_TIME_LIMIT


def normalize_output(output_path, norm_out_path, task_num, filesystem):
    """Reads file output_path, normalizes its contents, and writes the result
to file norm_out_path.
    """
    norm_out = open(norm_out_path, 'w')
    if filesystem:
        print('# Showing diff of task filesystem.', file=norm_out)
    else:
        print('# Showing diff of stdout.', file=norm_out)
    output = open(output_path)
    lines = sorted(output.read().splitlines())
    for line in lines:
        if line == './' or line == '.':
            p_line = line
        else:
            p_line = line.lstrip('./')
        print(p_line, file=norm_out)
    norm_out.close()
    output.close()


def verify(norm_out_path, task_num, filesystem_verify):
    """Returns 0 if verification succeeded, non-zero if it failed."""
    if filesystem_verify:
        task_verify_path = os.environ['REPO_DIR'] + '/verify_out/fs_status/task' + str(task_num) + '.fs.out'
    else:
        task_verify_path = os.environ['REPO_DIR'] + '/verify_out/select_targets/task' + str(task_num) + '.select.out'

    # special verification for task 2
    if int(task_num) == 2:
        files_in_tar = set()
        try:
            tar = tarfile.open(os.path.join(os.environ['TASK_DIR'], 'html.tar'))
            for member in tar.getmembers():
                files_in_tar.add(os.path.basename(member.name))
            if files_in_tar != {'index.html', 'home.html', 'labs.html',
                                'lesson.html', 'menu.html', 'navigation.html'}:
                print('-------------------------------------------')
                print('html.tar does not contain the correct files')
                print('contains: ' + str(files_in_tar))
                print('should be: ' + str({'index.html', 'home.html', 'labs.html', 'lesson.html', 'menu.html', 'navigation.html'}))
                return False
        except tarfile.ReadError:
            # valid tar file does not exist on the target path
            print('--------------------------------')
            print('html.tar is not a valid tar file')
            return False
        except IOError:
            pass

    # compare normalized output file and task verification file
    return filecmp.cmp(norm_out_path, task_verify_path)


def to_next_task(task_num):
    """Increments the contents of file curr_task."""
    curr_task_path = os.environ['REPO_DIR'] + '/task_progress/curr_task'
    with open(curr_task_path, 'w') as curr_task:
        print(int(task_num) + 1, end='', file=curr_task)


if __name__ == '__main__':
    main()
