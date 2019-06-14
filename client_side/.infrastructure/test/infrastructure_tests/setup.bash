load ../libs/assertions

# Enables test_get_task_code. This file describes each function it enables.
load ../libs/infrastructure_test_helper

setup() {
  source "${BATS_TEST_DIRNAME}/../../infrastructure.sh"

  INFRA_DIR="${BATS_TEST_DIRNAME}/../.."
  TASKS_DIR="${INFRA_DIR}/tasks"

  TASKS_SIZE=$(ls - 1 ${TASKS_DIR} | wc -l)

  FS_DIR=$(mktemp -d)
  FS_SYNC_DIR="${INFRA_DIR}/file_system"

  USER_OUT=$(mktemp -d)

  time_elapsed=0
}

teardown() {
  find "${INFRA_DIR}" -type f -name ".*" -not -path "*/file_system/*" -delete
  rm -rf "${FS_DIR}"
  rm -rf "${USER_OUT}"
}
