#!/usr/bin/env bats
load ../libs/setup

@test "reset_fs produces no output" {
  run reset_fs

  assert_success
  assert_output $output ""
}

@test "reset_fs creates non-empty file system directory" {
  reset_fs

  run find ${FS_DIR} -maxdepth 2

  assert_success
  [[ -n $output ]]
}

@test "reset_fs creates a correct file system directory" {
  reset_fs

  # These environment variables must exist for verify_task.py to run
  export FS_DIR
  export USER_OUT
  export TASKS_DIR

  # We are using verify_task.py and the fact that it checks the integrity of the
  # original file system directory on a "select" task.
  run "${INFRA_DIR}/verify_task.py" "a" "${FS_DIR}" find .

  # Assert that verify_task failed with a status of 3 and printed "incomplete"
  debug "Actual: $(cat /tmp/actual)" "Expected: $(cat /tmp/expected)"
  assert_failure
  [[ $status == 3 ]]
}

@test "reset_fs does not change the user's current directory" {
  run reset_fs
  assert_success

  cd ${FS_DIR}
  reset_fs
  assert_output "$(pwd)" "${FS_DIR}"

  cd "content"
  reset_fs
  assert_output "$(pwd)" "${FS_DIR}/content"

  cd "labs"
  reset_fs
  assert_output "$(pwd)" "${FS_DIR}/content/labs"

  cd "${FS_DIR}"
  reset_fs
  assert_output "$(pwd)" "${FS_DIR}"
}
