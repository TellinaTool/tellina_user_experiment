#!/bin/bash
# This script takes 1 argument which is the absolute path to the user experiment
# directory.

# Automatically export any assigned variables
set -a

################################################################################
#                              CONSTANT DEFINITIONS                            #
################################################################################

# The absolute path to the user experiment directory
EXP_DIR="$1"
# The absolute path to the experiment's infrastructure directory
INFRA_DIR="${EXP_DIR}/$(dirname ${BASH_SOURCE[0]})"

# Enables infrastructure functions.
source "${INFRA_DIR}"/infrastructure.sh

# Checks if the user has a usable graphical display. Detects X forwarding as
# well.
if ! xhost &> /dev/null; then
  print_experiment_prompt "no_display"
  return 1
fi

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
read -p "Enter your UW NetID: " UW_NETID

################################################################################
#                              VARIABLE DEFINITIONS                            #
#             This includes bash variables as well as variable files           #
################################################################################
# If a task_num file already exists, it means we are trying to resume the
# experiment.
if [[ -f "${INFRA_DIR}/.task_num" ]]; then
  task_num=$(cat "${INFRA_DIR}/.task_num")

  # Because we are incrementing the initial task num by one, if we are
  # recovering to the middle of the experiment, we have to set this to one lower
  # to allow the user to start at the task where they previous stopped.
  task_num=$((task_num - 1))
else
  task_num=0
  echo "${task_num}" > "${INFRA_DIR}/.task_num"
fi

# Determine the task order based on a truncated md5sum hash of the username.
# It is two two-character codes.  In each two-character code, the letter
# T/N is for Tellina/NoTellina, and the number indicates the task_set used.
TASK_ORDERS_CODES=("T1N2" "T2N1" "N1T2" "N2T1")

TASK_ORDER=${TASK_ORDERS_CODES[$((0x$(md5sum <<<${UW_NETID} | cut -c1) % 4))]}

# Create user meta-commands.
# Each user meta-command will create a file called .noverify in the
# infrastructure directory.

# abandon writes "abandon" to `.noverify`.
# This is to allow `abandon` to be an alias and delegates setting the $status
# variable to precmd.
alias abandon='echo "abandon" > ${INFRA_DIR}/.noverify'

alias reset='reset_fs; touch "${INFRA_DIR}"/.noverify'
alias task='print_task; touch "${INFRA_DIR}"/.noverify'
alias helpme='print_experiment_prompt "helpme" ; touch ${INFRA_DIR}/.noverify'

################################################################################
#                                  BASH PREEXEC                                #
################################################################################

# Saves the old value of PROMPT_COMMAND, since Bash Preexec overwrites it.
PROMPT_COMMAND_ORIG=${PROMPT_COMMAND}

# Install Bash preexec.
source "${INFRA_DIR}"/bash-preexec.sh

# Executed before the user-entered command is executed.
# Saves the most recent command into the .command file.
# If the user enters an "empty" command, then the .command file does not change.
preexec_func() {
  echo "$1" > "${INFRA_DIR}/.command"
}

# Executed after the user-entered command is executed
#
# This function does 1 of 2 things:
# 1. Determine if the user has run out of time.
# 2. Verify the output of the user command unless it was a meta-command.
#
# In either case, $status will be set to either "timeout", "success",
# "incomplete", or "abandon".
# If the status is not "incomplete", move on to the next task.
#
# This function always writes to the log.
precmd_func() {
  time_elapsed=${SECONDS}

  if (( time_elapsed >= TASK_TIME_LIMIT )); then
    # Checks if the user has run out of time. If they have, $time_elapsed is
    # truncated to the time limit
    echo "You have run out of time for task ${task_num}"

    status="timeout"
    time_elapsed=${TIME_LIMIT}
  elif [[ -f "${INFRA_DIR}/.noverify" ]]; then
    # Check if output verification should not be run.
    # This can happen if the user entered a user meta-command or at the
    # beginning of the experiment.

    # if the .noverify file has "abandon" in it, then the user used the
    # "abandon" meta-command.
    if [[ "$(cat "${INFRA_DIR}/.noverify")" == "abandon" ]]; then
      status="abandon"
    fi

    rm "${INFRA_DIR}/.noverify"
  else
    # Verify the command inside of .command.
    # Meld is opened if the exit code is non-zero.
    verify_task || meld "/tmp/actual" "/tmp/expected"
  fi

  write_log
  if [[ "${status}" == "abandon" ]] || \
     [[ "${status}" == "timeout" ]] || \
     [[ "${status}" == "success" ]]; then
    next_task
  fi
}

start_experiment
