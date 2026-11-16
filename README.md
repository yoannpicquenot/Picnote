# Picnote

Des listes et des notes, pour soi ou à partager avec son foyer.

Picnote est une app mobile (Flutter) pensée pour deux personnes qui vivent ensemble : les courses, la maison, les idées
cadeaux, les préparatifs d'un voyage. Chacun garde ses listes et ses notes perso, et partage ce qu'il veut avec l'autre.
Tout se synchronise en direct.

---

## Sommaire

- [Concepts](#concepts)
- [Parcours d'arrivée](#parcours-darrivée)
- [Accueil](#accueil)
- [Listes](#listes)
- [Notes](#notes)
- [Partage et foyer](#partage-et-foyer)
- [Temps réel et activité](#temps-réel-et-activité)
- [Notifications](#notifications)
- [Réglages et compte](#réglages-et-compte)
- [Limites actuelles](#limites-actuelles)
- [Développement](#développement)

---

## Concepts

| Concept       | Description                                                                                      |
| ------------- | ------------------------------------------------------------------------------------------------ |
| **Foyer**     | Le groupe qui partage listes et notes. **2 membres au maximum** pour l'instant.                   |
| **Membre**    | Un prénom et une couleur d'avatar, affichée à côté de tout ce qu'il ajoute ou coche.             |
| **Liste**     | Une checklist avec un nom, une icône (12 au choix), une couleur (5 au choix), un jour facultatif. |
| **Tâche**     | Un élément d'une liste. Cochée, elle passe dans « Fait », puis s'archive à minuit.                 |
| **Note**      | Un texte libre en blocs (titre, puces, cases à cocher, liens) avec mise en forme.                 |
| **Perso / partagé** | Tout est perso par défaut. Une liste ou une note partagée est visible et modifiable par l'autre. |

---

## Parcours d'arrivée

1. **Connexion sans mot de passe** : on saisit son e-mail, on reçoit un code à 6 chiffres. Le renvoi du code est limité
   dans le temps et trop d'essais bloquent temporairement.
2. **Prénom**, puis **couleur d'avatar**.
3. **« C'est pour qui ? »**
   - **Pour moi** : on crée un foyer solo, prêt pour le jour où l'on invite quelqu'un.
   - **À deux** : on nomme le foyer et on invite l'autre tout de suite.
   - **J'ai une invitation** : on saisit le code reçu (6 caractères, sans 0, O, 1 ni I). L'app montre le foyer et son
     membre avant de rejoindre, et refuse un code expiré ou un foyer complet. Si l'autre a déjà la même couleur, on en
     choisit une autre.

---

## Accueil

- Un message d'accueil selon le moment de la journée (« Salut Mel, bonne soirée ? »).
- Les **listes épinglées** (4 au maximum), avec le nombre d'éléments restants. Une nouvelle liste est épinglée tant qu'il
  reste de la place.
- **Aujourd'hui** et **Demain** : les listes datées de ces jours-là, ainsi que les tâches marquées « aujourd'hui ».
- **Voir les N listes** mène à la vue de toutes les listes.
- La **barre du bas** passe des Listes aux Notes, et son bouton « + » crée une liste ou une note.
- L'en-tête montre les avatars du foyer. Celui de l'autre s'estompe quand il n'est pas dans l'app.

---

## Listes

- **Créer / modifier** : nom, icône, couleur, jour (Aujourd'hui, Demain, Ce week-end, La semaine prochaine ou une date
  précise), rappel facultatif, visibilité (perso ou foyer).
- **Éléments** :
  - toucher pour modifier, glisser les poignées pour réordonner, glisser vers la gauche pour supprimer (avec annulation) ;
  - cocher envoie l'élément dans la section **Fait**, qui affiche qui l'a coché ;
  - **archivage à minuit** : un élément coché un jour disparaît à minuit (heure du téléphone). Chaque journée repart sur
    une liste propre, mais rien n'est effacé : les éléments sont archivés, pas supprimés.
- **Menu « ⋯ »** : modifier, partager ou repasser en perso, voir les **dernières modifs**, supprimer (annulable).

---

## Notes

- Une grille de notes avec un aperçu de la première ligne.
- **Éditeur en blocs** : tape `/` sur une ligne vide pour choisir *Texte*, *Titre*, *Liste à puces*, *Case à cocher* ou
  *Lien*.
- **Barre de mise en forme** au-dessus du clavier : gras, italique, souligné.
- « Dernière modification par » indique qui a modifié la note et quand.
- Rappel facultatif, partage avec le foyer, suppression annulable.
- Seul l'auteur d'une note partagée peut la repasser en perso ou la supprimer.

---

## Partage et foyer

- Toute liste ou note peut être **partagée avec le foyer** ou **repassée en perso** ; l'app confirme ce que l'autre verra
  ou ne verra plus.
- Seul dans son foyer, l'interrupteur de partage devient « Inviter ».
- **Invitation** : on saisit l'e-mail de l'autre, l'app génère un **code valable 7 jours** à lui transmettre. Depuis les
  réglages, on peut renvoyer ou annuler une invitation en attente.
- **Quitter le foyer** : les éléments partagés restent avec l'autre membre. Le dernier membre qui part supprime le foyer
  et tout son contenu. Le compte, lui, est conservé et peut créer ou rejoindre un autre foyer.
- **Retirer un membre** : il perd l'accès au foyer, et les éléments partagés restent dans le foyer.

---

## Temps réel et activité

- **Synchronisation en direct** : les changements de l'autre apparaissent immédiatement, sans rafraîchir.
- **Frappe en direct** : on voit le curseur de l'autre dans une note partagée, et son élément en cours de saisie dans une
  liste.
- **Présence** : l'avatar de l'autre est estompé quand il n'est pas dans l'app.
- **Dernières modifs** : un historique par liste ou note (créé, ajouté, coché, décoché, modifié, supprimé). Les
  modifications successives d'une même personne sur une note sont regroupées.

---

## Notifications

- **Activité du foyer** (Android) : une notification push environ une minute après que l'autre a fini de modifier une
  liste ou une note (« Mel a modifié Voyage à Bergen »). Toucher la notification ouvre l'élément concerné. Le texte suit
  la langue du téléphone.
- **Réglages** : activer ou couper toutes les notifications, choisir l'heure suggérée par défaut pour les rappels, et
  décider si l'on veut être prévenu de l'activité de l'autre.

---

## Réglages et compte

- **Mon compte** : prénom, couleur d'avatar, méthode de connexion (code par e-mail), déconnexion, suppression du compte. La suppression prend effet après
  **15 jours**, et l'on peut changer d'avis d'ici là.
- **Foyer** : renommer, voir les membres, inviter, retirer un membre, quitter.
- **Notifications** : voir la section précédente.
- **À propos** : conditions d'utilisation, confidentialité, contact et signalement de bugs.
- L'**apparence** (clair / sombre) et la **langue** (français / anglais) suivent les réglages du téléphone.

---

## Limites actuelles

- **En ligne uniquement** : pas de cache hors ligne. L'app signale quand la connexion est perdue.
- **Foyer de 2 personnes** au maximum.
- **Invitation par code** uniquement : l'invitation n'est pas encore envoyée par e-mail, il faut transmettre le code
  soi-même.
- **Les rappels** se règlent sur les listes et les notes, mais ne déclenchent pas encore de notification.
- **Notifications push sur Android uniquement** : iOS demande une clé APNs.
- **Co-édition** : si deux personnes écrivent en même temps dans la même note, la dernière sauvegarde l'emporte.

---

## Développement

### Stack

- **Flutter** : architecture MVVM (`ChangeNotifier`), `provider`, `go_router`, `flutter_quill` pour l'éditeur de notes.
- **Supabase** : authentification par code e-mail, Postgres avec RLS, Realtime (synchro, présence, frappe en direct),
  `pg_cron` et une Edge Function (`supabase/functions/notify`).
- **Firebase Cloud Messaging** pour les push Android.

L'organisation des dossiers est décrite dans [`CLAUDE.md`](CLAUDE.md).

### Configuration

Copier `env.example.json` vers `env.json` (ignoré par git) et renseigner l'URL et la clé publique du projet Supabase :

```json
{
  "SUPABASE_URL": "https://<project-ref>.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_..."
}
```

Les migrations se trouvent dans `supabase/migrations/` et s'appliquent avec `supabase db push`.

### Commandes

| Commande          | Rôle                                                   |
| ----------------- | ------------------------------------------------------ |
| `make run`        | Lance l'app sur Supabase                               |
| `make run-demo`   | Lance l'app avec des données de démo, sans backend     |
| `make test`       | Tests                                                  |
| `make analyze`    | Analyse statique                                       |
| `make l10n`       | Regénère les traductions après édition de `lib/l10n/*.arb` |
| `make apk`        | APK Android release                                    |
| `make appbundle`  | App Bundle pour le Play Store                          |
| `make ipa`        | Archive iOS (macOS uniquement)                         |
