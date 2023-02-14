#include <stdio.h>
#include <assert.h>
#include "../../include/memalloc.h"

#define VALUE_TO_TEST 10

int main()
{
    void *ptr;
    int *intptr;
    puts("Test 1");
    
    ptr = memalloc(4);          /* Alloc a piece of memory of 4 bytes */

    assert(ptr != NULL);
    
    *((int *) ptr) = VALUE_TO_TEST;
    intptr = (int *) ptr;
    assert(*intptr == VALUE_TO_TEST);
    
    memfree(ptr);
    
    puts("passed");

    return 0;
}
