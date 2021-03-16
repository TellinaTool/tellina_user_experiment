# User Experiment Data Set
This folder contains the scripts used to produce the data set for the user experiment (referenced as _taskset_). 
The data set goes through intermediate steps before its final form. The process is described in [Data Process](#data-process).

We describe as 'posts' the questions & answers posted on the stack exchange website or the commands and their description for the other websites. For example, one 'post' on StackOverflow consist of the pair formed by the original question and the accepted answer.

## Contents
- `data_collected/`: Contains the raw posts data parsed from the web.
- `data_clean/`: Contains the raw posts data that have been cleaned up (referenced as _candidate posts_).
- `data_filtered/`: Contains the posts that have been filtered from the raw posts data (referenced as _compatible posts_). In most case, only the first top 30 compatible posts have been extracted.
- `taskset/`: Contains the final set of posts that are going to be used in the user experiment (referenced as _sampled posts_).
- `web_scrapers/`: Contains the web scrapping scripts to extract the posts information from the websites.
- `utilities/`: Contains information about Tellina's training set.
- `clean_stackexchange.py`: Python script that cleans raw post data for one stack exchange website.
- `clean_stackexchanges.sh`: Bash script that calls `clean_stackexchange.py` for all stack exchange websites.
- `sample_tasks.ipynb`: Jupyter Notebook that randomly samples _compatible posts_ located in `data_filtered/` to build the taskset.
- `interactive_filter_stackexchange.py` Interactive python script that filters _candidate posts_ into _compatible posts_.


## Data Process
### 1. Post Acquisition
The posts are collected through web-scrapping on five source websites: 
- [StackOverflow](https://stackoverflow.com/)
- [SuperUser](https://superuser.com/)
- [Unix&Linux](https://unix.stackexchange.com/)
- [CommandLineFu](https://www.commandlinefu.com/)
- [Bash One-Liners](http://www.bashoneliners.com/)

The web-scrapping scripts for CommandLineFu and Bash One-Liners are located in the `web_scrapers/` folder. For the stack exchange websites (StackOverflow, SuperUser, and Unix&Linux), the posts are obtained using the [Stack Exchange Data Explorer](https://data.stackexchange.com/). See `web_scrapers/` for more details.

The data obtained from this step is stored in the `data_collected` folder. We refer to this data set as _raw posts_.

The _raw posts_ totals 2287 posts (Bash One-Liners has only 287 records for the entire website). We verified that the most popular questions have a score of at least 0.

### 2. Post Cleaning
This step cleans the data obtained from the previous step into something that can be parsed and automated easily.

For CommandLineFu and Bash One-Liners, the process is minimal: We prepend each line with the base URL of the website using the following commands:
* `sed -e 's#^#http://www.bashoneliners.com#' data_collected/bashoneliners_top500.csv > bashoneliners_top500_clean.csv`
* `sed -e 's#^#https://www.commandlinefu.com#' data_collected/commandlinefu_top500.csv > commandlinefu_top500_clean.csv`

For the stack exchange websites, we clean them using the Bash script `clean_stackexchanges.sh`. This script will call `clean_stackexchange.py` for each stack exchange website.

The data obtained from this step is stored in the `data_clean` folder. We refer to this data set as _candidate posts_.

### 3. Post Filtering
The goal of this step is too filter the _candidate posts_ that are compatible with Tellina and our user experiment.

For CommandLineFu and Bash One-Liners, the process uses various RegExps that are stored in `data_filtered/filters.txt`. Each command is called manually to gradually remove incompatible posts from the _candidate posts_.

For the stack exchange websites, the process is semi-automatic due to the more complex format of Questions and Answer websites like StackOverflow. We built `interactive_filter_stackexchange.py` to eliminate most of the noise automatically and help the user select the top compatible questions and answers posts.

For all the websites, we used the scoping specification from the [NL2Bash paper](https://github.com/TellinaTool/nl2bash) to inform each decision to either include or reject a post. We have conveniently copied a summary in `utilities/in_scope.txt` and `utilities/out_of_scope.txt`.

The data obtained from this step is stored in the `data_filtered` folder. We refer to this data set as _compatible posts_.

### 4. Post Sampling
This is the last step where we sample our _compatible posts_ to the number needed for the user experiment.

We use the Jupyter notebook `sample_tasks.ipynb` to sample the _compatible posts_ in `data_filtered/` to the `taskset/` directory. The refer to these as _sampled posts_.

## Requirements
The scripts in this folder structure use `Python` and `Bash`. The required python modules are declared in `requirements.txt`.

# Future Improvements
While converting sampled posts to tasks, we encountered some posts that were not translatable to actionable tasks for the user study:


- Questions or posts that are environment specific cannot be tested in a user study with the test harness because each participant will have a system slightly different, even while using a VM (e.g., process or shell name)
- Commands or utilities that affect processes or system (e.g. `kill`) can be dangerous on the participants' system and are not reproducible.
- Commands or utilities that do not terminate cannot be evaluated (e.g., `watch`).

Thus, we recommend an additional filtering step before sampling to weed out questions and utilities that are not translatable into actionable tasks and incompatible with our user study harness.