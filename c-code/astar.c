// Include the Ruby headers and goodies
#include <ruby.h>
#include <math.h>
#include <float.h>
#include "priorityqueue.h"

#define QUEUE_MAX INT_MAX
#define AT(x, y) ((y)*width+(x))

double unitdist[] = {1.4142135623731, 1.0000000000000, 1.4142135623731,
                     1.0000000000000, 0.0000000000000, 1.0000000000000,
                     1.4142135623731, 1.0000000000000, 1.4142135623731};

typedef struct Chunk {
    int x;
    int y;
    double g; // distance so far
    double h; // heuristic disance to go
    double weight;
} Chunk;

bool chunk_less_than(const void *p1, const void *p2)
{
    Chunk* c1 = (Chunk*) p1;
    Chunk* c2 = (Chunk*) p2;
    // printf("chunk_less_than %d, %d: %f / %d, %d: %f\n", c1->x, c1->y, c1->g+c1->h, c2->x, c2->y, c2->g+c2->h);
    if( (c1->g + c1->h) < (c2->g + c2->h) )
        return 1;
    else
        return 0;
}

void show_chunk_queue(PriorityQueue* queue)
{
    int i;
    for(i = 1; i <= queue->size; i++)
    {
        Chunk* c = (Chunk*)queue->heap[i];
        printf("[%d, %d | %f] ", c->x, c->y, c->g + c->h);
    }
    printf("\n");
}

void show_int_queue(PriorityQueue* queue)
{
    int i;
    for(i = 1; i <= queue->size; i++)
    {
        int* c = (int *)queue->heap[i];
        printf("[%d] ", *c);
    }
    printf("\n");
}

static void explore(
    Chunk* cmap, int* closed, PriorityQueue* queue, Chunk* cval,
    int width, int height,
    int end_x, int end_y,
    int x, int y)
{
    int sx = cval->x + x;
    int sy = cval->y + y;
    
    if( sx >= 0 && sx < width &&
        sy >= 0 && sy < height )
    {
        int coord = AT(sx, sy);
        if ( !closed[coord] )
        {
            closed[coord] = 1;
            
            Chunk* nextval = cmap + coord;
            if( nextval->weight >= 0 )
            {
                double gdist, hdist;
                gdist = unitdist[ (nextval->y - cval->y + 1) * 3 +
                                  (nextval->x - cval->x + 1) ] + (nextval->weight);
                if( nextval->h == 0 )
                {
                    hdist = sqrt( (double)(
                                    (nextval->x - end_x) * (nextval->x - end_x) +
                                    (nextval->y - end_y) * (nextval->y - end_y) ) );
                    nextval->h = hdist;
                }
                if( cval->g + gdist < nextval->g )
                {
                    nextval->g = cval->g + gdist;

                    pq_insert(queue, (void *)(nextval));

                    rb_warn("explore added x: %d, y: %d, g: %f, h: %f", sx, sy, nextval->g, hdist);
                    // rb_warn("explore added x: %d, y: %d, w: %f", sx, sy, nextval->weight);
                }
            }
        }
    }
}

static int neighbor_value(Chunk* cmap, int width, int height, int x, int y)
{
    if( x >= 0 && x < width &&
        y >= 0 && y < height )
    {
        return cmap[AT(x, y)].g;
    }
    else
    {
        return -1;
    }
}

