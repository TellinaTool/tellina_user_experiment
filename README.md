[![Build Status](https://travis-ci.com/TellinaTool/tellina_user_experiment.svg?branch=master)](https://travis-ci.com/TellinaTool/tellina_user_experiment)
# Tellina User Experiment
Tellina is a natural language -> command translation tool. Tellina accepts a natural language description of file system operations and displays a ranked list of bash one-liner suggestions made by the model. The user can scroll down the web page to explore more suggestions.

This repository contains the infrastructure for formally conducting user experiments for Tellina.

- [**server_side**](https://github.com/TellinaTool/tellina_user_experiment/tree/master/client_side): contains the files to be distributed to the users of the experiment.
- [**client_side**](https://github.com/TellinaTool/tellina_user_experiment/tree/master/server_side): contains the code used for the server side of the experiment, this includes both the post handler and the post-processor.
- [**data_set**](https://github.com/TellinaTool/tellina_user_experiment/tree/master/dataset): contains the scripts used to produce the data set for the user experiment (referenced as _taskset_).
- [**experiment_design_doc.md**](https://github.com/TellinaTool/tellina_user_experiment/blob/master/experiment_design_doc.md): instructions for setting up and conducting the user experiments.

## Distributing experiment
To distribute the files, run `make` or `make all`. This will run all tests and create the `.zip` file for distribution at the root of this folder.
  - The `DIST_NAME` variable in the [Makefile](Makefile) specifies the name of the `.zip` file that will be created.
  - The structure of the experiment archive is specified in [the experiment design doc](experiment_design_doc.md#directory-structure).

### Requirements
- [Bats](https://github.com/bats-core/bats-core)
- [zip](https://linux.die.net/man/1/zip) (if it's not already installed on your system)
