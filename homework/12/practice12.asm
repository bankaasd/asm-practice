; practice12.asm
BITS 32
GLOBAL _start

SECTION .data
    ; memory block: layout control sequences and static symbols
    newline     db 10
    minus_one   db "-1", 10
    not_found_l equ $-minus_one

SECTION .bss
    ; memory block: allocated tracking spaces for text structures
    text_buf    resb 256
    pat_buf     resb 64
    output_buf  resb 32
    text_len    resd 1
    pat_len     resd 1
    first_match resd 1
    match_cnt   resd 1

SECTION .text
_start:
    ; I/O block: acquire source text data from standard stream
    mov eax, 3          ; sys_read
    mov ebx, 0          ; stdin
    mov ecx, text_buf
    mov edx, 256
    int 0x80

    ; parse block: calculate true size constraint of the source text
    mov esi, text_buf
    call _strlen
    mov [text_len], eax

    ; I/O block: acquire matching pattern constraint from standard stream
    mov eax, 3          ; sys_read
    mov ebx, 0          ; stdin
    mov ecx, pat_buf
    mov edx, 64
    int 0x80

    ; parse block: calculate true size constraint of the pattern string
    mov esi, pat_buf
    call _strlen
    mov [pat_len], eax

    ; logic block: evaluate baseline structural bounds and empty cases
    mov dword [first_match], -1
    mov dword [match_cnt], 0

    cmp dword [pat_len], 0
    je .print_results   ; handles edge case pattern == ""
    
    mov eax, [text_len]
    cmp eax, [pat_len]
    jl .print_results   ; pattern is longer than base text content

    ; loops block: outer iteration cycle initialization over text array
    xor esi, esi        ; outer string character pointer index i = 0

.outer_loop:
    ; logic block: loop condition check (i <= text_len - pat_len)
    mov eax, [text_len]
    sub eax, [pat_len]
    cmp esi, eax
    jg .print_results

    ; loops block: nested iteration cycle initialization over pattern array
    xor edi, edi        ; inner pattern match counter index j = 0

.inner_loop:
    cmp edi, [pat_len]
    je .match_confirmed ; if j == pat_len, full substring match is validated

    ; math block: calculate combined displacement index [base + offset]
    mov ebx, esi
    add ebx, edi
    
    mov al, [text_buf + ebx]
    mov cl, [pat_buf + edi]
    cmp al, cl
    jne .mismatch_detected

    inc edi
    jmp .inner_loop

.mismatch_detected:
    inc esi             ; move outer tracking offset to next sequential byte
    jmp .outer_loop

.match_confirmed:
    ; logic block: update program statistics following a successful search hit
    inc dword [match_cnt]
    
    cmp dword [first_match], -1
    jne .skip_first_assignment
    mov [first_match], esi ; log initial match index position
    
.skip_first_assignment:
    ; math block: advance outer pointer by pat_len to prevent overlapping matches
    add esi, [pat_len]
    jmp .outer_loop

.print_results:
    ; logic block: inspect first match result code to determine print stream
    mov eax, [first_match]
    cmp eax, -1
    jne .print_numerical_index

    ; I/O block: output default not found flag token
    mov eax, 4
    mov ebx, 1
    mov ecx, minus_one
    mov edx, not_found_l
    int 0x80
    jmp .print_total_count

.print_numerical_index:
    ; parse block: format index token and display it to console
    mov eax, [first_match]
    call _itoa_print

.print_total_count:
    ; parse block: format match frequency code and display it to console
    mov eax, [match_cnt]
    call _itoa_print

.exit_proc:
    ; I/O block: safely terminate runtime environment execution
    mov eax, 1          ; sys_exit
    mov ebx, 0          ; exit status code 0
    int 0x80

; Subroutine: calculate string boundary size excluding terminal control codes
_strlen:
    xor eax, eax
.len_loop:
    mov dl, [esi + eax]
    cmp dl, 10          ; newline check
    je .len_done
    cmp dl, 0           ; null terminator check
    je .len_done
    inc eax
    jmp .len_loop
.len_done:
    ret

; Subroutine: Converts integer in EAX to layout sequence in output_buf
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