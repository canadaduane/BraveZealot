// Include the Ruby headers and goodies
#include <ruby.h>
#include <math.h>
#include <float.h>
#include "priorityqueue.h"
#include "astar.h"

double unitdist[] = {1.4142135623731, 1.0000000000000, 1.4142135623731,
                     1.0000000000000, 0.0000000000000, 1.0000000000000,
                     1.4142135623731, 1.0000000000000, 1.4142135623731};



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
    
    int width      = NUM2INT(argv[0]);
    int height     = NUM2INT(argv[1]);
    long i, len    = width * height;
    
    if (width <= 0 || height <= 0)
        rb_raise(rb_eArgError, "Width and height must be greater than 0");
    
    // Create a discretized map of Chunks
    Chunk* map = ALLOC_N(Chunk, len);
    for( i = 0; i < len; i++)
    {
        map[i].x = i % width;
        map[i].y = i / width;
        map[i].weight = initial_weight;
    }
    
    VALUE obj = Data_Wrap_Struct(class, 0, free, map);
    rb_obj_call_init(obj, argc, argv);
    
    return obj;
}

// The Astar#initialize method
static VALUE astar_init(int argc, VALUE* argv, VALUE self)
{
    double initial_weight = (argc == 3 ? NUM2DBL(argv[2]) : 0.0);

    rb_iv_set(self, "@width",          argv[0]);
    rb_iv_set(self, "@height",         argv[1]);
    rb_iv_set(self, "@initial_weight", DBL2NUM(initial_weight));
    
    astar_reset(self);
    
    return self;
}

static VALUE astar_width(VALUE self)
{
    return rb_iv_get(self, "@width");
}

static VALUE astar_height(VALUE self)
{
    return rb_iv_get(self, "@height");
}

static VALUE astar_initial_weight(VALUE self)
{
    return rb_iv_get(self, "@initial_weight");
}

static VALUE astar_reset(VALUE self)
{
    int width   = NUM2INT(rb_iv_get(self, "@width"));
    int height  = NUM2INT(rb_iv_get(self, "@height"));
    long i, len = width * height;
    
    Chunk* map;
    Data_Get_Struct(self, Chunk, map);

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
    
    if (argc == 0)
    {
        weight = NUM2DBL(rb_iv_get(self, "@initial_weight"));
    }
    else if (argc == 1)
    {
        Check_Type(argv[0], T_FLOAT);
        weight = NUM2DBL(argv[0]);
    }
    else
    {
        rb_raise(rb_eArgError, "expects 0..1 argument");
    }

    Chunk* map;
    Data_Get_Struct(self, Chunk, map);
    
    for( i = 0; i < len; i++ )
    {
        map[i].weight = weight;
    }
    
    return self;
}

