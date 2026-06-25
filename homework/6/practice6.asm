; practice6.asm
BITS 32
GLOBAL _start

SECTION .data
    ; memory block: text templates for comparisons
    sig_lt db "SIGNED: a < b", 10
    sig_lt_len equ $-sig_lt
    sig_eq db "SIGNED: a = b", 10
    sig_eq_len equ $-sig_eq
    sig_gt db "SIGNED: a > b", 10
    sig_gt_len equ $-sig_gt

    uns_lt db "UNSIGNED: a < b", 10
    uns_lt_len equ $-uns_lt
    uns_eq db "UNSIGNED: a = b", 10
    uns_eq_len equ $-uns_eq
    uns_gt db "UNSIGNED: a > b", 10
    uns_gt_len equ $-uns_gt

    max_sig_lbl db "max_signed: "
    max_sig_lbl_len equ $-max_sig_lbl
    max_uns_lbl db "max_unsigned: "
    max_uns_lbl_len equ $-max_uns_lbl

    newline db 10

SECTION .bss
    ; memory block: buffers for numerical conversion and storage
    input_buf  resb 32
    output_buf resb 32
    val_a      resd 1
    val_b      resd 1
    is_neg     resb 1

SECTION .text
_start:
    ; I/O block: read string for variable a
    mov eax, 3          ; sys_read
    mov ebx, 0          ; stdin
    mov ecx, input_buf
    mov edx, 32
    int 0x80

    ; parse block: parse input string into variable a
    mov esi, input_buf
    call _atoi
    mov [val_a], eax

    ; I/O block: read string for variable b
    mov eax, 3          ; sys_read
    mov ebx, 0          ; stdin
    mov ecx, input_buf
    mov edx, 32
    int 0x80

    ; parse block: parse input string into variable b
    mov esi, input_buf
    call _atoi
    mov [val_b], eax

    ; logic block: execute signed comparison routine
    call _cmp_signed

    ; logic block: execute unsigned comparison routine
    call _cmp_unsigned

.exit_proc:
    ; I/O block: exit program cleanly
    mov eax, 1          ; sys_exit
    mov ebx, 0          ; status 0
    int 0x80

; Subroutine: Parse string with optional negative sign to integer
_atoi:
    xor eax, eax
    mov ebx, 10
    mov byte [is_neg], 0

    ; parse block: check for negative sign prefix
    movzx edx, byte [esi]
    cmp dl, '-'
    jne .atoi_loop
    mov byte [is_neg], 1
    inc esi

.atoi_loop:
    ; loops block: iterate through digits
    movzx edx, byte [esi]
    cmp dl, 10
    je .atoi_done
    cmp dl, 0
    je .atoi_done

    ; math block: multiply accumulator and add current digit
    sub dl, '0'
    imul eax, ebx
    add eax, edx
    inc esi
    jmp .atoi_loop

.atoi_done:
    ; logic block: apply sign if negative flag is raised
    cmp byte [is_neg], 1
    jne .ret_atoi
    neg eax
.ret_atoi:
    ret

; Subroutine: Handle signed comparison, string printing and maximum finding
_cmp_signed:
    mov eax, [val_a]
    mov ebx, [val_b]
    cmp eax, ebx
    jl .sig_less
    je .sig_equal

.sig_greater:
    ; I/O block: print signed greater text
    mov eax, 4
    mov ebx, 1
    mov ecx, sig_gt
    mov edx, sig_gt_len
    int 0x80
    mov eax, [val_a]    ; val_a is max
    jmp .print_max_s

.sig_less:
    ; I/O block: print signed less text
    mov eax, 4
    mov ebx, 1
    mov ecx, sig_lt
    mov edx, sig_lt_len
    int 0x80
    mov eax, [val_b]    ; val_b is max
    jmp .print_max_s

.sig_equal:
    ; I/O block: print signed equal text
    mov eax, 4
    mov ebx, 1
    mov ecx, sig_eq
    mov edx, sig_eq_len
    int 0x80
    mov eax, [val_a]

.print_max_s:
    push eax            ; save max value
    ; I/O block: print max signed label
    mov eax, 4
    mov ebx, 1
    mov ecx, max_sig_lbl
    mov edx, max_sig_lbl_len
    int 0x80
    pop eax
    call _print_signed_numeric
    ret

; Subroutine: Handle unsigned comparison, string printing and maximum finding
_cmp_unsigned:
    mov eax, [val_a]
    mov ebx, [val_b]
    cmp eax, ebx
    jb .uns_less
    je .uns_equal

.uns_greater:
    ; I/O block: print unsigned greater text
    mov eax, 4
    mov ebx, 1
    mov ecx, uns_gt
    mov edx, uns_gt_len
    int 0x80
    mov eax, [val_a]
    jmp .print_max_u

.uns_less:
    ; I/O block: print unsigned less text
    mov eax, 4
    mov ebx, 1
    mov ecx, uns_lt
    mov edx, uns_lt_len
    int 0x80
    mov eax, [val_b]
    jmp .print_max_u

.uns_equal:
    ; I/O block: print unsigned equal text
    mov eax, 4
    mov ebx, 1
    mov ecx, uns_eq
    mov edx, uns_eq_len
    int 0x80
    mov eax, [val_a]

.print_max_u:
    push eax
    ; I/O block: print max unsigned label
    mov eax, 4
    mov ebx, 1
    mov ecx, max_uns_lbl
    mov edx, max_uns_lbl_len
    int 0x80
    pop eax
    call _print_unsigned_numeric
    ret

; Subroutine: Prints a signed number (supports negative values)
_print_signed_numeric:
    cmp eax, 0
    jge _print_unsigned_numeric
    push eax
    ; I/O block: print minus sign for negative numbers
    mov byte [output_buf], '-'
    mov eax, 4
    mov ebx, 1
    mov ecx, output_buf
    mov edx, 1
    int 0x80
    pop eax
    neg eax

; Subroutine: Prints an unsigned integer
_print_unsigned_numeric:
    cmp eax, 0
    jne .itoa_init
    mov byte [output_buf], '0'
    mov ebx, 1
    jmp .syscall_write

.itoa_init:
    xor ecx, ecx
    mov ebx, 10

.itoa_loop:
    ; loops block: extract digits using division
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
    mov ebx, ecx

.pop_loop:
    ; loops block: restore sequence from stack
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
    inc ebx

.syscall_write:
    ; I/O block: write layout buffer to stdout
    mov eax, 4
    mov edx, ebx
    mov ebx, 1
    mov ecx, output_buf
    int 0x80
    ret