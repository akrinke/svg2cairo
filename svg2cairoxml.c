/*
Copyright (c) 2010 Andreas Krinke

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

#include <stdio.h>
#include <stdlib.h>

#include <librsvg/rsvg.h>

#include <cairo.h>
#include <cairo-xml.h>

static void usage() {
    printf("usage: svg2cairoxml svg-file xml-file\n");
}

static cairo_status_t write_func(FILE *fp, unsigned char *data, unsigned int size) {
    if (fwrite(data, 1, size, fp) != size)
        return CAIRO_STATUS_WRITE_ERROR;
    
    return CAIRO_STATUS_SUCCESS;
}

int main(int argc, char *argv[]) {
    FILE *fp;
    RsvgHandle *rsvg;
    cairo_device_t *dev = NULL;
    cairo_surface_t *surface = NULL;
    cairo_t *cr = NULL;
    RsvgDimensionData dimensions;
    
    if (argc < 3) {
        usage();
        return 0;
    }
    
    fp = fopen(argv[1], "r");
    if (fp == NULL) {
        printf("could not open '%s' for read\n", argv[1]);
        return 1;
    }
    fclose(fp);

    fp = fopen(argv[2], "w");
    if (fp == NULL) {
        printf("could not open '%s' for write\n", argv[2]);
        return 1;
    }

    dev = cairo_xml_create_for_stream((cairo_write_func_t)write_func, fp);

    rsvg_set_default_dpi_x_y(-1, -1);

    rsvg = rsvg_handle_new_from_file(argv[1], NULL);
    rsvg_handle_get_dimensions(rsvg, &dimensions);
    
    fprintf(fp, "<image width='%d' height='%d'>\n", dimensions.width, dimensions.height);

    surface = cairo_xml_surface_create(dev, CAIRO_CONTENT_COLOR_ALPHA, dimensions.width, dimensions.height);

    cr = cairo_create(surface);

    rsvg_handle_render_cairo(rsvg, cr);
    rsvg_handle_close(rsvg, NULL);

    cairo_destroy(cr);
    cairo_surface_destroy(surface);
    
    fprintf(fp, "</image>\n");
    fclose(fp);

    return 0;
}

