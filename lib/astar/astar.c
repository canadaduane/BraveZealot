// Include the Ruby headers and goodies
#include <ruby.h>
#include <math.h>
#include <float.h>
#include "priorityqueue.h"

#define DEFAULT_WEIGHT 0.0
#define QUEUE_MAX 100000
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
    void* prev_chunk;
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

// A global reference to the Astar class
VALUE Astar = Qnil;

static VALUE astar_new(int argc, VALUE* argv, VALUE class) {
    double initial_weight = DEFAULT_WEIGHT;

    if (argc < 2)
        rb_raise(rb_eArgError, "Expecting width and height arguments");
    if (!rb_obj_is_kind_of(argv[0], rb_cNumeric))
        rb_raise(rb_eArgError, "Width must be numeric");
    if (!rb_obj_is_kind_of(argv[1], rb_cNumeric))
        rb_raise(rb_eArgError, "Height must be numeric");
    if (argc == 3)
        initial_weight = NUM2DBL(argv[2]);
    
    int width      = INT2NUM(argv[0]);
    int height     = INT2NUM(argv[1]);
    long i, len    = width * height;

    // Create a discretized map of Chunks
    Chunk* map = ALLOC_N(Chunk, len);
    
    for( i = 0; i < len; i++)
    {
        map[i].x = i % width;
        map[i].y = i / width;
        map[i].weight = initial;
        // rb_warn("init %d: x: %d, y: %d, weight: %f", i, map[i].x, map[i].y, map[i].weight);
    }
    
    return Data_Wrap_Struct(self, 0, free, map);
}

// The Astar#initialize method
static VALUE astar_init(int argc, VALUE* argv, VALUE self)
{
    double initial = 0.0;
    
    
    int width      = INT2NUM(argv[0]);
    int height     = INT2NUM(argv[1]);
    long i, len    = width * height;

    rb_iv_set(self, "@width", width);
    rb_iv_set(self, "@height", height);
    return self;
}

static VALUE astar_reset(VALUE self)
{
    int width   = NUM2INT(rb_iv_get(self, "@width"));
    int height  = NUM2INT(rb_iv_get(self, "@height"));
    long i, len = width * height;
    
    for( i = 0; i < len; i++ )
    {
        map[i].g = FLT_MAX;
        map[i].h = 0;
        map[i].prev_chunk = NULL;
    }
    
    return self;
}

static VALUE astar_clear(int argc, VALUE* argv, VALUE self)
{
    int width   = NUM2INT(rb_iv_get(self, "@width"));
    int height  = NUM2INT(rb_iv_get(self, "@height"));
    long i, len = width * height;
    double weight = DEFAULT_WEIGHT;
    
    if (argc == 1)
    {
        Need_Float(argv[0]);
        weight = NUM2DBL(argv[0]);
    }
    
    if (argc <= 1)
    {
        for( i = 0; i < len; i++ )
        {
            map[i].weight = weight;
        }
    }
    else
    {
        rb_raise(rb_eArgError, "expects 0..1 argument");
    }
}

