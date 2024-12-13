section .data
msg_file_opened    db "File opened successfully", 10, 0
msg_lseek_success  db "Lseek successful", 10, 0
msg_read_success   db "Read ELF header successfully", 10, 0
msg_entry_before   db "Entry point before modification: 0x", 0
msg_entry_after    db "Entry point after modification: 0x", 0
msg_write_success  db "Write successful", 10, 0
msg_file_closed    db "File closed successfully", 10, 0
msg_error          db "Error occurred!", 10, 0

filename           db "cible", 0
fd                 dq 0
e_entry_offset     equ 0x18        ; Offset de e_entry dans ELF header
buffer             resb 8          ; Stocke l'adresse actuelle
new_entry          dq 0x1000     ; Nouvelle adresse d'entrée (exemple)

section .text
global _start

_start:
    ; Ouvrir le fichier cible
    mov rax, 2                   ; sys_open
    lea rdi, [filename]
    mov rsi, 2                   ; O_RDWR
    mov rdx, 0o644
    syscall
    cmp rax, 0
    js error
    mov [fd], rax

    ; Lire et afficher l'adresse d'entrée avant modification
    call lseek_to_entry
    call read_entry
    lea rsi, [msg_entry_before]
    call print_string
    mov rsi, buffer
    call print_hex
    call newline

    ; Modifier le point d'entrée
    call lseek_to_entry
    call write_entry
    lea rsi, [msg_write_success]
    call print_string

    ; Lire et afficher après modification
    call lseek_to_entry
    call read_entry
    lea rsi, [msg_entry_after]
    call print_string
    mov rsi, buffer
    call print_hex
    call newline

    ; Fermer le fichier
    mov rax, 3                   ; sys_close
    mov rdi, [fd]
    syscall
    lea rsi, [msg_file_closed]
    call print_string
    jmp exit

error:
    lea rsi, [msg_error]
    call print_string
exit:
    mov rax, 60                  ; sys_exit
    xor rdi, rdi
    syscall

lseek_to_entry:
    mov rax, 8                   ; sys_lseek
    mov rdi, [fd]
    mov rsi, e_entry_offset
    mov rdx, 0                   ; SEEK_SET
    syscall
    ret

read_entry:
    mov rax, 0                   ; sys_read
    mov rdi, [fd]
    lea rsi, [buffer]
    mov rdx, 8
    syscall
    ret

write_entry:
    mov rax, 1                   ; sys_write
    mov rdi, [fd]
    lea rsi, [new_entry]
    mov rdx, 8
    syscall
    ret

print_string:
    mov rax, 1
    mov rdi, 1                   ; STDOUT
.loop:
    cmp byte [rsi], 0
    je .done
    mov rdx, 1
    syscall
    inc rsi
    jmp .loop
.done:
    ret

newline:
    mov rax, 1
    mov rdi, 1
    mov rsi, nl
    mov rdx, 1
    syscall
    ret

print_hex:
    mov rax, [rsi]
    mov rcx, 16
    lea rdi, [hex_buffer + 16]
    mov byte [rdi], 0
.loop:
    dec rdi
    mov rdx, rax
    and rdx, 0xF
    cmp rdx, 10
    jl .digit
    add dl, 'A' - 10
    jmp .store
.digit:
    add dl, '0'
.store:
    mov [rdi], dl
    shr rax, 4
    loop .loop
    lea rsi, [rdi]
    call print_string
    ret

section .data
nl db 10, 0
hex_buffer resb 17

