##############################################################################
# This file contains functions that the interface will use to manage the
# following things:
# - Creating the mock file system for the user
# - Timing each task
# - Determining which task and treatment ordering for the current experiment
# - Determine the next task to move onto and whether the experiment is over
# - Verify the output of a task
##############################################################################

# Converts a numeric ascii value to a character
chr() {
  [ "$1" -lt 256 ] || return 1
  printf "\\$(printf '%03o' "$1")"
}

# converts a character to its ascii value
ord() {
  LC_CTYPE=C printf '%d' "'$1"
}

# Outputs the nth alphabetic character. n starts at 0.
# $1: the number n specifying which characters
char_from() {
  local num_a=$(ord "a")
  local num_fr=$((num_a + $1 - 1))

  echo $(chr ${num_fr})
}

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

start_experiment() {
  # Enable task logging
  preexec_functions+=(preexec_func)
  precmd_functions+=(precmd_func)

  print_treatment
  print_task

  SECONDS=0
  time_elapsed=0
}

end_experiment() {
  # This effectively uninstalls Bash Pre-exec
  # Makes it so any commands typed after the experiment has ended will not be
  # passed through preexec and precmd.
  PROMPT_COMMAND=${PROMPT_COMMAND_OG}
  trap - DEBUG

  echo "Congratulations! You have completed the interactive portion of the" \
    "experiment!"
  echo "Please take some time to fill out the survey here ${SURVEY_URL} using" \
    "${USER_NAME} as your user name."

  cd "${EXP_DIR}"

  return 0
}
# Creates the mock file system that the user will be working on
# And moves them to that directory
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

print_task() {
  local task_code=$(cat "${INFRA_DIR}/.task_code")

  echo "-----------------------------------------------------------------------"
  echo "Task: ${curr_task}/${TASKS_SIZE}"

  jq -r '.description' "${TASKS_DIR}/task_${task_code}/task_${task_code}.json"
}

# See documentation for scripts/verify_task.py for more details on what it does
verify_task() {
  # Verify the output of the previous command.
  local task_code="$(cat "${INFRA_DIR}/.task_code")"
  local user_command="$(cat "${INFRA_DIR}/.command")"

  status=$("${INFRA_DIR}"/verify_task.py ${task_code} ${user_command})
  EXIT=$?
}

# Writes to log the results of the current task
# Parameters:
# $1 the STATUS of the task: 0 for abandon, 1 for success, 2 for timeout
# Increments the current task counter and determines if we need to go to the
# next task set
next_task() {
  make_fs

  # Increment the number of tasks finished by the user
  curr_task=$(( curr_task + 1 ))

  # If we're done with all the tasks
  if (( curr_task == TASKS_SIZE )); then
    end_experiment

    return 1
  fi

  # otherwise we check if we need to switch the task set and the treatment
  # And go into the second half of the experiment
  if (( curr_task == TASKS_SIZE / 2 + 1 )); then
    echo "You have finished the first half of the experiment! The treatment" \
      "will now switch."

    # Updates the treatment and the task set for the user
    if [[ "$(cat "${INFRA_DIR}/.treatment")" == "T" ]]; then
      echo "NT" > "${INFRA_DIR}/.treatment"
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

# Writes to the user's log file on the server
# The resets, command, time, and status parameters are optional
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
