# Bash source file loaded by Bats defining useful test assertions and output
# printing.

# Prints all arguments passed to the console.
debug() {
  echo "------------"
  for arg in $@; do
    echo "$arg"
  done
}

# Prints the actual and expected values of a test
# $1: actual value
# $2: expected value
output_failure() {
  echo "------------"
  echo "Actual: $1"
  echo "Expected: $2"
}

# Prints the exit status of a command run by a test.
# $1: the exit status of a command.
status_failure() {
  echo "------------"
  echo "Status: $1"
}

# Asserts that a command returned with 0 exit code.
assert_success() {
  status_failure $status
  [[ $status == 0 ]]
}

# Assert that a command returned with a non 0 exit code.
assert_failure() {
  status_failure $status
  [[ $status != 0 ]]
}

# Assert that a given actual value matches a given expected value.
# 
# Can provide an "-n" flag to instead check that the actual does not match the
# expected value. The flag must appear before both the actual and expected
# values
#
# $1: the actual value
# $2: the expected value
assert_output() {
  if [[ "$1" == "-n" ]]; then
    no_match="$1"
    shift
  fi

  local actual=$1
  local expected=$2

  output_failure $actual $expected
  if [[ -n $no_match ]]; then
    [[ $actual != $expected ]]
  else
    [[ $actual == $expected ]]
  fi
}
