#########################
## Files and directories
#########################

# Directory of distribution which is a symbolic link to CLIENT_DIR.
# This allows naming the directory distributed to the users without directly
# changing the CLIENT_DIR's name.
DIST_NAME=experiment

# The name of the distribution.
ZIP_DIST_NAME=$(DIST_NAME).zip

CLIENT_DIR=client_side
# This operation is safe because the test frame work will clean up any backup,
# temporary files, etc.
CLIENT_FILES=$(shell find $(CLIENT_DIR) -type f)

FS_DIR=$(CLIENT_DIR)/file_system

INFRA_DIR=$(CLIENT_DIR)/.infrastructure
TEST_DIR=$(INFRA_DIR)/test

#########################
## Host
#########################

# The machine that is hosting the website
HOST=tschweiz@attu.cs.washington.edu

# The website's directory on HOST
HOST_DIR=/cse/web/homes/tschweiz/research

# The host folder containing the website
WEBSITE_NAME=tellina_user_study

# Physical location where the website is hosted
PUBLIC_SITE=$(HOST_DIR)/$(WEBSITE_NAME)

# Hosted testing location
STAGING_SITE=$(HOST_DIR)/staging/$(WEBSITE_NAME)

# Local folder to store what is going to be hosted.
BUILD_TARGET=distribution

#########################
## Commands
#########################

RM=rm -rf
ZIP=zip -qr

#########################
## Tasks
#########################

# See https://www.gnu.org/software/make/manual/html_node/Phony-Targets.html
.PHONY: all test distribute publish-distribution stage-distribution cp_static

all: test distribute

test:
	$(MAKE) -C $(INFRA_DIR) test

# Assemble hosted content in folder specified by BUILD_TARGET
distribute: $(ZIP_DIST_NAME) dist-static dist-backend
	mkdir -p $(BUILD_TARGET)
	mv $< $(BUILD_TARGET)
	find $(BUILD_TARGET) -name "README.md" -type f -delete

# Publish the distribution to the production host folder.
publish: test distribute
	@echo "Publishing $<"
	@scp $< $(HOST):$(PUBLIC_SITE)

# Publish the distribution to the testing host folder.
stage-distribution: test distribute
	@echo "Staging $<"
	@scp $< $(HOST):$(STAGING_SITE)

clean: clean-dist clean-fs-dir

# Distribute static resources
dist-static:
	cp -a static/. $(BUILD_TARGET)

# Distribute the backend server_side
dist-backend:
	cp -r -p server_side $(BUILD_TARGET)

$(ZIP_DIST_NAME): $(DIST_NAME) $(CLIENT_FILES) test
	$(ZIP) $@ $<

$(DIST_NAME):
	ln -s $(CLIENT_DIR) $@

$(FS_DIR):
	cp -r $(INFRA_DIR)/file_system $@
	find $@ -type f -exec chmod a+w {} \;

# Check that the host has the website directory.
%/$(WEBSITE_NAME):
	@echo -n "Checking that host directory $@ exists... "
	@ssh $(HOST) '[ -d $@ ]'
	@echo "OK."

clean-dist:
	$(RM) $(ZIP_DIST_NAME)
	$(RM) $(DIST_NAME)
	$(RM) $(BUILD_TARGET)

clean-fs-dir:
	$(RM) $(FS_DIR)