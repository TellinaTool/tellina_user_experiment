# Directories
- `log.csv`: contains log of user experiments, see design doc for more details.
- `post_handler`:
  - Contains the web app that handles `POST` requests coming from the user and
    writes them to a log file.
- `post_processor`:
  - Contains the program that parses user log files into more readable results
    (see design doc).
