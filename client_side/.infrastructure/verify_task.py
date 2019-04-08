#!/usr/bin/env python3

"""
Determine whether the user's command has solved the task.

The first two inputs are the current task number and the time elapsed
since starting the task.  The remaining inputs are the user's command.

There are three exit codes returned from this script.
 * If the user has passed the task, returns 1.
 * If the user does not pass the task but has time remaining, returns 0.
   - On failure, it also tries to open "meld" to show the diff to the user
     If "meld" is not installed, it shows the diff in the user's default
     browser
"""

from __future__ import print_function
import sys
import os
import subprocess
import filecmp
import tarfile

USER_OUT_DIR = os.environ['USER_OUT']
if not os.path.exists(USER_OUT_DIR):
    os.mkdir(USER_OUT_DIR)

USER_FS_FILE = os.path.join(USER_OUT_DIR, 'fs_out')
USER_STDOUT_FILE = os.path.join(USER_OUT_DIR, 'std_out')

NORM_FS_FILE = os.path.join(USER_OUT_DIR, 'norm_fs')
NORM_STDOUT_FILE = os.path.join(USER_OUT_DIR, 'norm_stdout')

# There are two types of tasks: those that expect output, and
# those that expect a modification to the file system.
FILESYSTEM_TASKS = {2, 3, 4, 5, 6, 11, 12, 15, 17, 20, 22}

def main():
    # the current task number, as a str
    task_num = sys.argv[1]
    # the current command
    command = ' '.join(sys.argv[2:])

    try:
        user_fs_out = open(USER_FS_FILE, 'w')

        user_std_out = open(USER_STDOUT_FILE, 'w')

        devnull = open(os.devnull, 'wb')

        # get the files in the current filesystem
        filesystem = subprocess.call('find .', shell=True, stderr=devnull, stdout=user_fs_out)
        # get the stdout of the command
        stdout = subprocess.call(command, shell=True, stderr=devnull, stdout=user_std_out)

        # close output file for normalization
        user_fs_out.close()
        user_std_out.close()

        normalize_output(USER_FS_FILE, NORM_FS_FILE, True)
        normalize_output(USER_STDOUT_FILE, NORM_STDOUT_FILE, False)

        verify_fs = verify(NORM_FS_FILE, task_num, True)
        if int(task_num) not in FILESYSTEM_TASKS:
            verify_stdout = verify(NORM_STDOUT_FILE, task_num, False)
        else:
            verify_stdout = False

        # if the task was passed
        if (int(task_num) in FILESYSTEM_TASKS and verify_fs) or verify_stdout:
            #to_next_task(task_num)
            # return exit code 1
            sys.exit(1)
        else:
            sys.exit(0)
    except (OSError, subprocess.CalledProcessError) as e:
        print(e)
        sys.exit(0)


def normalize_output(out_file, norm_file, filesystem):
    """Reads file output_path, normalizes its contents, and writes the result
to file norm_out_path.
    """
    norm_out = open(norm_file, 'w')
    if filesystem:
        print('# Showing diff of task filesystem.', file=norm_out)
    else:
        print('# Showing diff of stdout.', file=norm_out)

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


def verify(norm_out_path, task_num, filesystem_verify):
    """Returns 0 if verification succeeded, non-zero if it failed."""
    task_dir = "task{}".format(task_num)

    if filesystem_verify:
        task_verify_path = os.path.join(os.environ['TASKS_DIR'], "{task}/{task}.fs.out".format(task=task_dir))
        diff_file = os.path.join(USER_OUT_DIR, 'fs_diff.html')
    else:
        task_verify_path = os.path.join(os.environ['TASKS_DIR'], "{task}/{task}.select.out".format(task=task_dir))
        diff_file = os.path.join(USER_OUT_DIR, 'select_diff.html')

    # special verification for task 2
    if int(task_num) == 2:
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
    files_match = filecmp.cmp(norm_out_path, task_verify_path)

    if not files_match:
        if os.environ.get('DISPLAY') is not None:
            if int(os.environ['MELD']) == 0:
                print("Meld not installed, displaying diff in browser", file=sys.stderr)

                import difflib
                import webbrowser

                out_lines = open(norm_out_path, 'r').readlines()
                verify_lines = open(task_verify_path, 'r').readlines()

                diff = difflib.HtmlDiff().make_file(out_lines, verify_lines,
                                                         fromdesc='Actual',
                                                         todesc='Expected')
                out_lines.close()
                verify_lines.close()

                with open(diff_file, 'w')as f:
                    f.writelines(diff)

                webbrowser.open('file://' + os.path.realpath(diff_file))

            else:
                subprocess.call(['meld', norm_out_path, task_verify_path])
        else:
            import difflib

            print("No display detetected, outputting unified diff", file=sys.stderr)

            out_lines = open(norm_out_path, 'r').readlines()
            verify_lines = open(task_verify_path, 'r').readlines()

            diff = difflib.unified_diff(out_lines, verify_lines,
                                                     fromfile='Actual',
                                                     tofile='Expected')
            out_lines.close()
            verify_lines.close()
            
            sys.stdout.writelines(diff)


    return files_match

if __name__ == '__main__':
    main()
