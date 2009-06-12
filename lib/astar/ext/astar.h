#ifndef ASTAR_H
#define ASTAR_H

#define DEFAULT_WEIGHT 0.0
#define QUEUE_MAX 100000
#define AT(x, y) ((y)*width+(x))

#ifndef DBL2NUM
#define DBL2NUM(dbl)  rb_float_new(dbl)
#endif

typedef struct Chunk {
    int x;
    int y;
    double g; // distance so far
    double h; // heuristic disance to go
    double weight;
    void* prev_chunk;
} Chunk;

typedef struct Triangle {
    int x1, y1;
    int x2, y2;
    int x3, y3;
} Triangle;

static VALUE astar_new(int argc, VALUE* argv, VALUE class);
static VALUE astar_init(int argc, VALUE* argv, VALUE self);
static VALUE astar_width(VALUE self);
static VALUE astar_height(VALUE self);
static VALUE astar_reset(VALUE self);
static VALUE astar_clear(int argc, VALUE* argv, VALUE self);
static void astar_explore(
    Chunk* map, int* closed, PriorityQueue* queue, Chunk* curr_chunk,
    int width, int height,
    int end_x, int end_y,
    int x, int y);
static VALUE astar_search(
    VALUE self,
    VALUE rb_start_x, VALUE rb_start_y,
    VALUE rb_end_x, VALUE rb_end_y);
static VALUE astar_get(VALUE self, VALUE rb_x, VALUE rb_y);
static VALUE astar_set(VALUE self, VALUE rb_x, VALUE rb_y, VALUE rb_weight);
static Triangle astar_triangle_vertex_sort(
    VALUE rb_x1, VALUE rb_y1,
    VALUE rb_x2, VALUE rb_y2,
    VALUE rb_x3, VALUE rb_y3);
static VALUE astar_triangle(
    VALUE self,
    VALUE rb_x1, VALUE rb_y1,
    VALUE rb_x2, VALUE rb_y2,
    VALUE rb_x3, VALUE rb_y3,
    VALUE rb_weight);
static VALUE astar_rectangle(
    VALUE self,
    VALUE rb_min_x, VALUE rb_min_y,
    VALUE rb_max_x, VALUE rb_max_y,
    VALUE rb_weight);
static VALUE astar_polygon(VALUE self, VALUE rb_ary_coords, VALUE rb_weight);

#endif