# Bash source file loaded by Bats providing functions to test different inputs
# for utility code.

# Runs get_task_code on the given parameters and assert that the output is
# correct
#
# Parameters
# $1: the total TASK_SIZE
# $2: the task set number (1 or 2)
# $3: the task number
# $4: the expected task code
test_get_task_code() {
  local TASKS_SIZE=$1
  local task_set=$2
  local task_num=$3
  local expected_task_code=$4

  run get_task_code

  assert_output $output $expected_task_code
}

# Runs determine_task_set on the given task order and experiment half and tests
# whether the outputs matches the given values
#
# Parameters:
# $1: the task order to test for
# $2: 0 for the first half of the experiment, 1 otherwise
# $3: the expected value for the treatment
# $4: the expected value for the task set
test_determine_task_set() {
  echo "$1" > "${INFRA_DIR}/.task_order"

  determine_task_set $2

  local treatment=$(cat "${INFRA_DIR}/.treatment")

  assert_output "$treatment" "$3"
  assert_output "$task_set" "$4"
}

# Runs verfiy task with the specified command and tests the output and exit code
# with the given expected values
#
# Parameters
# $1: the true task code to test for
# $2: the command to run verify_task with
# $3: the expected status
# $4: the expected EXIT code
test_verify_task() {
  make_fs
  cd "${FS_DIR}"

  echo "$1" > "${INFRA_DIR}/.task_code"
  echo "$2" > "${INFRA_DIR}/.command"
  local expected_status="$3"
  local expected_exit="$4"

  local status EXIT

  set +e
  verify_task
  set -e

  assert_output "$status" "$expected_status"
  assert_output "$EXIT" $expected_exit
}
