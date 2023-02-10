    ;; This is the main function to test our code

    ;; These are the functios
    extern alloc
    extern afree

    
    section .data
    ;; Constants
    SYS_exit equ 60
    EXIT_SUCCESS equ 0
    EXIT_FAILURE equ 1

    SYS_write equ 1
    STDOUT equ 1

    NULL equ 0x0
    LF equ 0xa

    LIMIT equ 100
    
    ;; my variables
    alloc_error_msg db "Error: trying to allocate memory", LF, NULL
    alloc_error_msg_len equ $ - alloc_error_msg

    two dq 2
    count dq 1


    section .bss
    
    addr resq 1


    section .text
    global _start
_start:
    ;; running a new test

loop:
    mov rbx, qword [count]
    cmp rbx, LIMIT
    je done_loop

    inc qword [count]
    
    mov rdi, qword [count]
    call alloc
    
    cmp rax, NULL               ; rax == null ; jump error 
    je error                    ; if there is an error print this

    ;; save the address
    mov qword [addr], rax
    
    ;;  allocate the number
    mov rbx, qword [count]
    mov byte [rax], bl

    ;; if (rax % 2 == 0)
    mov rax, qword [count]
    mov rdx, 0x0
    div qword [two]
    cmp rdx, NULL
    je loop

    ;; otherwire we free the memory
    mov rdi, qword [addr]
    call afree

    jmp loop
    


done_loop:
    
    jmp last                    ; finish the program is anything comes wrong

error:
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, alloc_error_msg
    mov rdx, alloc_error_msg_len
    syscall

    mov rax, SYS_exit
    mov rdi, EXIT_FAILURE
    syscall
    
last:                           ; get out
    
    mov rax, SYS_exit
    mov rdi, EXIT_SUCCESS
    syscall
    
