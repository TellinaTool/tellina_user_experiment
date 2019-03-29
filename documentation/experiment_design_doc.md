# Tellina User Study Design Doc

## Introduction

Tellina is a natural language -> command translation tool, which accepts a
natural language description of file system operations, and displays a ranked
list of bash one-liner suggestions made by the model. The user can scroll down
the web page to explore more suggestions.

To answer questions regarding the usefulness of the tool, people were given
descriptions of file system operations, and asked to write bash commands to
perform the operations.  The experimental group had access to Tellina, web
search, and man pages; the control group had access only to web search and
man pages. Measurements were done on whether subjects successfully complete the
tasks, and the amount of time that it takes to complete the tasks.  We will also
obtain qualitative feedback from a post-task questionnaire.

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

The experiment infrastructure will be consisted of several components:
- Server side: The server's main purpose is to collect and store data from all
  experiments. This includes information about users, issued commands, time
  spent on tasks, browsing history, etc.
- Client side: the client side consists of the following components
  - A slightly modified bash interface for the user to interact with.
  - Scripts that verify the output of a command and displays a diff.
  - Initial configuration script to set up the user and make sure that the
    server is responding.
  - Scripts that will send data to the server.
  - The directory with which the user will perform tasks on.
- Tasks:
  - We will have `N` tasks for each user:
  - The first `N/2` tasks will be logged as `1_n` where `n` is the task number
    in the set.
  - The second `N/2` tasks will be logged as `2_n` where `n` is the task number
    in the set.

## Implementation
### Server side
### Experiment data directory
This directory will hold all data collected from each experiment that was run.
It will have a rough structure of:
```
/
|__user1
|  |__log.csv
|  |__browser_hist.txt
|__user2k
|  |__log.csv
|  |__browser_hist.txt
|__user3
|__...

```

`log.csv` will have the following columns:
- task_no: the set_task number.
- treatment: T/NT for Tellina/No Tellina
- command: the command or a list of commands (separated with `;`) issued by
  the user.
- time (seconds): time in seconds the user took on a task
- status: `1` if the user succeeded, `2` if the user ran out of time, `0` if the
  user abandoned the task.
- resets: the number of times the user reset the file system.

`browser_hist.txt` will be a plain text file with links of all websites accessed
by the user during the experiment.

### Server application
There will be a simple Flask application managing the data directory.

The app will handle the following requests from the client:
- `create_user()`:
  - Route: `/methods/create_user`, methods: `POST`
  - Expected request:
    ```
    POST /methods/create_user
    Host: host
    Content-Type: application/x-www-form-urlencoded
    Content-Length: ...

    user_id=user_id
    ```
  - Creates a new user directory `user_id` and the CSV file associated to the
    user.
  - Respond with the `user_id` and the success code.
- `get_user_route(user_id)`
  - Route: `/methods/get_user_route`, methods: `GET`
  - Expected request:
    ```
    GET /methods/get_user_route?user_id=user_id
    ```
  - Returns the route for `user_id`.
  - If route not found then return a 404.
- `task_order()`
  - Route: `/methods/task_order`, methods: `GET`
  - Identify which task set ordering needs to be attributed to a user based on
    current distribution of task set ordering.
  - We will have 4 task orderings, with `s1, s2` as task set 1 and 2, and `T,
    NT` for Tellina and No Tellina

    ||1st|2nd|
    |-|-|-|
    |0|`s1 T`|`s2 NT`|
    |1|`s2 T`|`s1 NT`|
    |2|`s1 NT`|`s2 T`|
    |3|`s2 NT`|`s1 T`|
  - The method will choose the task ordering with the lowest number of samples,
    and at random if there are ties.
- `write_log(user_id)`:
  - Route: `/user/<user_id>/log`, methods: `POST`
  - Expected request:
    ```
    POST /user/<user_id>
    Host: host
    Content-Type: application/x-www-form-urlencoded
    Content-Length: ...

    key1=value1&key2=value2&...
    ```
  - The keys that are accepted are: `task_no`, `treatment`, `command`, `time`,
    `status`, `resets`.
  - The method will update each field accordingly in the user's CSV file.
    - If the field is not provided or empty, then the corresponding column in
      the CSV file will not be changed.
    - If the `command` field is not empty, then the column will be checked. If
      the column is empty then the command will be added, otherwise, it will be
      appended to the existing command, separated by a `;`.

- `write_browser_hist(user_id)`:
  - Route: `/user/<user_id>/browser`, methods: `POST`
  - Expected request:
    ```
    POST /user/<user_id>
    Host: host
    Content-Type: multipart/form-data
    Content-Length: ...

    data
    ```
  - This method takes in a file with the user's browsing history

### Client side
The client side will use common bash commands along with the help of several
python scripts to run the experiments. It is expected that the client side can
run on the CSE Linux VM without issue, and could potentially work on Attu as
well.

