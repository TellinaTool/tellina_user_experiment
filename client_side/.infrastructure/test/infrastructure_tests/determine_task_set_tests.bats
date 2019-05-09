#!/usr/bin/env bats
load setup

@test "determine_task_set correct for first half of experiment" {
  # Parameters for test_determine_task_set is in the order:
  # <TASK_ORDER> <EXPERIMENT_HALF> <EXPECTED_TREATMENT> <EXPECTED_TASK_SET>

  test_determine_task_set "T1N2" 1 "T" 1
  test_determine_task_set "T2N1" 1 "T" 2
  test_determine_task_set "N1T2" 1 "N" 1
  test_determine_task_set "N2T1" 1 "N" 2
}

@test "determine_task_set correct for second half of experiment" {
  # Parameters for test_determine_task_set is in the order:
  # <TASK_ORDER> <EXPERIMENT_HALF> <EXPECTED_TREATMENT> <EXPECTED_TASK_SET>

  test_determine_task_set "T1N2" 2 "N" 2
  test_determine_task_set "T2N1" 2 "N" 1
  test_determine_task_set "N1T2" 2 "T" 2
  test_determine_task_set "N2T1" 2 "T" 1
}
