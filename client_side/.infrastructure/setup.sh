#!/bin/bash
# This script takes 1 argument which is the absolute path to the user experiment
# directory.

# Checks if the user has a usable graphical display. Detects X forwarding as
# well.
if ! xhost &> /dev/null; then
  echo "No display detected, please make sure that you are" \
    "setting up the experiment in an environment with a graphical display."
  return 1
fi

# Automatically export any assigned variables
set -a

################################################################################
#                              CONSTANT DEFINITIONS                            #
################################################################################

# Saves the old value of PROMPT_COMMAND, since Bash Preexec overwrites it.
PROMPT_COMMAND_ORIG=${PROMPT_COMMAND}

# The absolute path to the user experiment directory
EXP_DIR="$1"
# The absolute path to the experiment's infrastructure directory
INFRA_DIR="${EXP_DIR}/$(dirname ${BASH_SOURCE[0]})"

# Establish tasks directories and related variables
TASKS_DIR="${INFRA_DIR}/tasks"

TASKS_SIZE=$(ls -1 "${TASKS_DIR}" | wc -l)
TASK_TIME_LIMIT=300

# Contains output of user commands.
USER_OUT="${INFRA_DIR}/user_out"

# The directory the user will perform tasks on
FS_DIR="${EXP_DIR}/file_system"

# The directory used by the infrastructure to reset FS_DIR.
# It is created by extracting the fs.tgz tarball in INFRA_DIR.

# The reason this isn't also distributed with the client ZIP is to prevent any
# confusion as well as having a relatively smaller ZIP file.
FS_SYNC_DIR="${INFRA_DIR}/file_system"
if [[ ! -d "${FS_SYNC_DIR}" ]]; then
  mkdir "${FS_SYNC_DIR}"
  tar -xzf "${INFRA_DIR}/fs.tgz" -C "${FS_SYNC_DIR}"
fi

# Establish the server information
SERVER_HOST="https://homes.cs.washington.edu/~atran35"
# Establish survey URL
EXPERIMENT_HOME_URL="${SERVER_HOST}/tellina_user_experiment"

POST_HANDLER="${EXPERIMENT_HOME_URL}/server_side/post_handler/post_handler.php"

MACHINE_NAME=$(hostname)
read -p "Enter your UW NetID: " USER_NAME

USER_ID="${USER_NAME}@${MACHINE_NAME}"

################################################################################
#                              VARIABLE DEFINITIONS                            #
#             This includes bash variables as well as variable files           #
################################################################################

# Establish infrastructure variables and functions
source "${INFRA_DIR}"/infrastructure.sh

# If a task_num file already exists, it means we are trying to resume the
# experiment
if [[ -f "${INFRA_DIR}/.task_num" ]]; then
  task_num=$(cat "${INFRA_DIR}/.task_num")
else
  task_num=1
  echo "${task_num}" > "${INFRA_DIR}/.task_num"
fi

# Determine the task order based on a truncated md5sum hash of the username.
# It is two two-character codes.  In each two-character code, the letter
# T/N is for Tellina/NoTellina, and the number indicates the task_set used.
TASK_ORDERS_CODES=("T1N2" "T2N1" "N1T2" "N2T1")

TASK_ORDER=${TASK_ORDERS_CODES[$((0x$(md5sum <<<${USER_NAME} | cut -c1) % 4))]}

# Create user meta-commands.
# Each user meta-commands will create a file called .noverify in the
# infrastructure directory

# abandon writes "abandon" to `.noverify`.
# This is to allow `abandon` to be an alias and delegates setting the $status
# variable to precmd.
alias abandon='echo "abandon" > ${INFRA_DIR}/.noverify'

alias reset='reset_fs; touch ${INFRA_DIR}/.noverify'
alias task='print_task; touch ${INFRA_DIR}/.noverify'
alias helpme='echo "task: prints the description of the current task."; \
   echo "reset: restore the file system to its original state."; \
   echo "abandon: abandon the current task."; \
   echo "helpme: prints this help message."; \
   touch ${INFRA_DIR}/.noverify'

################################################################################
#                                  BASH PREEXEC                                #
################################################################################

# Install Bash preexec.
source "${INFRA_DIR}"/bash-preexec.sh

# Executed before the user-entered command is executed
# Saves the most recent command into the .command file
# If the user enters an "empty" command, then the .command file does not change
preexec_func() {
  echo "$1" > "${INFRA_DIR}/.command"
}

# Executed after the user-entered command is executed
# - Only one of these cases can happen
# 1. Check if user has run out of time:
#    - `time_elapsed=$SECONDS` is more than some time limit constant.
#    - The check will happen after the command is executed.
#    - If the user ran out of time, `status="timeout"`,
#      `time_elapsed=$TIME_LIMIT`.
# 2. Handle user meta-command:
#    - Output verification will not be performed on these commands.
#    - The check is done by looking for the existence of the file
#       `.noverify` in the `.infrastructure` directory
#    - If `.noverify` contains the string "abandon", also sets status="abandon"
#    - Removes `.noverify`.
# 3. Check if the command in `.command` is correct.
#    - Does this by setting `status=$(verify_output.py $(cat .task_code) $(cat
#      .command))`
#    - This sets `status` to either "success" or "incomplete".
#    - If `status == "incomplete"` check the [exit code](#exit-stat) of
#      `verify_output.py`:
#      - `1`: open Meld for the file system.
#      - `2`: open Meld for the file system, issue warning, and call
#        `reset_fs`.
#      - `3`: open Meld for the `stdout`.
# - Call `write_log`. This writes information about the most recently executed
#   user command.
# - If `status="abandon" || status="timeout" || status="success"`, call
#   `next_task`.
precmd_func() {
  time_elapsed=${SECONDS}
  if (( time_elapsed >= TASK_TIME_LIMIT )); then
    echo "You have run out of time for task ${task_num}"

    status="timeout"
    time_elapsed=${TIME_LIMIT}
  elif [[ -f "${INFRA_DIR}/.noverify" ]]; then
    if [[ "$(cat "${INFRA_DIR}/.noverify")" == "abandon" ]]; then
      status="abandon"
    fi

    rm "${INFRA_DIR}/.noverify"
  else
    verify_task

    if [[ ${status} == "incomplete" ]]; then
      if (( EXIT == 2 )); then
        echo "You have modified the file system. It will now be reset to its" \
          "original state."
        reset_fs
      else
        echo "Actual output does not match expected. A diff has been shown."
      fi

      meld "/tmp/actual" "/tmp/expected" &
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

# Prints the introduction here
echo "Welcome to the user study!"
echo "At any point, run \"helpme\" to see a list of commands available to" \
  "you during the study."
echo "You will have 5 minutes to complete each task. Once the timer is" \
  "reached, the experiment will move on to the next task."
echo "Make sure that you are performing the tasks in the" \
  "$(basename $FS_DIR) directory"
echo "The experiment interface does not ensure that anything outside" \
  "of that directory is protected."

start_experiment
