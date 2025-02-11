// Socket steps
// 1. Create a socket
// 2. Bind the socket to an address
// 2.a. Create a struct sockaddr
// 2.b.
// 3. Listen for incoming connections
// 4. Accept incoming connections
// 5. Send and receive data

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <netinet/in.h>
#include <netdb.h>
#include <fcntl.h>
#include <errno.h>
#include <signal.h>
#include <pthread.h>
#include <syslog.h>
#include <sys/ioctl.h>
#include <linux/i2c-dev.h>

#ifndef AI_PASSIVE
#define AI_PASSIVE 0x0001
#endif

#define PORT 9000

int sock_fd, new_socket;
int status;
struct sockaddr sockaddr, newsockaddr;
struct addrinfo hints;
struct addrinfo *servinfo;

int main(int argc, char *argv[]) {
    

    memset(&hints, 0, sizeof(hints)); // Zero out hints
    hints.ai_family = AF_INET; // Set hints attributes
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE;

    // Open syslog
    openlog("aesdsocket", LOG_PID | LOG_NDELAY, LOG_USER);

    // Load address info into servinfo
    if (status = getaddrinfo(NULL, (char *)PORT, &hints, &servinfo) != 0) {
        perror("getaddrinfo failed");
        exit(EXIT_FAILURE);
        return -1;
    }

    // Create a socket
    if ((sock_fd = socket(PF_INET, SOCK_STREAM, 0)) == 0) {
        perror("socket failed");
        exit(EXIT_FAILURE);
        return -1;
    }

    // Bind the socket to an address
    if (bind(sock_fd, servinfo->ai_addr, sizeof(sockaddr)) < 0) {
        perror("bind failed");
        close(sock_fd);
        exit(EXIT_FAILURE);
        return -1;
    }
    
    // Free the address info from heap
    freeaddrinfo(servinfo);

    // Daemonize the process if -d flag is passed
    if (argc > 1) {
        if (strcmp(argv[1], "-d") == 0) {
            daemon(0, 0);
        }
    }

    // Loop to listen for connections
    while (1) {

        // Listen for incoming connections
        if (listen(sock_fd, 3) < 0) {
            perror("listen");
            close(sock_fd);
            exit(EXIT_FAILURE);
            return -1;
        }

        // Accept incoming connections
        if ((new_socket = accept(sock_fd, (struct sockaddr *)&newsockaddr, (socklen_t *)sizeof(newsockaddr))) < 0) {
            perror("accept");
            close(new_socket);
            exit(EXIT_FAILURE);
            return -1;
        }

        syslog(LOG_INFO, "Accepted connection from %d.%d.%d.%d\n", newsockaddr.sa_data[2], newsockaddr.sa_data[3], newsockaddr.sa_data[4], newsockaddr.sa_data[5]);

        // Recieve data
        char buffer[1024] = {0};
        int valread = read(new_socket, buffer, 1024);

        syslog(LOG_INFO, "Recieved %d bytes: %s\n", valread, buffer);

        // Write data to a file
        int fd = open("/var/tmp/aesdsocket", O_CREAT | O_WRONLY | O_TRUNC, 0666);
        write(fd, buffer, valread);

        // Write the contents of the file back to the client
        char file_buffer[1024] = {0};
        read(fd, file_buffer, 1024);
        write(new_socket, file_buffer, 1024);

        // Close the socket
        close(new_socket);
        syslog(LOG_INFO, "Closed connection from %d.%d.%d.%d\n", newsockaddr.sa_data[2], newsockaddr.sa_data[3], newsockaddr.sa_data[4], newsockaddr.sa_data[5]);

    }

    return 0;
}

// Signal handler for SIGINT
void sigint_handler(int sig) {
    syslog(LOG_INFO, "Caught signal, exiting\n");
    closelog();
    close(sock_fd);
    close(new_socket);
    system("rm /var/tmp/aesdsocket");
    exit(EXIT_SUCCESS);
}

// Signal handler for SIGTERM
void sigterm_handler(int sig) {
    syslog(LOG_INFO, "Caught signal, exiting\n");
    closelog();
    close(sock_fd);
    close(new_socket);
    system("rm /var/tmp/aesdsocket");
    exit(EXIT_SUCCESS);
}