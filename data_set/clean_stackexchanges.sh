#!/bin/bash
DATA_DIR="data_collected"
SITES="stackoverflow|unix.stackexchange|superuser"
SITE_TRAILER="questions"
IFS='|' for site in "$SITES"; do
    python clean_stackexchange.py "$DATA_DIR"/"${site}-top500.csv" 'https://'"${site}.com/$SITE_TRAILER"
done