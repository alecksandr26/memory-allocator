    ;; This is a code project where I create my own malloc in nasm

    section .data
    
    ;; Constants
    
    SYS_exit equ 60
    EXIT_FAILURE equ 1
    
    SYS_brk equ 12

    SYS_write equ 1
    STDOUT equ 1

    NULL equ 0
    LF equ 0xa


    ;; Constants of the heap
    
    ;; Capacity of the free address
    HEAP_FREE_CAPACITY equ 8192         ; 8 kilo bytes
    HEAP_FREE_CAPACITY_SIZE equ 1024     ; the size of each 1024

    ;; Variables
    size dd 0

    curr_brk dq NULL             ; address of the current heap

    ;; Message errors for free
    free_error_msg db "Error: Invalid address to free", LF, NULL
    free_error_msg_len equ $ - free_error_msg

    ;; Message errors for heap insert function 
    heap_insert_error_msg db "Error: Not enough space for free address", LF, NULL
    heap_insert_error_msg_len equ $ - heap_insert_error_msg

    ;; heap variables
    
    ;; the amount of free chucks that we have
    heap_size_free dq 0

    ;; Variables sections
    section .bss
    
    init_brk resq 1             ; the initial address of the heap
    free_heap resq 1            ; the address where we store the memory possible allocatable memory
    new_brk resq 1              ; the new address of the heap

    ;; heap variables
    heap_root_addr resq 1            ; 8 bytes for the heap root address

    section .text
    
    ;; These are the public methods 
    global alloc
    global free


    ;; Some extra functions needed

    ;; void *__heap_get_child(void *parent, unsigned char child_type)
    ;; parent -> rdi        the parent index 
    ;; child_type -> rsi    1 if the child is the left or 2 if the child is the right
    ;; __heap_get_child: Return the index of the child depending if it is the right child or the left child
__heap_get_child:
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

    ;; void *__heap_get_parent(void *child)
    ;; child -> rdi     The index of the buffer
    ;; __heap_get_parent: Return the parent index of the children index
__heap_get_parent:
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

    ;; short __heap_get_chunk_size(void *addr)
    ;; addr -> rdi          The address to the chuck of memory
    ;; __heap_get_chunk_size: Return the size of the chunk of memory
__heap_get_chuck_size:
    ;; get the address
    mov rdi, qword [rdi]
    
    ;; Get the size two bytes
    mov rax, 0
    mov ax, word [rdi-2]         ; get the size of the chunk
    
    ret
    

    ;; void *__heap_get_address(unsigned long index)
    ;; index -> rdi the index 
    ;; __heap_get_address: Calculate the address of some index to be able to fetch data from it
__heap_get_address:
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


    ;; long __heap_compare_sizes(long parent_index, long child_index)
    ;; parent_index -> rdi
    ;; child_index -> rsi
    ;; __heap_compare_sizes: Return -1 if parent_size < child_size or 0 if parent_size == child_size
    ;; 1 if parent_size > child_size.
__heap_compare_sizes:
    
    ;; Get the parent chunk size
    ;; rdi -> index 
    call __heap_get_address     ; Get the address of the parent 
    mov rdi, rax                ; Move the address to rdi
    ;; rdi -> address of the heap
    call __heap_get_chuck_size
    mov rbx, rax                ; Now move the size to rbx

    
    mov rdi, rsi                ; move the index of the child node
    ;; Get the child size
    call __heap_get_address
    mov rdi, rax
    call __heap_get_chuck_size  ; Now get the chunk size

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
        

    ;; void *__heap_extract()
    ;; __heap_extract: Return the address of the greater chunk of memory 
__heap_extract:
    ;; Get the first element
    mov rdi, 0
    call __heap_get_address
    mov r9, qword [rax]         ; Save the first address
    dec qword [heap_size_free]
    cmp qword [heap_size_free], 0
    je __heap_extract_last      ; Finishing 

    ;; Get the last chuck
    mov rdi, qword [heap_size_free]
    call __heap_get_address
    mov rbx, qword [rax]        ; Save the last address

    ;; Get the first chunk again
    mov rdi, 0
    call __heap_get_address
    mov qword [rax], rbx        ; swap the first position with the last address

    mov r10, 0                  ; Index pos
    
