; practice3.asm
BITS 32
GLOBAL _start

SECTION .data
    ; memory block: constants
    newline db 10

SECTION .bss
    ; memory block: buffer for output string (max 6 digits + newline)
    buffer resb 16

SECTION .text
_start:
    ; logic block: load input value (example: 123456) within range 0...999999
    mov eax, 123456

    ; logic block: check edge case if number is zero
    cmp eax, 0
    jne .parse_init
    
    ; memory block: direct write for zero case
    mov byte [buffer], '0'
    mov ebx, 1
    jmp .print_result

.parse_init:
    ; parse block: prepare registers for division loop
    mov ecx, 0          ; digit counter
    mov ebx, 10         ; math block: base 10 divisor

.convert_loop:
    ; loops block: loop for extracting digits from right to left
    cmp eax, 0
    je .pop_init

    ; math block: divide EAX by 10 (EDX contains remainder)
    xor edx, edx
    div ebx

    ; math block: convert remainder integer to ASCII character
    add edx, '0'

    ; memory block: push character to stack to reverse order
    push edx
    inc ecx
    jmp .convert_loop

.pop_init:
    ; parse block: setup destination buffer pointer
    mov edi, buffer
    mov ebx, ecx        ; save number of digits for length counter

.pop_loop:
    ; loops block: loop for retrieving digits from stack in correct order
    cmp ecx, 0
    je .append_nl

    ; memory block: pop character and write to buffer
    pop edx
    mov [edi], dl
    inc edi
    dec ecx
    jmp .pop_loop

.append_nl:
    ; memory block: append newline character to the end
    mov al, [newline]
    mov [edi], al
    inc ebx             ; math block: include newline in total length

.print_result:
    ; I/O block: invoke sys_write to print the formatted string
    mov eax, 4          ; sys_write
    mov edx, ebx        ; total string length
    mov ebx, 1          ; stdout
    mov ecx, buffer     ; buffer address
    int 0x80

.exit_proc:
    ; I/O block: invoke sys_exit to terminate program
    mov eax, 1          ; sys_exit
    mov ebx, 0          ; exit status 0
    int 0x80