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
    into CSV format, and append them to a single log file.
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
  - The directory where the user will perform tasks.
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
    shell as well. Tutorial would also teach users about `giveup`, `task`,
    `reset`, and `helpme`.
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
  - `giveup`: giveups the current task and goes to the next task.
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

The server implementation will be:
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
- **user_name**: the username associated with the information on the
  current row
- **machine_name**:
- **task_order**: the task order that was assigned to this user.
- **task_code**: the true task code of the current task.
- **treatment** for the current task: Tellina/NoTellina.
- **time_elapsed** (seconds): time in seconds the user took to formulate the command.
- **client_time_stamp**: the current time that the command was entered on the client
  side.
  - ISO-8601 formatted with UTC.
- **status**: `success` if the user succeeded, `timeout` if the user ran out of time,
  `giveup` if the user gave up on the task, and `incomplete` if the task is
  incomplete but the user still has time.
- **command**: the command that the user entered.

Example content of what `log.csv` could look like:

|server_time_stamp|user_name|machine_name|task_order|task_code|treatment|time_elapsed|client_time_stamp|status|command|
|-|-|-|-|-|-|-|-|-|-|
|2019-04-05T18:12:00Z|abc|machineA|s1Ts2NT|a|Tellina|33|2019-04-05T18:12:00Z|incomplete|find . -name "*.txt" -delete|
|2019-04-05T18:12:03Z|ddd|machineD|s1NTs2T|a|NoTellina|40|2019-04-05T18:12:00Z|success|find . -name "*.txt"|
|2019-04-05T18:12:04Z|abc|machineA|s1Ts2NT|a|Tellina|37|2019-04-05T18:12:00Z|incomplete|reset|
|2019-04-05T18:12:07Z|abc|machineA|s1Ts2NT|a|Tellina|40|2019-04-05T18:12:00Z|success|find . -name "*.txt"|
|...|...|...|...|...|...|...|...|...|...|
|2019-04-05T18:42:10Z|abc|machineB|s2Ts1NT|u|Tellina|100|2019-04-05T18:12:00Z|giveup|giveup|
|...|...|...|...|...|...|...|...|...|...|
|2019-04-08T18:48:02Z|bcd|machineB|s2Ts1NT|v|Tellina|300|2019-04-05T18:12:00Z|timeout|...|

The start time of a task is the **client_time_stamp** of the row where the
**command** column is "task started".  Its **time_elapsed** is 0.

The total time for a task is the **time_elapsed** of the row where the
**status** is either "success", "giveup", or "timeout". If the **status** is
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
|  |__prompts/        - Directory containing various text files used as prompts
|  |                    for the experiment.
|  |__tasks/
|  |  |__task1/
|  |  |  |__task1.json      - JSON file with description of task
|  |  |  |__task1.fs.out    - Expected state of file system
|  |  |  |__task1.std.out   - Expected stdout of user command
|  |  |__task2/
|  |  |  |__...
|  |  |__...
|  |__test/         - Contains testing code for the client side infrastructure
|  |  |               written in Bats.
|  |  |__*.bats     - Files defining tests for infrastructure.
|  |  |__*.bash     - "Library" files with helpful functions for testing.
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
- Set up <a id=variable_files>variable files</a> in the `.infrastructure` directory.
  This allows the client side to be resumed if a failure happens.
  - `.command`: the most recently entered command. Initial value is "start
    task"
  - `.task_num`: if this file exists during setup, the experiment will resume
    at the user task number written in this file.
  - `.noverify`: if this file exists, output verification will not be
    performed on the contents of `.command`.
- Initialize Bash variables that will be used throughout the experiment:
  - `time_elapsed`: the time in seconds that the user spent on a command.
    - This is because `$SECONDS` does not stop incrementing, and the time
      between the log write and the command being entered could be different by
      a few seconds. Initial value is `0`.
  - `status`: the status of the current task. Can be `success`, `timeout`,
    `giveup`, or `incomplete`. Initial value is "incomplete".
  - `task_num`: the user task number, this will be the task number showed
  - `task_set`: the current task set the user is in.
  - `treatment`: the current treatment.
  - `task_order`: the task order for the current user.
    to the user. Initial value is `1`.
- Initializes Bash constants to keep track of directories, time limits, task
  limits, etc.
- Defines user meta-commands.
- Gather user information including the machine name and the user's UWNetID.
- Determine the task order, which is which includes the order of the task set as
  well as the treatments.
  - An example task order would be: Task set 1 and no Tellina for the first
    half, task set 2 and Tellina for the second.
- Source `infrastructure.sh`, which defines the following functions:
  - `next_task`:
    - Increments the user task number, resets the `file_system` directory, and
      determines the following:
      - Whether to move on to the next task.
      - Whether the experiment is complete.
      - Whether to switch the statement.
  - `make_fs`:
    - Resets the `file_system` directory.
      - This method does not change the user's working directory.
  - `write_log`: Gather information needed for the log file:
- Install [Bash-Preexec](https://github.com/rcaloras/bash-preexec) by sourcing
  `bash-preexec.sh`.
- Set up the experiment prompts to follow the determined task order.
- Creates the `file_system` directory and changes the user into it.
- Begin the experiment.

#### Training
To familiarize the user to the infrastrcture, there will be two tasks provided
as training - one for the infrastructure and the other for Tellina.

The infrastructure training will be enabled at the beginning of the experiment,
right after the setup is complete. The Tellina training will only be enabled if
Tellina is to be used for the current half of the experiment.
If both infrastructure training and Tellina training is enabled, infrastructure
training will happen first, then Tellina training will happen right after.

The training is complete once the user succeeds the training task.

During the training:
- The user is expected to follow the instructions linked to by the training
  prompt.
- The user will not timeout.
- The user cannot `giveup` the training task.

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
  1. Check if user has ran out of time:
     - The check will happen after the command is executed.
     - If the user ran out of time, set the task `status` to `timeout`, write to
       the server log with `time_elapsed` truncated to the time limit, and move
       on to the next task.
  2. Handle `.noveriy` commands:
     - All user meta-commands are `.noverify` commands. The initial
        configuration command run by the user is also a `.noverify` command.
     - Output verification will not be performed on these commands.
     - The check is done by looking for the existence of the file
        `.noverify` in the `.infrastructure` directory.
      - The file is removed immediately after the check.
    - If `.noverify` is not empty and the content is "giveup", set the status
      to "giveup".
  3. Check if the command in `.command` is correct.
     - Does this by running `verify_output.py $task_code $(cat .command)` and
       checking its exit code.
     - If the exit code is:
       - `0`: set status to "success", otherwise set status to "incomplete".
       - `1`: open Meld for the file system.
       - `2`: open Meld for the file system, issue warning, and call
         `make_fs`.
       - `3`: open Meld for the `stdout`.
- Writes information about the most recently executed user command to the server
  log.
- If the status is either "giveup", "timeout" , or "success", call `next_task`.

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
  - <a id="exit-stat">**Exit code**</a>:
      - 0: The verification is successful.
      - 1: The output does not match expected and the task is a file system
        task.
      - 2: The file system has been changed and the task is a select task.
      - 3: The output does not match expected and the task is a select task.

#### Directory for experiment files:
- The files used for the experiment will be distributed in a TAR file along with
  the directory that contains them. Subsequent resets will extract the TAR into
  the directory that contains the files.
- The user will be performing tasks on files within this directory and can move
  around freely within it.

#### Testing

The client side is tested using [Bats](https://github.com/bats-core/bats-core).

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

