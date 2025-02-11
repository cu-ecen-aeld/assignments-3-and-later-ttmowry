CFLAGS = -Wall -g

SRCS = server.c

OBJS = $(SRCS:.c=.o)

TARGET = aesdsocket

%.o : %.c
	$(CROSS_COMPILE)gcc $(CFLAGS) -c $<

%(TARGET): $(OBJS)
	$(CROSS_COMPILE)gcc $(CFLAGS) -o $@ $(OBJS)

.PHONY: all
all: $(TARGET)

.PHONY: default
default: $(TARGET)

.PHONY: clean
clean:
	rm -f $(TARGET) $(OBJS)