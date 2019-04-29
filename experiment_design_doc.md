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
- Server side: The server's main purpose is to store data from all
  experiments. This includes information about users, issued commands, time
  spent on tasks, etc.  It will not collect the user's browsing history.
  - The server will only handle POST requests from clients, convert the request
    into CSV format and append them to a single log file.
- Experiment Instructions (a web page):
  Information about the experiment.

  Requirements:  which terminal they should use, where to run it (attu or a
  CSE Home VM are guaranteed to work, other Linux systems with meld
  installed may work).

  **The client task interface does not guarantee that the user's file system
  will be safe from misused commands. The only directory that can be rolled
  back using the interface will be the mock file system directory as well as
  the interface directory itself.**
  For example, the interface does not prevent or protect the user from
  running `rm -rf $HOME`.

  To set up the client side for experimentation, the user will be instructed to
  run the following commands in a bash session:
  ```sh
  wget .../bash_experiment.zip
  unzip bash_experiment.zip
  source bash_experiment/configure
  ```
- Client side: this contains
  - Initial configuration script that sources infrastructure code (next
    bullet point) to setup the experiment and begin it.
    - Tests that `meld` is available.
    - Defunes [meta-commands](#user-interface) related to the experiment
    - Changes the user's current directory to be where they will
      perform tasks.
  - Infrastructure code: this code will add the following functionality to the
    Bash shell it was sourced in:
    - After command execution, checks whether the command produces the correct
      output (w.r.t. the state of the file system or standard output).
      - Displays a diff if the actual and expected outputs do not match.
      - (see [Client Side](#client-side) for more details).
    - Logs information about each command from the user for the experiment to
      the server (see [log file format](#logging) on what information is sent).
      - It also [saves some information locally](#variable_files) as well.
  - The directory in which the user will perform tasks in.
- Tasks:
  - We will have `N` tasks for each user.
  - Each task has two different labels:
    - The "User Task Number": a number from `1` to `N`.
    - The "True Task Code": an alphabetic letter, starting from `a` to `z`, then
      `A` to `Z`, depending on what `N` is.
    - **Note**: the reason we need a "user task number" and a "true task code"
      is because some users might end up starting the experiment with task set
      2, in which case, if `N = 22`, the "user task number" will be `1` and
      the "true task code" will be "k".
  - Each task will have a corresponding expected output file for both file
    system output and standard output.
  - The two initial tasks that the user will be doing will be tutorial
    tasks. The tutorial will print instructions on what to do for each step to the
    shell as well. Tutorial would also teach users about `abandon`, `task`, and
    `reset`.
- Analysis scripts to process server logs: determine relative
  performance of subjects using Tellina versus those who are not, via
  statistical analysis.  This will be done with a post-processing program.

### User Experience

Users are given the URL to the experiment instructions.

Throughout the experiment, the users will be interacting with the bash shell, Meld, and a web browser of their choice.
  - They will use a Bash shell to perform tasks and man page lookups.
  - Meld is displayed to the user when actual output does not match expected
    output for commands they entered. More specifically:
    - Meld will close when the user enters a new command.
    - Meld will open iff the output of the command entered does not correspond
      with the expected output (either for the file system or `stdout`).
  - They will use the web browser to find resources and interact with Tellina
    (when applicable).

### User Interface

The Bash shell for the experiment will have all built-in commands, prompts, and
pipes unchanged. The experiment infrastructure, once set up, will add the
following differences to the shell's interface (assume print means "print to
`stdout`" unless specified otherwise):
- The user will be able to run the following **user meta-commands**:
  - `task`: prints the current task's description and number
  - `abandon`: abandons the current task and goes to the next task.
  - `reset`: reset the file system, without changing the user's current
    working directory.
    - This command will return the user to the directory where they called it.
  - `helpme`: lists the commands available to the user
- Prints any messages related to the experiment (prompts, current task
  descriptions, welcome/clean-up messages, warnings, etc.) to `stdout`.

Meld and the web browser are unmodified.

## Implementation
### Server side
The server side should be hosted on the [UW CSE's
Homes](https://www.cs.washington.edu/lab/web) or any machine maintained by the
department. This recudes the likelihood that the server goes down without
##us noticing, and eliminates the need for us to monitor it.

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
- **task_code**: the true task code of the current task.
- **treatment** for the current task: Tellina/NoTellina.
- **time_elapsed** (seconds): time in seconds the user took to formulate the command.
- **status**: `success` if the user succeeded, `timeout` if the user ran out of time,
  `abandon` if the user abandoned the task, and `incomplete` if the task is
  incomplete but the user still has time.
- **command**: the command that the user entered.

Example content of what `log.csv` could look like:

|server_time_stamp|user_id|task_order|client_time_stamp|task_code|treatment|time_elapsed|status|command|
|-|-|-|-|-|-|-|-|-|
|2019-04-05T18:12:00Z|abc@machineA|s1Ts2NT|2019-04-05T18:12:00Z|a|Tellina|33|incomplete|find . -name "*.txt" -delete|
|2019-04-05T18:12:03Z|ddd@machineD|s1NTs2T|2019-04-05T18:12:00Z|a|NoTellina|40|success|find . -name "*.txt"|
|2019-04-05T18:12:04Z|abc@machineA|s1Ts2NT|2019-04-05T18:12:00Z|a|Tellina|37|incomplete|reset|
|2019-04-05T18:12:07Z|abc@machineA|s1Ts2NT|2019-04-05T18:12:00Z|a|Tellina|40|success|find . -name "*.txt"|
|...|...|...|...|...|...|...|...|...|
|2019-04-05T18:42:10Z|abc@machineB|s2Ts1NT|2019-04-05T18:12:00Z|u|Tellina|100|abandon|abandon|
|...|...|...|...|...|...|...|...|...|
|2019-04-08T18:48:02Z|bcd@machineB|s2Ts1NT|2019-04-05T18:12:00Z|v|Tellina|300|timeout|...|

The start time of a task is the **client_time_stamp** of the row where the
**command** column is "task started".  Its **time_elapsed** is 0.

The total time for a task is the **time_elapsed** of the row where the
**status** is either "success", "abandon", or "timeout". If the **status** is
"timeout", **time_elapsed** will be the time limit.

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
The directory structure for the client side after extracting the ZIP archive
will look similar to:
```
user_experiment/
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
The instructions on how to set up the experiment will be on the website where
the user is also downloading the ZIP archive.

The script will source `.infrastructure/setup.sh`, which will do the following:
- Set up <a id=variable_files>variable files</a> that will keep track of the
  current task, task order, treatment, and the most recent command.
  - This will allow the client side to be resumed if a failure happens.
  - The files will be in the `.infrastructure` directory.
  - Files:
    - `.treatment`: the treatment for the current task
    - `.command`: the most recently entered command. Initial value is "start
      task"
    - `.task_order`: the task ordering for this user.
    - `.task_code`: the true task code of the current task. This is sent to the
      server.
- Initialize Bash variables that will be used throughout the experiment:
  - `time_elapsed`: the time in seconds that the user spent on a command.
    - This is because `$SECONDS` does not stop incrementing, and the time
      between the log write and the command being entered could be different by
      a few seconds. Initial value is `0`.
  - `status`: the status of the current task. Can be `success`, `timeout`,
    `abandon`, or `incomplete`. Initial value is "incomplete".
  - `curr_task`: the user task number, this will be the task number showed
    to the user. Initial value is `1`.
- Initializes Bash constants to keep track of directories, time limits, task
  limits, etc.
- Defines user meta-commands:
  - Each meta-command will be `alias <command_name>='touch .<command_name>'`.
- Create the user ID by gathering user information: stored in `$USER_ID`
  constant
  - Machine name: determined by the `hostname` bash command
  - Username: the user will be asked to enter their UW NetID
  - User ID will then be `username@machine_name`.
- Determine the task set ordering:
  - Stored in `.task_order` as the concatenation of the "1st" and "2nd" column
    for a row.
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
    - Writes the treatment to `.treatment`, the true task code to `.task_code`
- Source `infrastructure.sh`, which defines the following functions:
  - `next_task`:
    - Call `make_fs`.
    - "Increment" the code in `.task_code` (`a -> b`, etc.)
    - Increment the `curr_task` bash variable. This is the task number printed
      to the user.
      - If this variable is equal to `N / 2`, switch treatments and task sets
        and notify the user.
      - Check if all the tasks are complete, if it is then skip the following
        steps and clean up instead.
    - Set `time_elapsed=0`, `status="incomplete"`
    - Write "start task" to `.command`.
    - Call `write_log`. This writes the "start task" row to the log file.
    - Call `get_tasks_description.py $(cat .task_code)`.
    - Set `SECONDS=0`.
      - `SECONDS` is a build-in Bash variable that increments every second. The
        infrastructure uses this to check the time elapsed.
  - `make_fs`:
    - Gets the current working directory. Then changes to the base experiment
      directory (`user_experiment` from [Directory
      Structure](#directory-structure))
    - Removes the `file_system` directory and extracts the tarball to that
      directory.
    - Changes the user to the stored directory.
  - `write_log`:
    - Gather information needed for the log file:
      - The server time stamp is handled by the server.
      - `user_id`: `$USER_ID`
      - `task_order`: `$(cat .task_order)`
      - `client_time_stamp`: `$(date --utc +%FT%TZ)`
      - `task_code`: `$(cat .task_code)`
      - `treatment`: `$(cat .treatment)`
      - `time_elapsed`: `$time_elapsed`
      - `status`: `$status`
      - `command`: `.command`
    - Use `curl` to send the form with all gathered information to the server to
      write to the log. See `server_side/post_handler/example` for an example of
      what this could look like.
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
- Kill Meld.

##### `precut`:
- Ran right after the user command is executed and right before the
  prompt is displayed.
- Only one of the following cases can happen every time a command has finished
  executing:
  1. Check if user has ran out of time:
     - `time_elapsed=$SECONDS` is less than some time limit constant.
     - The check will happen after the command is executed.
     - If the user ran out of time, `status="timeout"`,
       `time_elapsed=$TIME_LIMIT`.
  2. Handle user meta-command:
     - Output verification will not be performed on these commands.
     - The check is done by looking for the existence of the file
        `.<commmand_name>` in the `.infrastructure` directory.
     - If `abandon`:
       - Set `status="abandon"`.
       - Remove `.abandon`.
     - Otherwise
       - If `reset`: Call `make_fs`. Remove `.reset`.
       - If `helpme`: print the list of user meta-commands. Remove `.helpme`.
       - If `task`: call `get_task_description.py` with `.task_code` to print the
         task's description. Remove `.task`
       - Set `status="incomplete"`.
  3. Check if the command in `.command` is correct.
     - Does this by setting `status=$(verify_output.py $(cat .task_code) $(cat
       .command))`
     - This sets `status` to either "success" or "incomplete".
     - If `status == "incomplete"` check the [exit code](#exit-stat) of
       `verify_output.py`:
       - `1`: open Meld for the file system.
       - `2`: open Meld for the file system, issue warning, and call
         `make_fs`.
       - `3`: open Meld for the `stdout`.
- Call `write_log`. This writes information about the most recently executed
  user command.
- If `status="abandon" || status="timeout" || status="success"`, call
  `next_task`.

#### Output verification:
- Verification will be done using a python script called
  `verify_output.py`:
  - **Parameters**: `<task_code> [command...]`
    - Each parameter after `<task_code>` is interpreted as part of the command
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
- The files used for the experiment will be distributed in a TAR file along with
  the directory that contains them. Subsequent resets will extract the TAR into
  the directory that contains the files.
- The user will be performing tasks on files within this directory and can move
  around freely within it.

## Risks and Concerns
- Do we want to automatically reset the file system after each command?
  - Encourages one-liner solutions.
     - But, is it necessary to enforce this?
  - Removes the necessity of the `reset` command. Less things for the user to worry about.

## Acknowledgements
- Some of the code used for the infrastructure was imported and modified from
  the following git repos:
  - TellinaTool/bash_task_interface.git
  - TellinaTool/user_study_chrome_extension.git
  - TellinaTool/resource-website.git

