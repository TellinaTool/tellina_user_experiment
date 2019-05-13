#!/usr/bin/env bats
load setup

@test "determine_task_set correct for first half of experiment" {
  # Parameters for test_determine_task_set is in the order:
  # <TASK_ORDER> <EXPERIMENT_HALF> <EXPECTED_TREATMENT> <EXPECTED_TASK_SET>

  test_determine_task_set "T1N2" 1 "T" 1
  test_determine_task_set "T2N1" 1 "T" 2
  test_determine_task_set "N1T2" 1 "N" 1
  test_determine_task_set "N2T1" 1 "N" 2
}

@test "determine_task_set correct for second half of experiment" {
  # Parameters for test_determine_task_set is in the order:
  # <TASK_ORDER> <EXPERIMENT_HALF> <EXPECTED_TREATMENT> <EXPECTED_TASK_SET>

  test_determine_task_set "T1N2" 2 "N" 2
  test_determine_task_set "T2N1" 2 "N" 1
  test_determine_task_set "N1T2" 2 "T" 2
  test_determine_task_set "N2T1" 2 "T" 1
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
