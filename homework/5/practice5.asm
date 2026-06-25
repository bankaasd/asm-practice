; practice5.asm
BITS 32
GLOBAL _start

SECTION .data
    ; memory block: constants and formatting symbols
    newline db 10

SECTION .bss
    ; memory block: text buffers and variables for calculation results
    input_buf  resb 32
    output_buf resb 32
    sum_val    resd 1
    len_val    resd 1

SECTION .text
_start:
    ; I/O block: read input string from standard input
    mov eax, 3          ; sys_read
    mov ebx, 0          ; stdin
    mov ecx, input_buf  ; destination buffer
    mov edx, 32         ; maximum buffer size
    int 0x80

    ; parse block: initialize markers for string-to-integer procedure
    mov esi, input_buf
    xor eax, eax        ; accumulator for the main number x
    mov ebx, 10         ; decimal base system multiplier

.atoi_loop:
    ; loops block: evaluate text characters one by one
    movzx edx, byte [esi]
    cmp dl, 10          ; terminal newline check
    je .atoi_ready
    cmp dl, 0           ; terminal null check
    je .atoi_ready
    
    ; math block: scale previous value and integrate new digit
    sub dl, '0'
    imul eax, ebx
    add eax, edx
    inc esi
    jmp .atoi_loop

.atoi_ready:
    ; logic block: establish working registers for math decomposition
    ; register EAX now safely holds the unsigned number x
    xor edi, edi        ; register EDI will accumulate sum of digits
    xor esi, esi        ; register ESI will count number of digits
    mov ecx, 10         ; unsigned base-10 divisor

.while_x_greater_zero:
    ; loops block: core process loop while x > 0
    cmp eax, 0
    je .extraction_done

    ; math block: mandatory preparation and unsigned division
    xor edx, edx        ; clear EDX completely before unsigned div operation
    div ecx             ; divide EDX:EAX by ECX. EAX = quotient, EDX = remainder

    ; math block: track total sum and update length register
    add edi, edx        ; add remainder (current digit) to sum
    inc esi             ; increment processed digit count
    jmp .while_x_greater_zero

.extraction_done:
    ; logic block: preserve runtime results into memory space
    mov [sum_val], edi
    mov [len_val], esi

    ; parse block: transform sum value to layout and trigger output
    mov eax, [sum_val]
    call _print_numeric_value

    ; parse block: transform length value to layout and trigger output
    mov eax, [len_val]
    call _print_numeric_value

.exit_proc:
    ; I/O block: execute system termination call via sys_exit
    mov eax, 1          ; sys_exit
    mov ebx, 0          ; safe exit code 0
    int 0x80

; internal subroutine to process formatting and printing of an integer
_print_numeric_value:
    ; logic block: catch zero baseline value early
    cmp eax, 0
    jne .itoa_init
    
    ; memory block: print standalone zero token
    mov byte [output_buf], '0'
    mov ebx, 1
    jmp .syscall_write

.itoa_init:
    xor ecx, ecx        ; internal stack counter
    mov ebx, 10         ; parsing divisor

.itoa_loop:
    ; loops block: extract segments from target integer
    cmp eax, 0
    je .pop_init
    xor edx, edx
    div ebx
    add edx, '0'
    push edx
    inc ecx
    jmp .itoa_loop

.pop_init:
    mov edx, output_buf
    mov ebx, ecx        ; register EBX retains string size metric

.pop_loop:
    ; loops block: re-establish forward layout sequence from stack
    cmp ecx, 0
    je .insert_nl
    pop eax
    mov [edx], al
    inc edx
    dec ecx
    jmp .pop_loop

.insert_nl:
    mov al, [newline]
    mov [edx], al
    inc ebx             ; math block: increase byte count for terminal sign

.syscall_write:
    ; I/O block: trigger execution of sys_write system service
    mov eax, 4          ; sys_write
    mov edx, ebx        ; total buffer size
    mov ebx, 1          ; stdout
    mov ecx, output_buf ; tracking buffer location
    int 0x80
    ret