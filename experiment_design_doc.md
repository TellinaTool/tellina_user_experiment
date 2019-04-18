# Tellina User Study Design Doc

## Introduction

Tellina is a natural language -> command translation tool.  Tellina accepts a
natural language description of file system operations, and displays a ranked
list of bash one-liner suggestions made by the model. The user can scroll down
the web page to explore more suggestions.

In an experiment, people were given
descriptions of file system operations, and asked to write bash commands to
perform the operations.  The experimental group had access to Tellina, web
search, and man pages; the control group had access only to web search and
man pages. Measurements were done on whether subjects successfully complete the
tasks, and the amount of time that it takes to complete the tasks.
A post-task questionnaire obtained qualitative feedback.

We need to redo the experiment, for a few reasons.
1. Tellina has changed since the user study was performed.  Tellina has better
   accuracy and handles more commands.  It would not be compelling to report an
   experiment on an implementation that has since been superseded.
2. The user study was relatively small (around 30 subjects), so the experimental
   results were not always statistically significant.  With a larger pool of
   subjects, the results will be more compelling.

This design document describes a new infrastructure for the user design, as the
previous one was buggy.

## Overview

### Experiment Infrastructure

The experiment infrastructure consists of several components:
- Server side: The server's main purpose is to collect and store data from all
  experiments. This includes information about users, issued commands, time
  spent on tasks, browsing history, etc.
  - The server will only handle POST requests from clients, convert the request
    into CSV format and append them to a single log file.
