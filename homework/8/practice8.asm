; practice8.asm
BITS 32
GLOBAL _start

SECTION .data
    ; memory block: literal elements and signs
    space     db " "
    newline   db 10
    minus_one db "-1", 10
    not_found_len equ $-minus_one

SECTION .bss
    ; memory block: array buffers and calculation metrics
    array       resd 100     ; support size up to 100 elements
    found_idx   resd 100     ; storage buffer for collected target indices
    input_buf   resb 32
    output_buf  resb 32
    n_val       resd 1
    target      resd 1
    match_count resd 1
    first_match resd 1

SECTION .text
_start:
    ; I/O block: read array size 'n' from console
    mov eax, 3          ; sys_read
    mov ebx, 0          ; stdin
    mov ecx, input_buf
    mov edx, 32
    int 0x80

    ; parse block: extract integer value 'n'
    mov esi, input_buf
    call _atoi
    mov [n_val], eax

    ; logic block: loop to populate the array from user input line by line
    xor ecx, ecx        ; loop element index counter i = 0
.read_items_loop:
    cmp ecx, [n_val]
    je .read_target_prep

    push ecx            ; preserve runtime array index counter
    
    ; I/O block: read single array item string
    mov eax, 3          ; sys_read
    mov ebx, 0          ; stdin
    mov ecx, input_buf
    mov edx, 32
    int 0x80

    ; parse block: convert input token to numerical item
    mov esi, input_buf
    call _atoi
    
    pop ecx             ; restore runtime array index counter
    ; memory block: store element into base structure [base + idx*4]
    mov [array + ecx * 4], eax

    inc ecx
    jmp .read_items_loop

.read_target_prep:
    ; I/O block: read final target item for search action
    mov eax, 3          ; sys_read
    mov ebx, 0          ; stdin
    mov ecx, input_buf
    mov edx, 32
    int 0x80

    ; parse block: parse target numerical value
    mov esi, input_buf
    call _atoi
    mov [target], eax

    ; logic block: initialize search structures and indicators
    mov dword [match_count], 0
    mov dword [first_match], -1

    xor ecx, ecx        ; reset lookup index i = 0
.search_array_loop:
    cmp ecx, [n_val]
    je .search_array_done

    ; memory block: check current item against target constraint
    mov eax, [array + ecx * 4]
    cmp eax, [target]
    jne .skip_index_match

    ; logic block: track match criteria and record tracking indices
    mov edx, [match_count]
    mov [found_idx + edx * 4], ecx  ; record current match index location
    
    cmp edx, 0
    jne .increment_matches
    mov [first_match], ecx          ; preserve initial search hit index

.increment_matches:
    inc dword [match_count]

.skip_index_match:
    inc ecx
    jmp .search_array_loop
.search_array_done:

    ; logic block: verify if any matching tokens were logged
    mov eax, [first_match]
    cmp eax, -1
    jne .print_valid_first_index

    ; I/O block: process special layout for negative target outcome
    mov eax, 4
    mov ebx, 1
    mov ecx, minus_one
    mov edx, not_found_len
    int 0x80

    mov eax, 0          ; total match count is zero
    call _itoa_print
    
    ; I/O block: write empty string trailing line
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80
    jmp .exit_proc

.print_valid_first_index:
    ; I/O block: display first captured search position index
    mov eax, [first_match]
    call _itoa_print

    ; I/O block: display absolute aggregate frequency count
    mov eax, [match_count]
    call _itoa_print

    ; loops block: print space-separated structural sequence of hit indexes
    xor ecx, ecx
.print_indices_loop:
    cmp ecx, [match_count]
    je .print_indices_done

    push ecx
    mov eax, [found_idx + ecx * 4]
    call _itoa_format
    
    ; I/O block: execute buffer stream print action
    mov eax, 4
    mov ebx, 1
    mov ecx, output_buf
    int 0x80

    ; I/O block: execute space split insertion
    mov eax, 4
    mov ebx, 1
    mov ecx, space
    mov edx, 1
    int 0x80

    pop ecx
    inc ecx
    jmp .print_indices_loop
.print_indices_done:

    ; I/O block: add terminal row split
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

.exit_proc:
    ; I/O block: jump out to standard system exit
    mov eax, 1          ; sys_exit
    mov ebx, 0          ; execution status 0
    int 0x80

; Subroutine: Parse character string to signed integer format
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