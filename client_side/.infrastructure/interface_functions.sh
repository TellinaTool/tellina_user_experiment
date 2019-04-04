##############################################################################
# This file contains functions that the interface will use to manage the
# following things:
# - Creating the mock file system for the user
# - Timing each task
# - Determining which task and treatment ordering for the current experiment
# - Determine the next task to move onto and whether the experiment is over
# - Verify the output of a task
##############################################################################


function start_experiment() {
  # Enable task logging
  preexec_functions+=(preexec_func)
  precmd_functions+=(precmd_func)

  print_treatment

  echo "Task Number: $TOTAL_TASKS/$TASKS_SIZE"
  task
}

function end_experiment() {
  # Remove bash-preexec
  rm -f ~/.bash-preexec.sh
  echo "Congratulations! You have completed the interactive portion of the experiment!"
  echo "Don't forget to remove the Chrome extension that you installed."
  echo "Please take some time to fill out the survey here <URL> using the same username you used for the experiment"
}

# Creates the mock file system that the user will be working on
# And moves them to that directory
function make_fs() {
  rm -rf $FS_DIR
  mkdir $FS_DIR
  tar -xzf $REPO_DIR/fs.tgz -C $FS_DIR

  # Moves the user to this directory
  cd $FS_DIR
}

# A simple timer for each task
function start_timer() {
  SECONDS=0

  while [ $SECONDS -lt $TIME_LIMIT ]; do
    sleep 1
  done

  echo "You've run out of time for the task"
  next_task 2
}

# Prints the list of resources that the user is allowed to use based on the
# current treatment
function print_treatment() {
  echo -n "For this half of the experiment you can use any online resources, man pages, "
  if [ "$TREATMENT" == "T" ]; then
    echo "and Tellina <URL> to help you solve the tasks."
  else
    echo "but you can't use Tellina to help you solve the tasks."
  fi
}

# Sets the appropriate task variables based on the TASK_ORDER var
# The task ordering is determine using this table
#
#    | |  1st  |  2nd  |
#    |-|-------|-------|
#    |0|`s1 T` |`s2 NT`|
#    |1|`s2 T` |`s1 NT`|
#    |2|`s1 NT`|`s2 T` |
#    |3|`s2 NT`|`s1 T` |
function determine_task_order() {
  if [ "$TASK_ORDER" == "0" ]; then
    CURR_TS=1
    TREATMENT="T"
  elif [ "$TASK_ORDER" == "1" ]; then
    CURR_TS=2
    TREATMENT="T"
  elif [ "$TASK_ORDER" == "2" ]; then
    CURR_TS=1
    TREATMENT="NT"
  else
    CURR_TS=2
    TREATMENT="NT"
  fi
}

# See documentation for scripts/verify_task.py for more details on what it does
function verify_task() {
  # Verify the output of the previous command.
  $CMDS/scripts/verify_task.py $CURR_TS $CURR_TASK $PREV_CMD
  EXIT=$?
}

# Writes to log the results of the current task
# Parameters:
# $1 the STATUS of the task: 0 for abandon, 1 for success, 2 for timeout
# Increments the current task counter and determines if we need to go to the
# next task set
function next_task() {
  # stop the timer
  kill $TIMER_PID
  wait $TIMER_PID 2> /dev/null

  write_log $CURR_RESETS $SECONDS $USER_CMD $1

  # Set the reset counter back to 0 for a new task
  CURR_RESETS=0

  # Increment the number of tasks finished by the user
  TASKS_FINISHED=$((TOTAL_TASKS+1))
  CURR_TASK=$((CURR_TASK+1))

  # If we're done with all the tasks
  if [ "$TASKS_FINISHED" -eq "$TASKS_SIZE" ]; then
    end_experiment

    return 1
  fi

  # otherwise we check if we need to switch the task set and the treatment
  # And go into the second half of the experiment
  if [ "$CURR_TASK" -eq "$TS_SIZE" ]; then
    CURR_TASK=0
    # change the task set number
    if [ "$CURR_TS" -eq 1 ]; then
      CURR_TS=2
    else
      CURR_TS=1
    fi
    # change the treatment code
    if [ "$TREATMENT" == "T" ]; then
      TREATMENT="NT"
    else
      TREATMENT="T"
    fi

    echo "Congratulations! You have finished the first half of the experiment!"
    print_treatment
  fi

  echo "Task Number: $TASK_NO"
  task

  # Start the timer
  start_timer &
  TIMER_PID=$!
}
