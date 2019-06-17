##############################################################################
# This file contains utility functions for use by the interface:
# - Creating the file system for the user.
# - Timing each task.
# - Determine task and treatment ordering for the current experiment.
# - Determine the next task to move onto and whether the experiment is over.
# - Verify the output of a task.
##############################################################################

HLINE="--------------------------------------------------------------------------------"

# Prints to stdout the character with the given numeric ASCII value.
#
# Exit status:
# - 0 if the passed value is within 0...256.  (And does no output.)
# - 1 otherwise.
chr() {
  [ "$1" -gt 0 ] && [ "$1" -lt 256 ] || return 1
  printf "\\$(printf '%03o' "$1")"
}

# Prints to stdout the numeric ASCII value of the given character.
ord() {
  LC_CTYPE=C printf '%d' "'$1"
}

# Prints the nth alphabetic character. n is 1-based; that is, char_from(1) is
# "a".
# $1: the number n specifying which character.
char_from() {
  local num_a=$(ord "a")
  local num_fr=$((num_a + $1 - 1))

  echo $(chr ${num_fr})
}

# Prints the true task code, from the current user task number and task set.
# The user task numbering is always sequential.
#
# The user task number is the global variable task_num.
# The task set is the global variable task_set (either 1 or 2).
# Task set 1 contains tasks 1 through TASK_SIZE / 2.
# Task set 2 contains tasks (TASK_SIZE / 2) + 1 through TASK_SIZE.
#
# Example:  with TASK_SIZE == 22, task_set == 1, and task_num == 12, the output
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

# Enables Bash preexec functions, prints out the first treatment and task, and
# starts the first task.
#
# This function is only called at the very beginning of the experiment.
start_experiment() {
  # Enable task logging
  preexec_functions+=(preexec_func)
  precmd_functions+=(precmd_func)

  cd "${FS_DIR}"

  echo "Welcome to the bash user study!"
  echo "At any point, run \"helpme\" to see a list of commands available to you."

  begin_treatment 1
  next_task

  # Because precmd is enabled by this function, precmd will be invoked before
  # the next command line prompt.
  # ".noverify" is touched so that precmd does not attempt to verify
  # user output on the "start_task" command that was written to `.command`.
  touch "${INFRA_DIR}/.noverify"

  # write_log does not need to be called because it is called by precmd.
}

# "Uninstalls" Bash Preexec by removing its triggers.
# Remove all variable files created by the infrastructure.
# Stops the experiment completely by returning from the sourced scripts.
end_experiment() {
  # This effectively uninstalls Bash Pre-exec.
  # Makes it so any commands typed after the experiment has ended will not be
  # passed through preexec and precmd.
  PROMPT_COMMAND=${PROMPT_COMMAND_OG}
  trap - DEBUG

  # Remove all variable files.
  find ${INFRA_DIR} -type f -name ".*" -delete
  cd "${EXP_DIR}"

  echo "Congratulations! You have completed the interactive portion of the experiment."
  echo "Please fill out the survey on the experiment home page."

  return 0
}

# Resets the user's file system directory by syncing it with the
# infrastructure's file system directory.
reset_fs() {
  rsync --exclude=".*" --omit-dir-times --recursive --quiet --delete \
    --times \
    "${FS_SYNC_DIR}/" "${FS_DIR}"
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
  # Sets the current treatment and task set based on the task ordering for the
  # experiment.
  local experiment_half=$1

  if (( ${experiment_half} == 1 )); then
    treatment="${TASK_ORDER:0:1}"
    task_set=${TASK_ORDER:1:1}
  else
    treatment="${TASK_ORDER:2:1}"
    task_set=${TASK_ORDER:3:1}
  fi

  print_treatment

  if (( task_num == 0 )); then
    if ! [[ -f "${INFRA_DIR}/.task_num" ]]; then
      # If the user is at the very beginning and is not resuming to task 1, then
      # enables infrastructure training.
      INF_TRAINING=true

      if [[ "$treatment" == "T" ]]; then
        # If the treatment is T, enables Tellina training.
        TEL_TRAINING=true
      fi
    fi
  else
    # If the treatment is T and the user is not at the beginning, enables
    # Tellina training.
    if [[ "$treatment" == "T" ]]; then
      TEL_TRAINING=true
    fi
  fi
}

# Checks whether infrastructure training or Tellina training is enabled and
# disables them if complete..
#
# Prioritizes infrastructure training.
check_and_update_training_status() {
  # The check is based on the status of the task assigned to the training. The
  # training is then complete when the $status of the task is "success", in
  # which case the corresponding training variable ($INF_TRAINING or
  # $TEL_TRAINING) gets unset.

  # In the case that both $INF_TRAINING and $TEL_TRAINING are true, the priority
  # for $INF_TRAINING is especially important.
  # At this point, $status is "success", meaning if $INF_TRAINING and
  # $TEL_TRAINING are checked separately, they will both be unset, thus skipping
  # the training for Tellina.
  if [[ "${INF_TRAINING:-false}" == "true" ]]; then
    if [[ "${status}" == "success" ]]; then
      # If the user successfully did the infrastructure training, disables it.
      unset INF_TRAINING

      if [[ "${TEL_TRAINING:-false}" == "true" ]]; then
        tellina_training
      fi
    else
      # Otherwise, print the information about the training.
      infra_training
    fi
  elif [[ "${TEL_TRAINING:-false}" == "true" ]]; then
    if [[ "${status}" == "success" ]]; then
      # if the user successfully did the Tellina training, disables it.
      unset TEL_TRAINING
    else
      # Otherwise, print the information about the training.
      tellina_training
    fi
  fi
}

