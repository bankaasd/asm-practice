; practice7.asm
BITS 32
GLOBAL _start

SECTION .data
    ; memory block: labels and characters for formatted output
    space   db " "
    newline db 10
    min_msg db "min: "
    min_len equ $-min_msg
    max_msg db "max: "
    max_len equ $-max_msg
    idx_msg db " index: "
    idx_len equ $-idx_msg

SECTION .bss
    ; memory block: array definition and tracking variables
    array      resd 50      ; reserved 50 double-words (equivalent to dd 50 dup(?))
    input_buf  resb 16
    output_buf resb 16
    n_val      resd 1
    min_val    resd 1
    min_idx    resd 1
    max_val    resd 1
    max_idx    resd 1

SECTION .text
_start:
    ; I/O block: read input size 'n' from standard console
    mov eax, 3          ; sys_read
    mov ebx, 0          ; stdin
    mov ecx, input_buf
    mov edx, 16
    int 0x80

    ; parse block: convert input string 'n' into an integer
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
    mov [n_val], eax    ; store total elements count

    ; logic block: loop to populate the array via formula
    xor ecx, ecx        ; index loop counter i = 0
.fill_loop:
    cmp ecx, [n_val]
    je .fill_done

    ; math block: calculate element value using f(i) = (i-25)*(i-25) + 10
    mov eax, ecx
    sub eax, 25
    imul eax, eax
    add eax, 10

    ; memory block: store element using scale indexation [base + idx*4]
    mov [array + ecx * 4], eax

    inc ecx
    jmp .fill_loop
.fill_done:

    ; loops block: iterate and print all elements in a single line
    xor ecx, ecx        ; reset index i = 0
.print_array_loop:
    cmp ecx, [n_val]
    je .print_array_done

    push ecx            ; preserve outer loop index
    mov eax, [array + ecx * 4]
    call _itoa
    
    ; I/O block: display current numeric element
    mov eax, 4
    mov ebx, 1
    mov ecx, output_buf
    int 0x80

    ; I/O block: display space separator
    mov eax, 4
    mov ebx, 1
    mov ecx, space
    mov edx, 1
    int 0x80

    pop ecx
    inc ecx
    jmp .print_array_loop
.print_array_done:

    ; I/O block: print trailing newline for the array line
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    ; logic block: initialize min/max search with the first element
    mov eax, [array + 0]
    mov [min_val], eax
    mov [max_val], eax
    mov dword [min_idx], 0
    mov dword [max_idx], 0

    mov ecx, 1          ; start checking from index 1
.search_loop:
    cmp ecx, [n_val]
    je .search_done

    mov eax, [array + ecx * 4]

    ; logic block: evaluate minimum boundary
    cmp eax, [min_val]
    jge .check_max
    mov [min_val], eax
    mov [min_idx], ecx

.check_max:
    ; logic block: evaluate maximum boundary
    cmp eax, [max_val]
    jle .next_item
    mov [max_val], eax
    mov [max_idx], ecx

.next_item:
    inc ecx
    jmp .search_loop
.search_done:

    ; I/O block: print accumulated minimum stats
    mov eax, 4
    mov ebx, 1
    mov ecx, min_msg
    mov edx, min_len
    int 0x80

    mov eax, [min_val]
    call _itoa
    mov eax, 4
    mov ebx, 1
    mov ecx, output_buf
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, idx_msg
    mov edx, idx_len
    int 0x80

    mov eax, [min_idx]
    call _itoa
    mov eax, 4
    mov ebx, 1
    mov ecx, output_buf
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    ; I/O block: print accumulated maximum stats
    mov eax, 4
    mov ebx, 1
    mov ecx, max_msg
    mov edx, max_len
    int 0x80

    mov eax, [max_val]
    call _itoa
    mov eax, 4
    mov ebx, 1
    mov ecx, output_buf
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, idx_msg
    mov edx, idx_len
    int 0x80

    mov eax, [max_idx]
    call _itoa
    mov eax, 4
    mov ebx, 1
    mov ecx, output_buf
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

.exit_proc:
    ; I/O block: invoke standard exit routine
    mov eax, 1          ; sys_exit
    mov ebx, 0          ; exit code 0
    int 0x80

; Subroutine: convert integer in EAX to string layout, updates EDX with size
_itoa:
    push ecx
    push ebx
    push edi
    
    cmp eax, 0
    jne .itoa_process
    mov byte [output_buf], '0'
    mov byte [output_buf+1], 0
    mov edx, 1
    jmp .itoa_ret

.itoa_process:
    xor ecx, ecx
    mov ebx, 10
.itoa_loop:
    ; loops block: extract digits using math layout
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
    mov ebx, ecx        ; hold string total length metric
.pop_loop:
    cmp ecx, 0
    je .pop_done
    pop eax
    mov [edi], al
    inc edi
    dec ecx
    jmp .pop_loop
.pop_done:
    mov byte [edi], 0   ; null terminator
    mov edx, ebx        ; return total length in EDX
.itoa_ret:
    pop edi
    pop ebx
    pop ecx
    ret