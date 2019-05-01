##############################################################################
# This file contains utility functions for use by the interface:
# - Creating the mock file system for the user
# - Timing each task
# - Determining which task and treatment ordering for the current experiment
# - Determine the next task to move onto and whether the experiment is over
# - Verify the output of a task
##############################################################################

# Converts a numeric ASCII value to a character.
chr() {
  [ "$1" -lt 256 ] || return 1
  printf "\\$(printf '%03o' "$1")"
}

# Converts a character to its ASCII value.
ord() {
  LC_CTYPE=C printf '%d' "'$1"
}

# Outputs the nth alphabetic character. n is 1-based; that is, char_from(1) is "a".
# $1: the number n specifying which characters
char_from() {
  local num_a=$(ord "a")
  local num_fr=$((num_a + $1 - 1))

  echo $(chr ${num_fr})
}

# Gets the true task code from the user task number and the task set.
# The user task number is always sequential.
# The task can be in either task set 1 or 2, with the dividing task being
# TASKS_SIZE / 2.
# That is, if the current task set is 2 and the user current user task number
# is 12, then its true task code is "a", because it is in task set 1.
get_task_code() {
  if ((task_set == 1)); then
    local task_no=$((curr_task > TASKS_SIZE / 2 ? \
      curr_task - TASKS_SIZE / 2 : \
      curr_task))
  else
    local task_no=$((curr_task > TASKS_SIZE / 2 ? \
      curr_task : \
      curr_task + TASKS_SIZE / 2))
  fi


  echo "$(char_from ${task_no})"
}

# Enables Bash preexec functions and prints out the first treatment and task.
# Also sets $SECONDS and $time_elapsed to 0.
start_experiment() {
  # Enable task logging
  preexec_functions+=(preexec_func)
  precmd_functions+=(precmd_func)

  print_treatment
  print_task

  SECONDS=0
  time_elapsed=0
}

# "Uninstalls" Bash Preexec by removing its triggers.
# Remove all variable files created by the infrastructure
# Stops the experiment completely by returning from the sourced scripts.
end_experiment() {
  # This effectively uninstalls Bash Pre-exec
  # Makes it so any commands typed after the experiment has ended will not be
  # passed through preexec and precmd.
  PROMPT_COMMAND=${PROMPT_COMMAND_OG}
  trap - DEBUG

  # Remove all variable files
  rm -r "${INFRA_DIR}/.*"
  cd "${EXP_DIR}"

  echo "Congratulations! You have completed the interactive portion of the" \
    "experiment!"
  echo "Please take some time to fill out the survey at ${SURVEY_URL} ."

  return 0
}

# Creates the file system directory that the user will be working on.
# If the directory already exists, removes it and creates it again.
# Saves the user's current working directory and returnst to it once the
# directory is set up.
make_fs() {
  pushd "${INFRA_DIR}" &> /dev/null

  rm -rf "${FS_DIR}"
  mkdir "${FS_DIR}" > /dev/null
  tar -xzf "${INFRA_DIR}/fs.tgz" -C "${FS_DIR}"

  # Moves the user to this directory
  popd &> /dev/null
}

# Prints the list of resources that the user is allowed to use based on the
# current treatment
print_treatment() {
  echo -n "For this half of the experiment you can use any online resources," \
    "man pages, "
  if [[ "$(cat "${INFRA_DIR}/.treatment")" == "T" ]]; then
    echo "and Tellina <URL> to help you solve the tasks."
  else
    echo "but you can't use Tellina to help you solve the tasks."
  fi
}

# Prints the current task number and its description.
print_task() {
  local task_code=$(cat "${INFRA_DIR}/.task_code")

  echo "-----------------------------------------------------------------------"
  echo "Task: ${curr_task}/${TASKS_SIZE}"

  jq -r '.description' "${TASKS_DIR}/task_${task_code}/task_${task_code}.json"
}

# See documentation for ./verify_task.py for more details on what it does
# Captures the stdout of verify_task.py into $status
# Captures the exit code of verify_task.py into $EXIT
verify_task() {
  # Verify the output of the previous command.
  local task_code="$(cat "${INFRA_DIR}/.task_code")"
  local user_command="$(cat "${INFRA_DIR}/.command")"

  status=$("${INFRA_DIR}"/verify_task.py ${task_code} ${user_command})
  EXIT=$?
}

# Increment the current task number and update the true task code in .task_code
# accordingly
#   - Check if all the tasks are complete, if it is then skip the following
#     steps and clean up instead.
#   - If this current_task is equal to `TASKS_SIZE / 2`, switch treatments and
#     task sets and notify the user.
# Write "start task" to `.command`.
# Writes to the log
# Set time_elapsed=0, status="incomplete", SECONDS=0
# Prints out the task's information
next_task() {
  make_fs

  # Increment the number of tasks finished by the user
  curr_task=$(( curr_task + 1 ))
  echo "${curr_task}" > "${INFRA_DIR}/.curr_task"

  # If we're done with all the tasks
  if (( curr_task == TASKS_SIZE )); then
    end_experiment

    return 1
  fi

  # otherwise we check if we need to switch the task set and the treatment
  # And go into the second half of the experiment
  if (( curr_task == TASKS_SIZE / 2 + 1 )); then
    echo "You have finished the first half of the experiment!"

    # Updates the treatment and the task set for the user
    if [[ "$(cat "${INFRA_DIR}/.treatment")" == "T" ]]; then
      echo "N" > "${INFRA_DIR}/.treatment"
    else
      echo "T" > "${INFRA_DIR}/.treatment"
    fi
    if ((task_set == 1)); then
      task_set=2
    else
      task_set=1
    fi

    print_treatment
  fi

  echo $(get_task_code) > "${INFRA_DIR}/.task_code"
  SECONDS=0
  time_elapsed=0
  status="incomplete"

  echo "start_task" > "${INFRA_DIR}/.command"

  write_log
  print_task
}

# Writes a command to the log file on the server with a POST request.
write_log() {
  curl -s -X POST ${SERVER_HOST}/${SERVER_ROUTE} \
    -d user_id="$USER_ID" \
    -d task_order="$(cat "${INFRA_DIR}/.task_order")" \
    -d client_time_stamp="$(date --utc +%FT%TZ)" \
    -d task_code="$(cat "${INFRA_DIR}/.task_code")" \
    -d treatment="$(cat "${INFRA_DIR}/.treatment")" \
    -d time_elapsed="${time_elapsed}" \
    -d status="${status}" \
    -d command="$(cat "${INFRA_DIR}/.command")" &> /dev/null
}
