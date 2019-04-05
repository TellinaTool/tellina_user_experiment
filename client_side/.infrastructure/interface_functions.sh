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

  SECONDS=0
  echo "Task Number: $TOTAL_TASKS/$TASKS_SIZE"
  task
}

function end_experiment() {
  # Remove bash-preexec
  rm -f $INFRA_DIR/bash-preexec.sh
  rm -f $INFRA_DIR/.*

  echo "Congratulations! You have completed the interactive portion of the experiment!"
  echo "Don't forget to remove the Chrome extension that you installed."
  echo "Please take some time to fill out the survey here <URL> using $USER_NAME as your user name."

  cd $EXP_DIR
  exec bash
}

# Creates the mock file system that the user will be working on
# And moves them to that directory
function make_fs() {
  rm -rf $FS_DIR
  mkdir $FS_DIR > /dev/null
  tar -xzf $INFRA_DIR/fs.tgz -C $FS_DIR

  # Moves the user to this directory
  cd $FS_DIR
}

# Prints the list of resources that the user is allowed to use based on the
# current treatment
function print_treatment() {
  echo -n "For this half of the experiment you can use any online resources, man pages, "
  if [ "$(cat .treatment)" == "T" ]; then
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
    echo "1" > $INFRA_DIR/.task_order
    echo "T" > $INFRA_DIR/.treatment
  elif [ "$TASK_ORDER" == "1" ]; then
    echo "2" > $INFRA_DIR/.task_order
    echo "T" > $INFRA_DIR/.treatment
  elif [ "$TASK_ORDER" == "2" ]; then
    echo "1" > $INFRA_DIR/.task_order
    echo "NT" > $INFRA_DIR/.treatment
  else
    echo "2" > $INFRA_DIR/.task_order
    echo "NT" > $INFRA_DIR/.treatment
  fi
}

# See documentation for scripts/verify_task.py for more details on what it does
function verify_task() {
  # Verify the output of the previous command.
  ./verify_task.py $CURR_TASK $COMMAND
  EXIT=$?
}

# Writes to log the results of the current task
# Parameters:
# $1 the STATUS of the task: 0 for abandon, 1 for success, 2 for timeout
# Increments the current task counter and determines if we need to go to the
# next task set
function next_task() {
  STATUS=$1

  # Write everything to the log
  write_log

  # Increment the number of tasks finished by the user
  TASK_NO=$((TASK_NO+1))
  echo $TASK_NO > $INFRA_DIR/.curr_task

  # If we're done with all the tasks
  if [ "$TASK_NO" -eq "$TASKS_SIZE" ]; then
    end_experiment

    return 1
  fi

  # otherwise we check if we need to switch the task set and the treatment
  # And go into the second half of the experiment
  if [ "$TASK_NO" -eq "$TS_SIZE" ]; then
    echo "Congratulations! You have finished the first half of the experiment!"
    print_treatment
  fi

  SECONDS=0
  echo "Task Number: $TASK_NO"
  task
}

POST="curl -X POST $HOST:$PORT"

# Creates a user in the logging server
# Gets the machine name and user's name and concatenate them for the user_id
# Sends a POST request to the server to create the user, then GET the user's
# route to communicate with the server
function create_user() {
  MACHINE_NAME=$(hostname)
  read -p "Enter your UW NetID: " USER_NAME

  USER_ID=${USER_NAME}_${MACHINE_NAME}

  $POST/create_user -F "user_id=$USER_ID" 2> /dev/null
}

# Writes to the user's log file on the server
# The resets, command, time, and status parameters are optional
function write_log() {
  $POST/$USER_ID/log -d "time_stamp=$TIME_STAMP&task_no=$TASK_NO&treatment=$TREATMENT&command=$COMMAND&time=$TIME_SPENT&status=$STATUS"
}