- Client side: this contains
  - Information about the experiment, requirements for the client side
    infrastructure (which terminal they should use, what system they should be
    on, etc.), and instruction on how to set up the client side infrastructure
    and begin the experiment.
  - Initial configuration script that sources infrastructure code to setup the
    experiment and begin it.
    - This will also change the user's current directory to be where they will
      be performing tasks.
  - Infrastructure code: this code will add the following functionality to the
    Bash shell it was sourced in:
    - Logs information recorded for the experiment to the server (see [log file
      format](#logging) on what information is sent).
      - It also [logs some information locally](#variable_files) as well.
    - After command execution, verifies that the command produces the correct
      output (w.r.t. the state of the file system, standard output, or both).
      - Displays a diff if the actual and expected outputs do not match (one for
        the file system state and one for `stdout` if applicable).
    - Adds meta-commands and meta-functions:
      - Helpful user meta-commands to help the user navigate the experiments
        more easily.
      - Infrastructure bash functions that manage the experiment as well as
        communicate with the server.
        - Example functions include: move to next task, determine task order,
          send log, extract the directory for the user to perform tasks on, etc.
      - (see [Client Side](#client-side) for more details).
  - The directory in which the user will perform tasks in.
- Analysis of experimental data: determine relative performance of subjects
  using Tellina versus those who are not, via statistical analysis.
- Tasks:
  - We will have `N` tasks for each user.
  - The tasks will be labeled sequentially.
  - Each task will have a corresponding expected output file for both file
    system output and standard output.

### User Experience

Users are given the client side of the experiment infrastructure. Once they are
ready to begin, they will source the initial configuration script in a Bash
shell to begin the experiment.

Throughout the experiment, the users will be interacting with the shell where
they started the experiment in, Meld, and a web browser of their choice.
  - They will use a Bash shell to perform tasks and man page lookups.
  - Meld is displayed to the user when actual output does not match expected
    output for commands they entered. More specifically:
    1. Meld will be closed at the beginning of *any* task.
    2. Meld will close (or remain closed) when the user succeeds a task, abandons
       a task, times out on a task, or resets the file system.
    3. Meld will open and remain opened (killed then re-spawned) when the user is
       not done with a task but has issued at least one command.
  - They will use the web browser to find resources and interact with Tellina
    (when applicable).

### User Interface

The Bash shell for the experiment will have all built-in commands, prompts, and
pipes unchanged. The experiment infrastructure, once set up, will add the
following differences to the shell's interface (assume print means "print to
`stdout`" unless specified otherwise):
- The user will be able to run the following **user meta-commands**:
  - `task`: prints the current task's description and number
  - `abandon`: abandons the current task and go to the next task.
  - `reset`: reset the file system
    - This command will return the user to the directory where they called it.
  - `helpme`: lists the commands available to the user
- Prints any messages related to the experiment (prompts, current task
  descriptions, welcome/clean-up messages, warnings, etc.) to `stdout`.

**Note:** the two initial tasks that the user will be doing will be tutorial
tasks. The tutorial will print instructions on what to do for each step to the
shell as well.

Meld and the web browser are unmodified.

## Implementation
### Server side
The server side should be hosted on the [UW CSE's
Homes](https://www.cs.washington.edu/lab/web) or any machine maintained by the
department. This allows the server to be reliable and will significant reduce
the possibility of the server being overloaded with traffic.

The server will only handle `POST` requests.  It will log each `POST`
request to a CSV file.

The server implementation will be similar to:
```PHP
<?php
if (isset($_POST) && ($_POST)) {
    $filename="log.csv";
    $line = gmdate("Y-m-d\TH:i:s\Z");
    $line .= ","
    $line .= implode(",", $_POST);
    $line .= "\n";
    file_put_contents($filename, $line, FILE_APPEND);
}
?>
```

#### Logging
The log file (`log.csv`) that is appended to by the
server will have the following columns:
- **server_time_stamp**: the current time that the server received the `POST`
  request from the client.
  - ISO-8601 formatted with UTC.
- **user_id**: the username and machine name associated with the information on the
  current row
- **task_order**: the task order that was assigned to this user.
- **client_time_stamp**: the current time that the command was entered on the client
  side.
  - ISO-8601 formatted with UTC.
- **task_no**: the current task number.
- **treatment**: Tellina/NoTellina.
- **command**: the command that the user entered.
- **time_elapsed** (seconds): time in seconds the user took to formulate the command.
- **status**: `success` if the user succeeded, `timeout` if the user ran out of time,
  `abandon` if the user abandoned the task, and `incomplete` if the task is
  incomplete but the user still has time.

Example content of what `log.csv` could look like:

|server_time_stamp|user_id|task_order|client_time_stamp|task_no|treatment|command|time_elapsed|status|
|-|-|-|-|-|-|-|-|-|
|2019-04-05T18:12:00Z|abc@machineA|0|2019-04-05T18:12:00Z|1|Tellina|find . -name "*.txt" -delete|33|incomplete|
|2019-04-05T18:12:03Z|ddd@machineD|2|2019-04-05T18:12:00Z|1|NoTellina|find . -name "*.txt"|40|success|
|2019-04-05T18:12:04Z|abc@machineA|0|2019-04-05T18:12:00Z|1|Tellina|reset|37|incomplete|
|2019-04-05T18:12:07Z|abc@machineA|0|2019-04-05T18:12:00Z|1|Tellina|find . -name "*.txt"|40|success|
|...|...|...|...|...|...|...|...|...|
|2019-04-05T18:42:10Z|abc@machineB|1|2019-04-05T18:12:00Z|21|Tellina|abandon|100|abandon|
|...|...|...|...|...|...|...|...|...|
|2019-04-08T18:48:02Z|bcd@machineB|1|2019-04-05T18:12:00Z|22|Tellina|...|300|timeout|

The start time of a task is the **client_time_stamp** of the row where the
**command** column is "task started".

The total time for a task is the **time_elapsed** of the row where the
**status** is either "success", "abandon", or "timeout".

### Client side
It is expected that the client side can run on the CSE Linux VM without issue,
and could potentially work on Attu as well.

The client requires the user to have a graphical interface for the experiment.
This is because the client uses [Meld](http://meldmerge.org/) to display the
diffs between actual and expected output.

#### Distribution
The client side will be distributed to users through a ZIP archive. The contents
of the archive is described bellow.

#### Directory Structure
The directory structure for the client side after extracting the ZIP archive to
`dir` will look similar to:
```
dir/
|__.infrastructure
|  |__setup.sh        - Bash script that sources function definition files, sets
|  |                    variables for the experiment (paths to scripts, to files,
|  |                    etc.), enables bash-preeexec.
|  |__bash-preexec.sh - Bash script that defines Bash-preexec functions.
|  |__*.sh            - Bash files with definitions for functions useful
|  |                    for the experiment (infrastructure functions, user
|  |                    functions, etc.)
|  |__*.py            - Python scripts that helps with output verification, task
|  |                    order determination, and printing task descriptions.
|  |__file_system.tar - The original version of the directory the user will be
|  |                    performing tasks on.
|  |__tasks/
|  |  |__task1/
|  |  |  |__task1.json      - JSON file with description of task
|  |  |  |__task1.fs.out    - Expected state of file system
|  |  |  |__task1.std.out   - Expected stdout of user command
|  |  |__task2/
|  |  |  |__...
|  |  |__...
|  |__...
|__configure        - Bash script that the user can run to start the experiment.
|                     Sources ./.infrastructure/setup.sh.
|__file_system/     - The directory that the user will be performing tasks on.
|  |                  Extracted from files.tar on setup. Removed and
|  |                  re-extracted on user reset. The user will automatically be
|  |                  changed into this directory when the experiment starts and
|  |                  on resets.
|  |__...
|__README.txt       - Description of experiment (what's going to happen, time
                      limit, resources, etc.)
```

#### Setting Up
To set up the client side for experimentation, the user will be instructed to
run the following command:
```sh
source ./configure
```

The script will source `.infrastructure/setup.sh`, which will do the following:
- Set up <a id=variable_files>variable files</a> that will keep track of the
  current task, task order, treatment, and the most recent command.
  - This will allow the client side to be resumed if a failure happens.
  - The files will be in the `.infrastructure` directory.
  - Files:
    - `.treatment`: the treatment for the current task
    - `.command`: the most recently entered command. Initial value is "start
      task"
    - `.task_order`: the task ordering for this user `[0-3]`
    - `.task_no`: the true number of the current task. This is the number sent
      to the server.
- Initialize Bash variables that will be used throughout the experiment:
  - `time_elapsed`: the time in seconds that the user spent on a command.
    - This is because `$SECONDS` does not stop incrementing, and the time
      between the log write and the command being entered could be different by
      a few seconds. Initial value is `0`.
  - `status`: the status of the current task. Can be `success`, `timeout`,
    `abandon`, or `incomplete`. Initial value is "incomplete".
  - `curr_task`: the sequential task number, this will be the task number showed
    to the user. Initial value is `1`.
      - **Note**: the reason we need a "true" task number and a "sequential"
        task number is because some users might end up starting the experiment
        with task set 2, in which case, the "true" task number will be `N / 2`,
        not `1`.
- Initializes Bash constants to keep track of directories, time limits, task
  limits, etc.
- Defines user meta-commands:
  - Each meta-command will be `alias <command_name>='touch .<command_name>'`.
- Create the user ID by gathering user information: stored in `$USER_ID`
  constant
  - Machine name: determined by the `hostname` bash command
  - Username: the user will be asked to enter their UW NetID
  - User ID will then be `username@machine_name`.
- Determine the task set ordering: stored in `.task_order`
  - We will have 4 task orderings, with `s1, s2` as task set 1 and 2, and `T,
    NT` for Tellina and No Tellina

    ||1st|2nd|
    |-|-|-|
    |0|`s1 T`|`s2 NT`|
    |1|`s2 T`|`s1 NT`|
    |2|`s1 NT`|`s2 T`|
    |3|`s2 NT`|`s1 T`|
    - The task ordering will then be determined by this bash command:
    ```sh
    echo $((0x$(md5sum <<<$USER_ID | cut -c1) % 4))
    ```
    - This function makes sure that the same `$USER_ID` will have the same task
      ordering.
    - Writes the treatment to `.treatment`, the true task number to `.task_no`
- Sources `infrastructure.sh`, which defines the following functions:
  - `next_task`:
    - Kill Meld if it's opened.
    - Call `write_log`.
    - Call `make_fs`.
    - Increment the number in `.task_no`
    - Increment the `curr_task` bash variable. This is the task number printed
      to the user.
      - If this variable is equal to `N / 2`, switch treatments and task sets
        and notify the user.
      - Check if all the tasks are complete, if it is then skip the following
        steps and clean up instead.
    - Set `SECONDS=0`.
      - `SECONDS` is a build-in Bash variable that increments every second. The
        infrastructure uses this to check the time elapsed.
    - Set `time_elapsed=0`, `status="incomplete"`
    - Write "start task" to `.command`.
    - Call `write_log`.
    - Call `get_tasks_description.py .curr_task`.
  - `make_fs`:
    - Gets the current working directory. Then changes to the base experiment
      directory (`dir` from [Directory Structure](#directory-structure))
    - Removes the `file_system` directory and extracts the tarball to that
      directory.
    - Changes the user to the stored directory.
  - `write_log`:
    - Gets information needed for the log file:
      - The server time stamp is handled by the server.
      - `user_id`: `$USER_ID`
      - `task_order`: `.task_order`
      - `client_time_stamp`: `$(date --utc +%FT%TZ)`
      - `task_no`: `.task_no`
      - `treatment`: `.treatment`
      - `command`: `.command`
      - `time_elapsed`: `$time_elapsed`
      - `status`: `$status`
- Install [Bash-Preexec](https://github.com/rcaloras/bash-preexec) by sourcing
  `bash-preexec.sh`.
- Set up the experiment prompts to follow the determined task order.
- Call `make_fs`, `write_log`.
- Change the user into the `file_system/` directory.
- Prints treatment.
- Prints the first task description.

#### Bash-Preexec
Bash-preexec allows running code before and after the execution of a command
that was ran interactively in the terminal.

The following configurations will be implemented:
##### `preexec`:
- Ran right after the user enters a command and right before the
command is executed
- Write the command to `.command`.

##### `precmd`:
- Ran right after the user command is executed and right before the
  prompt is displayed.
- Only one of the following cases can happen every time a command has finished
  executing:
  1. Check if user has ran out of time: `time_elapsed=$SECONDS` is less than some
     time limit constant.
     - The check will happen after the command is executed.
     - If the user ran out of time, `status="timeout"` and call
       `next_task`.
  2. Handle user meta-command:
     - Output verification will not be performed on these commands.
     - The check is done by looking for the existence of the file
        `.<commmand_name>` in the `.infrastructure` directory.
     - If `abandon`:
       - Set `status="abandon"` and call `next_task`.
       - Remove `.abandon`.
     - Otherwise
       - If `reset`:
         - Kills Meld.
         - Calls `make_fs`
         - Remove `.reset`.
       - If `helpme`: prints the list of user meta-commands. Remove `.helpme`.
       - If `task`: calls `get_task_description.py` with `.task_no` to print the
         task's description. Remove `.task`
       - Set `status="incomplete"` and call `write_log`.
  3. Check if the command in `.command` is correct.
     - Does this by setting `status=$(verify_output.py $(cat .task_no) $(cat
       .command))`
     - This sets `status` to either "success" or "incomplete".
     - If `status == "incomplete"` check the [exit code](#exit-stat) of
       `verify_output.py`:
       - `1`: display Meld for the file system.
       - `2`: display Meld for the file system, issue warning, and call
         `make_fs`.
       - `3`: display Meld for the `stdout`.
     - Otherwise: call `next_task`.

#### Output verification:
- Verification will be done using a python script called
  `verify_output.py`:
  - **Parameters**: `<task_no> [command...]`
    - Each parameter after `<task_no>` is interpreted as part of the command
      the user entered.
  - The script checks the task number to see whether it is a "file system"
    task, which modifies the file system, or a "select" task, which does not
    modify the file system and only outputs to `stdout`:
    - If it is a "file system" task, the script will:
      - Get the current state of the file system and compares it to the expected
        file system for the current task.
    - Else if it is a "select" task, the script will:
      - Get the current state of the file system and compares it to the original
        state to make sure that it was not changed.
      - If the file system was not modified:
        - Re-execute the user command and capture the `stdout`.
        - Check that the captured `stdout` of the user command matches the
          corresponding expected output.
      - If the file system was modified then the task failed.
  - <a id="exit-stat">**Exit status**</a>:
    - Prints `success` to `stdout` if the actual output matches expected. Exit
      code is `0`.
    - Prints `incomplete` to `stdout` if the actual output does not match
      expected.
      - If the task is a file system task, exit code is `1`.
      - If the task is a select task:
        - If the file system has been changed, exit code is `2`.
        - Otherwise, exit code is `3`.

#### Directory for experiment files:
- The files used for the experiment will be distributed in a TAR file. The
  initial configuration of the interface and subsequent resets will extract
  the TAR into a specified directory.
- The user will be performing tasks on files within this directory and can move
  around freely within it.

## Risks and Concerns
- User file system safety.
  - **The client task interface does not guarantee that the user's file system
      will be safe from misused commands. The only directory that can be rolled
      back using the interface will be the mock file system directory as well as
      the interface directory itself.**
    - For example, the interface does not prevent or protect the user from
      running `rm -rf $HOME`.
  - Need to display this in the README.txt when the client is distributed.

## Acknowledgements
- Some of the code used for the infrastructure was imported and modified from
  the following git repos:
  - TellinaTool/bash_task_interface.git
  - TellinaTool/user_study_chrome_extension.git
  - TellinaTool/resource-website.git

