/* These are simple unit tests of my module of alloc in asm
   You need to compile it with -no-pie flag
 */

#include <stdio.h>
#include <string.h>
#include <assert.h>

#include "../include/alloc.h"



/* There are the testcases */
void test_heap_extract()
{
    void *addr1, *addr2, *addr3, *addr4, *addr5;
    
    addr2 = alloc(10);
    afree(addr2);

    addr1 = alloc(15);
    afree(addr1);

    addr4 = alloc(20);
    afree(addr4);


    addr5 = alloc(25);
    afree(addr5);

    addr3 = alloc(5);
    assert(addr3 == addr5 && "The addr5 should be the same addres of addr3");
}


void test_datatypes()
{
    long *ptr;
    int *ptr2;
    short *ptr3;

    ptr = alloc(sizeof(long));
    *ptr = 10;
    afree(ptr);


    ptr2 = alloc(sizeof(int));
    ptr3 = alloc(sizeof(short));
    
    assert(((void *) ptr) == ((void *) ptr2) && "ptr shouble the same address of ptr2");
    assert((((void *) ptr2) + 6) == ((void *) ptr3) && "ptr2 is located 6 bytes lower than ptr3");
}


typedef struct node_t {
    int val;
    struct node_t *next;
} Node;


typedef struct {
    Node *head;
    unsigned size;
} Stack;



void stack_push(Stack *stack, int val)
{
    Node *new_node;

    new_node = (Node *) alloc(sizeof(Node));

    if (stack->head != NULL)
        new_node->next = stack->head;
    
    new_node->val = val;
    stack->head = new_node;
    stack->size++;
}


int stack_pop(Stack *stack)
{
    Node *node;
    int val;

    val = stack->head->val;
    node = stack->head;
    stack->head = stack->head->next;

    afree(node);
    return val;
}



/* Lets create an stack data structure */
void test_stack()
{
    Stack stack;
    int val;
    
    memset(&stack, 0, sizeof(Stack));

    stack_push(&stack, 0);
    stack_push(&stack, 3);
    stack_push(&stack, 5);

    val = stack_pop(&stack);
    assert(val == 5 && "val should be 5");
    
    stack_push(&stack, 2);
    
    val = stack_pop(&stack);
    assert(val == 2 && "val should be 2");
}


int main()
{
   
    test_stack();
    
    return 0;
}





