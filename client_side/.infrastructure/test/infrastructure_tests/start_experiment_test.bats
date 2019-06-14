#!/usr/bin/env bats
load ../libs/setup

@test "start_experiment enables Bash-preexec functions" {
  local task_num=1
  local preexec_functions=()
  local precmd_functions=()
  local task_code="a"
  local treatment="T"

  set +e
  start_experiment
  set -e

  preexec_functions=$(echo ${preexec_functions[@]})
  assert_contains "$preexec_functions" "preexec_func"

  precmd_functions=$(echo ${precmd_functions[@]})
  assert_contains "$precmd_functions" "precmd_func"
}
