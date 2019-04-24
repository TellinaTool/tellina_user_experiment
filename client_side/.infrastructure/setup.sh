#!/bin/bash
# This script takes 1 argument which is the full path to the user experiment
# directory.
set -a

# Get the full path to the user experiment directory
EXP_DIR=$1
# Get the full path to the experiment's infrastructure directory
INFRA_DIR=$EXP_DIR/$(dirname ${BASH_SOURCE[0]})

# Makes sure that all the scripts are executable
chmod +x ${INFRA_DIR}/*.sh
chmod +x ${INFRA_DIR}/*.py

# Establish tasks directories and related variables
TASKS_SIZE=22

TASKS_DIR="${INFRA_DIR}/tasks"
TIME_LIMIT=300

USER_OUT="${INFRA_DIR}/user_out"

# Establish the file system directory the user will perform tasks on
FS_DIR="${EXP_DIR}/file_system"

# Establish the server information
SERVER_HOST="https://homes.cs.washington.edu/~atran35"
SERVER_ROUTE="/tellina_user_experiment/server_side/post_handler/post_handler.php"

# Establish infrastructure variables and functions
touch ${INFRA_DIR}/.{task_code,treatment,task_order,command}

echo "a" > ${INFRA_DIR}/.task_code
echo "start task" > ${INFRA_DIR}/.command

curr_task=0
time_elapsed=0
status="incomplete"
curr_task=0

MACHINE_NAME=$(hostname)
read -p "Enter your UW NetID: " USER_NAME

USER_ID="${USER_NAME}@${MACHINE_NAME}"

# Determine the task order based on a truncated md5sum hash of the username.
# The following table is used to determine the ordering with "s" indicating the
# task set, and T/NT for Tellina/NoTellina
#    | |  1st  |  2nd  |
#    |-|-------|-------|
#    |0|`s1 T` |`s2 NT`|
#    |1|`s2 T` |`s1 NT`|
#    |2|`s1 NT`|`s2 T` |
#    |3|`s2 NT`|`s1 T` |
case $(echo $((0x$(md5sum <<<${USER_NAME} | cut -c1) % 4))) in
  0)
    echo "T1N2" > ${INFRA_DIR}/.task_code
    echo "0" > ${INFRA_DIR}/.task_order
    echo "T" > ${INFRA_DIR}/.treatment
    ;;
  1)
    echo "T2N1" > ${INFRA_DIR}/.task_code
    echo "1" > ${INFRA_DIR}/.task_order
    echo "T" > ${INFRA_DIR}/.treatment
    ;;
  2)
    echo "N1T2" > ${INFRA_DIR}/.task_code
    echo "2" > ${INFRA_DIR}/.task_order
    echo "NT" > ${INFRA_DIR}/.treatment
    ;;
  3)
    echo "N2T1" > ${INFRA_DIR}/.task_code
    echo "3" > ${INFRA_DIR}/.task_order
    echo "NT" > ${INFRA_DIR}/.treatment
    ;;
esac

source ${INFRA_DIR}/interface_functions.sh
source ${INFRA_DIR}/user_functions.sh


# Install Bash preexec.
source ${INFRA_DIR}/bash-preexec.sh

# preexec will send user commands to the server
preexec_func() {
  # Gets all the variables needed by the infrastructure and logs the user's command
  TASK_NO=$(cat ${INFRA_DIR}/.curr_task)
  TREATMENT=$(cat ${INFRA_DIR}/.treatment)
  TIME_STAMP=$(date +%T)
echo "$1" > ${INFRA_DIR}/.prev_cmd }
precmd_func() {
  TIME_SPENT=${SECONDS}
  COMMAND=$(cat ${INFRA_DIR}/.prev_cmd)

  if [ $TIME_SPENT -gt $TIME_LIMIT ]; then
    next_task 2
  elif [ -n "$COMMAND" ] && [ "$COMMAND" != "abandon" ] && [ "$COMMAND" != "reset" ] && [ "$COMMAND" != "helpme" ] && [ "$COMMAND" != "task" ]; then
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

make_fs

# Stuff here
echo "Welcome to the user study!"
echo "At any point, run \"helpme\" to see a list of commands available to you during the study."
echo "You will have 5 minutes to complete each task. Once the timer is reached, the experiment"
echo "will move on to the next task."
echo "Make sure that you are performing the tasks in the $(basename $FS_DIR) directory"
echo "The experiment interface does not ensure that anything outside of that directory is protected."
echo "To start performing tasks, run \"start_experiment\""
