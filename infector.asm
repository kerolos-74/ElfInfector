section .data
    prompt db "Entrez votre annee de naissance: ", 0    ; Message affiché à l'utilisateur
    prompt_len equ $ - prompt                          ; Taille du message
    year_buffer db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0        ; Buffer pour stocker l'année saisie (max 10 caractères)
    newline db 0xA, 0                                  ; Saut de ligne

section .bss
    input_len resb 4                                   ; Longueur des données saisies

section .text
global _start

_start:
    ; Afficher le prompt
    mov rax, 1                ; syscall write
    mov rdi, 1                ; file descriptor (stdout)
    mov rsi, prompt           ; adresse du message
    mov rdx, prompt_len       ; longueur du message
    syscall

    ; Lire l'entrée utilisateur
    mov rax, 0                ; syscall read
    mov rdi, 0                ; file descriptor (stdin)
    mov rsi, year_buffer      ; adresse du buffer pour stocker l'entrée
    mov rdx, 10               ; nombre maximum de caractères à lire
    syscall

    ; Afficher la saisie pour vérification
    mov rax, 1                ; syscall write
    mov rdi, 1                ; file descriptor (stdout)
    mov rsi, year_buffer      ; adresse du buffer contenant l'entrée
    mov rdx, 10               ; longueur maximale affichée
    syscall

    ; Saut de ligne
    mov rax, 1                ; syscall write
    mov rdi, 1                ; file descriptor (stdout)
    mov rsi, newline          ; adresse du saut de ligne
    mov rdx, 1                ; taille du saut de ligne
    syscall

    ; Quitter le programme
    mov rax, 60               ; syscall exit
    xor rdi, rdi              ; code retour 0
    syscall
