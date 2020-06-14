#define _CRT_SECURE_NO_WARNINGS

#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cache.h"

static uint64_t timestamp = 0;

// INitialize cache structure
void cache_initialize(struct cache_t *cache, int num_sets, int num_ways,
                      int num_bytes, int replacement_policy)
{
    cache->num_sets = num_sets;   // number of sets per way.
    cache->num_ways = num_ways;   // associativity.
    cache->num_bytes = num_bytes; // line size.
    cache->replacement_policy = replacement_policy;

    cache->index_bits = (int) log2(cache->num_sets); // number of index bits.
    cache->byte_bits = (int) log2(cache->num_bytes); // number of byte bits.
    cache->tag_bits =
        32 - cache->byte_bits - cache->index_bits; // number of address bits.

    cache->sets = calloc(1, cache->num_sets * sizeof(*cache->sets));
    for (int i = 0; i < cache->num_sets; ++i)
    {
        cache->sets[i].cache_lines =
            calloc(1, cache->num_ways * sizeof(*cache->sets[i].cache_lines));
        for (int j = 0; j < cache->num_ways; ++j)
        {
            cache->sets[i].cache_lines[j].data = calloc(1, cache->num_bytes);
        }
    }
}

// Release resource allocated by cache structure
void cache_free(struct cache_t *cache)
{
    for (int i = 0; i < cache->num_sets; ++i)
    {
        for (int j = 0; j < cache->num_ways; ++j)
        {
            free(cache->sets[i].cache_lines[j].data);
        }
        free(cache->sets[i].cache_lines);
    }
    free(cache->sets);
}

// Find the cache line in the given cache set that matches the given tag, 
// or return -1 if there is no such tag.
int find_tag(struct cache_t *cache, struct cache_set_t *set, int tag)
{
    int line;
    for (line = 0; line < cache->num_ways; ++line)
    {
        if (set->cache_lines[line].valid && set->cache_lines[line].tag == tag)
        {            
            return line;
        }
    }
    return -1;
}

// Find first invalid cache line in the given cache set, 
// or return -1 if there is no invalid lines (cache set full).
int find_empty_line(struct cache_t *cache, struct cache_set_t *set)
{
    int line;
    for (line = 0; line < cache->num_ways; ++line)
    {
        if (!set->cache_lines[line].valid)
        {            
            return line;
        }
    }
    return -1;
}

// Find the cache line in the given cache set that is LRU. 
int find_lru(struct cache_t *cache, struct cache_set_t *set)
{
    int lru = 0;
    if (cache->replacement_policy == 0) // True LRU
    {
        for (int i = 0; i < cache->num_ways; ++i)
        {
            if (set->cache_lines[i].timestamp > set->cache_lines[lru].timestamp)
            {
                lru = i;
            }
        }
    }
    else // Pseudo-LRU
    {
        for (int i = 0; i < cache->num_ways; ++i)
        {
            if (set->cache_lines[i].mru == 0)
            {
                lru = i;
                break;
            }
        }
    }

    return lru;
}

// Sets the timestamp, depending on the selected policy.
void make_timestamp(struct cache_t *cache, struct cache_set_t *set, int line)
{
    if (cache->replacement_policy == 0) // True LRU
    {
        set->cache_lines[line].timestamp = timestamp++;
    }
    else // Pseudo-LRU
    {
        // reset all lines
        for (int i = 0; i < cache->num_ways; ++i)
        {
            set->cache_lines[i].mru = 0;
        }
        // set this line MRU
        set->cache_lines[line].mru = 1;
    }
}

// Place the data block in the given cache line in the given cache set.
void place_line(struct cache_t *cache, struct cache_set_t *set, int line, int tag, struct cache_request_t *req)
{
    set->cache_lines[line].valid = true;
    set->cache_lines[line].tag = tag;

    if (req->type == AT_WRITE)
    {
        set->cache_lines[line].dirty = true;
    }
    else
    {
        set->cache_lines[line].dirty = false;
    }
    

    make_timestamp(cache, set, line);
}

// Handle each request
void handle_cache_request(struct cache_t *cache, struct cache_request_t *req)
{
    uint32_t address = req->address;

    // extract each address part: tag, index and byte.
    uint32_t tag = (address >> (32 - cache->tag_bits));
    uint32_t index = (address << (32 - cache->index_bits - cache->byte_bits)) >>
                (32 - cache->index_bits);
    uint32_t byte = (address << (32 - cache->byte_bits)) >> (32 - cache->byte_bits);

    if (req->type == AT_INV)
    {
        cache->stat.cache_invalidates++;
    }
    else
    {
        cache->stat.cache_accesses++;
        if (req->type == AT_READ)
        {
            cache->stat.cache_reads++;
        }
        else
        {
            cache->stat.cache_writes++;
        }
    }

    // check each line in corresponding set to find corresponding tag
    int line = find_tag(cache, &cache->sets[index], tag);
    if (line != -1)
    {
        // printf("match\n");

        if (req->type == AT_WRITE)
        {
            cache->sets[index].cache_lines[line].dirty = true;
        }
        else if (req->type == AT_INV)
        {
            // invalidate block if found
            cache->sets[index].cache_lines[line].valid = false;
            return;
        }

        make_timestamp(cache, &cache->sets[index], line);

        cache->stat.cache_hits++;
        return;
    }
    

    // printf("miss\n");
    cache->stat.cache_misses++;

    // check each line in corresponding set to find empty cache line
    line = find_empty_line(cache, &cache->sets[index]);
    if (line != -1)
    {
        // printf("find empty\n");
        place_line(cache,  &cache->sets[index], line, tag, req);
        return;
    }

    // printf("eviction required\n");

    cache->stat.cache_evictions++;

    // find evicted line
    int lru = find_lru(cache, &cache->sets[index]);

    // writeback
    if (cache->sets[index].cache_lines[lru].dirty)
    {
        cache->stat.cache_writebacks++;
    }

    // printf("evict\n");

    place_line(cache,  &cache->sets[index], lru, tag, req);
}