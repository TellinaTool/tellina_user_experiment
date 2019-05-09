#!/usr/bin/env bats
load setup

@test "make_fs produces no output" {
  run make_fs

  assert_success
  assert_output $output ""
}

@test "make_fs creates non-empty file system directory" {
  make_fs

  run find ${FS_DIR} -maxdepth 2

  assert_success
  [[ -n $output ]]
}

@test "make_fs creates a correct file system directory" {
  make_fs

  # These environment variables must exist for verify_task.py to run
  export FS_DIR
  export USER_OUT
  export TASKS_DIR

  # We are using verify_task.py and the fact that it checks the integrity of the
  # original file system directory on a "select" task.
  run "${INFRA_DIR}/verify_task.py" "a" find .

  # Assert that verify_task failed with a status of 3 and printed "incomplete"
  assert_failure
  [[ $status == 3 ]]

  assert_output $output "incomplete"
}

@test "make_fs does not change the user's current directory" {
  run make_fs
  assert_success

  cd ${FS_DIR}
  make_fs
  assert_output "$(pwd)" "${FS_DIR}"

  cd "content"
  make_fs
  assert_output "$(pwd)" "${FS_DIR}/content"

  cd "labs"
  make_fs
  assert_output "$(pwd)" "${FS_DIR}/content/labs"

  cd "${FS_DIR}"
  make_fs
  assert_output "$(pwd)" "${FS_DIR}"
}
