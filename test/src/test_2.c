#include <stdio.h>
#include <assert.h>

#include "../../include/memalloc.h"

#define AMOUNT_OF_BYTES 100

int main()
{
    size_t i;
    void *ptr, *ptr2, *ptr3;
    
    puts("Test 2");
    ptr = memalloc(AMOUNT_OF_BYTES); /*  Alloc a lot of bytes */

    for (i = 0; i < AMOUNT_OF_BYTES; i++)
        *((char *) ptr + i) = (char) i;

    ptr2 = memalloc(AMOUNT_OF_BYTES * 2); /* Alloc more bytes */

    for (i = 0; i < AMOUNT_OF_BYTES * 2; i++)
        *((char *) ptr2 + i) = (char) i;

    ptr3 = memalloc(AMOUNT_OF_BYTES * sizeof(int)); /* Alloc more and more bytes */

    for (i = 0; i < AMOUNT_OF_BYTES; i++)
        *(((int *) ptr3) + i) = i + 1;

    memfree(ptr);
    
    for (i = 0; i < AMOUNT_OF_BYTES; i++)
        assert(*(((int *) ptr3) + i) == (int) i + 1);

    memfree(ptr3);
 
    for (i = 0; i < AMOUNT_OF_BYTES * 2; i++)
        assert(*((char *) ptr2 + i) == (char) i);
    
    memfree(ptr2);

    
    puts("Passed");
    return 0;
}

