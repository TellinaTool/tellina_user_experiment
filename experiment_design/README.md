This folder contains resources to prepare the Tellina user experiment. 

# Contents

- `freqs.cm` contains the frequency of each bash utility from the [NLP2Bash](https://github.com/TellinaTool/nl2bash/tree/master/data) dataset
- `sample_tasks.ipynb` samples *n* commands from the `freqs.cm` population in order to have a representative task set for the user experiment.

# Python scripts
The python scripts in this folder use [`pipenv`](https://docs.pipenv.org/) to manage package dependency and virtual environment. The package dependencies can be seen in the `Pipfile`.