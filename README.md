[![Build Status](https://travis-ci.com/TellinaTool/tellina_user_experiment.svg?branch=master)](https://travis-ci.com/TellinaTool/tellina_user_experiment)
# Tellina User Experiment
Tellina is a natural language -> command translation tool. Tellina accepts a natural language description of file system operations and displays a ranked list of bash one-liner suggestions made by the model. The user can scroll down the web page to explore more suggestions. http://tellina.rocks/

This repository contains the infrastructure for formally conducting user experiments for Tellina.

- [**static**](https://github.com/TellinaTool/tellina_user_experiment/tree/master/static): contains the static content hosted on a public server. This is where the homepage and consent page of the experiment are located.
- [**backend**](https://github.com/TellinaTool/tellina_user_experiment/tree/master/backend): contains the code used for the server side of the experiment, this includes both the post handler.
- [**client_side**](https://github.com/TellinaTool/tellina_user_experiment/tree/master/client_side): contains the files to be distributed to the users of the experiment.
- [**data_set**](https://github.com/TellinaTool/tellina_user_experiment/tree/master/dataset): contains the scripts used to produce the data set for the user experiment (referenced as _taskset_).
- [**infrastructure.md**](https://github.com/TellinaTool/tellina_user_experiment/blob/master/infrastructure.md): describes the technical infrastructure and implementation of the user experiment.


## Distributing the experiment to a new host

1. Clone this repository locally
2. Update the Makefile in the local repo with the intended values for `HOST` and `HOST_DIR`.
3. Update `SERVER_HOST` in `client_side/.infrastructure/setup.sh` with the new host.
4. Create directory `HOST_DIR/WEBSITE_NAME` on `HOST`.
   a. (Optional) Create directory `HOST_DIR/staging/WEBSITE_NAME` if you would like to have a testing website.
5. Run  `make all publish` to build and upload the study website on the new host.
6. Update the permission of `$HOST/$HOST_DIR/backend/log.csv` with `chmod 666 log.csv`

### Requirements
- Linux Environment (MacOS or Windows is not compatible)
- [Bats](https://github.com/bats-core/bats-core)
- [zip](https://linux.die.net/man/1/zip) (if it's not already installed on your system)

## Previously
In a past experiment, people were given descriptions of file system operations, and asked to write bash commands to perform the operations.  The experimental group had access to Tellina, web search, and man pages; the control group had access only to web search and man pages. Measurements were done on whether subjects successfully complete the tasks, and the amount of time that it takes to complete the tasks. A post-task questionnaire obtained qualitative feedback.

We need to redo the experiment, for a few reasons.
1. Tellina has changed since the user study was performed.  Tellina has better
   accuracy and handles more commands.  It would not be compelling to report an
   experiment on an implementation that has since been superseded.
2. The user study was relatively small (around 30 subjects), so the experimental
   results were not always statistically significant.  With a larger pool of
   subjects, the results will be more compelling.