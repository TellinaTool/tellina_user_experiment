#!/bin/bash
python clean_stackexchange.py data_collected/stackoverflow_top500.csv https://stackoverflow.com/questions/
python clean_stackexchange.py data_collected/unixlinux_top500.csv https://unix.stackexchange.com/questions/
python clean_stackexchange.py data_collected/superuser_top500.csv https://superuser.com/questions/