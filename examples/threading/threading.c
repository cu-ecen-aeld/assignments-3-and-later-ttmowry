#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

// Optional: use these functions to add debug or error prints to your application
#define DEBUG_LOG(msg,...)
//#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)

void* threadfunc(void* thread_param)
{

    // TODO: wait, obtain mutex, wait, release mutex as described by thread_data structure
    // hint: use a cast like the one below to obtain thread arguments from your parameter
    //struct thread_data* thread_func_args = (struct thread_data *) thread_param;
    struct thread_data* thread_params = (struct thread_data *) thread_param;
    
    usleep(thread_params->wait_to_take);
    int rc = pthread_mutex_lock(thread_params->mutex);
    if (rc != 0)
    {
        ERROR_LOG("Failed to lock mutex");
        return thread_params;
    }
    usleep(thread_params->wait_to_release);
    rc = pthread_mutex_unlock(thread_params->mutex);
    if (rc != 0)
    {
        ERROR_LOG("Failed to unlock mutex");
        return thread_params;
    }
    thread_params->thread_complete_success = true;
    return thread_params;
}


bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex,int wait_to_obtain_ms, int wait_to_release_ms)
{
    /**
     * TODO: allocate memory for thread_data, setup mutex and wait arguments, pass thread_data to created thread
     * using threadfunc() as entry point.
     *
     * return true if successful.
     *
     * See implementation details in threading.h file comment block
     */
    struct thread_data * thread_data = malloc(sizeof(struct thread_data));

    int rc = pthread_mutex_init(&mutex, NULL);
    if (rc != 0)
    {
        ERROR_LOG("Failed to initialize mutex");
        return false;
    }
    thread_data->wait_to_take = wait_to_obtain_ms;
    thread_data->wait_to_release = wait_to_release_ms;
    thread_data->mutex = &mutex;
    if (pthread_create(thread, NULL, threadfunc, thread_data) != 0)
    {
        ERROR_LOG("Failed to create thread");
        return false;
    } 
    return true;
}

