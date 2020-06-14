#ifndef CACHE_H
#define CACHE_H

#include <stdbool.h>

struct cache_line_t
{
    bool mru; // MRU bit used by 1-bit-LRU.

    uint64_t timestamp; // relative access time used by True-LRU

    bool valid; // Bit which states if the block has been accessed.

    bool dirty; // Dirty bit variable. Keeps track if data modified.

    uint32_t tag; // Tag address for cache data

    char *data; // data bytes.
    
};

struct cache_set_t
{
    struct cache_line_t *cache_lines;
};

struct cache_stat_t
{ 
    int cache_accesses;   // Tracks number of cache accesses.
    int cache_reads;      // Tracks number of cache reads.
    int cache_writes;     // Tracks number of cache writes.
    int cache_invalidates; // Tracks number of cache invalidates.
    int cache_hits;       // Tracks number of cache hits.
    int cache_misses;     // Tracks number of cache misses.
    float hit_ratio;      // Records hit ratio.
    float miss_ratio;     // Records miss ratio.
    int cache_evictions;  // Tracks number of evictions.
    int cache_writebacks; // Tracks number of writebacks.       

    int tag_request;   // Tracks current tag request.
    int index_request; // Tracks current index request.
    int byte_request;  // Tracks current byte request.
};

struct cache_t
{
    int num_sets;     // Records number of sets.
    int num_ways;    // Records number of ways.
    int num_bytes;        // Records line size.    
    int replacement_policy;

    int tag_bits;         // Records number of tag bits.
    int index_bits;       // Records number of index bits.
    int byte_bits;        // Records nymber of byte select bits.

    struct cache_set_t *sets;  // Pointer to cache sets    
    struct cache_stat_t stat; // statistics
};

enum AccessType { AT_READ, AT_WRITE, AT_INV };

struct cache_request_t 
{
    int type;
    uint32_t address;
};

void cache_initialize(struct cache_t *cache, int num_sets, int num_ways, int num_bytes, int replacement_policy);

void cache_free(struct cache_t *cache);

void handle_cache_request(struct cache_t * cache, struct cache_request_t *req);

#endif