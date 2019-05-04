# Bash source file loaded by Bats providing functions to test different inputs
# for utility code.

# Tests the conversion between ASCII code to character and vice versa for
# alphabetic characters.
#
# The test is case sensitive and determines whether to test conversion on upper
# case characters or lower case characters based on the starting ASCII code
#
# Parameters:
# $1: starting ASCII code
# $2: conversion command
test_ascii_alpha_conversion() {
  local start_num=$1
  local end_num=$((start_num + 26))

  local cmd=$2

  if (( start_num == 97 )); then
    local alph=(a b c d e f g h i j k l m n o p q r s t u v w x y z)
  else
    local alph=(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)
  fi

  local i=$start_num
  while ((i < end_num)); do
    local alph_index=$((i - start_num))

    if [[ "$cmd" == "chr" ]]; then
      run $cmd $i
      assert_success

      debug "Input: $i"
      assert_output $output ${alph[alph_index]}
    else
      run $cmd ${alph[alph_index]}
      assert_success

      debug "Input: ${alph[alph_index]}"
      assert_output $output $i
    fi

    i=$((i + 1))
  done
}

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
