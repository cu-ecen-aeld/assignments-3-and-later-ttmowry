#!/bin/sh
# Assignment 1 finder script

# This assignment takes 2 arguments
# The first argument is the directory to search
# The second argument is the string to search for
# Exits 1 and prints an error message if the number of arguments is not 2
# Exits 1 and prints an error message if the first argument is not a directory
# prints message "The numer of files are X and the number of matching lines are Y"
# where X is the number of files in the directory and Y is the number of lines in the files that contain the search string

FILESDIR=$1
SEARCHDIR=$2

if [ $# -ne 2 ]; then

    echo "Error: Invalid number of arguments"
    echo "First argument is the directory to search, second argument is the string to search for"
    exit 1

else if [ ! -d $FILESDIR ]; then

    echo "Error: $FILESDIR is not a directory"
    exit 1

else

    NUMFILES=$(ls $FILESDIR | wc -l)
    NUMLINES=$(grep -r $SEARCHDIR $FILESDIR | wc -l)
    echo "The number of files are $NUMFILES and the number of matching lines are $NUMLINES"

fi
fi