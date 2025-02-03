CC = aarch64-none-linux-gnu-gcc

CFLAGS = -Wall -Werror -g

SRCS = writer.c

OBJS = $(SRCS:.c=.o)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

writer: $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

.PHONY: all
all: writer

.PHONY: clean
clean:
	rm -f $(OBJS) writer