# Trains the user on how the infrastructure itself works. This includes:
# - User meta-commands.
# - Tasks and diff printing.
# - The directory that they should be performing tasks on.
infra_training() {
  echo ${HLINE}
  echo "For this task, please follow the instructions at"
  echo "${EXPERIMENT_HOME_URL}/website/training/infrastructure_training.html"
  echo "to learn how to do the experiment."
}

# Introduces the user to Tellina and suggests a couple of known query-command
# pairs.
tellina_training() {
  echo ${HLINE}
  echo "For this task, follow the instructions at"
  echo "<tellina_training_url>"
  echo "to acquaint yourself with Tellina."
}

# Prints the list of resources that the user is allowed to use based on the
# current treatment.
print_treatment() {
  echo ${HLINE}
  if [[ "$treatment" == "T" ]]; then
    echo "For this half of the experiment you can use any online resources and man pages,"
    echo "and Tellina (https://tellina.rocks)."
  else
    if (( task_num >= TASKS_SIZE / 2 + 1 )); then
      echo "For this half of the experiment you can use any online resources and man pages,"
      echo "but you should not use Tellina."
    else
      echo "For this half of the experiment you can use any online resources and man pages."
    fi
  fi
}

# Prints the current task number and its description.
print_task() {
  if (( task_num == 1 )); then
    echo "You have 5 minutes to complete each task."
  fi
  echo ${HLINE}
  echo "Task: ${task_num}/${TASKS_SIZE}"

  ${INFRA_DIR}/jq-linux64 -r '.description' \
    "${TASKS_DIR}/task_${task_code}/task_${task_code}.json"
}

# See documentation for ./verify_task.py for more details on what it does.
#
# Parameters:
# - $1: the directory that the user command was run in.
#
# Runs ./verify_task.py with the global task_code and the command in .command
# and captures its exit code.
#
# If ./verify_task.py returns exit code:
# - 0: sets $status to success.
# - 2: prints a prompt warning that the user has changed the file system and
#      resets the file system.
# - Otherwise: prints a prompt that the actual output does not match.
#
# Returns the exit code of ./verify_task.py
verify_task() {
  # Verify the output of the previous command.
  local exit_code
  local user_command="$(cat "${INFRA_DIR}/.command")"

  "${INFRA_DIR}"/verify_task.py ${task_code} "$1" ${user_command}
  exit_code=$?

  case $exit_code in
    0)
      status="success"
      ;;
    1)
      echo "File system does not match expected. A diff has been shown."
      ;;
    2)
      echo "You have modified the file system. It will now be reset to its original state."
      reset_fs
      ;;
    3)
      echo "Command output does not match expected output. A diff has been shown."
      ;;
  esac

  return $exit_code
}

# This is called to start the user on a new task.
#
# Restores the file system and sets the variables.
# May begin a new treatment.
# Writes "start task" to `.command`.
# Prints the description of the current task.
start_task() {
  reset_fs
  cd ${FS_DIR}

  # Check if we need to switch the task set and the treatment
  if (( task_num == TASKS_SIZE / 2 + 1 )); then
    echo "You have finished the first half of the experiment!"

    begin_treatment 2
  fi

  # If the user is in training, set the task_code to the appropriate training
  # tasks. "task_u" for infrastructure training, and "task_v" for Tellina
  # training.
  #
  # Otherwise, calculate the task_code from the current_task and task_set.
  if [[ ${INF_TRAINING:-false} == "true" ]]; then
    task_code="u"
  elif [[ ${TEL_TRAINING:-false} == "true" ]]; then
    task_code="v"
  else
    task_code=$(get_task_code)
  fi

  SECONDS=0
  time_elapsed=0
  status="incomplete"

  echo "start_task" > "${INFRA_DIR}/.command"

  print_task
}

# Increments the current task number and either starts a new task or ends the
# experiment.
#
# If the user is in training, the current task number does not increment.
next_task() {
  check_and_update_training_status

  if [[ "${TEL_TRAINING:-false}" != "true" ]] && \
     [[ "${INF_TRAINING:-false}" != "true" ]]; then
    # Increment the number of tasks finished by the user.
    task_num=$(( task_num + 1 ))
    echo "${task_num}" > "${INFRA_DIR}/.task_num"
  fi

  # If done with all the tasks
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
    -d task_code="$task_code" \
    -d treatment="$treatment" \
    -d time_elapsed="$time_elapsed" \
    -d client_time_stamp="$(date --utc +%FT%TZ)" \
    -d status="$status" \
    -d command="$(cat "${INFRA_DIR}/.command")" &>> ${INF_LOG_FILE}
}
