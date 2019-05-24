#!/usr/bin/env bats
load setup

@test "set_task_set correct for first half of experiment" {
  # Parameters for test_set_task_set is in the order:
  # <TASK_ORDER> <EXPERIMENT_HALF> <EXPECTED_TREATMENT> <EXPECTED_TASK_SET>

  test_set_task_set "T1N2" 1 "T" 1
  test_set_task_set "T2N1" 1 "T" 2
  test_set_task_set "N1T2" 1 "N" 1
  test_set_task_set "N2T1" 1 "N" 2
}

@test "set_task_set correct for second half of experiment" {
  # Parameters for test_set_task_set is in the order:
  # <TASK_ORDER> <EXPERIMENT_HALF> <EXPECTED_TREATMENT> <EXPECTED_TASK_SET>

  test_set_task_set "T1N2" 2 "N" 2
  test_set_task_set "T2N1" 2 "N" 1
  test_set_task_set "N1T2" 2 "T" 2
  test_set_task_set "N2T1" 2 "T" 1
}

@test "get_task_code correct - small even task size" {
  # Parameters for test_get_task_code is in the order:
  # <TASK_SIZE> <TASK_SET> <TASK_NUM> <EXPECTED_TASK_CODE>

  # test correctness for task set 1
  test_get_task_code 2 1 1 a
  test_get_task_code 2 1 2 a

  # test correctness for task set 2
  test_get_task_code 2 2 1 b test_get_task_code 2 2 2 b
}

@test "get_task_code correct - large even task size" {
  # Parameters for test_get_task_code is in the order:
  # <TASK_SIZE> <TASK_SET> <TASK_NUM> <EXPECTED_TASK_CODE>

  local expected_set_1=(a b c d e f g h i j k l m)
  local expected_set_2=(n o p q r s t u v w x y z)
  local task_size=26
  local i=0

  # Each expected_set_N array is treated as a circular array
  # Which means it is indexed by (i % S) where S is the size of the array

  # test correctness for task set 1
  while (( i < task_size )); do
    test_get_task_code $task_size 1 \
      $((i + 1)) ${expected_set_1[i % ${#expected_set_1[@]}]}

    i=$((i + 1))
  done

  # test correctness for task set 2
  while (( i < task_size )); do
    test_get_task_code $task_size 2 \
      $((i + 1)) ${expected_set_1[i % ${#expected_set_2[@]}]}

    i=$((i + 1))
  done
}

@test "get_task_code correct - small odd task size" {
  skip "get_task_code does not handle odd task sizes yet"

  # test correctness for task set 1
  test_get_task_code 3 1 1 a
  test_get_task_code 3 1 2 ""
  test_get_task_code 3 1 3 a

  # test correctness for task set 2
  test_get_task_code 3 2 1 b
  test_get_task_code 3 2 2 c
  test_get_task_code 3 2 3 ""
}

@test "get_task_code correct - large odd task size" {
  skip "get_task_code does not handle odd task sizes yet"

  local expected_set_1=(a b c d e f g h i j k l "")
  local expected_set_2=(m n o p q r s t u v w x y "")
  local task_size=25
  local i=0

  # Each expected_set_N array is treated as a circular array
  # Which means it is indexed by (i % S) where S is the size of the array

  # test correctness for task set 1
  while (( i < task_size )); do
    debug "i:$i"
    test_get_task_code $task_size 1 \
      $((i + 1)) ${expected_set_1[i % ${#expected_set_1[@]}]}

    i=$((i + 1))
  done

  # test correctness for task set 2
  while (( i < task_size )); do
    test_get_task_code $task_size 2 \
      $((i + 1)) ${expected_set_1[i % ${#expected_set_2[@]}]}

    i=$((i + 1))
  done
}

@test "start_task resets time variables" {
  local time_elapsed=$SECONDS
  SECONDS=0

  sleep 3

  start_task

  [[ $SECONDS -lt 1 ]]
  assert_output "$time_elapsed" 0
}

@test "start_task sets correct log information" {
  local TASKS_SIZE=10
  local task_num=1
  local task_set=1
  local status command task_code

  start_task

  command=$(cat "${INFRA_DIR}/.command")

  assert_output "$status" "incomplete"
  assert_output "$command" "start_task"
  assert_output "$task_code" "a"
}

@test "start_task switches treatment" {
  local TASKS_SIZE=10
  local TASK_ORDER="T1N2"
  local task_num task_set time_elapsed status task_code treatment

  task_num=5
  set_task_set 1

  start_task

  assert_output "$treatment" "T"
  assert_output "$task_set" 1
  assert_output "$task_code" "e"

  task_num=6

  start_task

  assert_output "$treatment" "N"
  assert_output "$task_set" 2
  assert_output "$task_code" "f"
}

@test "next_task increments task_num" {
  local task_num=0

  # Write log will fail because we don't have a URL for curl
  set +e
  next_task
  set -e

  assert_output "$task_num" 1

  task_num=$(cat "${INFRA_DIR}/.task_num")
  assert_output "$task_num" 1
}

@test "next_task resets the file system directory" {
  local task_num=0

  set +e
  next_task
  set -e

  assert_output "$task_num" 1
  run find ${fs_dir} -type f
  [[ -n "$output" ]]

  find ${FS_DIR} -type f -delete

  run find ${FS_DIR} -type f
  assert_output "$output" ""

  set +e
  next_task
  set -e

  assert_output "$task_num" 2
  run find ${fs_dir} -type f
  [[ -n "$output" ]]
}

@test "next_task ends experiment" {
  local TASKS_SIZE=10
  local task_num=9

  run next_task

  assert_success
}
