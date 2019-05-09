load ../libs/assertions

# Enables test_get_task_code. See this file for detailed description of each
# function it enables.
load ../libs/infrastructure_test_helper

setup() {
  source "${BATS_TEST_DIRNAME}/../../infrastructure.sh"

  INFRA_DIR="${BATS_TEST_DIRNAME}/../.."
  TASKS_DIR="${INFRA_DIR}/tasks"

  TASKS_SIZE=$(ls - 1 ${TASKS_DIR} | wc -l)

  FS_DIR=$(mktemp -d)
  USER_OUT=$(mktemp -d)

  time_elapsed=0

  touch "${INFRA_DIR}"/.{task_code,treatment,task_order,command}
}

tear_down() {
  find ${INFRA_DIR} -type f -name ".*" -delete
  rm "${FS_DIR}"
  rm -rf "${USER_OUT}"
}
