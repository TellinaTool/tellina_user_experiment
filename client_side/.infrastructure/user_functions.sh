##############################################################################
# This file contains functions that the user can use throughout the experiment
##############################################################################


# Resets the mock file system by removing the directory and extracting the
# original tar again
# Sends a POST request to the server
# Increments the variable CURR_RESETS
# Parameters:
# $1: current number of resets
function reset() {
  cd $REPO_DIR

  make_fs
}

# Abandons the current task by doing the following
# Invokes next_task with status 0
function abandon() {
  next_task 0
}

# Prints the available user commands
function helpme() {
  echo "task: prints the description of the current task."
  echo "reset: restore the file system to its original state."
  echo "abandon: abandon the current task."
  echo "helpme: prints this help message."
}

# See documentation for scripts/get_task_description.py for more details on what it does
function task() {
  TASK_NO=$(cat $INFRA_DIR/.curr_task)
  TASK_FILE=$TASKS_DIR/task$TASK_NO/task$TASK_NO.json

  echo "Task: $TASK_NO"
  $INFRA_DIR/get_task_description.py $TASK_FILE $TASK_NO
}
