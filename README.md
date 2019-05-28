[![Build Status](https://travis-ci.org/anhnamtran/tellina_user_experiment.svg?branch=master)](https://travis-ci.org/anhnamtran/tellina_user_experiment)
# Tellina User Experiment

## Directory explanation
- `server_side`: the code used for the server side of the experiment, this
  includes both the post handler and the post-processor.
- `client_side`: this is the directory that contains the files to be distributed
  to the users of the experiment.
  - To distribute the files, run `make` or `make all`. This will run all tests
    and create the `.zip` file for distribution.
    - The `DIST_NAME` variable in the [Makefile](Makefile) specifies the name of
      the `.zip` file that will be created.
  - The structure of this directory is specified in
    [here](experiment_design_doc.md#directory-structure) in the experiment
    design doc.
