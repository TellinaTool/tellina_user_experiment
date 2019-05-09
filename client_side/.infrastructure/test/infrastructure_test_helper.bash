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
