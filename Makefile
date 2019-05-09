# Commands
RM=rm -rf
BATS=$(shell which bats)
GZIP=tar -pczf
ZIP=zip -qr

# Files and directories
# the name of the distribution
DIST_NAME=tellina_user_experiment

ZIP_DIST_NAME=$(DIST_NAME).zip

CLIENT_DIR=client_side
CLIENT_FILES=$(shell find $(CLIENT_DIR))
FS_DIR=$(CLIENT_DIR)/file_system

INFRA_DIR=$(CLIENT_DIR)/.infrastructure
TEST_DIR=$(INFRA_DIR)/test

.PHONY: all test

all: distribution

test:
	$(MAKE) -C ${INFRA_DIR} test

distribution: test $(FS_DIR) zip

zip: $(ZIP_DIST_NAME)

clean: clean-dist clean-fs-dir

clean-dist:
	$(RM) $(ZIP_DIST_NAME)
	$(RM) $(DIST_NAME)

clean-fs-dir:
	$(RM) $(FS_DIR)

$(ZIP_DIST_NAME): $(DIST_NAME) $(CLIENT_FILES)
	$(ZIP) $(ZIP_DIST_NAME) $<

$(DIST_NAME): $(CLIENT_DIR)
	ln -s $< $(DIST_NAME)

$(FS_DIR):
	mkdir $(FS_DIR)
	find . -name "fs.tgz" | xargs -I{} tar -xzf {} -C $(FS_DIR)
