; practice11.asm
BITS 32
GLOBAL _start

SECTION .data
    ; memory block: templates and characters
    space_char db " "
    star_char  db "*"
    newline    db 10

SECTION .bss
    ; memory block: buffers and tracking variables
    input_buf  resb 16
    line_buf   resb 128
    h_val      resd 1
    row_idx    resd 1
    space_cnt  resd 1
    star_cnt   resd 1

SECTION .text
_start:
    ; I/O block: read height h from standard input
    mov eax, 3          ; sys_read
    mov ebx, 0          ; stdin
    mov ecx, input_buf
    mov edx, 16
    int 0x80

    ; parse block: convert string input to integer h
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
    mov [h_val], eax

    ; logic block: initialize outer loop counter for tree rows
    mov dword [row_idx], 0

.outer_row_loop:
    ; loops block: check if all rows are processed
    mov eax, [row_idx]
    cmp eax, [h_val]
    je .exit_proc

    ; math block: calculate spaces count = h - 1 - row_idx
    mov eax, [h_val]
    sub eax, 1
    sub eax, [row_idx]
    mov [space_cnt], eax

    ; math block: calculate stars count = 2 * row_idx + 1
    mov eax, [row_idx]
    shl eax, 1          ; multiply by 2
    inc eax
    mov [star_cnt], eax

    ; parse block: prepare destination buffer pointer
    mov edi, line_buf

    ; loops block: nested loop to write spaces into buffer
    xor ecx, ecx
.spaces_loop:
    cmp ecx, [space_cnt]
    je .stars_init
    mov al, [space_char]
    mov [edi], al       ; memory block: write space to line buffer
    inc edi
    inc ecx
    jmp .spaces_loop

.stars_init:
    ; loops block: nested loop to write stars into buffer
    xor ecx, ecx
.stars_loop:
    cmp ecx, [star_cnt]
    je .line_done
    mov al, [star_char]
    mov [edi], al       ; memory block: write star to line buffer
    inc edi
    inc ecx
    jmp .stars_loop

.line_done:
    ; memory block: append terminal newline symbol to current line buffer
    mov al, [newline]
    mov [edi], al
    inc edi

    ; logic block: compute exact total line buffer length
    mov edx, edi
    sub edx, line_buf   ; EDX contains total line length

    ; logic block: call print_line subroutine
    mov ecx, line_buf   ; ECX contains buffer address
    call print_line

    inc dword [row_idx]
    jmp .outer_row_loop

.exit_proc:
    ; I/O block: cleanly exit program via sys_exit
    mov eax, 1          ; sys_exit
    mov ebx, 0          ; status 0
    int 0x80

; Subroutine: print_line(buf in ECX, len in EDX)
print_line:
    ; I/O block: execute sys_write to print the buffered row
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    int 0x80
    ret