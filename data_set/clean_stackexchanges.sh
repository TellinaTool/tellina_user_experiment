#!/bin/bash
python clean_stackexchange.py data-collected/stackoverflow-top500.csv https://stackoverflow.com/questions/
python clean_stackexchange.py data-collected/unixlinux-top500.csv https://unix.stackexchange.com/questions/
python clean_stackexchange.py data-collected/superuser-top500.csv https://superuser.com/questions/