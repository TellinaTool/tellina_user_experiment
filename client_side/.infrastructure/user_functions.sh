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
  CURR_RESETS=$(($CURR_RESETS+1))
  cd $REPO_DIR
  rm -rf $FS_DIR

  source $CMD/make_fs

  write_log $3
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
  echo "help: prints this help message."
}

# See documentation for scripts/get_task_description.py for more details on what it does
function task() {
  $CMDS/scripts/get_task_description.py $CURR_TS $CURR_TASK
}