static void astar_explore(
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
    
    // New search requires blank 'g' and 'h' values
    astar_reset(self);
    
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
        astar_explore(map, closed, queue, curr_chunk, width, height, end_x, end_y, -1, -1);
        astar_explore(map, closed, queue, curr_chunk, width, height, end_x, end_y, -1,  0);
        astar_explore(map, closed, queue, curr_chunk, width, height, end_x, end_y, -1, +1);
        astar_explore(map, closed, queue, curr_chunk, width, height, end_x, end_y,  0, -1);
        astar_explore(map, closed, queue, curr_chunk, width, height, end_x, end_y,  0, +1);
        astar_explore(map, closed, queue, curr_chunk, width, height, end_x, end_y, +1, -1);
        astar_explore(map, closed, queue, curr_chunk, width, height, end_x, end_y, +1,  0);
        astar_explore(map, closed, queue, curr_chunk, width, height, end_x, end_y, +1, +1);

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

static VALUE astar_get(VALUE self, VALUE rb_x, VALUE rb_y)
{
    VALUE rb_width = rb_iv_get(self, "@width");
    
    Check_Type(rb_x, T_FIXNUM);
    Check_Type(rb_y, T_FIXNUM);
    Check_Type(rb_width, T_FIXNUM);

    int x         = NUM2INT(rb_x);
    int y         = NUM2INT(rb_y);
    int width     = NUM2INT(rb_width);
    
    Chunk* map;
    Data_Get_Struct(self, Chunk, map);
    
    return DBL2NUM(map[AT(x, y)].weight);
}

static VALUE astar_set(VALUE self, VALUE rb_x, VALUE rb_y, VALUE rb_weight)
{
    Check_Type(rb_weight, T_FLOAT);
    
    int x         = NUM2INT(rb_x);
    int y         = NUM2INT(rb_y);
    double weight = NUM2DBL(rb_weight);
    int width     = NUM2INT(rb_iv_get(self, "@width"));
    
    Chunk* map;
    Data_Get_Struct(self, Chunk, map);
    
    map[AT(x, y)].weight = weight;
    
    return self;
}

static Triangle astar_triangle_vertex_sort(
    VALUE rb_x1, VALUE rb_y1,
    VALUE rb_x2, VALUE rb_y2,
    VALUE rb_x3, VALUE rb_y3)
{
    Triangle t;
    
    t.x1        = NUM2INT(rb_x1);
    t.y1        = NUM2INT(rb_y1);
    t.x2        = NUM2INT(rb_x2);
    t.y2        = NUM2INT(rb_y2);
    t.x3        = NUM2INT(rb_x3);
    t.y3        = NUM2INT(rb_y3);
    
    // Swap variables
    int x, y;
    
    // Bubble sort by y values in ascending order (smallest to biggest)
    if (t.y2 < t.y1)
    {
        y    = t.y1; x    = t.x1;
        t.y1 = t.y2; t.x1 = t.x2;
        t.y2 = y;    t.x2 = x;
    }
    if (t.y3 < t.y2)
    {
        y    = t.y2; x    = t.x2;
        t.y2 = t.y3; t.x2 = t.x3;
        t.y3 = y;    t.x3 = x;
    }
    if (t.y2 < t.y1)
    {
        y    = t.y1; x    = t.x1;
        t.y1 = t.y2; t.x1 = t.x2;
        t.y2 = y;    t.x2 = x;
    }
    
    // Calculate lengths of edges
    int l1_2 = t.y2 - t.y1;
    int l1_3 = t.y3 - t.y1;
    
    if(l1_2 < l1_3)
    {
        y    = t.y2; x    = t.x2;
        t.y2 = t.y3; t.x2 = t.x3;
        t.y3 = y;    t.x3 = x;
    }
    
    // vertex 1 -> vertex 2 is the "long edge" of the triangle
    // vertex 1 -> vertex 3 is the first "short edge"
    // vertex 3 -> vertex 2 is the second "short edge"
    
    // printf("x1: %d, x2: %d, x3: %d\n", t.x1, t.x2, t.x3);
    // printf("y1: %d, y2: %d, y3: %d\n", t.y1, t.y2, t.y3);
    
    return t;
}

static VALUE astar_triangle(
    VALUE self,
    VALUE rb_x1, VALUE rb_y1,
    VALUE rb_x2, VALUE rb_y2,
    VALUE rb_x3, VALUE rb_y3,
    VALUE rb_weight)
{
    Check_Type(rb_weight, T_FLOAT);
    
    int x, y;
    Triangle t = astar_triangle_vertex_sort(rb_x1, rb_y1, rb_x2, rb_y2, rb_x3, rb_y3);
    
    int width     = NUM2INT(rb_iv_get(self, "@width"));
    int height    = NUM2INT(rb_iv_get(self, "@height"));
    double weight = NUM2DBL(rb_weight);
    
    Chunk* map;
    Data_Get_Struct(self, Chunk, map);
    
    int e_y_long   = t.y2 - t.y1;
    int e_y_short1 = t.y3 - t.y1;
    int e_y_short2 = t.y2 - t.y3;
    
    int e_x_long   = t.x2 - t.x1;
    int e_x_short1 = t.x3 - t.x1;
    int e_x_short2 = t.x2 - t.x3;
    
    if (abs(e_x_long) > abs(e_y_long))
    {
        e_x_long += (t.x2 == t.x1 ? 0 : (t.x2 > t.x1 ? 1 : -1));
        e_y_long++;
    }

    if (abs(e_x_short1) > abs(e_y_short1))
    {
        e_x_short1 += (t.x3 == t.x1 ? 0 : (t.x3 > t.x1 ? 1 : -1));
        e_y_short1++;
    }

    if (abs(e_x_short2) > abs(e_y_short2))
    {
        e_x_short2 += (t.x2 == t.x3 ? 0 : (t.x2 > t.x3 ? 1 : -1));
        e_y_short2++;
    }
    
    // if (e_short1 + e_short2 != e_long)
    // rb_raise(rb_eException, "Long edge should equal sum of both short edges");
    
    // printf("exl: %d, exs1: %d, exs2: %d\n", e_x_long, e_x_short1, e_x_short2);
    // printf("eyl: %d, eys1: %d, eys2: %d\n", e_y_long, e_y_short1, e_y_short2);
    
    float e_long_rate   = (float)(e_x_long)   / e_y_long;
    float e_short1_rate = (float)(e_x_short1) / e_y_short1;
    float e_short2_rate = (float)(e_x_short2) / e_y_short2;
    
    // printf("elr: %f, es1r: %f, es2r: %f\n", e_long_rate, e_short1_rate, e_short2_rate);
    
    // Calculate rate of change for left and right sides of triangle
    float left_rate  = e_long_rate;
    float right_rate = e_short1_rate;
    
    if (right_rate < left_rate)
    {
        float rate = left_rate;
        left_rate  = right_rate;
        right_rate = rate;
    }
    
    float left_x = t.x1 + 0.5, right_x = t.x1 + 0.5;
    
    if (e_short1_rate < 0) left_x  += (e_short1_rate + 1);
    if (e_short1_rate > 0) right_x += (e_short1_rate - 1);
    // printf("left_x: %f, right_x: %f\nleft_rate: %f, right_rate: %f\n", left_x, right_x, left_rate, right_rate);
    
    // Draw the upper part of the triangle
    for (y = t.y1; y < t.y3; y++)
    {
        // printf("up y: %d, lx: %f, rx: %f\n", y, left_x, right_x);
        int int_left_x = (int)left_x;
        int pos = AT(int_left_x, y);
        for (x = (int)left_x; x <= (int)right_x; x++)
        {
            map[pos++].weight = weight;
        }
        left_x  += left_rate;
        right_x += right_rate;
    }
    
    if (e_long_rate > e_short2_rate)
    {
        left_rate  = e_long_rate;
        right_rate = e_short2_rate;
        right_x    = t.x3 + 0.5;
    }
    else
    {
        left_rate  = e_short2_rate;
        right_rate = e_long_rate;
        left_x     = t.x3 + 0.5;
    }
    
    // Draw the lower part of the triangle
    for (y = t.y3; y <= t.y2; y++)
    {
        // printf("lw y: %d, lx: %f, rx: %f\n", y, left_x, right_x);
        int int_left_x = (int)left_x;
        int pos = AT(int_left_x, y);
        for (x = (int)left_x; x <= (int)right_x; x++)
        {
            map[pos++].weight = weight;
        }
        left_x  += left_rate;
        right_x += right_rate;
    }

    return self;
}

static VALUE astar_rectangle(
    VALUE self,
    VALUE rb_min_x, VALUE rb_min_y,
    VALUE rb_max_x, VALUE rb_max_y,
    VALUE rb_weight)
{
    Check_Type(rb_weight, T_FLOAT);
    
    int x, y;
    int min_x     = NUM2INT(rb_min_x);
    int min_y     = NUM2INT(rb_min_y);
    int max_x     = NUM2INT(rb_max_x);
    int max_y     = NUM2INT(rb_max_y);
    int width     = NUM2INT(rb_iv_get(self, "@width"));
    int height    = NUM2INT(rb_iv_get(self, "@height"));
    double weight = NUM2DBL(rb_weight);
    
    Chunk* map;
    Data_Get_Struct(self, Chunk, map);
    
    if( min_x > max_x ) rb_raise(rb_eException, "min_x is greater than max_x");
    if( min_y > max_y ) rb_raise(rb_eException, "min_y is greater than max_y");
    
    for( y = min_y; y <= max_y; y++ )
    {
        int pos = AT(min_x, y);
        for( x = min_x; x <= max_x; x++ )
        {
            map[pos++].weight = weight;
        }
    }
    
    return self;
}

static VALUE astar_polygon(VALUE self, VALUE rb_ary_coords, VALUE rb_weight)
{
    long i, coords_len = RARRAY_LEN(rb_ary_coords);
    VALUE* coords = RARRAY_PTR(rb_ary_coords);
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
    rb_define_method(Astar, "width", astar_width, 0);
    rb_define_method(Astar, "height", astar_height, 0);
    rb_define_method(Astar, "initial_weight", astar_initial_weight, 0);
    
    // "Drawing" primitives
    rb_define_method(Astar, "clear", astar_clear, -1);
    rb_define_method(Astar, "get", astar_get, 2);
    rb_define_method(Astar, "[]",  astar_get, 2);
    rb_define_method(Astar, "set", astar_set, 3);
    rb_define_method(Astar, "[]=", astar_set, 3);
    rb_define_method(Astar, "triangle",  astar_triangle, 7);
    rb_define_method(Astar, "rectangle", astar_rectangle, 5);
    rb_define_method(Astar, "polygon",   astar_polygon, 2);
}
