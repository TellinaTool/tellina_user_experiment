#!/usr/bin/env bats
#
# Each correctness test checks the correctness for different ways the user's
# command can be quoted.
load ../libs/setup

export FS_DIR
export USER_OUT
export TASKS_DIR

@test "verify_task select task success" {
  # Parameters for test_verify_task are
  # <task_code> <command> <expected status> <expected exit code>

  # cmd should be a $'single quoted' string preceeded by a '$'.
  # See "Quoting" section in 'man bash' for why this works.
  local cmd

  # find "content" ...
  cmd=$'find "content" -type f -size +800c -size -10k'
  test_verify_task "a" "$cmd" "success" 0

  # find ""content"" ...
  cmd=$'find ""content"" -type f -size +800c -size -10k'
  test_verify_task "a" "$cmd" "success" 0

  # find 'content' ...
  cmd=$'find \'content\' -type f -size +800c -size -10k'
  test_verify_task "a" "$cmd" "success" 0

  # find content
  cmd=$'find content -type f -size +800c -size -10k'
  test_verify_task "a" "$cmd" "success" 0

  # find content/
  cmd=$'find content/ -type f -size +800c -size -10k'
  test_verify_task "a" "$cmd" "success" 0

  # find content/* -type f -size +800c -size -10k'
  cmd=$'find content/* -type f -size +800c -size -10k'
  test_verify_task "a" "$cmd" "success" 0
}

@test "verify_task select task unchanged file system failure" {
  local cmd

  # find "'content'" ...
  cmd=$'find "\'content\'" -type f -size +800c -size -10k'
  test_verify_task "a" "$cmd" "incomplete" 3

  # find '"content"' ...
  cmd=$'find \'"content"\' -type f -size +800c -size -10k'
  test_verify_task "a" "$cmd" "incomplete" 3

  # find "\"content\"" ...
  cmd=$'find "\\"content\\"" -type f -size +800c -size -10k'
  test_verify_task "a" "$cmd" "incomplete" 3

  # find 'content/*' -type f -size +800c -size -10k'
  cmd=$'find \'content/*\' -type f -size +800c -size -10k'
  test_verify_task "a" "$cmd" "incomplete" 3

  # find "content/*" -type f -size +800c -size -10k'
  cmd=$'find "content/*" -type f -size +800c -size -10k'
  test_verify_task "a" "$cmd" "incomplete" 3
}

@test "verify_task select task changed file system failure" {
  local cmd

  # rm -r *
  cmd=$'rm -r *'
  test_verify_task "a" "$cmd" "incomplete" 2

  # find content -type f -size +10k -size -800c -delete
  cmd=$'find content -type f -size +10k -o -size -800c -delete && find content'
  test_verify_task "a" "$cmd" "incomplete" 2
}

@test "verify_task file system task success" {
  local cmd

  # find ... "*.html" ...
  cmd='find . -name "*.html" -exec tar -rvf html.tar {} \;'
  test_verify_task "b" "$cmd" "success" 0

  # cd lib ; mv showdown showup
  cmd='cd lib ; mv showdown showup'
  test_verify_task "o" "$cmd" "success" 0

  # find css/ -type f | xargs rm
  cmd='find css/ -type f | xargs rm'
  test_verify_task "v" "$cmd" "success" 0
}

@test "verify_task file system task failure" {
  local cmd # should 'single quoted'

  # find ... '*.html' ...
  cmd='find . -name '*.html' -exec tar -rvf html.tar {} \;'
  test_verify_task "b" "$cmd" "incomplete" 1

  # find ... *.html ...
  cmd='find . -name *.html -exec tar -rvf html.tar {} \;'
  test_verify_task "b" "$cmd" "incomplete" 1

  # find ... ""*.html"" ...
  cmd='find . -name ""*.html"" -exec tar -rvf html.tar {} \;'
  test_verify_task "b" "$cmd" "incomplete" 1
}
