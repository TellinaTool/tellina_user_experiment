##############################################################################
# This file contains utility functions for use by the interface:
# - Creating the file system for the user.
# - Timing each task.
# - Determine task and treatment ordering for the current experiment.
# - Determine the next task to move onto and whether the experiment is over.
# - Verify the output of a task.
##############################################################################

# Converts a numeric ASCII value to a character.
#
# Prints the value to stdout and exits with the status code of `printf`
# (0 if there are no syntax errors).
#
# If the passed value is larger than 256 or smaller than 0, exits with status
# code 1 to indicate failure.
chr() {
  [ "$1" -gt 0 ] && [ "$1" -lt 256 ] || return 1
  printf "\\$(printf '%03o' "$1")"
}

# Converts a character to its ASCII value.
#
# Prints the character to stdout and exits with the status code of printf.
ord() {
  LC_CTYPE=C printf '%d' "'$1"
}

# Outputs the nth alphabetic character. n is 1-based; that is, char_from(1) is
# "a".
# $1: the number n specifying which character.
char_from() {
  local num_a=$(ord "a")
  local num_fr=$((num_a + $1 - 1))

  echo $(chr ${num_fr})
}

# Prints the true task code, from the current user task number and task set.
# The user task number is always sequential.
#
# The task can be in either task set 1 or 2.
# Task set 1 contains tasks 1 up to and including TASK_SIZE / 2.
# Task set 2 contains tasks (TASK_SIZE / 2) + 1 up to and incuding TASK_SIZE.
#
# Example with TASK_SIZE == 22, task_set == 1, and task_num == 12, the output
# will be "a".
get_task_code() {
  if ((task_set == 1)); then
    local task_no=$((task_num > TASKS_SIZE / 2 ? \
      task_num - TASKS_SIZE / 2 : \
      task_num))
  else
    local task_no=$((task_num > TASKS_SIZE / 2 ? \
      task_num : \
      task_num + TASKS_SIZE / 2))
  fi


  echo "$(char_from ${task_no})"
}

# Sets the current treatment and task set based on the task ordering for the
# experiment.
#
# Parameters:
# $1: 1 to specify that the user is in the first half of the experiment, 2
# otherwise
set_task_set() {
  local first_half=$1

  if (( ${first_half} == 1 )); then
    treatment="${TASK_ORDER:0:1}"
    task_set=${TASK_ORDER:1:1}
  else
    treatment="${TASK_ORDER:2:1}"
    task_set=${TASK_ORDER:3:1}
  fi
}

# Enables Bash preexec functions, prints out the first treatment and task, and
# start the first task.
#
# This function is only called at the very beginning of the experiment.
start_experiment() {
  # Enable task logging
  preexec_functions+=(preexec_func)
  precmd_functions+=(precmd_func)

  cd "${FS_DIR}"

  print_experiment_prompt "introduction"
  begin_treatment 1
  next_task

  # Because precmd is enabled by this function, precmd will be invoked before
  # the next command line prompt.

  # ".noverify" is touched so that precmd does
  # not attempt to verify user output on the "start_task" command that was
  # written to `.command`.
  touch "${INFRA_DIR}/.noverify"

  # write_log does not need to be called because it is called by precmd.
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
  find ${INFRA_DIR} -type f -name ".*" -delete
  cd "${EXP_DIR}"

  print_experiment_prompt "ending"

  return 0
}

# Resets the user's file system directory by syncing it with the
# infrastructure's Extracted file system directory.
reset_fs() {
  rsync --omit-dir-times --recursive --quiet --delete "${FS_SYNC_DIR}/" "${FS_DIR}"
}

# Prints out the treatment conditions for the experiment and optionally starts
# training for the infrastructure and/or Tellina.
#
# If the experiment just started, infra_training will be started.
# If the current treatment is "T", tellina_training will be started.
#
# Parameters:
# $1: the half of the experiment to begin treatment for, can be 1 or 2.
begin_treatment() {
  # Sets the task set for the given half
  set_task_set $1

  if (( task_num == 1 )); then
    infra_training
  fi
  if [[ "$treatment" == "T" ]]; then
    tellina_training
  fi

  print_treatment
}

# TODO: implement this
# Trains the user on how the infrastructure itself works. This includes:
# - User meta-commands.
# - Tasks and diff printing.
# - The directory that they should be performing tasks on.
infra_training() {
  return 0
}

# TODO: implement this
# Introduces the user to Tellina and suggests a couple of known query-command
# pairs.
tellina_training() {
  return 0
}

# Prints the text associated with a given experiment prompt.
print_experiment_prompt() {
  local prompt="$1"

  cat "${INFRA_DIR}"/prompts/$prompt.txt
}

# Prints the list of resources that the user is allowed to use based on the
# current treatment.
print_treatment() {
  if [[ "$treatment" == "T" ]]; then
    print_experiment_prompt "treatment_tellina"
  else
    if (( task_num >= TASKS_SIZE / 2 + 1 )); then
      print_experiment_prompt "treatment_no_tellina_second_half"
    else
      print_experiment_prompt "treatment_no_tellina_first_half"
    fi
  fi
}

# Prints the current task number and its description.
print_task() {
  echo "-----------------------------------------------------------------------"
  echo "Task: ${task_num}/${TASKS_SIZE}"

  ${INFRA_DIR}/jq-linux64 -r '.description' \
    "${TASKS_DIR}/task_${task_code}/task_${task_code}.json"
}

# See documentation for ./verify_task.py for more details on what it does
# Captures the stdout of verify_task.py into $status
# Captures the exit code of verify_task.py into $EXIT
verify_task() {
  # Verify the output of the previous command.
  local user_command="$(cat "${INFRA_DIR}/.command")"

  status=$("${INFRA_DIR}"/verify_task.py ${task_code} ${user_command})
  EXIT=$?
}

# Determines whether to move on to the second half of the experiment based on
# the current task_num and TASK_SIZE.
#
# Resets all relevent varialbes to their inital values and writes "start task"
# to `.command`.
#
# Prints the description of the current task.
start_task() {
  # Check if we need to switch the task set and the treatment
  if (( task_num == TASKS_SIZE / 2 + 1 )); then
    echo "You have finished the first half of the experiment!"

    begin_treatment 2
  fi

  # Determines the task code from current_task and task_set.
  task_code=$(get_task_code)
  SECONDS=0
  time_elapsed=0
  status="incomplete"

  echo "start_task" > "${INFRA_DIR}/.command"

  print_task
}

# Resets the user's file system directory, increments the current task number,
# starts a new task.
#
# This function will instead end the experiment if the current task number is
# equal to TASKS_SIZE.
next_task() {
  reset_fs

  # Increment the number of tasks finished by the user
  task_num=$(( task_num + 1 ))
  echo "${task_num}" > "${INFRA_DIR}/.task_num"

  # If we're done with all the tasks
  if (( task_num == TASKS_SIZE )); then
    end_experiment

    return 0
  fi

  # Otherwise start another task
  start_task
  write_log
}

# Writes the command in `.command` to the log file on the server with a POST
# request.
write_log() {
  curl -s -X POST ${POST_HANDLER} \
    -d user_id="$UW_NETID" \
    -d host_name="$MACHINE_NAME" \
    -d task_order="$TASK_ORDER" \
    -d client_time_stamp="$(date --utc +%FT%TZ)" \
    -d task_code="$task_code" \
    -d treatment="$treatment" \
    -d time_elapsed="$time_elapsed" \
    -d status="$status" \
    -d command="$(cat "${INFRA_DIR}/.command")" &> /dev/null
}
