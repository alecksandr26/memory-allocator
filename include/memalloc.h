#ifndef __MEM_ALLOC_H__
#define __MEM_ALLOC_H__

#include <stddef.h>

/* memalloc: Alloc an specific amount of memory, return null if there is no more memory */
extern void *memalloc(size_t nbytes);

/* memfree: Free an allocated block of memory */
extern void memfree(void *addr);

#endif
