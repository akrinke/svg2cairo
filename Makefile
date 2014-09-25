TARGET = svg2cairoxml
SRC = svg2cairoxml.c
OBJ = $(SRC:.c=.o)

CC = gcc

#############################################################
# Uncomment for alternative Cairo installation in /usr/local/
CFLAGS = -I/usr/local/include/cairo
LDFLAGS = -L/usr/local/lib
#############################################################

CFLAGS  += -Wall -O3 $(shell pkg-config --cflags librsvg-2.0 cairo)
LDFLAGS += $(shell pkg-config --libs librsvg-2.0 cairo)
RM = rm

%.o: %.c
	$(CC) $(CFLAGS) -o $@ -c $<

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(OBJ) $(LDFLAGS) -o $@

clean:
	$(RM) -f $(OBJ) $(TARGET) core

.PHONY: all clean