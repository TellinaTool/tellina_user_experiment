#!/usr/bin/env/ bats
load assertions

# Enables the following functions:
# test_ascii_alpha_conversion
# test_get_task_code
load utility_test_helper

setup() {
  if [ "${BATS_TEST_NUMBER}" = 1 ];then
    echo "# ---$(basename ${BATS_TEST_FILENAME%.*})---" >&3
  fi

  source "${BATS_TEST_DIRNAME}/../infrastructure.sh"
}

@test "chr correct lower case output" {
  test_ascii_alpha_conversion 97 "chr"
}

@test "chr correct upper case output" {
  test_ascii_alpha_conversion 65 "chr"
}

@test "chr fails on bad input" {
  run chr 256
  assert_failure

  run chr 300
  assert_failure

  run chr -1
  assert_failure
}

@test "ord correct lower case output" {
  test_ascii_alpha_conversion 97 "ord"
}

@test "ord correct upper case output" {
  test_ascii_alpha_conversion 65 "ord"
}

@test "char_from correct nth character of lower case alphabet" {
  local lower_alph=(a b c d e f g h i j k l m n o p q r s t u v w x y z)

  for i in {1..26}; do
    run char_from $i
    [[ $status == 0 ]]

    debug "Input: $i"
    assert_output $output ${lower_alph[i - 1]}
  done
}

@test "get_task_code correct - small even task size" {
  # test correctness for task set 1
  test_get_task_code 2 1 1 a
  test_get_task_code 2 1 2 a

  # test correctness for task set 2
  test_get_task_code 2 2 1 b
  test_get_task_code 2 2 2 b
}

@test "get_task_code correct - large even task size" {
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
