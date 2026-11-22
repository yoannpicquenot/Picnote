// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'PICNOTE.';

  @override
  String get appName => 'Picnote';

  @override
  String get listEmpty => 'Vide';

  @override
  String listRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count restants',
      one: '1 restant',
      zero: 'Tout est fait',
    );
    return '$_temp0';
  }

  @override
  String get listPersonal => 'Perso';

  @override
  String get homeLoadError => 'Impossible de charger tes listes';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get today => 'Aujourd’hui';

  @override
  String get tomorrow => 'Demain';

  @override
  String get yesterday => 'Hier';

  @override
  String inDays(int n) {
    return 'dans $n jours';
  }

  @override
  String reminderAt(String date, String time) {
    return '$date à $time';
  }

  @override
  String get dateNone => 'Aucun';

  @override
  String get dateThisWeekend => 'Ce week-end';

  @override
  String get dateNextWeek => 'La semaine prochaine';

  @override
  String get datePick => 'Choisir une date';

  @override
  String get optional => 'Facultatif';

  @override
  String get previousMonth => 'Mois précédent';

  @override
  String get nextMonth => 'Mois suivant';

  @override
  String get datePickDay => 'Choisis un jour';

  @override
  String get calendarDone => 'Valider';

  @override
  String get time => 'Heure';

  @override
  String get reminder => 'Rappel';

  @override
  String reminderForBoth(String name) {
    return 'Une notification pour toi et $name';
  }

  @override
  String get reminderForYou => 'Une notification pour toi';

  @override
  String get remindMeOn => 'Me le rappeler';

  @override
  String get whoSeesIt => 'Qui la voit';

  @override
  String get onlyMe => 'Juste moi';

  @override
  String get personalNote => 'Note perso';

  @override
  String get personalList => 'Liste perso';

  @override
  String get theHousehold => 'Le foyer';

  @override
  String partnerSeesItToo(String name) {
    return '$name la voit aussi';
  }

  @override
  String get cantBeEmpty => 'Ne peut pas être vide.';

  @override
  String editField(String label) {
    return 'Modifier : $label';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get undo => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get markDone => 'Marquer comme fait';

  @override
  String get markNotDone => 'Marquer comme à faire';

  @override
  String get ok => 'OK';

  @override
  String get back => 'Retour';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get later => 'Plus tard';

  @override
  String get edit => 'Modifier';

  @override
  String get you => 'toi';

  @override
  String get youLabel => 'Toi';

  @override
  String get and => ' et ';

  @override
  String get editListTitle => 'Modifier la liste.';

  @override
  String get newListTitle => 'Nouvelle liste.';

  @override
  String get createList => 'Créer la liste';

  @override
  String get changeIconAndColor => 'Changer l’icône et la couleur';

  @override
  String get listName => 'Nom de la liste';

  @override
  String get day => 'Jour';

  @override
  String get dayHint => 'Apparaît dans Aujourd’hui et Demain';

  @override
  String get color => 'Couleur';

  @override
  String get icon => 'Icône';

  @override
  String get newNoteTitle => 'Nouvelle note.';

  @override
  String get createNote => 'Créer la note';

  @override
  String get titleOptional => 'Titre (facultatif)';

  @override
  String get makePersonalQuestion => 'Passer en perso ?';

  @override
  String get shareListQuestion => 'Partager la liste ?';

  @override
  String get shareNoteQuestion => 'Partager la note ?';

  @override
  String get makePersonal => 'Passer en perso';

  @override
  String get share => 'Partager';

  @override
  String partnerWontSee(String name, String item) {
    return '$name ne verra plus « $item ».';
  }

  @override
  String partnerWillSee(String name, String item) {
    return '$name verra « $item » et pourra la modifier.';
  }

  @override
  String get inviteResentStatus => 'Renvoyée';

  @override
  String get invitePendingStatus => 'En attente';

  @override
  String get copyCode => 'Copier le code';

  @override
  String get codeCopied => 'Code copié';

  @override
  String get resend => 'Renvoyer';

  @override
  String get invalidEmail => 'Cette adresse ne semble pas valide';

  @override
  String get theirEmail => 'Son adresse e-mail';

  @override
  String inviteSub(String household) {
    return 'Saisis son adresse e-mail. On lui envoie un code pour rejoindre $household.';
  }

  @override
  String get sendInvitation => 'Envoyer l’invitation';

  @override
  String get inviteSomeone => 'Inviter quelqu’un';

  @override
  String get invite => 'Inviter';

  @override
  String get welcomeTitle => 'Bonjour,';

  @override
  String get welcomeSub =>
      'Tes listes et tes notes, pour toi ou à partager avec ton foyer.';

  @override
  String get continueWithEmail => 'Continuer avec un e-mail';

  @override
  String get emailTitle => 'Ton adresse e-mail ?';

  @override
  String get emailSub => 'On t’envoie un code. Aucun mot de passe à retenir.';

  @override
  String get emailHint => 'email@exemple.fr';

  @override
  String get offlineTryAgain =>
      'Pas de connexion, réessaie quand tu seras en ligne';

  @override
  String get codeTitle => 'Regarde tes e-mails.';

  @override
  String get codeSentTo => 'Code à 6 chiffres envoyé à ';

  @override
  String get codeFieldLabel => 'Code à 6 chiffres';

  @override
  String get codeWrong => 'Ce code ne correspond pas, vérifie ton email';

  @override
  String get codeExpired => 'Ce code a expiré';

  @override
  String get getNewCode => 'Recevoir un nouveau code';

  @override
  String get codeLocked => 'Trop d’essais, réessaie dans quelques minutes';

  @override
  String get changeEmail => 'Modifier l’email';

  @override
  String resendIn(int seconds) {
    return 'Renvoyer dans $seconds s';
  }

  @override
  String get resendCode => 'Renvoyer le code';

  @override
  String get checkSpam => 'Rien reçu ? Regarde dans tes spams.';

  @override
  String get nameTitle => 'Comment on t’appelle ?';

  @override
  String get firstName => 'Prénom';

  @override
  String get avatarTitle => 'Choisis ta couleur.';

  @override
  String get avatarSub =>
      'Elle s’affiche à côté de tout ce que tu ajoutes ou coches.';

  @override
  String get householdStartTitle => 'Ton foyer.';

  @override
  String get householdStartSub =>
      'Le foyer regroupe tes listes et tes notes. Crée le tien, ou rejoins celui de l’autre.';

  @override
  String get createAHousehold => 'Créer un foyer';

  @override
  String get joinAHousehold => 'Rejoindre un foyer';

  @override
  String colorTakenBy(String name, String color) {
    String _temp0 = intl.Intl.selectLogic(color, {
      'terra': 'le terracotta',
      'sage': 'le vert',
      'mustard': 'le moutarde',
      'rose': 'le rouge',
      'other': 'le marron',
    });
    return '$name a déjà $_temp0.';
  }

  @override
  String get byEmail => 'Par e-mail';

  @override
  String get byCode => 'Par code';

  @override
  String get inviteCodeTitle => 'Donne-lui ce code.';

  @override
  String get inviteCodeSub =>
      'Ta moitié le saisit dans Picnote, via « Rejoindre un foyer ». Il marche pendant 7 jours.';

  @override
  String inviteCodeGroupLabel(String code) {
    return 'Code d’invitation $code';
  }

  @override
  String get shareCode => 'Partager le code';

  @override
  String shareCodeText(String code) {
    return 'Rejoins mon foyer sur Picnote avec ce code : $code';
  }

  @override
  String get openGmail => 'Ouvrir Gmail';

  @override
  String get createTitle => 'Nomme ton foyer.';

  @override
  String get createSub => 'Tu pourras le changer plus tard.';

  @override
  String get goToMyHousehold => 'Aller dans mon foyer';

  @override
  String get inviteCardSub =>
      'Partagez vos listes et vos notes, et voyez ce que l’autre ajoute.';

  @override
  String get inviteHowSub =>
      'Envoie-lui un e-mail, ou donne-lui le code toi-même.';

  @override
  String get invitationSent => 'Invitation envoyée.';

  @override
  String invitationSentTo(String email) {
    return 'À $email';
  }

  @override
  String get closeLabel => 'Fermer';

  @override
  String get codeToShare => 'Code à partager';

  @override
  String get invitationPending => 'Invitation en attente';

  @override
  String get joinHouseholdTitle => 'Rejoindre un foyer.';

  @override
  String get joinHouseholdSub =>
      'Les 6 caractères du code que l’autre t’a envoyé. Tes listes et notes viennent avec toi.';

  @override
  String joinedHousehold(String household) {
    return 'Tu as rejoint $household';
  }

  @override
  String get householdNameHint => 'ex. L’appart';

  @override
  String get inviteTheOther => 'Invite ta moitié.';

  @override
  String get joinCodeTitle => 'Ton code d’invitation.';

  @override
  String get joinCodeSub =>
      'Les 6 caractères du code que l’autre personne t’a envoyé.';

  @override
  String get inviteCodeFieldLabel => 'Code d’invitation à 6 caractères';

  @override
  String get joinCodeInvalid =>
      'Ce code n’est pas valide ou a expiré. Demande une nouvelle invitation.';

  @override
  String get joinCodeChecking => 'Vérification du code…';

  @override
  String get joinCodeAlphabet => 'Lettres et chiffres, jamais de 0, O, 1 ou I.';

  @override
  String get householdFullTitle => 'Ce foyer est complet.';

  @override
  String get householdFullSub =>
      'Pour l’instant, un foyer compte 2 personnes au maximum. Tu peux créer le tien.';

  @override
  String householdFullWho(String names) {
    return '$names, 2 sur 2';
  }

  @override
  String get createMyHousehold => 'Créer mon foyer';

  @override
  String partnerInvitesYou(String name) {
    return '$name t’invite.';
  }

  @override
  String joinSub(String name) {
    return 'Rejoins son foyer pour partager des listes et des notes avec $name.';
  }

  @override
  String joinWho(String name) {
    return '$name, et toi en rejoignant';
  }

  @override
  String get colorTakenShort => 'Couleur déjà prise';

  @override
  String get joinHousehold => 'Rejoindre le foyer';

  @override
  String get tabLists => 'Listes';

  @override
  String get tabNotes => 'Notes';

  @override
  String get newNote => 'Nouvelle note';

  @override
  String get newList => 'Nouvelle liste';

  @override
  String get settings => 'Réglages';

  @override
  String get offline => 'Hors ligne';

  @override
  String taskDeleted(String title) {
    return '« $title » supprimé';
  }

  @override
  String greeting(String name) {
    return 'Salut $name,';
  }

  @override
  String get shallWeStart => 'On commence ?';

  @override
  String get goodDay => 'Bonne journée ?';

  @override
  String get goodNight => 'Bonne soirée ?';

  @override
  String get todayTitle => 'Aujourd’hui.';

  @override
  String get tomorrowTitle => 'Demain.';

  @override
  String seeAllLists(int count) {
    return 'Voir les $count listes';
  }

  @override
  String get nothingPlanned => 'Rien de prévu. Profites-en.';

  @override
  String get firstListTitle => 'Ta première liste.';

  @override
  String get firstListSub =>
      'Courses, maison, idées cadeaux : commence par ce que tu as en tête.';

  @override
  String get createAList => 'Créer une liste';

  @override
  String get justNow => 'à l’instant';

  @override
  String minutesAgo(int n) {
    return 'il y a $n min';
  }

  @override
  String hoursAgo(int n) {
    return 'il y a $n h';
  }

  @override
  String get yesterdayLower => 'hier';

  @override
  String get noNotesYet => 'Pas encore de note. Touche + pour en créer une.';

  @override
  String get notesTitle => 'Notes.';

  @override
  String get notesLede => 'Une idée à garder ?';

  @override
  String get untitled => 'Sans titre';

  @override
  String get nowPersonalList => 'Liste passée en perso';

  @override
  String sharedWith(String name) {
    return 'Partagée avec $name';
  }

  @override
  String listDeleted(String name) {
    return '$name supprimée';
  }

  @override
  String get editList => 'Modifier la liste';

  @override
  String get editListSub => 'Nom, couleur, icône, jour, rappel';

  @override
  String get inviteToShareList => 'Pour partager cette liste avec l’autre';

  @override
  String get shareWithHousehold => 'Partager avec le foyer';

  @override
  String get onlyYouWillSee => 'Visible par toi uniquement';

  @override
  String partnerWillSeeAndEdit(String name) {
    return '$name la verra et pourra la modifier';
  }

  @override
  String get deleteList => 'Supprimer la liste';

  @override
  String deleteListSub(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Supprime $count éléments. Tu pourras annuler.',
      one: 'Supprime 1 élément. Tu pourras annuler.',
    );
    return '$_temp0';
  }

  @override
  String get dragToReorder => 'Glisser pour déplacer';

  @override
  String get firstItemPlaceholder => 'Écris ton premier élément…';

  @override
  String get addItem => 'Ajouter un élément';

  @override
  String get doneSection => 'Fait';

  @override
  String get listHint =>
      'Touche un élément pour le modifier, glisse les points pour le déplacer, ou vers la gauche pour le supprimer.';

  @override
  String get allLists => 'Toutes les listes';

  @override
  String get home => 'Accueil';

  @override
  String personalShareWith(String name) {
    return 'Perso. Partager avec $name';
  }

  @override
  String get listOptions => 'Options de la liste';

  @override
  String get mascot => 'Mascotte';

  @override
  String get sharedList => 'Liste partagée';

  @override
  String get personalListOnlyYou => 'Liste perso, visible par toi uniquement';

  @override
  String get allListsTitle => 'Toutes les listes.';

  @override
  String get noListsYet => 'Aucune liste. Touche + pour en créer une.';

  @override
  String deleteNamed(String name) {
    return 'Supprimer $name';
  }

  @override
  String get nowPersonalNote => 'Note passée en perso';

  @override
  String noteDeleted(String name) {
    return '$name supprimée';
  }

  @override
  String get lastEditedBy => 'Dernière modification par';

  @override
  String get reminderOff => 'Aucun';

  @override
  String get inviteToShareNote => 'Pour partager cette note avec l’autre';

  @override
  String get deleteNote => 'Supprimer la note';

  @override
  String get youCanUndo => 'Tu pourras annuler.';

  @override
  String get noteOptions => 'Options de la note';

  @override
  String get sharedNote => 'Note partagée';

  @override
  String get personalNoteOnlyYou => 'Note perso, visible par toi uniquement';

  @override
  String get slashHint => 'Tape / pour ajouter un titre, une liste ou un lien.';

  @override
  String get reminderTitle => 'Rappel.';

  @override
  String get removeReminder => 'Retirer le rappel';

  @override
  String reminderBothNotified(String name) {
    return 'Toi et $name recevez une notification.';
  }

  @override
  String get blockText => 'Texte';

  @override
  String get blockTextDesc => 'Écris, tout simplement';

  @override
  String get blockHeading => 'Titre';

  @override
  String get blockHeadingDesc => 'Titre de section';

  @override
  String get blockBullet => 'Liste à puces';

  @override
  String get blockBulletDesc => 'Liste simple';

  @override
  String get blockCheckbox => 'Case à cocher';

  @override
  String get blockCheckboxDesc => 'Choses à cocher';

  @override
  String get blockLink => 'Lien';

  @override
  String get blockLinkDesc => 'Colle une adresse web';

  @override
  String get formatBold => 'Gras';

  @override
  String get formatItalic => 'Italique';

  @override
  String get formatUnderline => 'Souligné';

  @override
  String get blockListItem => 'Élément';

  @override
  String get blockTodo => 'À faire';

  @override
  String get blockLinkHint => 'Colle un lien';

  @override
  String get blockTextHint => 'Tape / pour les blocs';

  @override
  String noBlockNamed(String query) {
    return 'Aucun bloc nommé « $query »';
  }

  @override
  String get leaveHouseholdQuestion => 'Quitter le foyer ?';

  @override
  String get leaveHousehold => 'Quitter le foyer';

  @override
  String sharedStayIn(String household, String name) {
    return 'Les listes et notes partagées restent dans $household avec $name.';
  }

  @override
  String lastMemberLeave(String household) {
    return 'Tu es le dernier membre : $household et toutes ses listes et notes seront supprimés définitivement.';
  }

  @override
  String get keepAccount =>
      'Tu gardes ton compte et tu peux créer ou rejoindre un autre foyer.';

  @override
  String removeQuestion(String name) {
    return 'Retirer $name ?';
  }

  @override
  String removeNamed(String name) {
    return 'Retirer $name';
  }

  @override
  String loseAccess(String name, String household) {
    return '$name n’a plus accès à $household.';
  }

  @override
  String get sharedStayInHousehold =>
      'Les listes et notes partagées restent dans le foyer.';

  @override
  String wasRemoved(String name) {
    return '$name a été retiré';
  }

  @override
  String get settingsTitle => 'Réglages.';

  @override
  String get myAccount => 'Mon compte';

  @override
  String get householdSection => 'Foyer.';

  @override
  String get householdName => 'Nom du foyer';

  @override
  String get householdRenamed => 'Foyer renommé';

  @override
  String get justYouForNow => 'Juste toi pour l’instant';

  @override
  String get member => 'Membre';

  @override
  String get remove => 'Retirer';

  @override
  String get invitationResent => 'Invitation renvoyée';

  @override
  String get invitationCancelled => 'Invitation annulée';

  @override
  String get inviteSomeoneSub => 'Par e-mail, pour partager listes et notes';

  @override
  String get householdFullNote =>
      'Ton foyer est complet : 2 membres au maximum pour l’instant.';

  @override
  String get notificationsSection => 'Notifications.';

  @override
  String get notifications => 'Notifications';

  @override
  String notificationsOnAt(String time) {
    return 'Activées, rappels à $time';
  }

  @override
  String get notificationsOff => 'Coupées';

  @override
  String get aboutSection => 'À propos.';

  @override
  String get termsOfUse => 'Conditions d’utilisation';

  @override
  String get privacyPolicy => 'Confidentialité';

  @override
  String get contactAndBugs => 'Contact et bugs';

  @override
  String get linkFailed =>
      'Impossible d’ouvrir la page. Elle est sur picnote.cc.';

  @override
  String get mailFailed =>
      'Aucune app e-mail trouvée. Écris-nous à hello@picnote.cc.';

  @override
  String get aboutFooter =>
      'Picnote 1.0.0. L’apparence et la langue suivent les réglages du téléphone.';

  @override
  String get deletionCancelled => 'Suppression annulée.';

  @override
  String deletionBanner(String date) {
    return 'Ton compte sera supprimé le $date. D’ici là, tu peux changer d’avis.';
  }

  @override
  String get cancelDeletion => 'Annuler la suppression';

  @override
  String personalBothDeleted(int lists, int notes) {
    String _temp0 = intl.Intl.pluralLogic(
      lists,
      locale: localeName,
      other: 'Tes $lists listes',
      one: 'Ta liste',
    );
    String _temp1 = intl.Intl.pluralLogic(
      notes,
      locale: localeName,
      other: 'tes $notes notes',
      one: 'ta note',
    );
    return '$_temp0 et $_temp1 perso seront supprimées.';
  }

  @override
  String personalListsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tes $count listes perso seront supprimées.',
      one: 'Ta liste perso sera supprimée.',
    );
    return '$_temp0';
  }

  @override
  String personalNotesDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tes $count notes perso seront supprimées.',
      one: 'Ta note perso sera supprimée.',
    );
    return '$_temp0';
  }

  @override
  String get deleteAccountQuestion => 'Supprimer ton compte ?';

  @override
  String get deleteMyAccount => 'Supprimer mon compte';

  @override
  String accountDeletedOn(String date) {
    return 'Ton compte sera supprimé le $date';
  }

  @override
  String lastMemberDelete(String household) {
    return 'Tu es le dernier membre : $household et tout son contenu seront supprimés aussi.';
  }

  @override
  String get deactivatedFor15Days =>
      'Ton compte est désactivé pendant 15 jours, puis effacé définitivement. Reconnecte-toi d’ici là pour changer d’avis.';

  @override
  String get accountTitle => 'Compte.';

  @override
  String get avatarColor => 'Couleur de l’avatar';

  @override
  String colorShownTo(String name) {
    return '$name voit cette couleur à côté de ce que tu modifies.';
  }

  @override
  String get colorShown =>
      'Cette couleur s’affiche à côté de ce que tu modifies.';

  @override
  String get profileSection => 'Profil.';

  @override
  String get firstNameSaved => 'Prénom enregistré';

  @override
  String get signInSection => 'Connexion.';

  @override
  String get codeByEmail => 'Code par e-mail';

  @override
  String get codeByEmailSub =>
      'Pas de mot de passe : un code à 6 chiffres à chaque fois';

  @override
  String get logOut => 'Se déconnecter';

  @override
  String get fifteenDays => '15 jours pour changer d’avis';

  @override
  String get notificationsTitle => 'Notifications.';

  @override
  String get generalSection => 'Général.';

  @override
  String get allowNotifications => 'Autoriser les notifications';

  @override
  String get allowNotificationsOn => 'Rappels et activité du foyer';

  @override
  String get allowNotificationsOff => 'Coupées : ni rappels ni alertes';

  @override
  String get remindersSection => 'Rappels.';

  @override
  String get dailyReminders => 'Ce qu’il reste à faire';

  @override
  String get dailyRemindersSub =>
      'Toutes les 3 h de 9 h à 21 h, s’il reste des choses pour aujourd’hui ou demain';

  @override
  String get defaultTime => 'Heure par défaut';

  @override
  String get defaultTimeSub => 'Proposée quand tu ajoutes un rappel';

  @override
  String whenPartnerEdits(String name) {
    return 'Quand $name coche ou modifie';
  }

  @override
  String get eachTime => 'Une notification à chaque fois';

  @override
  String get phoneNotificationSettings =>
      'Tu peux aussi gérer Picnote dans les réglages de notifications du téléphone.';

  @override
  String get visibilityShared => 'Partagée';

  @override
  String get noDeadline => 'Non due';

  @override
  String get noReminder => 'Pas de rappel';

  @override
  String get editNoteTitle => 'Modifier la note.';

  @override
  String get editNote => 'Modifier la note';

  @override
  String get whoSeesItTitle => 'Qui la voit.';

  @override
  String get deadlineTitle => 'Échéance.';

  @override
  String get deadline => 'Échéance';

  @override
  String get removeDeadline => 'Retirer l’échéance';

  @override
  String get reminderOnlyYou => 'Toi seul reçois une notification.';

  @override
  String get defaultListName => 'Liste';

  @override
  String get renameList => 'Renommer la liste';

  @override
  String get add => 'Ajouter';

  @override
  String get householdAndSettings => 'Foyer et réglages';

  @override
  String get whosHere => 'Qui est là';

  @override
  String memberYou(String name) {
    return '$name (toi)';
  }

  @override
  String quoted(String item) {
    return '« $item »';
  }

  @override
  String get aListLower => 'une liste';

  @override
  String get aNoteLower => 'une note';

  @override
  String youEditedAgo(String what, String ago) {
    return 'Tu as modifié $what, $ago';
  }

  @override
  String theyEditedAgo(String what, String ago) {
    return 'A modifié $what, $ago';
  }

  @override
  String get nothingChangedYet => 'Rien de modifié pour l’instant';

  @override
  String get pinnedTitle => 'Épinglées.';

  @override
  String get otherListsTitle => 'Autres listes.';

  @override
  String get pinHint => 'Épingle jusqu’à 4 listes pour les voir sur l’accueil.';

  @override
  String get homeFull =>
      'L’accueil est plein. Retire une liste pour en épingler une autre.';

  @override
  String pinNamed(String name) {
    return 'Épingler $name';
  }

  @override
  String unpinNamed(String name) {
    return 'Désépingler $name';
  }

  @override
  String get latestChanges => 'Dernières modifs';

  @override
  String get toShareThisList => 'Pour partager cette liste';

  @override
  String get toShareThisNote => 'Pour partager cette note';

  @override
  String get theListLower => 'la liste';

  @override
  String get theNoteLower => 'la note';

  @override
  String logByYou(String verb, String what) {
    String _temp0 = intl.Intl.selectLogic(verb, {
      'check': 'Tu as coché',
      'uncheck': 'Tu as décoché',
      'add': 'Tu as ajouté',
      'edit': 'Tu as modifié',
      'del': 'Tu as supprimé',
      'other': 'Tu as créé',
    });
    return '$_temp0 $what';
  }

  @override
  String logByName(String name, String verb, String what) {
    String _temp0 = intl.Intl.selectLogic(verb, {
      'check': 'a coché',
      'uncheck': 'a décoché',
      'add': 'a ajouté',
      'edit': 'a modifié',
      'del': 'a supprimé',
      'other': 'a créé',
    });
    return '$name $_temp0 $what';
  }

  @override
  String logSolo(String verb, String what) {
    String _temp0 = intl.Intl.selectLogic(verb, {
      'check': 'Coché',
      'uncheck': 'Décoché',
      'add': 'Ajouté',
      'edit': 'Modifié',
      'del': 'Supprimé',
      'other': 'Créé',
    });
    return '$_temp0 $what';
  }

  @override
  String logSoloList(String verb) {
    String _temp0 = intl.Intl.selectLogic(verb, {
      'edit': 'Liste modifiée',
      'other': 'Liste créée',
    });
    return '$_temp0';
  }

  @override
  String logSoloNote(String verb) {
    String _temp0 = intl.Intl.selectLogic(verb, {
      'edit': 'Note modifiée',
      'other': 'Note créée',
    });
    return '$_temp0';
  }

  @override
  String listDoneUnpin(String name) {
    return '« $name » est terminée. La désépingler ?';
  }

  @override
  String get unpin => 'Désépingler';

  @override
  String partnerCreatedList(String who, String name) {
    return '$who a créé la liste « $name »';
  }

  @override
  String partnerCreatedNote(String who, String name) {
    return '$who a créé la note « $name »';
  }

  @override
  String get see => 'Voir';

  @override
  String isTyping(String name) {
    return '$name écrit…';
  }

  @override
  String get tableTitle => 'Tableau.';

  @override
  String get tableRemoveColumn => 'Retirer la colonne';

  @override
  String get tableRemoveRow => 'Retirer la ligne';

  @override
  String get tableHeaderHint => 'Titre';

  @override
  String get tableAddRow => '+ Ligne';

  @override
  String get tableAddColumn => '+ Colonne';

  @override
  String get blockTable => 'Tableau';

  @override
  String get blockTableDesc => 'Lignes et colonnes';

  @override
  String blockHeadingLevel(int level) {
    return 'Titre $level';
  }

  @override
  String get formatHeading => 'Titre';

  @override
  String get headingColor => 'Couleur du titre';

  @override
  String headingColorName(String color) {
    String _temp0 = intl.Intl.selectLogic(color, {
      'terra': 'Terracotta',
      'sage': 'Vert',
      'mustard': 'Moutarde',
      'rose': 'Rouge',
      'cocoa': 'Marron',
      'grey': 'Gris',
      'other': 'Noir',
    });
    return '$_temp0';
  }

  @override
  String get formatUndo => 'Annuler';

  @override
  String get formatRedo => 'Rétablir';

  @override
  String createdBy(String name) {
    return 'Créée par $name';
  }

  @override
  String get createdByYou => 'Créée par toi';

  @override
  String askAuthor(String name) {
    return 'Pour la passer en perso ou la supprimer, demande à $name.';
  }

  @override
  String get pinToHome => 'Épingler sur l’accueil';

  @override
  String get unpinFromHome => 'Retirer de l’accueil';

  @override
  String get pinnedToHome => 'Liste épinglée sur l’accueil';

  @override
  String get unpinnedFromHome => 'Liste retirée de l’accueil';

  @override
  String partnerEditedList(String who, String name) {
    return '$who a modifié la liste « $name »';
  }

  @override
  String partnerEditedNote(String who, String name) {
    return '$who a modifié la note « $name »';
  }
}
