CFLAGS = -Wall -Werror -g

SRCS = writer.c

OBJS = $(SRCS:.c=.o)

%.o: %.c
	$(CROSS_COMPILE)gcc $(CFLAGS) -c $< -o $@

writer: $(OBJS)
	$(CROSS_COMPILE)gcc $(CFLAGS) -o $@ $^

.PHONY: all
all: writer

.PHONY: clean
clean:
	rm -f $(OBJS) writer