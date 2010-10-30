CFLAGS  = -Wall `pkg-config --cflags librsvg-2.0 cairo`
LDFLAGS = `pkg-config --libs librsvg-2.0 cairo`

all:
	$(CC) $(CFLAGS) -o svg2cairoxml svg2cairoxml.c $(LDFLAGS)