static void explore(
    Chunk* map, int* closed, PriorityQueue* queue, Chunk* curr_chunk,
    int width, int height,
    int end_x, int end_y,
    int x, int y)
{
    int sx = curr_chunk->x + x;
    int sy = curr_chunk->y + y;
    
    if( sx >= 0 && sx < width &&
        sy >= 0 && sy < height )
    {
        int coord = AT(sx, sy);
        
        if ( !closed[coord] )
        {
            Chunk* nextval = map + coord;
            if( nextval->weight >= 0 )
            {
                double gdist, hdist;
                gdist = unitdist[ (nextval->y - curr_chunk->y + 1) * 3 +
                                  (nextval->x - curr_chunk->x + 1) ] + (nextval->weight);
                if( nextval->h == 0 )
                {
                    hdist = sqrt( (double)(
                                    (nextval->x - end_x) * (nextval->x - end_x) +
                                    (nextval->y - end_y) * (nextval->y - end_y) ) );
                    nextval->h = hdist;
                }
                if( curr_chunk->g + gdist < nextval->g )
                {
                    nextval->g = curr_chunk->g + gdist;
                    nextval->prev_chunk = (void *)curr_chunk;
                    pq_insert(queue, (void *)(nextval));

                    // printf("explore added x: %d, y: %d, w: %f, g: %f, h: %f\n",
                    //         sx, sy, nextval->weight, nextval->g, hdist);
                }
            }
        }
    }
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
    int dx      = end_x - start_x;
    int dy      = end_y - start_y;
    
    Chunk* map;
    Chunk* curr_chunk;
    
    Data_Get_Struct(self, Chunk, map);
    
    if (start_x < 0 || start_x >= width)
        rb_raise(rb_eArgError, "start_x not in range");
    if (start_y < 0 || start_y >= height)
        rb_raise(rb_eArgError, "start_y not in range");
    if (end_x < 0 || end_x >= width)
        rb_raise(rb_eArgError, "end_x not in range");
    if (end_y < 0 || end_y >= height)
        rb_raise(rb_eArgError, "end_y not in range");
    
    // Keep a closed list of visited nodes
    int* closed = ALLOC_N(int, width * height);
    memset(closed, 0, sizeof(int) * width * height);
    
    // Create the PQ and initialize it with the starting chunk
    PriorityQueue* queue = pq_new(QUEUE_MAX, chunk_less_than, dummy_free);
    closed[AT(start_x, start_y)] = 0;
    curr_chunk = map + AT(start_x, start_y);
    curr_chunk->h = sqrt((end_x-start_x)*(end_x-start_x)+(end_y-start_y)*(end_y-start_y));
    curr_chunk->g = 0;
    pq_insert(queue, (void *)(curr_chunk));
    
    // Actually do the search
    int coord;
    double distance = 0.0;
    while(curr_chunk->x != end_x || curr_chunk->y != end_y)
    {
        // show_chunk_queue(queue);
        // Remove chunk with lowest f-score
        curr_chunk = (Chunk*)pq_pop(queue);
        
        // No solution if there are no chunks left
        if( curr_chunk == NULL ) {
            pq_free(queue);
            return Qnil;
        }
        
        // Add chunk to closed set
        closed[AT(curr_chunk->x, curr_chunk->y)] = 1;
        
        // printf("curr_chunk | x: %d, y: %d, f: %f, g: %f, h: %f\n", curr_chunk->x, curr_chunk->y, (curr_chunk->g + curr_chunk->h), curr_chunk->g, curr_chunk->h);
        // Add 8 neighbors if they are not in the closed list
        explore(map, closed, queue, curr_chunk, width, height, end_x, end_y, -1, -1);
        explore(map, closed, queue, curr_chunk, width, height, end_x, end_y, -1,  0);
        explore(map, closed, queue, curr_chunk, width, height, end_x, end_y, -1, +1);
        explore(map, closed, queue, curr_chunk, width, height, end_x, end_y,  0, -1);
        explore(map, closed, queue, curr_chunk, width, height, end_x, end_y,  0, +1);
        explore(map, closed, queue, curr_chunk, width, height, end_x, end_y, +1, -1);
        explore(map, closed, queue, curr_chunk, width, height, end_x, end_y, +1,  0);
        explore(map, closed, queue, curr_chunk, width, height, end_x, end_y, +1, +1);

    }
    
    // Start traceback from the goal
    curr_chunk = map + AT(end_x, end_y);
    VALUE trace = rb_ary_new();
    
    if( curr_chunk->prev_chunk != NULL )
    {
        // Find our way from the goal back to the start
        rb_ary_unshift(trace, rb_ary_new3(2, INT2NUM(curr_chunk->x), INT2NUM(curr_chunk->y)));
        // rb_warn("traceback: x: %d, y: %d", curr_chunk->x, curr_chunk->y);
        while(curr_chunk->x != start_x || curr_chunk->y != start_y)
        {
            curr_chunk = (Chunk *)curr_chunk->prev_chunk;
            if( curr_chunk == NULL ) { rb_warn("null traceback"); break; }
            rb_ary_unshift(trace, rb_ary_new3(2, INT2NUM(curr_chunk->x), INT2NUM(curr_chunk->y)));
            // rb_warn("traceback: x: %d, y: %d", curr_chunk->x, curr_chunk->y);
        }
    }
    
    
    pq_free(queue);
    return trace;
}

