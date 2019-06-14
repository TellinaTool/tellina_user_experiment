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
CLIENT_FILES=$(shell find $(CLIENT_DIR) -type f)

FS_DIR=$(CLIENT_DIR)/file_system
TASKS_MODIFICATION_TIMES=TASK_G_TIME TASK_H_TIME TASK_P_TIME

INFRA_DIR=$(CLIENT_DIR)/.infrastructure
TEST_DIR=$(INFRA_DIR)/test

# Website

# The machine that is hosting the website
HOST=atran35@attu.cs.washington.edu

# The website's directory on HOST
HOST_DIR=/cse/web/homes/atran35/research

# Can be something else if needed
WEBSITE_NAME=$(DIST_NAME)

PUBLIC_SITE=$(HOST_DIR)/$(WEBSITE_NAME)
STAGING_SITE=$(HOST_DIR)/staging/$(WEBSITE_NAME)

.PHONY: all test publish-distribution stage-distribution

all: $(ZIP_DIST_NAME)

test:
	$(MAKE) -C $(INFRA_DIR) test

clean: clean-dist clean-fs-dir

clean-dist:
	$(RM) $(ZIP_DIST_NAME)
	$(RM) $(DIST_NAME)

clean-fs-dir:
	$(RM) $(FS_DIR)

$(ZIP_DIST_NAME): $(DIST_NAME) $(CLIENT_FILES) $(TASKS_MODIFICATION_TIMES) test
	$(ZIP) $@ $<

$(DIST_NAME):
	ln -s $(CLIENT_DIR) $@

$(FS_DIR):
	cp -r $(INFRA_DIR)/file_system $@
	find $@ -type f -exec chmod a+w {} \;

TASK_G_TIME: $(FS_DIR)
	$(eval TIME=$(shell date -d "-300 days" +%Y%m%d%H%M))
	$(eval TOUCH=touch -m -t $(TIME))

	find "$</css/" -type f -exec touch -m {} \;

	$(TOUCH) $</css/bootstrap3/bootstrap-glyphicons.css
	$(TOUCH) $</css/fonts/glyphiconshalflings-regular.eot
	$(TOUCH) $</css/fonts/glyphiconshalflings-regular.otf
	$(TOUCH) $</css/fonts/glyphiconshalflings-regular.svg
	$(TOUCH) $</css/fonts/glyphiconshalflings-regular.ttf

TASK_H_TIME: $(FS_DIR)
	$(eval TIME=201602050900)
	$(eval TOUCH=touch -m -t $(TIME))

	find "$</content/" -type f -exec $(TOUCH) {} \;

TASK_P_TIME: $(FS_DIR)
	$(eval TIME=201701100036)
	$(eval TOUCH=touch -m -t $(TIME))

	find "$</content/labs/2013" -type f -exec $(TOUCH) {} \;

# Copy the ZIP distribution on the public site specified by PUBLIC_SITE.
publish-distribution: $(ZIP_DIST_NAME) $(PUBLIC_SITE)
	@echo "Publishing $<"
	@scp $< $(HOST):$(PUBLIC_SITE)

# Copy the ZIP distribution on the staging site specified by STAGING_SITE.
stage-distribution: $(ZIP_DIST_NAME) $(STAGING_SITE)
	@echo "Staging $<"
	@scp $< $(HOST):$(STAGING_SITE)

# Check that the host has the website directory.
%/$(WEBSITE_NAME):
	@echo -n "Checking that host directory $@ exists... "
	@ssh $(HOST) '[ -d $@ ]'
	@echo "OK."