// Returns the smallest neighbor to cval, or NULL if no neighbors
static Chunk* smallest_neighbor(Chunk* cmap, Chunk* cval, int width, int height)
{
    Chunk* rval = NULL;
    int g, min = INT_MAX;
    
    g = neighbor_value(cmap, width, height, cval->x - 1, cval->y - 1);
    if( g >= 0 && g < min )
    { min = g; rval = cmap + AT(cval->x - 1, cval->y - 1); }
    
    g = neighbor_value(cmap, width, height, cval->x - 1,  cval->y);
    if( g >= 0 && g < min )
    { min = g; rval = cmap + AT(cval->x - 1, cval->y); }
    
    g = neighbor_value(cmap, width, height, cval->x - 1, cval->y + 1);
    if( g >= 0 && g < min )
    { min = g; rval = cmap + AT(cval->x - 1, cval->y + 1); }
    
    g = neighbor_value(cmap, width, height, cval->x, cval->y - 1);
    if( g >= 0 && g < min )
    { min = g; rval = cmap + AT(cval->x, cval->y - 1); }
    
    g = neighbor_value(cmap, width, height, cval->x, cval->y + 1);
    if( g >= 0 && g < min )
    { min = g; rval = cmap + AT(cval->x, cval->y + 1); }
    
    g = neighbor_value(cmap, width, height, cval->y + 1, cval->y - 1);
    if( g >= 0 && g < min )
    { min = g; rval = cmap + AT(cval->x + 1, cval->y - 1); }
    
    g = neighbor_value(cmap, width, height, cval->y + 1,  cval->y);
    if( g >= 0 && g < min )
    { min = g; rval = cmap + AT(cval->x + 1, cval->y); }
    
    g = neighbor_value(cmap, width, height, cval->y + 1, cval->y + 1);
    if( g >= 0 && g < min )
    { min = g; rval = cmap + AT(cval->x + 1, cval->y + 1); }
    
    return rval;
}

// A global reference to the Astar class
VALUE Astar = Qnil;

// The Astar#initialize method
static VALUE astar_init(VALUE self, VALUE map, VALUE width) {
    if (RARRAY_LEN(map) < NUM2INT(width))
        rb_raise(rb_eArgError, "Map size must be greater than or equal to width");
    if (RARRAY_LEN(map) % NUM2INT(width) != 0)
        rb_raise(rb_eArgError, "Map size must be divisible by width");
    
    rb_iv_set(self, "@map", map);
    rb_iv_set(self, "@width", width);
    rb_iv_set(self, "@height", INT2NUM(RARRAY_LEN(map) / NUM2INT(width)));
    return self;
}

