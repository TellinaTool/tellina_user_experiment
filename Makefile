# Commands
RM=rm -rf
ZIP=zip -qr

# Files and directories.

# Directory of distribution which is a symbolic link to CLIENT_DIR.
# This allows naming the directory distributed to the users without directly
# changing the CLIENT_DIR's name.
DIST_NAME=bash_user_experiment

# The name of the distribution.
ZIP_DIST_NAME=$(DIST_NAME).zip

CLIENT_DIR=client_side
# This operation is safe because the test frame work will clean up any backup,
# temporary files, etc.
CLIENT_FILES=$(shell find $(CLIENT_DIR))
FS_DIR=$(CLIENT_DIR)/file_system

INFRA_DIR=$(CLIENT_DIR)/.infrastructure
TEST_DIR=$(INFRA_DIR)/test

.PHONY: all test

all: $(ZIP_DIST_NAME)

test:
	$(MAKE) -C $(INFRA_DIR) test

clean: clean-dist clean-fs-dir

clean-dist:
	$(RM) $(ZIP_DIST_NAME)
	$(RM) $(DIST_NAME)

clean-fs-dir:
	$(RM) $(FS_DIR)

$(ZIP_DIST_NAME): $(DIST_NAME) $(FS_DIR) test
	$(ZIP) $@ $<

$(DIST_NAME): $(CLIENT_DIR) $(CLIENT_FILES)
	ln -s $< $@

$(FS_DIR):
	mkdir $@
	find . -name "fs.tgz" | xargs -I{} tar -xzf {} -C $@
