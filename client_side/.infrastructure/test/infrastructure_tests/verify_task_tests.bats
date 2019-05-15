#!/usr/bin/env bats
load setup

export FS_DIR
export USER_OUT
export TASKS_DIR

@test "verify_task maintains quoting for command" {
  # Parameters for test_verify_task are
  # <task_code> <command> <expected status> <expected exit code>
  local cmd # cmd should be a 'single quoted' string.

  cmd='find "content" -type f -size +800c -size -10k'
  test_verify_task "a" "$cmd" "success" 0

  cmd='find 'content' -type f -size +800c -size -10k'
  test_verify_task "a" "$cmd" "success" 0

  cmd='find "\"content\""'
  test_verify_task "a" "$cmd" "incomplete" 3

  cmd='find "'content'"'
  test_verify_task "a" "$cmd" "incomplete" 3
}
