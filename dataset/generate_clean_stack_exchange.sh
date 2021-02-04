#!/bin/bash
python clean_stack_exchange.py data-collected/stackoverflow-top500.csv https://stackoverflow.com/questions/
python clean_stack_exchange.py data-collected/unixlinux-top500.csv https://unix.stackexchange.com/questions/
python clean_stack_exchange.py data-collected/superuser-top500.csv https://superuser.com/questions/