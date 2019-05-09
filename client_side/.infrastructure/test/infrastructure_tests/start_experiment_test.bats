#!/usr/bin/env bats
load setup

@test "start_experiment enables Bash-preexec functions" {
  local task_num=1
  local preexec_functions=()
  local precmd_functions=()
  echo "a" > "${INFRA_DIR}/.task_code"

  start_experiment

  rm "${INFRA_DIR}/.noverify"

  preexec_functions=$(echo ${preexec_functions[@]})
  assert_contains "$preexec_functions" "preexec_func"

  precmd_functions=$(echo ${precmd_functions[@]})
  assert_contains "$precmd_functions" "precmd_func"
}
