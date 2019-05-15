#!/usr/bin/env/ bats
#
# Tests utility code used by the client side infrastructure to handle internal
# information.
load ../libs/assertions

setup() {
  source "${BATS_TEST_DIRNAME}/../../infrastructure.sh"

  INFRA_DIR="${BATS_TEST_DIRNAME}/../.."
  TASKS_DIR="${INFRA_DIR}/tasks"

  FS_DIR=$(mktemp -d)
  USER_OUT=$(mktemp -d)

  time_elapsed=0

  touch "${INFRA_DIR}"/.{task_code,treatment,task_order,command}
}

teardown() {
  find "${INFRA_DIR}" -type f -name ".*" -delete
  rm -rf "${FS_DIR}"
  rm -rf "${USER_OUT}"
}

@test "chr correct lower case output" {
  run chr 97
  assert_success
  assert_output "$output" "a"

  run chr 110
  assert_success
  assert_output "$output" "n"

  run chr 122
  assert_success
  assert_output "$output" "z"
}

@test "chr correct upper case output" {
  run chr 65
  assert_success
  assert_output "$output" "A"

  run chr 78
  assert_success
  assert_output "$output" "N"

  run chr 90
  assert_success
  assert_output "$output" "Z"
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
  run ord "a"
  assert_success
  assert_output "$output" 97

  run ord "n"
  assert_success
  assert_output "$output" 110

  run ord "z"
  assert_success
  assert_output "$output" 122
}

@test "ord correct upper case output" {
  run ord "A"
  assert_success
  assert_output "$output" 65

  run ord "N"
  assert_success
  assert_output "$output" 78

  run ord "Z"
  assert_success
  assert_output "$output" 90
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
