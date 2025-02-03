// Assignment is an alternative to the writer.sh application
// Requirements are the same as the writer.sh application except 
// this application isn't required to make a directory that doesn't exist
// This also sets up system logging in /var/log/syslog

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>

int main( int argc, char *argv[] ) {

    // Open the system log
    openlog("writer", LOG_PID, LOG_USER);

    FILE *file = fopen(argv[1], "w");
    if (file == NULL) {
        syslog(LOG_ERR, "Error: Could not open file %s\n", argv[1]);
        return 1;
    }

    // Check for correct number of arguments
    if (argc != 2) {
        syslog(LOG_ERR,"Error: Incorrect number of arguments\n");
        syslog(LOG_ERR,"First argument must be a file to write to, second must be a string\n");
        return 1;
    }

    // Write the message to the system log
    syslog(LOG_DEBUG, "writing %s to %s", argv[2], argv[1]);

    fprintf(file, "%s\n", argv[2]);

    return 0;
}