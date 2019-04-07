#!/bin/bash
set -a
# Get the client experiment directory
EXP_DIR=$PWD
# Get the client infrastructure directory
INFRA_DIR=$EXP_DIR/$(dirname ${BASH_SOURCE[0]})

# Establish tasks directories and related variables
TASKS_SIZE=22
TS_SIZE=11 # half of the TASKS_SIZE

TASKS_DIR="$INFRA_DIR/tasks"
TIME_LIMIT=300

# Establish the mock file system directory
FS_DIR="$EXP_DIR/file_system"

# Establish the server configurations
# TODO: change this to an actual host
HOST="localhost"
PORT="8080"

# Establish infrastructure variables and functions
touch $INFRA_DIR/.{curr_task,treatment,task_order,prev_cmd}

echo "1" > $INFRA_DIR/.curr_task
echo "0" > $INFRA_DIR/.task_order
echo "T" > $INFRA_DIR/.treatment

source $INFRA_DIR/interface_functions.sh

create_user
make_fs

source $INFRA_DIR/user_functions.sh

# Install Bash preexec.
curl --silent https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh -o $INFRA_DIR/bash-preexec.sh
source $INFRA_DIR/bash-preexec.sh

# preexec will send user commands to the server
preexec_func() {
  # Gets all the variables needed by the infrastructure and logs the user's command
  TASK_NO=$(cat $INFRA_DIR/.curr_task)
  TREATMENT=$(cat $INFRA_DIR/.treatment)
  TIME_STAMP=$(date +%T)

  echo "$1" > $INFRA_DIR/.prev_cmd
}

precmd_func() {
  TIME_SPENT=$SECONDS
  COMMAND=$(cat $INFRA_DIR/.prev_cmd)

  if [ $TIME_SPENT -gt $TIME_LIMIT ]; then
    echo "You've run about of time for task $TASK_NO. Moving on to the next task."
    next_task 2
  elif [ "$COMMAND" != "abandon" ] && [ "$COMMAND" != "reset" ] && [ "$COMMAND" != "help" ] && [ "$COMMAND" != "task"]; then
    verify_task
    if [ "$EXIT" = 1 ]; then
      next_task 1
    else
      echo "You've modified the file system, a diff of the changes has been shown."
      echo "You can continue, or run \"reset\" to restore the file system to its original state."
      STATUS=3
      write_log
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