static VALUE astar_get_map(VALUE self)
{
    return rb_iv_get(self, "@map");
}

static VALUE astar_add_rect(
    VALUE self,
    VALUE rb_min_x, VALUE rb_min_y,
    VALUE rb_max_x, VALUE rb_max_y,
    VALUE rb_weight)
{
    int x, y;
    int min_x  = NUM2INT(rb_min_x);
    int min_y  = NUM2INT(rb_min_y);
    int max_x  = NUM2INT(rb_max_x);
    int max_y  = NUM2INT(rb_max_y);
    int width  = NUM2INT(rb_iv_get(self, "@width"));
    int height = NUM2INT(rb_iv_get(self, "@height"));
    VALUE* map = RARRAY_PTR(rb_iv_get(self, "@map"));
    
    if( min_x > max_x ) rb_raise(rb_eException, "min_x is greater than max_x");
    if( min_y > max_y ) rb_raise(rb_eException, "min_y is greater than max_y");
    
    for( y = min_y; y <= max_y; y++ )
    {
        for( x = min_x; x <= max_x; x++ )
        {
            map[y * width + x] = rb_weight;
        }
    }
    // (double)NUM2INT(map[i]) / 100.0;
    
    return self;
}

static VALUE astar_add_poly(VALUE self, VALUE rb_ary_coords, VALUE rb_weight)
{
    long i, coords_len = RARRAY_LEN(rb_ary_coords);
    VALUE* coords = RARRAY_PTR(rb_ary_coords);
    VALUE* map = RARRAY_PTR(rb_iv_get(self, "@map"));
    int min_x = INT_MAX, min_y = INT_MAX, max_x = 0, max_y = 0;
    
    if( coords_len == 4 )
    {
        int is_rectangle = 1;
        VALUE* a = RARRAY_PTR( coords[coords_len-1] );
        for( i = 0; i < coords_len; i++ )
        {
            VALUE* b = RARRAY_PTR( coords[i] );
            double x1 = NUM2INT(a[0]), y1 = NUM2INT(a[1]);
            double x2 = NUM2INT(b[0]), y2 = NUM2INT(b[1]);
            min_x = min3(min_x, x1, x2);
            min_y = min3(min_y, y1, y2);
            max_x = max3(max_x, x1, x2);
            max_y = max3(max_y, y1, y2);
            if( x1 - x2 != 0 && y1 - y2 != 0 )
            {
                is_rectangle = 0;
                break;
            }
            a = b;
        }
        
        if( is_rectangle )
        {
            ID Intern_add_rect = rb_intern("add_rect");
            rb_funcall(self, Intern_add_rect, 5,
                INT2NUM(min_x), INT2NUM(min_y),
                INT2NUM(max_x), INT2NUM(max_y),
                rb_weight);
        }
        else
        {
            rb_raise(rb_eException, "Obstacles must be rectangular (for now).");
        }
    }
    else
    {
        // Polygons not supported for now
        rb_raise(rb_eException, "Obstacles must have four sides.");
    }
    return self;
}

// The initialization method for this module; Ruby calls this for us
void Init_astar() {
    Astar = rb_define_class("Astar", rb_cObject);
    rb_define_singleton_method(Astar, "new", astar_new, -1);
    rb_define_method(Astar, "initialize", astar_init, -1);
    rb_define_method(Astar, "search", astar_search, 4);
    rb_define_method(Astar, "map", astar_get_map, 0);
    rb_define_method(Astar, "add_rect", astar_add_rect, 5);
    rb_define_method(Astar, "add_poly", astar_add_poly, 2);
}
