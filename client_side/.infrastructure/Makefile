BATS=$(shell which bats)
# Check that Bats is installed.
ifeq (, $(BATS))
$(error Bats (https://github.com/bats-core/bats-core) is not installed.)
endif

TEST_DIR=test
TEST_FILES=$(shell find $(TEST_DIR) -type f -name "*.bats")

.PHONY: all
all: test

test: fix-execs $(TEST_FILES)
	@$(BATS) $(TEST_FILES)

fix-execs:
	@find . -name "*.sh" -or -name "*.py" -or -name "configure"\
		-exec chmod 755 {} \;
