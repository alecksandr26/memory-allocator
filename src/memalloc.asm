    ;; This is the interface to alloc memory

    section .data
    
    ;; Constants
    
    SYS_exit equ 60
    EXIT_FAILURE equ 1
    
    SYS_brk equ 12

    SYS_write equ 1
    STDOUT equ 1

    NULL equ 0
    LF equ 0xa

    ;; Variables
    size dd 0

    curr_brk dq NULL             ; address of the current heap

    ;; Message errors for free
    afree_error_msg db "Error: Invalid address to free", LF, NULL
    afree_error_msg_len equ $ - afree_error_msg
    
    ;; Variables sections
    section .bss
    
    init_brk resq 1             ; the initial address of the heap
    new_brk resq 1              ; the new address of the heap

    ;; Include heap
    ;; Constants
    extern HEAP_FREE_CAPACITY
    extern HEAP_FREE_CAPACITY_SIZE

    ;; Variables
    extern heap_size_free       ; The size of the free chunks
    extern free_heap            ; the address where we store the memory possible allocatable memory

    ;; Functions
    extern heap_get_chunk_size
    extern heap_compare_sizes
    extern heap_get_address
    extern heap_extract
    extern heap_insert

    section .text
    
    ;; These are the public methods
    global memalloc
    global memfree
        
    ;; bool __alloc_check_size(long space)
    ;; space -> rdi
    ;; __alloc_check_size: Takes the first chuck of memory and check if it has the enough space
__alloc_check_size:
    mov rbx, rdi                ; move the size
    mov rdi, 0x0
    ;; rdi -> index
    call heap_get_address     ; Get the address of the first node
    mov rdi, rax
    ;; rdi -> address of the index
    call heap_get_chunk_size  ; Get the size
    
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

    call heap_insert

__alloc_resize_chuck_last:
    mov rax, r12
    ret

    
    ;; void *memalloc(size_t nbytes)
    ;; nbytes -> rdi      ; the amount of bytes that we want
    ;; memalloc: return the amount the address of the page of the memory that we want
memalloc:
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
    call heap_extract
    
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
    mov rdi, qword [rbp - 8]

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
    mov rdi, qword [rbp - 8]
    sub rdi, 2
    
    add rsp, 8
    pop rbp
    ret

    ;; void memfree(void *addr)
    ;; addr -> rdi              ; the address of the page of memory to free
    ;; memfree: free a chunk of memory
memfree:
    ;; get the current address
    mov rax, qword [new_brk]

    sub rdi, 2                  ; subtract by 2
    cmp rax, rdi                ; if (rax < rdi)
    jb __afree_error
    
    ;; get the initial address of the heap 
    mov rax, qword [free_heap]
    add rax, HEAP_FREE_CAPACITY  ; Calculate

    cmp rdi, rax                ; if (rdi < rax)
    jb __afree_error

    ;;  If everything looks right try to insert to the heap another free location
    add rdi, 2
    call heap_insert
    
    
    jmp __afree_last
    
__afree_error:                   ; If we receive an invalid address
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, afree_error_msg
    mov rdx, afree_error_msg_len
    syscall
    
    ;; quit the program
    mov rax, SYS_exit
    mov rdi, EXIT_FAILURE
    syscall
    
__afree_last:
    ret