__heap_extract_loop:
    ;; calculate the children indexes
    mov rdi, r10
    mov rsi, 1
    call __heap_get_child
    mov r11, rax                ; save the index of the left child

    mov rsi, 2
    call __heap_get_child
    mov r12, rax                ; save the index of the right chil


    ;; check the left position
    cmp r11, qword [heap_size_free]
    jae __heap_extract_loop_first_if

    mov rdi, r11
    mov rsi, r10
    call __heap_compare_sizes
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
    call __heap_compare_sizes
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
    call __heap_get_address
    mov rbx, rax
    mov rdi, r10
    call __heap_get_address

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


    ;; void __heap_insert(void *addr)
    ;; addr -> rdi   The new address to insert 
    ;; __heap_insert: To insert a new chunk of memory
__heap_insert:
    mov rbx, rdi                ; Move the address -> rbx
    mov rdi, qword [heap_size_free] ; mov the size of the heap
    
    cmp rdi, HEAP_FREE_CAPACITY_SIZE ; check if there is enough space
    je __heap_insert_error      ; Out of capacity

    ;;  Get the address of the new index
    ;; rdi -> child index
    call __heap_get_address
    mov qword [rax], rbx        ; put the new address or element to the heap
    
__heap_insert_loop:
    ;; Get the parent index
    ;; rdi -> child index
    call __heap_get_parent
    mov r9, rax                 ; Save the parent posiion
    mov r10, rdi                ; Save the children position
    
    mov rsi, r10                ; Move the children index
    mov rdi, rax
    
    cmp rsi, 0                   ; if (child_index == 0)
    je __heap_insert_last
    
    ;; Compare the sizes | rdi -> parent index, rsi -> child index
    call __heap_compare_sizes
    cmp rax, 0
    jge __heap_insert_last

    mov rdi, r9                 ; Get the parent index
    ;; Get an address | rdi -> index parent 
    call __heap_get_address     ; Get the parent address
    mov rbx, rax                ; Save parent address into the rbx 
    
    mov rdi, r10                ; Get the child address
    ;; Get an address | rdi -> index child
    call __heap_get_address

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


    
    ;; bool __alloc_check_size(long space)
    ;; space -> rdi
    ;; __alloc_check_size: Takes the first chuck of memory and check if it has the enough space
__alloc_check_size:
    mov rbx, rdi                ; move the size
    mov rdi, 0x0
    ;; rdi -> index
    call __heap_get_address     ; Get the address of the first node
    mov rdi, rax
    ;; rdi -> address of the index
    call __heap_get_chuck_size  ; Get the size
    
    cmp rbx, rax                ; if (rbx <= rax)
    jbe __alloc_check_size_enough ; If there is enough space

    mov rax, 0
    ret

__alloc_check_size_enough:
    mov rax, 1
    ret


    ;; void* __alloc_resize_chuck(void *addr, long new_size)
    ;; rdi -> addr
    ;; rsi -> new_size
    ;; __alloc_resize_chuck: Resize all the chuck and if there left extra space
    ;; insert that extra space into the heap and return the resize chuck
__alloc_resize_chuck:
    ;; Get the size of the new chuck of memory
    mov r12, rdi
    mov rax, 0
    mov ax, word [rdi - 2]
    sub rax, rsi

    ;; Check if its worth rize if not
    cmp rax, 3
    jb __alloc_resize_chuck_last

    ;; Set the new space to the chuck
    mov word [rdi-2], si

    ;; Create the new chuck
    add rdi, rsi                ; move the pointer
    sub rax, 2
    mov word [rdi], ax          ; add the new size
    add rdi, 2                  ; Get the new address of chuck

    call __heap_insert

