##############################################################################
# This file contains functions that the interface will use to communicate with
# the logging server to:
# - Create user
# - Get task ordering
# - Write to a user's log
##############################################################################


POST="curl -s -X POST $HOST:$PORT"
GET="curl -s $HOST:$PORT"

# Creates a user in the logging server
# Gets the machine name and user's name and concatenate them for the user_id
# Sends a POST request to the server to create the user, then GET the user's
# route to communicate with the server
function create_user() {
  MACHINE_NAME=$(hostname)
  read -p "Enter your username: " USER_NAME

  USER_ID=${USER_NAME}_${MACHINE_NAME}

  $POST/methods/create_user -F "user_id=$USER_ID" &> /dev/null
  USER_ROUTE=$($GET/methods/get_user_route?user_id=$USER_ID)
}

# Signals the server to send back the current task order
function get_task_order() {
  echo "$($GET/methods/task_order)"
}

# Writes to the user's log file on the server
# The resets, command, time, and status parameters are optional
function write_log() {
  local RESETS=$1
  local TIME_SPENT=$2
  local COMMAND=$3
  local STATUS=$4

  $POST/$USER_ROUTE/log -F "task_no=$TASK_NO&treatment=$TREATMENT&command=$COMMAND&time=$TIME_SPENT&status=$STATUS&resets=$RESETS"
}
