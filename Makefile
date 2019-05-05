# Commands
RM=rm -rf
BATS=$(shell which bats)
GZIP=tar -pczf
ZIP=zip -qr

# Files and directories
DIST_NAME=tellina_user_experiment
ZIP_DIST=$(DIST_NAME).zip
GZIP_DIST=$(DIST_NAME).tar.gz

CLIENT_DIR=client_side
FS_DIR=$(CLIENT_DIR)/file_system

INFRA_DIR=$(CLIENT_DIR)/.infrastructure
TEST_DIR=$(INFRA_DIR)/test

$(find $(INFRA_DIR) -name "*.sh" -or -name "*.py" -or -name "configure"\
	-exec chmod 777 {} \;)

.PHONY: all test

all: test distribution

distribution: $(FS_DIR) zip gzip

zip: $(ZIP_DIST)

gzip: $(GZIP_DIST)

test: $(BATS) $(TEST_DIR)
	@$(BATS) $(TEST_DIR)

clean: clean-dist clean-fs-dir

clean-dist:
	$(RM) $(ZIP_DIST)
	$(RM) $(GZIP_DIST)

clean-fs-dir:
	$(RM) $(FS_DIR)

$(ZIP_DIST): $(CLIENT_DIR)
	$(ZIP) $(ZIP_DIST) $(CLIENT_DIR)

$(GZIP_DIST): $(CLIENT_DIR)
	$(GZIP) $(GZIP_DIST) $(CLIENT_DIR)

$(FS_DIR):
	mkdir $(FS_DIR)
	find . -name "fs.tgz" | xargs -I{} tar -xzf {} -C $(FS_DIR)
