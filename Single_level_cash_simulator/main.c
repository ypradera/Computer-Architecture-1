#define _CRT_SECURE_NO_WARNINGS

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdint.h>

#include "cache.h"

void read_cache_request(const char *str, struct cache_request_t *req)
{
    int type, address;
    sscanf(str, "%d", &type);
    req->type = type;
    sscanf(str + 2, "%x", &address);
    req->address = (uint32_t) address;    
}

void print_result(struct cache_t *cache, struct cache_stat_t *stat)
{
    printf("CACHE PARAMETERS\n");
    printf("Number of sets: %d\n", cache->num_sets);
    printf("Associativity: %d\n", cache->num_ways);
    printf("Cache line size: %d\n", cache->num_bytes);   
    printf("Replacement policy: %s\n", cache->replacement_policy == 0 ? "True LRU" : "1-bit LRU"); 

    printf("CACHE STATISTICS\n");
    printf("Total number of cache accesses: %d\n", stat->cache_accesses);
    printf("Number of cache reads: %d\n", stat->cache_reads);
    printf("Number of cache writes: %d\n", stat->cache_writes);   
    printf("Number of invalidates: %d\n", stat->cache_invalidates); 

    printf("Number of cache hits: %d\n", stat->cache_hits);
    printf("Number of cache misses: %d\n", stat->cache_misses);
    printf("Cache hit ratio: %.2f%%\n", (float) stat->cache_hits / stat->cache_accesses * 100);   
    printf("Cache miss ratio: %.2f%%\n", (float) stat->cache_misses / stat->cache_accesses * 100); 

    printf("Number of evictions: %d\n", stat->cache_evictions);
    printf("Number of writebacks: %d\n", stat->cache_writebacks);
}


// argv[1] = file input.
// argv[2] = Number of sets.
// argv[3] = Associativity.
// argv[4] = cache line size.
int main(int argc, char * argv[])
{     
    struct cache_t cache;
    memset(&cache, 0, sizeof(cache));

    struct cache_request_t cache_request;       

    FILE* in;

    if(argc != 6)               // if not enough input args.
    {
        printf("Usage: input-file sets-number ways-number line-size policy\n");        
        return 1;
    }

    cache_initialize(&cache, atoi(argv[2]), atoi(argv[3]), atoi(argv[4]), atoi(argv[5]));     

    in = fopen(argv[1], "r"); // Opening file to be read.

    char line[20];
    while(fgets(line, 20, in)) // Retrieve each line until done.
    {        
        read_cache_request(line, &cache_request);
        handle_cache_request(&cache, &cache_request);
    }
    fclose(in);

    print_result(&cache, &cache.stat); // Call to display all results.    

    cache_free(&cache);

    return 0;
}