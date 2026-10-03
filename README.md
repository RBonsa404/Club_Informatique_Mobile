<div align="center">

<img src="assets/img/logo-256.png" alt="Logo du Club Informatique de l'IST" width="104" />

# Club Informatique de l'IST : application mobile

Application Android de la plateforme du Club Informatique de l'Institut Supérieur de Technologie, Ouagadougou

![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13-0175C2?logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-application-3DDC84?logo=android&logoColor=white)

</div>

---

## Présentation

L'application reprend les couleurs, les polices et les contenus de la [plateforme web](https://istclubinformatique.up.railway.app), dans une navigation pensée pour le téléphone : onglets en bas de l'écran, fiches plein écran, gestes de retour et « tirer pour actualiser ».

Elle n'a pas de serveur à elle. Elle appelle l'API de la plateforme web, avec les mêmes comptes et les mêmes données : une inscription faite sur le téléphone apparaît aussitôt sur le site, et inversement. Le backend n'est pas modifié.

## Contenu de la version 1

| Onglet | Écrans |
|---|---|
| Accueil | présentation du club, prochains rendez-vous du membre, prochains événements, actualités |
| Activités | événements (à venir, passés) et formations ; fiche détaillée ; inscription, liste d'attente, désinscription |
| Projets | projets du club ; fiche détaillée ; proposition d'un projet ; suivi de ses propositions |
| Notifications | annonces, rappels, décisions sur les projets ; compteur de non lues ; ouverture de la page concernée |
| Compte | connexion, création de compte, mot de passe oublié ; profil et photo ; mot de passe ; mes inscriptions ; supports et devoirs ; présentation du club et bureau ; contact ; thème clair ou sombre |

Les espaces Formateur, Responsable du Club, Administrateur, Super Admin et DSI restent sur le site web : l'application y renvoie depuis l'onglet Compte.

Comme sur le site, rien n'est inventé : chaque donnée affichée vient de l'API, et une donnée absente donne un état vide.

## Prérequis

| Outil | Version |
|---|---|
| Flutter | 3.47 ou plus récent |
| SDK Android | plateforme 36, outils de compilation 36 |
| Java | 17 ou plus récent |
| Node.js | 22 ou plus récent, pour l'aperçu dans un navigateur seulement |

```bash
flutter doctor
```

## Compiler l'application Android

1. Récupérer les dépendances :

   ```bash
   flutter pub get
   ```

2. Produire le fichier APK :

   ```bash
   flutter build apk --release
   ```

Le fichier se trouve dans `build/app/outputs/flutter-apk/app-release.apk`. Il s'installe sur un téléphone Android en autorisant l'installation depuis une source inconnue.

Pour lancer l'application sur un téléphone branché en USB, avec le débogage USB activé :

```bash
flutter run
```

## Adresse de l'API

| Cas | Adresse utilisée |
|---|---|
| Application installée | `https://istclubinformatique.up.railway.app/api/v1` |
| Aperçu dans un navigateur | `/api/v1`, sous la même origine que l'aperçu |
| Autre backend | `--dart-define=API_URL=https://<domaine>/api/v1` à la compilation |

```bash
flutter build apk --release --dart-define=API_URL=https://<domaine>/api/v1
```

Aucun secret n'est écrit dans l'application : elle ne contient que cette adresse publique.

## Aperçu dans un navigateur

L'application se vérifie aussi dans un navigateur, à la taille d'un téléphone. Un petit serveur sert la version web et relaie `/api` vers un backend, pour que l'application et l'API partagent la même origine.

1. Compiler la version web :

   ```bash
   flutter build web
   ```

2. Lancer l'aperçu, relié par défaut au backend local `http://localhost:8080` :

   ```bash
   node outils/apercu.mjs
   ```

L'aperçu s'ouvre sur http://localhost:5180. Pour le relier à un autre backend, passer son adresse en argument.

## Session et sécurité

| Sujet | Mise en œuvre |
|---|---|
| Jeton d'accès | gardé en mémoire, jamais écrit sur l'appareil |
| Renouvellement | cookie de session posé par le serveur, conservé dans le stockage chiffré d'Android |
| Session expirée | renouvelée automatiquement, puis la requête est rejouée ; sinon retour à la connexion |
| Droits | appliqués par le serveur ; l'application ne fait que masquer ce que le rôle ne peut pas ouvrir |
| Liens externes | seules les adresses `https`, `http` et `mailto` sont ouvertes |

## Tests

```bash
flutter test
```

```bash
flutter analyze
```

Les tests couvrent les dates, la lecture des réponses de l'API, les messages d'erreur, la règle de mot de passe et la correspondance entre les liens des notifications et les écrans.

## Organisation du code

```
lib/
├── main.dart              démarrage : session, préférences, fournisseurs
├── app.dart               routes, onglets, thèmes
├── core/
│   ├── config.dart        adresse de l'API, coordonnées du club
│   ├── theme.dart         charte : couleurs, polices, composants
│   ├── format.dart        dates, texte rédigé, règle de mot de passe
│   ├── preferences.dart   thème choisi
│   ├── auth/session.dart  connexion, renouvellement, client HTTP
│   └── api/               appels à l'API, modèles, erreurs, cookies
├── ui/                    composants communs : cartes, états, listes paginées
└── features/              écrans : accueil, activités, contenus, compte, authentification
```

## Limites connues

| Sujet | État |
|---|---|
| iOS | non compilé : la compilation demande un Mac |
| Notifications poussées | absentes : les notifications se lisent à l'ouverture de l'application |
| Liens des courriels | la vérification d'adresse et la réinitialisation du mot de passe s'ouvrent sur le site web |
| Signature | l'APK est signé avec la clé de développement ; une clé de publication est nécessaire pour Google Play |

## Contact

Club Informatique de l'IST, Institut Supérieur de Technologie, Ouagadougou
[clubinformatique.ist@gmail.com](mailto:clubinformatique.ist@gmail.com)
