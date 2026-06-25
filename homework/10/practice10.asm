; practice10.asm
BITS 32
GLOBAL _start

SECTION .data
    ; memory block: labels and format characters
    space       db " "
    newline     db 10
    popc_msg    db "popcount: "
    popc_len    equ $-popc_msg
    mod_msg     db "modified: "
    mod_len     equ $-mod_msg

    ; logic block: bit positions for modification (p=5, q=6, r=0)
    bit_p       equ 5
    bit_q       equ 6
    bit_r       equ 0

SECTION .bss
    ; memory block: conversion and formatting buffers
    input_buf   resb 32
    output_buf  resb 64
    x_val       resd 1
    pop_count   resd 1

SECTION .text
_start:
    ; I/O block: read input 32-bit number x from stdin
    mov eax, 3          ; sys_read
    mov ebx, 0          ; stdin
    mov ecx, input_buf
    mov edx, 32
    int 0x80

    ; parse block: convert input string to 32-bit unsigned integer
    mov esi, input_buf
    call _atoi
    mov [x_val], eax

    ; logic block: prepare buffer for binary representation printing
    mov edi, output_buf ; destination buffer pointer
    mov ebx, [x_val]    ; copy of x to process bit by bit
    xor ecx, ecx        ; bit loop counter (0 to 31)

.binary_loop:
    ; loops block: iterate 32 times for each bit position
    cmp ecx, 32
    je .binary_done

    ; math block: check the highest bit using a test mask
    test ebx, 0x80000000
    jz .write_zero
    mov byte [edi], '1'
    jmp .bit_written
.write_zero:
    mov byte [edi], '0'
.bit_written:
    inc edi

    ; math block: shift left to inspect the next bit in queue
    shl ebx, 1
    inc ecx

    ; logic block: check if a 4-bit group separator space is needed
    mov eax, ecx
    and eax, 3          ; check if ecx % 4 == 0
    jnz .binary_loop
    cmp ecx, 32         ; avoid adding a trailing space at the very end
    je .binary_loop
    
    mov byte [edi], ' ' ; insert group separator space
    inc edi
    jmp .binary_loop

.binary_done:
    mov al, [newline]
    mov [edi], al
    inc edi

    ; I/O block: print the complete binary representation line
    push edi
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, output_buf
    pop edi
    sub edi, output_buf ; calculate total string length
    mov edx, edi
    int 0x80

    ; logic block: calculate popcount using shr + and 1
    mov eax, [x_val]    ; restore fresh copy of x
    xor edi, edi        ; accumulator for set bits
    xor ecx, ecx        ; iteration counter

.popcount_loop:
    ; loops block: shift and accumulate bit statistics
    cmp ecx, 32
    je .popcount_done

    mov edx, eax
    and edx, 1          ; math block: isolate the lowest bit
    add edi, edx        ; accumulate bit to total count
    
    shr eax, 1          ; math block: logical shift right
    inc ecx
    jmp .popcount_loop

.popcount_done:
    mov [pop_count], edi

    ; I/O block: print popcount descriptive label
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, popc_msg
    mov edx, popc_len
    int 0x80

    ; parse block: format popcount value to layout and print
    mov eax, [pop_count]
    call _itoa_print

    ; logic block: modify bits according to specification criteria
    mov eax, [x_val]

    ; math block: set bit p and bit q via logical OR with masks
    or eax, (1 << bit_p)
    or eax, (1 << bit_q)

    ; math block: clear bit r via logical AND with inverted mask
    and eax, ~(1 << bit_r)

    ; I/O block: print modified value descriptive label
    push eax
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, mod_msg
    mov edx, mod_len
    int 0x80
    pop eax

    ; parse block: format final modified integer and print
    call _itoa_print

.exit_proc:
    ; I/O block: exit program cleanly
    mov eax, 1          ; sys_exit
    mov ebx, 0          ; status 0
    int 0x80

; Subroutine: Parse character string to unsigned integer format
_atoi:
    xor eax, eax
    mov ebx, 10
.atoi_loop_proc:
    movzx edx, byte [esi]
    cmp dl, 10
    je .atoi_ret
    cmp dl, 0
    je .atoi_ret
    sub dl, '0'
    imul eax, ebx
    add eax, edx
    inc esi
    jmp .atoi_loop_proc
.atoi_ret:
    ret

; Subroutine: Converts integer in EAX to string token inside output_buf
_itoa_format:
    push ecx
    push ebx
    push edi
    cmp eax, 0
    jne .itoa_proc
    mov byte [output_buf], '0'
    mov byte [output_buf+1], 0
    mov edx, 1
    jmp .itoa_finish
.itoa_proc:
    xor ecx, ecx
    mov ebx, 10
.itoa_loop:
    cmp eax, 0
    je .pop_prep
    xor edx, edx
    div ebx
    add edx, '0'
    push edx
    inc ecx
    jmp .itoa_loop
.pop_prep:
    mov edi, output_buf
    mov edx, ecx
.pop_loop:
    cmp ecx, 0
    je .pop_done
    pop eax
    mov [edi], al
    inc edi
    dec ecx
    jmp .pop_loop
.pop_done:
    mov byte [edi], 0
.itoa_finish:
    pop edi
    pop ebx
    pop ecx
    ret

; Subroutine: Formats integer in EAX with trailing newline and prints it directly
_itoa_print:
    call _itoa_format
    mov edi, output_buf
    add edi, edx
    mov al, [newline]
    mov [edi], al
    inc edx
    mov byte [edi+1], 0
    
    push edx
    mov eax, 4
    mov ebx, 1
    mov ecx, output_buf
    pop edx
    int 0x80
    ret