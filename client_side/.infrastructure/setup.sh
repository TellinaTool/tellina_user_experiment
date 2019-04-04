#!/bin/bash
# Get the client experiment directory
EXP_DIR=$PWD
# Get the client infrastructure directory
INFRA_DIR=$EXP_DIR/$(dirname ${BASH_SOURCE[0]})

# Establish tasks directories and related variables
TASKS_SIZE=22
TS_SIZE=11 # half of the TASKS_SIZE

TASKS_DIR="$INFRA_DIR/tasks"
TIME_LIMIT=300

# Establish the helpful commands that we'll use

# Establish the mock file system directory
FS_DIR="$EXP_DIR/file_system"

# Establish the server configurations
# TODO: change this to an actual host
HOST="localhost"
PORT="8080"

# Establish experiment variables and functions
source $INFRA_DIR/interface_functions.sh

create_user
make_fs

source $INFRA_DIR/user_functions.sh

# Install Bash preexec.
curl https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh -o $INFRA_DIR/bash-preexec.sh
source $INFRA_DIR/bash-preexec.sh

# preexec will send user commands to the server
preexec_func() {
  TASK_NO="${CURR_TS}_${CURR_TASK}"
  USER_CMD=$1
  write_log $CURR_RESETS $SECONDS $USER_CMD
}

precmd_func() {
  if [ "$USER_CMD" != "abandon" ] && [ "$USER_CMD" != "reset" ] && [ "$USER_CMD" != "help" ] && [ "$USER_CMD" != "task"]; then
    verify_task
    if [ "$EXIT" = 1 ]; then
      next_task 1
    else
      echo "You've modified the file system, a diff of the changes has been shown."
      echo "You can continue, or run \"reset\" to restore the file system to its original state."
    fi
  fi
}

# Stuff here
echo "Welcome to the user study!"
echo "At any point, run \"helpme\" to see a list of commands available to you during the study."
echo "You will have 5 minutes to complete each task. Once the timer is reached, the experiment"
echo "will move on to the next task."
echo "Make sure that you are performing the tasks in the $(basename $FS_DIR) directory"
echo "The experiment interface does not ensure that anything outside of that directory is protected."
echo "To start performing tasks, run \"start_experiment\""
