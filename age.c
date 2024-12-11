#include <stdio.h>
#include <time.h> // Pour obtenir l'année actuelle automatiquement

int main() {
    int annee_naissance, age;
    time_t t = time(NULL);
    struct tm tm = *localtime(&t);
    int annee_actuelle = tm.tm_year + 1900; // Obtenir l'année actuelle

    // Demander à l'utilisateur son année de naissance
    printf("Entrez votre ann\xC3\xA9e de naissance : ");
    scanf("%d", &annee_naissance);

    // Calcul de l'âge
    if (annee_naissance > annee_actuelle) {
        printf("L'ann\xC3\xA9e de naissance ne peut pas être dans le futur !\n");
        return 1; // Quitte le programme avec une erreur
    }

    age = annee_actuelle - annee_naissance;

    // Afficher l'âge
    printf("Vous avez %d ans.\n", age);

    return 0;
}

