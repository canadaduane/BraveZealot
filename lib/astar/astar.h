#ifndef ASTAR_H
#define ASTAR_H

#define DEFAULT_WEIGHT 0.0
#define QUEUE_MAX 100000
#define AT(x, y) ((y)*width+(x))

typedef struct Chunk {
    int x;
    int y;
    double g; // distance so far
    double h; // heuristic disance to go
    double weight;
    void* prev_chunk;
} Chunk;

static VALUE astar_new(int argc, VALUE* argv, VALUE class);
static VALUE astar_init(int argc, VALUE* argv, VALUE self);
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
static VALUE astar_add_rect(
    VALUE self,
    VALUE rb_min_x, VALUE rb_min_y,
    VALUE rb_max_x, VALUE rb_max_y,
	VALUE rb_weight);
static VALUE astar_add_poly(VALUE self, VALUE rb_ary_coords, VALUE rb_weight);

#endif