#!/bin/bash
# This script takes 1 argument which is the full path to the user experiment
# directory.
if ! xhost &> /dev/null; then
  echo "No display detected, please make sure that you are" \
    "setting up the experiment in an environment with a graphical display."
  return 1
fi

set -a

# Saves the old value of PROMPT_COMMAND, since Bash Preexec overrides it
PROMPT_COMMAND_OG=${PROMPT_COMMAND}

# Get the full path to the user experiment directory
EXP_DIR="$1"
# Get the full path to the experiment's infrastructure directory
INFRA_DIR="${EXP_DIR}/$(dirname ${BASH_SOURCE[0]})"

# Makes sure that all the scripts are executable
chmod +x "${INFRA_DIR}"/*.sh
chmod +x "${INFRA_DIR}"/*.py

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
source "${INFRA_DIR}"/infrastructure.sh
touch "${INFRA_DIR}"/.{task_code,treatment,task_order,command}

echo "start task" > "${INFRA_DIR}/.command"

time_elapsed=0
status="incomplete"
curr_task=1

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
    echo "T1N2" > "${INFRA_DIR}/.task_order"
    echo "T" > "${INFRA_DIR}/.treatment"
    task_set=1
    ;;
  1)
    echo "T2N1" > "${INFRA_DIR}/.task_order"
    echo "T" > "${INFRA_DIR}/.treatment"
    task_set=2
    ;;
  2)
    echo "N1T2" > "${INFRA_DIR}/.task_order"
    echo "NT" > "${INFRA_DIR}/.treatment"
    task_set=1
    ;;
  3)
    echo "N2T1" > "${INFRA_DIR}/.task_order"
    echo "NT" > "${INFRA_DIR}/.treatment"
    task_set=2
    ;;
esac

echo $(get_task_code) > "${INFRA_DIR}/.task_code"

alias reset="touch ${INFRA_DIR}/.reset"
alias task="touch ${INFRA_DIR}/.task"
alias abandon="touch ${INFRA_DIR}/.abandon"
alias helpme="touch ${INFRA_DIR}/.helpme"

# Install Bash preexec.
source "${INFRA_DIR}"/bash-preexec.sh

# preexec will send user commands to the server
preexec_func() {
  # Gets all the variables needed by the infrastructure and logs the user's command
  echo "$1" > "${INFRA_DIR}/.command"
  curr_task=$(cat "${INFRA_DIR}/.curr_task")
  treatment=$(cat "${INFRA_DIR}/.treatment")
  time_stamp=$(date +%T)
}

precmd_func() {
  time_elapsed=${SECONDS}

  if (( time_elapsed >= TIME_LIMIT )); then
    status="timeout"
  elif [[ -f "${INFRA_DIR}/.abandon" ]]; then
    status="abandon"

    rm "${INFRA_DIR}/.abandon"
  elif [[ -f "${INFRA_DIR}/.reset" ]]; then
    status="incomplete"
    make_fs

    rm "${INFRA_DIR}/.reset"
  elif [[ -f "${INFRA_DIR}/.task" ]]; then
    status="incomplete"

    print_task

    rm "${INFRA_DIR}/.task"
  elif [[ -f "${INFRA_DIR}/.helpme" ]]; then
    status="incomplete"

    echo "task: prints the description of the current task."
    echo "reset: restore the file system to its original state."
    echo "abandon: abandon the current task."
    echo "helpme: prints this help message."

    rm "${INFRA_DIR}/.helpme"
  elif [[ "$(cat "${INFRA_DIR}/.command")" == "start task" ]]; then
    status="incomplete"
  else
    verify_task

    if [[ ${status} == "incomplete" ]]; then
      if (( EXIT == 2 )); then
        echo "You have modified the file system. It will now be reset to its" \
          "original state."
        make_fs
      else
        echo "Actual output does not match expected. A diff has been shown."
      fi

      meld "/tmp/task_actual" "/tmp/task_expected" &
    elif [[ -z ${status} ]]; then
      status="Verification error!"
    fi
  fi

  write_log
  if [[ "${status}" == "abandon" ]] || \
     [[ "${status}" == "timeout" ]] || \
     [[ "${status}" == "success" ]]; then
    next_task
  fi
}

make_fs
cd "${FS_DIR}"

# Stuff here
echo "Welcome to the user study!"
echo "At any point, run \"helpme\" to see a list of commands available to you during the study."
echo "You will have 5 minutes to complete each task. Once the timer is reached, the experiment"
echo "will move on to the next task."
echo "Make sure that you are performing the tasks in the $(basename $FS_DIR) directory"
echo "The experiment interface does not ensure that anything outside of that directory is protected."
start_experiment
