BATS=$(shell which bats)

TEST_DIR=test
TEST_FILES=$(shell find $(TEST_DIR) -type f -name "*.bats")

.PHONY: all
all: test

test: fix-execs $(BATS) $(TEST_FILES)
	@$(BATS) $(TEST_FILES)

fix-execs:
	@find . -name "*.sh" -or -name "*.py" -or -name "configure"\
		-exec chmod 755 {} \;
