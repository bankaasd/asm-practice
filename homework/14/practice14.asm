; practice14.asm
BITS 32
GLOBAL _start

SECTION .data
    ; memory block: templates and row headers
    space       db " "
    newline     db 10
    median_msg  db "median: "
    median_len  equ $-median_msg

SECTION .bss
    ; memory block: storage array buffer and runtime tracking metrics
    array       resd 100
    input_buf   resb 32
    output_buf  resb 32
    n_val       resd 1
    min_idx     resd 1

SECTION .text
_start:
    ; I/O block: acquire array limit 'n' from standard console stream
    mov eax, 3          ; sys_read
    mov ebx, 0          ; stdin
    mov ecx, input_buf
    mov edx, 32
    int 0x80

    ; parse block: transform string representation into an integer
    mov esi, input_buf
    call _atoi
    mov [n_val], eax

    ; loops block: load user elements into the uninitialized array block
    xor ecx, ecx        ; index counter i = 0
.read_loop:
    cmp ecx, [n_val]
    je .print_before_prep
    push ecx            ; safeguard index across system boundaries

    ; I/O block: execute single token read operation
    mov eax, 3          ; sys_read
    mov ebx, 0          ; stdin
    mov ecx, input_buf
    mov edx, 32
    int 0x80

    ; parse block: convert input token string to numerical object
    mov esi, input_buf
    call _atoi

    pop ecx             ; restore working loop counter index
    ; memory block: populate array cell via scale index [base + idx*4]
    mov [array + ecx * 4], eax
    inc ecx
    jmp .read_loop

.print_before_prep:
    ; logic block: call routine to print array before executing sort sequence
    call _print_array

    ; logic block: implement core selection sort algorithm
    xor ecx, ecx        ; outer loop index i = 0
.outer_sort_loop:
    mov eax, [n_val]
    dec eax             ; n - 1
    cmp ecx, eax        ; loop until i < n - 1
    jge .sort_completed

    mov [min_idx], ecx  ; set min_idx = i

    ; loops block: nested inner search loop initialization
    mov edi, ecx
    inc edi             ; inner loop index j = i + 1

.inner_sort_loop:
    cmp edi, [n_val]    ; loop until j < n
    jge .swap_elements_prep

    ; memory block: load values for boundary evaluation
    mov eax, [min_idx]
    mov edx, [array + eax * 4] ; edx = array[min_idx]
    mov ebx, [array + edi * 4] ; ebx = array[j]

    ; logic block: perform comparison to track smallest element
    cmp ebx, edx
    jge .skip_min_update
    mov [min_idx], edi  ; update min_idx = j

.skip_min_update:
    inc edi
    jmp .inner_sort_loop

.swap_elements_prep:
    ; math block: perform conditional element exchange operations
    mov eax, [min_idx]
    cmp eax, ecx        ; if min_idx == i, no physical swap needed
    je .next_outer_iteration

    ; memory block: swap data contents using register exchange pipelines
    mov edx, [array + ecx * 4]
    mov ebx, [array + eax * 4]
    mov [array + ecx * 4], ebx
    mov [array + eax * 4], edx

.next_outer_iteration:
    inc ecx
    jmp .outer_sort_loop

.sort_completed:
    ; logic block: call routine to print array after finishing sort sequence
    call _print_array

    ; math block: evaluate lower median index via equation (n - 1) / 2
    mov eax, [n_val]
    dec eax             ; n - 1
    shr eax, 1          ; unsigned division by 2 (shift right)

    ; memory block: extract computed median element from structure
    mov ebx, [array + eax * 4]

    ; I/O block: execute descriptive row message stream
    push ebx
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, median_msg
    mov edx, median_len
    int 0x80
    pop eax

    ; parse block: convert targeted median integer value and print it
    call _itoa_print

.exit_proc:
    ; I/O block: return operational execution focus back to OS environment
    mov eax, 1          ; sys_exit
    mov ebx, 0          ; exit status code 0
    int 0x80

; Subroutine: print all elements contained inside array buffer space
_print_array:
    xor ecx, ecx
.print_loop:
    cmp ecx, [n_val]
    je .print_done
    push ecx

    mov eax, [array + ecx * 4]
    call _itoa_format
    
    ; I/O block: print numeric character contents
    mov eax, 4
    mov ebx, 1
    mov ecx, output_buf
    int 0x80

    ; I/O block: append single spacer symbol
    mov eax, 4
    mov ebx, 1
    mov ecx, space
    mov edx, 1
    int 0x80

    pop ecx
    inc ecx
    jmp .print_loop
.print_done:
    ; I/O block: finalize printed row sequence with line split symbol
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80
    ret

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