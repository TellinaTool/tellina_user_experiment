#!/usr/bin/env bats
load setup

export FS_DIR
export USER_OUT
export TASKS_DIR

@test "verify_task correct re-execution one command regular quoting" {
  # Parameters for test_verify_task are
  # <task_code> <command> <expected status> <expected exit code>
  local cmd

  debug "--------------------- Expected failure"
  cmd="find . -type -name \"content\""
  test_verify_task "a" "$cmd" "incomplete" 3

  debug "--------------------- Expected success"
  cmd="find \"content\" -type f -size +800c -size -10k"
  test_verify_task "a" "$cmd" "success" 0
}
