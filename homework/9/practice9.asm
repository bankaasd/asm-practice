; practice9.asm
BITS 32
GLOBAL _start

SECTION .data
    ; memory block: LCG constants and formatting characters
    seed        dd 123456789        ; initial state value for LCG
    multiplier  dd 1103515245       ; LCG constant multiplier
    increment   dd 12345            ; LCG constant increment
    
    hash_char   db "#"
    open_paren  db " ("
    close_paren db ")", 10          ; closing parenthesis accompanied by a newline
    prefix      db "0: "            ; template string for line headers

SECTION .bss
    ; memory block: distribution array and conversion buffers
    freq        resd 10             ; 10 bins to track frequencies of digits 0-9
    input_buf   resb 16
    output_buf  resb 16
    n_val       resd 1
    current_row resd 1

SECTION .text
_start:
    ; I/O block: read aggregate amount 'n' from standard input
    mov eax, 3          ; sys_read
    mov ebx, 0          ; stdin
    mov ecx, input_buf
    mov edx, 16
    int 0x80

    ; parse block: transform string representation of 'n' into integer
    mov esi, input_buf
    xor eax, eax
    mov ebx, 10
.atoi_loop:
    movzx edx, byte [esi]
    cmp dl, 10
    je .atoi_done
    cmp dl, 0
    je .atoi_done
    sub dl, '0'
    imul eax, ebx
    add eax, edx
    inc esi
    jmp .atoi_loop
.atoi_done:
    mov [n_val], eax

    ; logic block: clear frequency table memory cells
    xor ecx, ecx
.clear_freq_loop:
    cmp ecx, 10
    je .generation_init
    mov dword [freq + ecx * 4], 0
    inc ecx
    jmp .clear_freq_loop

.generation_init:
    ; logic block: generate pseudorandom data loop bounded by 'n'
    xor ecx, ecx        ; cycle counter = 0
.generation_loop:
    cmp ecx, [n_val]
    je .print_histogram_init
    push ecx            ; preserve outer loop index register

    ; math block: execute LCG transformation x = (1103515245 * x + 12345) mod 2^31
    mov eax, [seed]
    mov edx, [multiplier]
    mul edx             ; EDX:EAX = EAX * multiplier
    add eax, [increment]
    and eax, 0x7FFFFFFF ; apply mod 2^31 via bitmasking (clear sign bit)
    mov [seed], eax     ; preserve new LCG state

    ; math block: map number to 0-9 scope using base-10 division modulus
    xor edx, edx
    mov ebx, 10
    div ebx             ; quotient in EAX, remainder (0..9) in EDX

    ; memory block: record data occurrence inside destination frequency slot
    inc dword [freq + edx * 4]

    pop ecx
    inc ecx
    jmp .generation_loop

.print_histogram_init:
    ; loops block: iterate over the 10 defined rows to display stats
    mov dword [current_row], 0

.row_loop:
    cmp dword [current_row], 10
    je .exit_proc

    ; parse block: modify active numeric symbol inside prefix template
    mov eax, [current_row]
    add al, '0'
    mov [prefix], al

    ; I/O block: print active row prefix sequence
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, prefix
    mov edx, 3
    int 0x80

    ; logic block: load element quantity recorded for active section
    mov esi, [current_row]
    mov edi, [freq + esi * 4]  ; EDI = absolute match counter

    ; loops block: print a continuous string of '#' matching the counter value
    xor ecx, ecx        ; active char counter = 0
.bar_loop:
    cmp ecx, edi
    je .bar_done
    push ecx

    ; I/O block: write out a single structural bar symbol
    mov eax, 4
    mov ebx, 1
    mov ecx, hash_char
    mov edx, 1
    int 0x80

    pop ecx
    inc ecx
    jmp .bar_loop
.bar_done:

    ; I/O block: append visual metadata separator
    mov eax, 4
    mov ebx, 1
    mov ecx, open_paren
    mov edx, 2
    int 0x80

    ; parse block: convert literal counter digit to string presentation
    mov eax, edi
    call _itoa

    ; I/O block: print text version of the counter metric
    mov eax, 4
    mov ebx, 1
    mov ecx, output_buf
    int 0x80

    ; I/O block: terminate active data row layout
    mov eax, 4
    mov ebx, 1
    mov ecx, close_paren
    mov edx, 2
    int 0x80

    inc dword [current_row]
    jmp .row_loop

.exit_proc:
    ; I/O block: request normal OS environment release process
    mov eax, 1          ; sys_exit
    mov ebx, 0          ; exit status 0
    int 0x80

; Subroutine: Translate integer value to string sequence in output_buf
_itoa:
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