#### Setting Up
To set up the client side for experimentation, a `configure` bash script will be
run by the user.

The script will do the following:
- Set up necessary environment variables.
- Set up necessary aliases for `reset`, `abandon`.
- Install [Bash-Preexec](https://github.com/rcaloras/bash-preexec).
- Prompt the user to install the Chrome history tracking extension
  - Check if the extension is installed?
- Collect user information:
  - Machine name
  - User name
- Send user information to the server and get the user URL for the experiment.
- Set up the task set ordering:
  - Get the ordering from the server
  - Set up the experiment prompts to follow that order.

For Bash-Preexec, the following configurations will be implemented:
- `preexec`:
  - Send command to the server
- `precmd`:
  - Check for specific commands:
    - `abandon`: reset the timer and go on to next task
    - `reset`: reset the file system and increment `resets` count in log file
  - Check if the previous command's output is correct. If it is then move on to
    the next task, if not then display a diff of the file system and let the
    user continue.
  - Determine if the user ran out of time or abandoned the task.
  - Keep track of the time limit for the user (using the `$SECONDS` environment
    variable).
  - Check if all the tasks are complete.
    - Remind them to uninstall the extension.
    - Remind them to do the survey.
  - Send user's data to the server:
    - Task number
    - Treatment.
    - Command(s) used.
    - Time taken.
    - Status.
    - Resets.

#### Communication With Server
Communication with the server will be done through simple bash functions that
act as wrappers around `curl` to send HTTP requests.

The functions are:
- `create_user()`:
  - Gets the machine name and the user's name.
  - Sends `POST` request to the server to create a user directory.
  - Sends `GET` request to the server to get the user's URL and save it into an
    environment variable.

- `get_task_order()`:
  - Sends `GET` request to get the task ordering for the current user.
  - Returns a number from [0-3] that determines the ordering.

- `write_log()`:
  - Parameters: `command` (optional), `time` (optional), `status` (optional),
    `resets` (optional).
    - All parameters are optional, but each call to write log will use the
      current user ID, task, and treatment.
  - Sends a `POST` request to the server with the specified parameters.

#### Tracking Browsing History
Browsing history will be tracked by a Chrome extension that the user will have
to install.

The extension will communicate directly with the server, sending webpages
accessed by the user and writing it to the `browser_hist.txt` file.

#### Task Interface
- Mock File System
  - The files used for the file system will be distributed in a TAR file. The
    initial configuration of the interface and subsequent resets will extract
    the TAR into a specified directory.
  - Tasks directory:
    - For each task, a corresponding expected output file is kept as well.
    - Each task and it's expected output (for both `stdout` and `fs` structure)
      will be kept in their respective task sets in folders `tasks` and
      `expected`.
  - Output verification:
    - Verification will be done using a python script called
      `verify_output.py`:
      - Parameters: `<task_no> <time_elapsed> [command...]`
      - Return: `1` if the task passed, `0` if it did not.
      - The script will get the current state of the file system, normalize it,
        and compare it with the corresponding task's expected output.
      - The script will also check the `stdout` of the user command on the
        corresponding expected output as well.
    - If the verification passes, the interface will reset the mock file system,
      send a `1` to the log file, and move on to the next task.
- Tutorial
  - 2 simple tasks will be displayed to the user in the beginning of the
    experiment to introduce them to Tellina and how the system works.
- Time limit:
  - Each task will have up to **5** minutes to be completed.
  - Once the time limit is reached, the user will be interrupted.
  - This will reset the timer, the mock file system, send a `2` status to the
    server, and move on to the next task.
- Custom commands:
  - `reset`:
    - Reset the file system and increment the number of resets in the log file.
  - `abandon`:
    - Abandoning a task will reset the timer, the mock file system, and send a `0`
      status to the log file.
  - `help`:
    - Prints out the two custom commands
  - `task`:
    - Prints out the current task description.

## Risks and Concerns
- Scalability.
  - Is using Flask the right approach for the server side?
  - Hosting flask on the dev server will not scale well, will have to host on a
    WSGI server.
  - Have to ensure good runtime for logging code and verification code.
- User file system safety.
  - **The client task interface does not guarantee that the user's file system
      will be safe from misused commands. The only directory that can be rolled
      back using the interface will be the mock file system directory as well as
      the interface directory itself.**
    - For example, the interface does not prevent or protect the user from
      running `rm -rf $HOME`.
- How to enforce logging tool (specifically browser history logging)?
  - Should the tutorial check that? Should the initial config check that?
- Should we limit the number of resets and commands?
  - Why? How many?

## Acknowledgements
- Some of the code used for the infrastructure was imported and modified from
  the following git repos:
  - TellinaTool/bash_task_interface.git
  - TellinaTool/user_study_chrome_extension.git
  - TellinaTool/resource-website.git

