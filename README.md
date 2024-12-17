# **Projet d'infection ELF en Assembleur**

## **Description**  
Ce projet a pour objectif d'analyser et d'implémenter un programme en **assembleur** capable de modifier le comportement d’un fichier ELF.  
L’infection consiste à transformer un segment **PT_NOTE** en **PT_LOAD**, injecter un **shellcode** dans ce segment, et rediriger l’adresse d’entrée (**e_entry**) vers le code injecté.

Le fichier ELF initial affiche le message : *"c'est un elf sain"*. Après modification, le shellcode affiche un message d’infection avant de tenter d'exécuter le code original.

---

## **Fonctionnalités**  
- Modification d’un segment **PT_NOTE** en **PT_LOAD**.  
- Injection d’un shellcode à une adresse choisie (offset **0x4000**).  
- Redirection du **point d’entrée** (**e_entry**) vers le shellcode.  
- Affichage d’un message d’infection injecté dans le fichier ELF.


## **Structure du projet**  
- `infector.asm` : Code source en assembleur.  
- `cible` : Fichier ELF original.  

---

## **Instructions d'utilisation**  

### **1. Compilation**  
Assemble le code source avec **nasm** et creer un executable  :  
```bash
nasm -f elf64 infector.asm -o infector
ld infector.o -o infector

### **2. Création de l'ELF sain**  
Compile un fichier ELF simple en C pour afficher **"c'est un elf sain"** :  

```bash
gcc -o cible cible.c

## **3. Exécution de l'infector**  
Lance l'infector pour modifier le fichier ELF :  

```bash
./infector