static VALUE astar_search(
    VALUE self,
    VALUE rb_start_x, VALUE rb_start_y,
    VALUE rb_end_x, VALUE rb_end_y)
{
    int width   = NUM2INT(rb_iv_get(self, "@width"));
    int height  = NUM2INT(rb_iv_get(self, "@height"));
    int start_x = NUM2INT(rb_start_x);
    int start_y = NUM2INT(rb_start_y);
    int end_x   = NUM2INT(rb_end_x);
    int end_y   = NUM2INT(rb_end_y);
    int dx = end_x - start_x;
    int dy = end_y - start_y;
    
    long i, len = RARRAY(rb_iv_get(self, "@map"))->len;
    VALUE* map = RARRAY(rb_iv_get(self, "@map"))->ptr;
    
    if (start_x < 0 || start_x >= width)
        rb_raise(rb_eArgError, "start_x not in range");
    if (start_y < 0 || start_y >= height)
        rb_raise(rb_eArgError, "start_y not in range");
    if (end_x < 0 || end_x >= width)
        rb_raise(rb_eArgError, "end_x not in range");
    if (end_y < 0 || end_y >= height)
        rb_raise(rb_eArgError, "end_y not in range");
    
    // Keep a closed list of visited nodes
    int* closed = ALLOC_N(int, len);
    memset(closed, 0, sizeof(int)*len);
    
    // Create a discretized map using our C-struct instead of a ruby value
    Chunk* cmap = ALLOC_N(Chunk, len);
    for( i = 0; i < len; i++)
    {
        cmap[i].x = i % width;
        cmap[i].y = i / width;
        cmap[i].g = FLT_MAX;
        cmap[i].h = 0;
        cmap[i].weight = (double)NUM2INT(map[i]) / 100.0;
        // rb_warn("init %d: x: %d, y: %d, weight: %f", i, cmap[i].x, cmap[i].y, cmap[i].weight);
    }
    
    // int integers[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    // 
    // PriorityQueue* q = pq_new(QUEUE_MAX, icmp, dummy_free);
    // pq_insert(q, (void*)(integers + 5));
    // pq_insert(q, (void*)(integers + 1));
    // pq_insert(q, (void*)(integers + 3));
    // pq_insert(q, (void*)(integers + 2));
    // 
    // show_int_queue(q);
    // int* top = pq_pop(q);
    // printf("top: %d", *top);
    // 
    // pq_insert(q, (void*)(integers + 0));
    // pq_insert(q, (void*)(integers + 9));
    // pq_insert(q, (void*)(integers + 5));
    // show_int_queue(q);
    // 
    // top = pq_pop(q);
    // show_int_queue(q);
    // 
    // top = pq_pop(q);
    // show_int_queue(q);
    // 
    // top = pq_pop(q);
    // show_int_queue(q);
    // 
    // top = pq_pop(q);
    // show_int_queue(q);
    // 
    // top = pq_pop(q);
    // show_int_queue(q);
    // 
    // return self;
    
    // Create the PQ and initialize it with the starting chunk
    PriorityQueue* queue = pq_new(QUEUE_MAX, chunk_less_than, dummy_free);
    closed[AT(start_x, start_y)] = 1;
    Chunk* cval = cmap + AT(start_x, start_y);
    cval->h = sqrt((end_x-start_x)*(end_x-start_x)+(end_y-start_y)*(end_y-start_y));
    cval->g = 0;
    pq_insert(queue, (void *)(cval));
    
    // Actually do the search
    int coord;
    double distance = 0.0;
    while(cval->x != end_x && cval->y != end_y)
    {
        show_chunk_queue(queue);
        cval = (Chunk*)pq_pop(queue);
        rb_warn("cval | x: %d, y: %d, f: %f, g: %f, h: %f", cval->x, cval->y, (cval->g + cval->h), cval->g, cval->h);
        // Add 8 neighbors if they are not in the closed list
        explore(cmap, closed, queue, cval, width, height, end_x, end_y, -1, -1);
        explore(cmap, closed, queue, cval, width, height, end_x, end_y, -1,  0);
        explore(cmap, closed, queue, cval, width, height, end_x, end_y, -1, +1);
        explore(cmap, closed, queue, cval, width, height, end_x, end_y,  0, -1);
        explore(cmap, closed, queue, cval, width, height, end_x, end_y,  0, +1);
        explore(cmap, closed, queue, cval, width, height, end_x, end_y, +1, -1);
        explore(cmap, closed, queue, cval, width, height, end_x, end_y, +1,  0);
        explore(cmap, closed, queue, cval, width, height, end_x, end_y, +1, +1);

    }
    
    // Start traceback from the goal
    cval = cmap + AT(end_x, end_y);
    
    // Find our way from the goal back to the start
    VALUE trace = rb_ary_new();
    rb_ary_unshift(trace, rb_ary_new3(2, INT2NUM(cval->x), INT2NUM(cval->y)));
    // rb_warn("traceback: x: %d, y: %d", cval->x, cval->y);
    while(cval->x != start_x || cval->y != start_y)
    {
        cval = smallest_neighbor(cmap, cval, width, height);
        if( cval == NULL ) { rb_warn("null traceback"); break; }
        rb_ary_unshift(trace, rb_ary_new3(2, INT2NUM(cval->x), INT2NUM(cval->y)));
        // rb_warn("traceback: x: %d, y: %d", cval->x, cval->y);
    }
    
    free(cmap);
    pq_free(queue);
    // return INT2NUM(x);
    return trace;
}

// The initialization method for this module; Ruby calls this for us
void Init_astar() {
    Astar = rb_define_class("Astar", rb_cObject);
    rb_define_method(Astar, "initialize", astar_init, 2);
    rb_define_method(Astar, "search", astar_search, 4);
}
