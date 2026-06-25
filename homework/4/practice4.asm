; practice4.asm
BITS 32
GLOBAL _start

SECTION .data
    ; memory block: constants
    newline db 10

SECTION .bss
    ; memory block: buffers for input and output operations
    input_buf  resb 16
    output_buf resb 16

SECTION .text
_start:
    ; I/O block: read input string from console using sys_read
    mov eax, 3          ; sys_read
    mov ebx, 0          ; stdin
    mov ecx, input_buf  ; destination buffer
    mov edx, 16         ; max bytes to read
    int 0x80

    ; parse block: initialize registers for string-to-int conversion
    mov esi, input_buf
    xor eax, eax        ; accumulator for the integer result
    mov ebx, 10         ; base 10 multiplier

.string_to_int_loop:
    ; loops block: process characters one by one
    movzx edx, byte [esi]
    cmp dl, 10          ; check for newline character (Enter)
    je .conversion_done
    cmp dl, 0           ; check for null terminator
    je .conversion_done

    ; math block: parse character to digit and update accumulator
    sub dl, '0'
    imul eax, ebx
    add eax, edx

    inc esi
    jmp .string_to_int_loop

.conversion_done:
    ; logic block: store result in register and handle zero edge case
    ; The parsed integer is now stored in EAX. Now we convert it back to string.
    cmp eax, 0
    jne .output_prep
    
    ; memory block: handle zero input directly
    mov byte [output_buf], '0'
    mov ebx, 1
    jmp .print_result

.output_prep:
    ; parse block: prepare registers for int-to-string conversion
    xor ecx, ecx        ; digit counter
    mov ebx, 10         ; base 10 divisor

.int_to_string_loop:
    ; loops block: extract digits from the integer
    cmp eax, 0
    je .pop_setup

    xor edx, edx
    div ebx             ; math block: divide EAX by 10, remainder in EDX
    add edx, '0'        ; convert remainder to ASCII character

    ; memory block: push character to stack to reverse digit order
    push edx
    inc ecx
    jmp .int_to_string_loop

.pop_setup:
    ; parse block: set up destination buffer pointer
    mov edi, output_buf
    mov ebx, ecx        ; save number of digits as base length counter

.pop_loop:
    ; loops block: pop digits from stack in correct order
    cmp ecx, 0
    je .add_newline

    pop edx
    mov [edi], dl
    inc edi
    dec ecx
    jmp .pop_loop

.add_newline:
    ; memory block: append trailing newline to output string
    mov al, [newline]
    mov [edi], al
    inc ebx             ; math block: include newline in total string length

.print_result:
    ; I/O block: output the final string to console using sys_write
    mov eax, 4          ; sys_write
    mov edx, ebx        ; calculated string length
    mov ebx, 1          ; stdout
    mov ecx, output_buf ; buffer address
    int 0x80

.exit_proc:
    ; I/O block: terminate program cleanly via sys_exit
    mov eax, 1          ; sys_exit
    mov ebx, 0          ; exit status 0
    int 0x80