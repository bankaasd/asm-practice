; practice13.asm
BITS 32
GLOBAL _start

SECTION .data
    ; memory block: templates and messages
    space       db " "
    newline     db 10
    pal_yes     db "PALINDROME: YES", 10
    pal_yes_len equ $-pal_yes
    pal_no      db "PALINDROME: NO", 10
    pal_no_len  equ $-pal_no

SECTION .bss
    ; memory block: structural arrays and state indicators
    orig_array  resd 200      ; original buffer (up to 200 elements)
    copy_array  resd 200      ; extra buffer for copy and reverse operations
    input_buf   resb 32
    output_buf  resb 32
    n_val       resd 1

SECTION .text
_start:
    ; I/O block: read element count 'n' from standard input
    mov eax, 3          ; sys_read
    mov ebx, 0          ; stdin
    mov ecx, input_buf
    mov edx, 32
    int 0x80

    ; parse block: convert string 'n' to integer
    mov esi, input_buf
    call _atoi
    mov [n_val], eax

    ; loops block: read 'n' numbers into orig_array line by line
    xor ecx, ecx        ; index counter i = 0
.read_loop:
    cmp ecx, [n_val]
    je .read_done
    push ecx            ; preserve outer loop index counter

    ; I/O block: read single number string
    mov eax, 3          ; sys_read
    mov ebx, 0          ; stdin
    mov ecx, input_buf
    mov edx, 32
    int 0x80

    ; parse block: convert input string token to integer
    mov esi, input_buf
    call _atoi

    pop ecx             ; restore loop index counter
    ; memory block: store item using scale indexation [base + idx*4]
    mov [orig_array + ecx * 4], eax
    inc ecx
    jmp .read_loop
.read_done:

    ; loops block: output original array elements in a single line
    xor ecx, ecx
.print_orig_loop:
    cmp ecx, [n_val]
    je .print_orig_done
    push ecx

    mov eax, [orig_array + ecx * 4]
    call _itoa_format
    
    ; I/O block: print formatted number
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, output_buf
    int 0x80
    
    ; I/O block: print space split separator
    mov eax, 4
    mov ebx, 1
    mov ecx, space
    mov edx, 1
    int 0x80

    pop ecx
    inc ecx
    jmp .print_orig_loop
.print_orig_done:
    ; I/O block: print trailing newline for the original array line
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    ; logic block: copy orig_array block to copy_array block via loop
    xor ecx, ecx
.copy_loop:
    cmp ecx, [n_val]
    je .copy_done
    
    ; math block: move data using [base + idx*4] indexing
    mov eax, [orig_array + ecx * 4]
    mov [copy_array + ecx * 4], eax
    inc ecx
    jmp .copy_loop
.copy_done:

    ; logic block: reverse the copy_array block in-place
    xor esi, esi        ; left tracking pointer i = 0
    mov edi, [n_val]
    dec edi             ; right tracking pointer j = n - 1
.reverse_loop:
    cmp esi, edi
    jge .reverse_done
    
    ; math block: swap pair elements using scale indexation [base + idx*4]
    mov eax, [copy_array + esi * 4]
    mov ebx, [copy_array + edi * 4]
    mov [copy_array + esi * 4], ebx
    mov [copy_array + edi * 4], eax

    inc esi
    dec edi
    jmp .reverse_loop
.reverse_done:

    ; loops block: output reversed array elements in a single line
    xor ecx, ecx
.print_rev_loop:
    cmp ecx, [n_val]
    je .print_rev_done
    push ecx

    mov eax, [copy_array + ecx * 4]
    call _itoa_format
    
    ; I/O block: print formatted number
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, output_buf
    int 0x80
    
    ; I/O block: print space split separator
    mov eax, 4
    mov ebx, 1
    mov ecx, space
    mov edx, 1
    int 0x80

    pop ecx
    inc ecx
    jmp .print_rev_loop
.print_rev_done:
    ; I/O block: print trailing newline for the reversed array line
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    ; logic block: evaluate palindrome condition by comparing both blocks
    xor ecx, ecx
.palindrome_loop:
    cmp ecx, [n_val]
    je .is_palindrome_yes

    ; math block: compare pair elements at current offset
    mov eax, [orig_array + ecx * 4]
    mov ebx, [copy_array + ecx * 4]
    cmp eax, ebx
    jne .is_palindrome_no

    inc ecx
    jmp .palindrome_loop

.is_palindrome_yes:
    ; I/O block: output valid palindrome confirmation token
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, pal_yes
    mov edx, pal_yes_len
    int 0x80
    jmp .exit_proc

.is_palindrome_no:
    ; I/O block: output rejected palindrome mismatch token
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, pal_no
    mov edx, pal_no_len
    int 0x80

.exit_proc:
    ; I/O block: release control back to system cleanly
    mov eax, 1          ; sys_exit
    mov ebx, 0          ; exit status code 0
    int 0x80

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