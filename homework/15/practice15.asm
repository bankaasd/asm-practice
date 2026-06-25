; practice15.asm
BITS 32
GLOBAL _start

SECTION .data
    ; memory block: text formatting templates
    newline   db 10
    calls_msg db "calls = "
    calls_len equ $-calls_msg

SECTION .bss
    ; memory block: data arrays and global execution counter
    input_buf  resb 16
    output_buf resb 16
    calls      resd 1       ; global call counter as requested by professor
    fact_res   resd 1

SECTION .text
_start:
    ; I/O block: read input value 'n' from console
    mov eax, 3          ; sys_read
    mov ebx, 0          ; stdin
    mov ecx, input_buf
    mov edx, 16
    int 0x80

    ; parse block: convert input string into integer n
    mov esi, input_buf
    call _atoi
    
    ; logic block: initialize call counter to zero
    mov dword [calls], 0

    ; logic block: call recursive factorial procedure
    call fact
    mov [fact_res], eax ; store factorial calculation result

    ; parse block: format factorial result and print it
    mov eax, [fact_res]
    call _itoa_print

    ; I/O block: print label for recursive call metrics
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, calls_msg
    mov edx, calls_len
    int 0x80

    ; parse block: format calls counter value and print it
    mov eax, [calls]
    call _itoa_print

.exit_proc:
    ; I/O block: execute clean exit via system service
    mov eax, 1          ; sys_exit
    mov ebx, 0          ; exit code 0
    int 0x80

; Recursive function: fact(n in eax) -> result in eax
fact:
    ; logic block: increment the global recursive call tracking variable
    inc dword [calls]

    ; memory block: standard procedure prologue execution
    push ebp
    mov ebp, esp
    push ebx            ; save non-volatile register ebx

    ; logic block: check base case scenario (n <= 1)
    cmp eax, 1
    jbe .base_case

    ; memory block: preserve active 'n' on call stack before recursion
    push eax
    
    ; math block: calculate parameter shift n - 1
    dec eax
    
    ; logic block: recursive function invocation
    call fact
    
    ; memory block: pop original parameter 'n' from stack into register ebx
    pop ebx
    
    ; math block: multiply return accumulator by original parameter value
    mul ebx             ; edx:eax = eax * ebx
    jmp .epilog

.base_case:
    ; logic block: load value 1 for base case terminal execution
    mov eax, 1

.epilog:
    ; memory block: standard procedure epilogue execution
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; Subroutine: Parse character string to unsigned integer format
_atoi:
    xor eax, eax
    mov ebx, 10
.atoi_loop_proc:
    ; loops block: character evaluation cycle
    movzx edx, byte [esi]
    cmp dl, 10
    je .atoi_ret
    cmp dl, 0
    je .atoi_ret
    sub dl, '0'
    imul eax, ebx       ; math block: accumulation logic
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
    ; loops block: decimal splitting extraction cycle
    cmp eax, 0
    je .pop_prep
    xor edx, edx
    div ebx             ; math block: division base-10 splitting
    add edx, '0'
    push edx
    inc ecx
    jmp .itoa_loop
.pop_prep:
    mov edi, output_buf
    mov edx, ecx
.pop_loop:
    ; loops block: stack character reconstruction cycle
    cmp ecx, 0
    je .pop_done
    pop eax
    mov [edi], al       ; memory block: store char to buffer
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
    mov [edi], al       ; memory block: append newline
    inc edx
    mov byte [edi+1], 0
    
    push edx
    ; I/O block: write out formatted buffer contents
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, output_buf
    pop edx
    int 0x80
    ret