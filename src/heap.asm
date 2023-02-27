    ;; This is the module of the heap
    section .data
    
    SYS_exit equ 60
    EXIT_FAILURE equ 1
    
    SYS_brk equ 12

    SYS_write equ 1
    STDOUT equ 1

    NULL equ 0
    LF equ 0xa

    ;; Message errors for heap insert function 
    heap_insert_error_msg db "Error: Not enough space for free address", LF, NULL
    heap_insert_error_msg_len equ $ - heap_insert_error_msg

    ;; Capacity of the free address
    HEAP_FREE_CAPACITY equ 8192         ; 8 kilo bytes
    global HEAP_FREE_CAPACITY
    HEAP_FREE_CAPACITY_SIZE equ 1024     ; the size of each 1024
    global HEAP_FREE_CAPACITY_SIZE
    ;; the amount of free chucks that we have

    heap_size_free dq 0
    global heap_size_free

    section .bss
    

    free_heap resq 1                 ; the address where we store the memory possible allocatable memory
    global free_heap
    
    heap_root_addr resq 1            ; 8 bytes for the heap root address
    
    section .text

    global heap_get_chunk_size  ; This method should be from the alloc module
    global heap_compare_sizes   ; Also this one
    
    global heap_get_address
    global heap_extract
    global heap_insert

    ;; void *heap_get_address(unsigned long index)
    ;; index -> rdi the index 
    ;; heap_get_address: Calculate the address of some index to be able to fetch data from it
heap_get_address:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    
    mov qword [rsp], 8
    
    mov rax, rdi
    mul qword [rsp]
    
    add rax, qword [free_heap]

    add rsp, 8
    pop rbp
    ret
    

    ;; short heap_get_chunk_size(void *addr)
    ;; addr -> rdi          The address to the chuck of memory
    ;; heap_get_chunk_size: Return the size of the chunk of memory
heap_get_chunk_size:
    ;; get the address
    mov rdi, qword [rdi]
    
    ;; Get the size two bytes
    mov rax, 0
    mov ax, word [rdi-2]         ; get the size of the chunk
    
    ret
    
    ;; void *heap_get_parent(void *child)
    ;; child -> rdi     The index of the buffer
    ;; heap_get_parent: Return the parent index of the children index
heap_get_parent:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    

    mov qword [rsp], 2          ; set the number 2

    ;; p = (index - 1) / 2
    mov rax, rdi                ; move the child address to rax
    mov rdx, 0x0
    sub rax, 1                  ; subtract by 1
    div qword [rsp]             ; get the parent index


    add rsp, 8
    pop rbp
    ret

    ;; void *heap_get_child(void *parent, unsigned char child_type)
    ;; parent -> rdi        the parent index 
    ;; child_type -> rsi    1 if the child is the left or 2 if the child is the right
    ;; heap_get_child: Return the index of the child depending if it is the right child or the left child
heap_get_child:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    
    mov qword [rsp], 2          ; set the number 2
    
    mov rax, rdi                ; Moving parent address to rax
    mul qword [rsp]             ; multiply with 2

    add rax, rsi                ; sum rax + (2 or 1) depending 

    add rsp , 8
    pop rbp
    ret

    ;; long heap_compare_sizes(long parent_index, long child_index)
    ;; parent_index -> rdi
    ;; child_index -> rsi
    ;; heap_compare_sizes: Return -1 if parent_size < child_size or 0 if parent_size == child_size
    ;; 1 if parent_size > child_size.
heap_compare_sizes:
    
    ;; Get the parent chunk size
    ;; rdi -> index 
    call heap_get_address     ; Get the address of the parent 
    mov rdi, rax                ; Move the address to rdi
    ;; rdi -> address of the heap
    call heap_get_chunk_size
    mov rbx, rax                ; Now move the size to rbx

    
    mov rdi, rsi                ; move the index of the child node
    ;; Get the child size
    call heap_get_address
    mov rdi, rax
    call heap_get_chunk_size  ; Now get the chunk size

    ;; Now compare the sizes
    cmp rbx, rax                ; if (child_size > parent_size)
    ja __heap_compare_sizes_if
    cmp rax, rbx                ; else if (child_size == parent_size)
    je __heap_compare_sizes_else_if
    mov rax, -1                 ; else in the case where (child_size < parent_size)
    ret
    
__heap_compare_sizes_if:
    mov rax, 1
    ret                         ; And return
    
__heap_compare_sizes_else_if:
    mov rax, 0
    ret
    
    ;; void *heap_extract()
    ;; heap_extract: Return the address of the greater chunk of memory 