__alloc_resize_chuck_last:
    mov rax, r12
    ret

  
    
    ;; void *alloc(unsigned amount_bytes)
    ;; amount_bytes -> rdi      ; the amount of bytes that we want
    ;; alloc: return the amount the address of the page of the memory that we want
alloc:
    push rbp
    mov rbp, rsp
    sub rsp, 8                  ; Create the frame to store the amount_bytes

    ;; save the size
    mov qword [rbp-8], rdi

    ;; can't receive zero amount_bytes
    cmp edi, NULL
    je __alloc_error

    ;; Check if there is free chucks
    mov rax, qword [heap_size_free]
    cmp rax, 1
    jb __alloc_check_size_no_free_chucks

    ;; if there check the size
    ;; rdi -> the space needed
    call __alloc_check_size
    cmp rax, 0
    je __alloc_check_size_no_free_chucks ; If the space is not enough jump and allocate one more

    ;; If there is chuck extract it
    call __heap_extract
    
    mov rdi, rax
    mov rsi, qword [rbp-8]
    
    ;;  Resize the selected chuck of memory and return it
    call __alloc_resize_chuck
    
    jmp __alloc_last

__alloc_check_size_no_free_chucks:  
    
    ;; increment the real capcity by two bytes

    
    add qword [rbp-8], 2

    mov rdi, qword [rbp-8]

    ;; get the current address of the brk
    mov rax, SYS_brk
    mov rdi, new_brk
    syscall
    
    cmp qword [curr_brk], NULL
    jne __alloc_else
    ;; this means that it is the first time running an alloc

    ;; get the address of the heap 
    mov qword [free_heap], rax

    ;; try to create our frame of memory for free address 
    mov rdi, rax
    mov rax, SYS_brk    
    add rdi, HEAP_FREE_CAPACITY
    syscall

    cmp rax, qword [free_heap]                ; if this is true there is an error
    je __alloc_error
    
    
    ;; get the initial brk address
    mov qword [init_brk], rax
__alloc_else:
    
    
    ;; getting the current address
    mov qword [curr_brk], rax
    mov qword [new_brk], rax

    ;; get again the size
    mov rdi, qword [rbp-8]

    ;; create the new chuck of memory and incremenet the size of chunks 
    add qword [new_brk], rdi
    inc dword [size]

    mov rax, SYS_brk
    mov rdi, qword [new_brk]
    syscall

    ;; compare if somethings come wrong trying to move the break addres
    cmp rax, qword [curr_brk]
    je __alloc_error
    
    ;; put the return value 
    mov rax, qword [curr_brk]

    ;; take two bytes and put the size of chuck these are metadata
    mov rdi, qword [rbp - 8]
    sub rdi, 2
    mov word [rax], di          ; put the size of chuck
    
    ;; increment the address by 2
    add rax, 2
    
    jmp __alloc_last
    
__alloc_error:
    mov rax, NULL                 ; putting a null address

__alloc_last:
    mov rdi, qword [rbp-8]
    sub rdi, 2
    
    add rsp, 8
    pop rbp
    ret



    ;; void free(void *addr)
    ;; addr -> rdi              ; the address of the page of memory to free
    ;; free: free a chunk of memory
free:
    ;; get the current address
    mov rax, qword [new_brk]

    sub rdi, 2                  ; subtract by 2
    cmp rax, rdi                ; if (rax < rdi)
    jb __free_error

    
    ;; get the initial address of the heap 
    mov rax, qword [free_heap]
    add rax, HEAP_FREE_CAPACITY  ; Calculate

    cmp rdi, rax                ; if (rdi < rax)
    jb __free_error

    ;;  If everything looks right try to insert to the heap another free location
    add rdi, 2
    call __heap_insert
    
    
    jmp __free_last
    
__free_error:                   ; If we receive an invalid address
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, free_error_msg
    mov rdx, free_error_msg_len
    syscall
    
    ;; quit the program
    mov rax, SYS_exit
    mov rdi, EXIT_FAILURE
    syscall
    
__free_last:
    ret
    
    


    ;; void collect()
    ;; collect: simple garbage collector to the heap
collect:
