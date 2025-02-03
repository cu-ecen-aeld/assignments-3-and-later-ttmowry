#!/bin/bash

# Assignment 1 writer script

# This assignment takes 2 arguments
# The first argument is the fill path of the file to write to (including the file name)
# The second argument is the string to write to the file

# If a file does not exist at the path specified in the first argument, the script will 
# create the file and write the string to it

WRITEFILE=$1
WRITESTR=$2

WRITEDIR=$(dirname $WRITEFILE)

if [ $# -ne 2 ]; then

    echo "Error: Invalid number of arguments"
    echo "First argument is the file to write to, second argument is the string to write"
    exit 1

else if [ ! -f $WRITEFILE ]; then

    $(mkdir -p $WRITEDIR && touch $WRITEFILE)
    echo $WRITESTR > $WRITEFILE
    exit 0

else


    echo $WRITESTR > $WRITEFILE
    exit 0

fi
fi