heap_extract:
    ;; Get the first element
    mov rdi, 0
    call heap_get_address
    mov r9, qword [rax]         ; Save the first address
    dec qword [heap_size_free]
    cmp qword [heap_size_free], 0
    je __heap_extract_last      ; Finishing 

    ;; Get the last chuck
    mov rdi, qword [heap_size_free]
    call heap_get_address
    mov rbx, qword [rax]        ; Save the last address

    ;; Get the first chunk again
    mov rdi, 0
    call heap_get_address
    mov qword [rax], rbx        ; swap the first position with the last address

    mov r10, 0                  ; Index pos
    
__heap_extract_loop:
    ;; calculate the children indexes
    mov rdi, r10
    mov rsi, 1
    call heap_get_child
    mov r11, rax                ; save the index of the left child

    mov rsi, 2
    call heap_get_child
    mov r12, rax                ; save the index of the right chil


    ;; check the left position
    cmp r11, qword [heap_size_free]
    jae __heap_extract_loop_first_if

    mov rdi, r11
    mov rsi, r10
    call heap_compare_sizes
    cmp rax, 0
    jle __heap_extract_loop_first_if
    
    mov r13, r11                ; catch the left child index
    jmp __heap_extract_loop_continue

__heap_extract_loop_first_if:
    mov r13, r10                ; cacth the actual index
    
__heap_extract_loop_continue:
    ;; check the right position 
    cmp r12, qword [heap_size_free]
    jae __heap_extract_loop_second_continue

    mov rdi, r12
    mov rsi, r13
    call heap_compare_sizes
    cmp rax, 0
    jle __heap_extract_loop_second_continue

    mov r13, r12

__heap_extract_loop_second_continue:
    ;; Compare if it is the same index 
    cmp r13, r10
    je __heap_extract_last      ; if it is break the loop
    
    ;; otherwise swap the values and assing a new value

    ;; firstly get the addresses
    mov rdi, r13
    call heap_get_address
    mov rbx, rax
    mov rdi, r10
    call heap_get_address

    ;; swap
    mov rdi, qword [rax]
    mov rsi, qword [rbx]
    mov qword [rax], rsi
    mov qword [rbx], rdi
    
    mov r10, r13
    jmp __heap_extract_loop

__heap_extract_last:
    mov rax, r9                 ; Put the extracted address and return it
    ret
    
    ;; void heap_insert(void *addr)
    ;; addr -> rdi   The new address to insert 
    ;; heap_insert: To insert a new chunk of memory
heap_insert:                        
    mov rbx, rdi                ; Move the address -> rbx
    mov rdi, qword [heap_size_free] ; mov the size of the heap
    
    cmp rdi, HEAP_FREE_CAPACITY_SIZE ; check if there is enough space
    je __heap_insert_error      ; Out of capacity

    ;;  Get the address of the new index
    ;; rdi -> child index
    call heap_get_address
    mov qword [rax], rbx        ; put the new address or element to the heap
    
__heap_insert_loop:
    ;; Get the parent index
    ;; rdi -> child index
    call heap_get_parent
    mov r9, rax                 ; Save the parent posiion
    mov r10, rdi                ; Save the children position
    
    mov rsi, r10                ; Move the children index
    mov rdi, rax
    
    cmp rsi, 0                   ; if (child_index == 0)
    je __heap_insert_last
    
    ;; Compare the sizes | rdi -> parent index, rsi -> child index
    call heap_compare_sizes
    cmp rax, 0
    jge __heap_insert_last

    mov rdi, r9                 ; Get the parent index
    ;; Get an address | rdi -> index parent 
    call heap_get_address     ; Get the parent address
    mov rbx, rax                ; Save parent address into the rbx 
    
    mov rdi, r10                ; Get the child address
    ;; Get an address | rdi -> index child
    call heap_get_address

    ;; Swap the address 
    mov rdx, qword [rax] ; Copy the child address
    mov rdi, qword [rbx] ; Put paste the parent addres into the child space
    mov qword [rax], rdi
    mov qword [rbx], rdx ; Put the child address into the parent space

    ;; Now parent index is the child index 
    mov rdi, r9
    cmp rdi, 0
    je __heap_insert_last
    
    ;;  repeat the loop until we sort the heap
    jmp __heap_insert_loop
    
    
__heap_insert_error:            ; If we get an error close the program

    ;; Print out of capcity
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, heap_insert_error_msg
    mov rdx, heap_insert_error_msg_len
    syscall

    ;; Exit from the promgram with error
    mov rax, SYS_exit
    mov rdi, EXIT_FAILURE
    syscall
    
__heap_insert_last: 
    inc qword [heap_size_free]  ; Increment the size of the heap
    ret
