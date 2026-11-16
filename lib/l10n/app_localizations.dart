import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('fr')];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'PICNOTE.'**
  String get appTitle;

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'Picnote'**
  String get appName;

  /// No description provided for @listEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Vide'**
  String get listEmpty;

  /// No description provided for @listRemaining.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Tout est fait} =1{1 restant} other{{count} restants}}'**
  String listRemaining(int count);

  /// No description provided for @listPersonal.
  ///
  /// In fr, this message translates to:
  /// **'Perso'**
  String get listPersonal;

  /// No description provided for @homeLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger tes listes'**
  String get homeLoadError;

  /// No description provided for @tryAgain.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get tryAgain;

  /// No description provided for @today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd’hui'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In fr, this message translates to:
  /// **'Demain'**
  String get tomorrow;

  /// No description provided for @yesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get yesterday;

  /// No description provided for @inDays.
  ///
  /// In fr, this message translates to:
  /// **'dans {n} jours'**
  String inDays(int n);

  /// No description provided for @reminderAt.
  ///
  /// In fr, this message translates to:
  /// **'{date} à {time}'**
  String reminderAt(String date, String time);

  /// No description provided for @dateNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get dateNone;

  /// No description provided for @dateThisWeekend.
  ///
  /// In fr, this message translates to:
  /// **'Ce week-end'**
  String get dateThisWeekend;

  /// No description provided for @dateNextWeek.
  ///
  /// In fr, this message translates to:
  /// **'La semaine prochaine'**
  String get dateNextWeek;

  /// No description provided for @datePick.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une date'**
  String get datePick;

  /// No description provided for @optional.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif'**
  String get optional;

  /// No description provided for @previousMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois précédent'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois suivant'**
  String get nextMonth;

  /// No description provided for @datePickDay.
  ///
  /// In fr, this message translates to:
  /// **'Choisis un jour'**
  String get datePickDay;

  /// No description provided for @calendarDone.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get calendarDone;

  /// No description provided for @time.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get time;

  /// No description provided for @reminder.
  ///
  /// In fr, this message translates to:
  /// **'Rappel'**
  String get reminder;

  /// No description provided for @reminderForBoth.
  ///
  /// In fr, this message translates to:
  /// **'Une notification pour toi et {name}'**
  String reminderForBoth(String name);

  /// No description provided for @reminderForYou.
  ///
  /// In fr, this message translates to:
  /// **'Une notification pour toi'**
  String get reminderForYou;

  /// No description provided for @remindMeOn.
  ///
  /// In fr, this message translates to:
  /// **'Me le rappeler'**
  String get remindMeOn;

  /// No description provided for @whoSeesIt.
  ///
  /// In fr, this message translates to:
  /// **'Qui la voit'**
  String get whoSeesIt;

  /// No description provided for @onlyMe.
  ///
  /// In fr, this message translates to:
  /// **'Juste moi'**
  String get onlyMe;

  /// No description provided for @personalNote.
  ///
  /// In fr, this message translates to:
  /// **'Note perso'**
  String get personalNote;

  /// No description provided for @personalList.
  ///
  /// In fr, this message translates to:
  /// **'Liste perso'**
  String get personalList;

  /// No description provided for @theHousehold.
  ///
  /// In fr, this message translates to:
  /// **'Le foyer'**
  String get theHousehold;

  /// No description provided for @partnerSeesItToo.
  ///
  /// In fr, this message translates to:
  /// **'{name} la voit aussi'**
  String partnerSeesItToo(String name);

  /// No description provided for @cantBeEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Ne peut pas être vide.'**
  String get cantBeEmpty;

  /// No description provided for @editField.
  ///
  /// In fr, this message translates to:
  /// **'Modifier : {label}'**
  String editField(String label);

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @undo.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get undo;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @markDone.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme fait'**
  String get markDone;

  /// No description provided for @markNotDone.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme à faire'**
  String get markNotDone;

  /// No description provided for @ok.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @continueLabel.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueLabel;

  /// No description provided for @create.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get create;

  /// No description provided for @later.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get later;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @you.
  ///
  /// In fr, this message translates to:
  /// **'toi'**
  String get you;

  /// No description provided for @youLabel.
  ///
  /// In fr, this message translates to:
  /// **'Toi'**
  String get youLabel;

  /// No description provided for @and.
  ///
  /// In fr, this message translates to:
  /// **' et '**
  String get and;

  /// No description provided for @editListTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la liste.'**
  String get editListTitle;

  /// No description provided for @newListTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle liste.'**
  String get newListTitle;

  /// No description provided for @createList.
  ///
  /// In fr, this message translates to:
  /// **'Créer la liste'**
  String get createList;

  /// No description provided for @changeIconAndColor.
  ///
  /// In fr, this message translates to:
  /// **'Changer l’icône et la couleur'**
  String get changeIconAndColor;

  /// No description provided for @listName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la liste'**
  String get listName;

  /// No description provided for @day.
  ///
  /// In fr, this message translates to:
  /// **'Jour'**
  String get day;

  /// No description provided for @dayHint.
  ///
  /// In fr, this message translates to:
  /// **'Apparaît dans Aujourd’hui et Demain'**
  String get dayHint;

  /// No description provided for @color.
  ///
  /// In fr, this message translates to:
  /// **'Couleur'**
  String get color;

  /// No description provided for @icon.
  ///
  /// In fr, this message translates to:
  /// **'Icône'**
  String get icon;

  /// No description provided for @newNoteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle note.'**
  String get newNoteTitle;

  /// No description provided for @createNote.
  ///
  /// In fr, this message translates to:
  /// **'Créer la note'**
  String get createNote;

  /// No description provided for @titleOptional.
  ///
  /// In fr, this message translates to:
  /// **'Titre (facultatif)'**
  String get titleOptional;

  /// No description provided for @makePersonalQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Passer en perso ?'**
  String get makePersonalQuestion;

  /// No description provided for @shareListQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Partager la liste ?'**
  String get shareListQuestion;

  /// No description provided for @shareNoteQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Partager la note ?'**
  String get shareNoteQuestion;

  /// No description provided for @makePersonal.
  ///
  /// In fr, this message translates to:
  /// **'Passer en perso'**
  String get makePersonal;

  /// No description provided for @share.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get share;

  /// No description provided for @partnerWontSee.
  ///
  /// In fr, this message translates to:
  /// **'{name} ne verra plus « {item} ».'**
  String partnerWontSee(String name, String item);

  /// No description provided for @partnerWillSee.
  ///
  /// In fr, this message translates to:
  /// **'{name} verra « {item} » et pourra la modifier.'**
  String partnerWillSee(String name, String item);

  /// No description provided for @inviteResentStatus.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyée'**
  String get inviteResentStatus;

  /// No description provided for @invitePendingStatus.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get invitePendingStatus;

  /// No description provided for @inviteCode.
  ///
  /// In fr, this message translates to:
  /// **'Code à partager : {code}'**
  String inviteCode(String code);

  /// No description provided for @copyCode.
  ///
  /// In fr, this message translates to:
  /// **'Copier le code'**
  String get copyCode;

  /// No description provided for @codeCopied.
  ///
  /// In fr, this message translates to:
  /// **'Code copié'**
  String get codeCopied;

  /// No description provided for @resend.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer'**
  String get resend;

  /// No description provided for @invalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Cette adresse ne semble pas valide'**
  String get invalidEmail;

  /// No description provided for @inviteEmailHelp.
  ///
  /// In fr, this message translates to:
  /// **'Envoie-lui le code ci-dessus : il suffit de le saisir dans Picnote, via « J’ai une invitation ».'**
  String get inviteEmailHelp;

  /// No description provided for @theirEmail.
  ///
  /// In fr, this message translates to:
  /// **'Son adresse e-mail'**
  String get theirEmail;

  /// No description provided for @inviteSomeoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Inviter quelqu’un.'**
  String get inviteSomeoneTitle;

  /// No description provided for @inviteSentSub.
  ///
  /// In fr, this message translates to:
  /// **'L’autre a 7 jours pour rejoindre {household}.'**
  String inviteSentSub(String household);

  /// No description provided for @inviteSub.
  ///
  /// In fr, this message translates to:
  /// **'Saisis son adresse e-mail. On lui envoie un lien pour rejoindre {household}.'**
  String inviteSub(String household);

  /// No description provided for @sendInvitation.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer l’invitation'**
  String get sendInvitation;

  /// No description provided for @inviteSomeone.
  ///
  /// In fr, this message translates to:
  /// **'Inviter quelqu’un'**
  String get inviteSomeone;

  /// No description provided for @invite.
  ///
  /// In fr, this message translates to:
  /// **'Inviter'**
  String get invite;

  /// No description provided for @welcomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour,'**
  String get welcomeTitle;

  /// No description provided for @welcomeSub.
  ///
  /// In fr, this message translates to:
  /// **'Tes listes et tes notes, pour toi ou à partager avec ton foyer.'**
  String get welcomeSub;

  /// No description provided for @continueWithEmail.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec un e-mail'**
  String get continueWithEmail;

  /// No description provided for @emailTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton adresse e-mail ?'**
  String get emailTitle;

  /// No description provided for @emailSub.
  ///
  /// In fr, this message translates to:
  /// **'On t’envoie un code. Aucun mot de passe à retenir.'**
  String get emailSub;

  /// No description provided for @emailHint.
  ///
  /// In fr, this message translates to:
  /// **'email@exemple.fr'**
  String get emailHint;

  /// No description provided for @offlineTryAgain.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion, réessaie quand tu seras en ligne'**
  String get offlineTryAgain;

  /// No description provided for @codeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Regarde tes e-mails.'**
  String get codeTitle;

  /// No description provided for @codeSentTo.
  ///
  /// In fr, this message translates to:
  /// **'Code à 6 chiffres envoyé à '**
  String get codeSentTo;

  /// No description provided for @codeFieldLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code à 6 chiffres'**
  String get codeFieldLabel;

  /// No description provided for @codeWrong.
  ///
  /// In fr, this message translates to:
  /// **'Ce code ne correspond pas, vérifie ton email'**
  String get codeWrong;

  /// No description provided for @codeExpired.
  ///
  /// In fr, this message translates to:
  /// **'Ce code a expiré'**
  String get codeExpired;

  /// No description provided for @getNewCode.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir un nouveau code'**
  String get getNewCode;

  /// No description provided for @codeLocked.
  ///
  /// In fr, this message translates to:
  /// **'Trop d’essais, réessaie dans quelques minutes'**
  String get codeLocked;

  /// No description provided for @changeEmail.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l’email'**
  String get changeEmail;

  /// No description provided for @resendIn.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer dans {seconds} s'**
  String resendIn(int seconds);

  /// No description provided for @resendCode.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get resendCode;

  /// No description provided for @checkSpam.
  ///
  /// In fr, this message translates to:
  /// **'Rien reçu ? Regarde dans tes spams.'**
  String get checkSpam;

  /// No description provided for @nameTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment on t’appelle ?'**
  String get nameTitle;

  /// No description provided for @firstName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get firstName;

  /// No description provided for @avatarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ta couleur.'**
  String get avatarTitle;

  /// No description provided for @avatarSub.
  ///
  /// In fr, this message translates to:
  /// **'Elle s’affiche à côté de tout ce que tu ajoutes ou coches.'**
  String get avatarSub;

  /// No description provided for @householdTitle.
  ///
  /// In fr, this message translates to:
  /// **'C’est pour qui ?'**
  String get householdTitle;

  /// No description provided for @householdSub.
  ///
  /// In fr, this message translates to:
  /// **'Commence de ton côté ou à deux. Tu pourras inviter quelqu’un plus tard.'**
  String get householdSub;

  /// No description provided for @justMe.
  ///
  /// In fr, this message translates to:
  /// **'Pour moi'**
  String get justMe;

  /// No description provided for @justMeSub.
  ///
  /// In fr, this message translates to:
  /// **'Tes listes et notes, rien qu’à toi'**
  String get justMeSub;

  /// No description provided for @twoOfUs.
  ///
  /// In fr, this message translates to:
  /// **'À deux'**
  String get twoOfUs;

  /// No description provided for @twoOfUsSub.
  ///
  /// In fr, this message translates to:
  /// **'Crée le foyer et invite l’autre'**
  String get twoOfUsSub;

  /// No description provided for @haveInvitation.
  ///
  /// In fr, this message translates to:
  /// **'J’ai une invitation'**
  String get haveInvitation;

  /// No description provided for @createTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nomme ton foyer.'**
  String get createTitle;

  /// No description provided for @createSubSolo.
  ///
  /// In fr, this message translates to:
  /// **'Il sera prêt le jour où tu invites quelqu’un.'**
  String get createSubSolo;

  /// No description provided for @createSubDuo.
  ///
  /// In fr, this message translates to:
  /// **'L’autre verra ce nom dans l’invitation.'**
  String get createSubDuo;

  /// No description provided for @householdNameHint.
  ///
  /// In fr, this message translates to:
  /// **'ex. L’appart'**
  String get householdNameHint;

  /// No description provided for @youAreTwo.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes deux.'**
  String get youAreTwo;

  /// No description provided for @partnerJoinedHousehold.
  ///
  /// In fr, this message translates to:
  /// **'{name} a rejoint ton foyer.'**
  String partnerJoinedHousehold(String name);

  /// No description provided for @seeMyLists.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes listes'**
  String get seeMyLists;

  /// No description provided for @invitationSent.
  ///
  /// In fr, this message translates to:
  /// **'Invitation envoyée.'**
  String get invitationSent;

  /// No description provided for @inviteTheOther.
  ///
  /// In fr, this message translates to:
  /// **'Invite l’autre.'**
  String get inviteTheOther;

  /// No description provided for @joinCodeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton code d’invitation.'**
  String get joinCodeTitle;

  /// No description provided for @joinCodeSub.
  ///
  /// In fr, this message translates to:
  /// **'Les 6 caractères du code que l’autre personne t’a envoyé.'**
  String get joinCodeSub;

  /// No description provided for @inviteCodeFieldLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code d’invitation à 6 caractères'**
  String get inviteCodeFieldLabel;

  /// No description provided for @joinCodeInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Ce code n’est pas valide ou a expiré. Demande une nouvelle invitation.'**
  String get joinCodeInvalid;

  /// No description provided for @joinCodeChecking.
  ///
  /// In fr, this message translates to:
  /// **'Vérification du code…'**
  String get joinCodeChecking;

  /// No description provided for @joinCodeAlphabet.
  ///
  /// In fr, this message translates to:
  /// **'Lettres et chiffres, jamais de 0, O, 1 ou I.'**
  String get joinCodeAlphabet;

  /// No description provided for @householdFullTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ce foyer est complet.'**
  String get householdFullTitle;

  /// No description provided for @householdFullSub.
  ///
  /// In fr, this message translates to:
  /// **'Pour l’instant, un foyer compte 2 personnes au maximum. Tu peux créer le tien.'**
  String get householdFullSub;

  /// No description provided for @householdFullWho.
  ///
  /// In fr, this message translates to:
  /// **'{names}, 2 sur 2'**
  String householdFullWho(String names);

  /// No description provided for @createMyHousehold.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon foyer'**
  String get createMyHousehold;

  /// No description provided for @partnerInvitesYou.
  ///
  /// In fr, this message translates to:
  /// **'{name} t’invite.'**
  String partnerInvitesYou(String name);

  /// No description provided for @joinSub.
  ///
  /// In fr, this message translates to:
  /// **'Rejoins son foyer pour partager des listes et des notes avec {name}.'**
  String joinSub(String name);

  /// No description provided for @joinWho.
  ///
  /// In fr, this message translates to:
  /// **'{name}, et toi en rejoignant'**
  String joinWho(String name);

  /// No description provided for @colorTaken.
  ///
  /// In fr, this message translates to:
  /// **'{name} a déjà ta couleur. Choisis-en une autre :'**
  String colorTaken(String name);

  /// No description provided for @colorTakenShort.
  ///
  /// In fr, this message translates to:
  /// **'Couleur déjà prise'**
  String get colorTakenShort;

  /// No description provided for @joinHousehold.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre le foyer'**
  String get joinHousehold;

  /// No description provided for @tabLists.
  ///
  /// In fr, this message translates to:
  /// **'Listes'**
  String get tabLists;

  /// No description provided for @tabNotes.
  ///
  /// In fr, this message translates to:
  /// **'Notes'**
  String get tabNotes;

  /// No description provided for @newNote.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle note'**
  String get newNote;

  /// No description provided for @newList.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle liste'**
  String get newList;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settings;

  /// No description provided for @offline.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get offline;

  /// No description provided for @taskDeleted.
  ///
  /// In fr, this message translates to:
  /// **'« {title} » supprimé'**
  String taskDeleted(String title);

  /// No description provided for @greeting.
  ///
  /// In fr, this message translates to:
  /// **'Salut {name},'**
  String greeting(String name);

  /// No description provided for @shallWeStart.
  ///
  /// In fr, this message translates to:
  /// **'On commence ?'**
  String get shallWeStart;

  /// No description provided for @goodDay.
  ///
  /// In fr, this message translates to:
  /// **'Bonne journée ?'**
  String get goodDay;

  /// No description provided for @goodNight.
  ///
  /// In fr, this message translates to:
  /// **'Bonne soirée ?'**
  String get goodNight;

  /// No description provided for @todayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd’hui.'**
  String get todayTitle;

  /// No description provided for @tomorrowTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demain.'**
  String get tomorrowTitle;

  /// No description provided for @seeAllLists.
  ///
  /// In fr, this message translates to:
  /// **'Voir les {count} listes'**
  String seeAllLists(int count);

  /// No description provided for @nothingPlanned.
  ///
  /// In fr, this message translates to:
  /// **'Rien de prévu. Profites-en.'**
  String get nothingPlanned;

  /// No description provided for @firstListTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ta première liste.'**
  String get firstListTitle;

  /// No description provided for @firstListSub.
  ///
  /// In fr, this message translates to:
  /// **'Courses, maison, idées cadeaux : commence par ce que tu as en tête.'**
  String get firstListSub;

  /// No description provided for @createAList.
  ///
  /// In fr, this message translates to:
  /// **'Créer une liste'**
  String get createAList;

  /// No description provided for @justNow.
  ///
  /// In fr, this message translates to:
  /// **'à l’instant'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In fr, this message translates to:
  /// **'il y a {n} min'**
  String minutesAgo(int n);

  /// No description provided for @hoursAgo.
  ///
  /// In fr, this message translates to:
  /// **'il y a {n} h'**
  String hoursAgo(int n);

  /// No description provided for @yesterdayLower.
  ///
  /// In fr, this message translates to:
  /// **'hier'**
  String get yesterdayLower;

  /// No description provided for @noNotesYet.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de note. Touche + pour en créer une.'**
  String get noNotesYet;

  /// No description provided for @notesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notes.'**
  String get notesTitle;

  /// No description provided for @notesLede.
  ///
  /// In fr, this message translates to:
  /// **'Une idée à garder ?'**
  String get notesLede;

  /// No description provided for @untitled.
  ///
  /// In fr, this message translates to:
  /// **'Sans titre'**
  String get untitled;

  /// No description provided for @nowPersonalList.
  ///
  /// In fr, this message translates to:
  /// **'Liste passée en perso'**
  String get nowPersonalList;

  /// No description provided for @sharedWith.
  ///
  /// In fr, this message translates to:
  /// **'Partagée avec {name}'**
  String sharedWith(String name);

  /// No description provided for @listDeleted.
  ///
  /// In fr, this message translates to:
  /// **'{name} supprimée'**
  String listDeleted(String name);

  /// No description provided for @editList.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la liste'**
  String get editList;

  /// No description provided for @editListSub.
  ///
  /// In fr, this message translates to:
  /// **'Nom, couleur, icône, jour, rappel'**
  String get editListSub;

  /// No description provided for @inviteToShareList.
  ///
  /// In fr, this message translates to:
  /// **'Pour partager cette liste avec l’autre'**
  String get inviteToShareList;

  /// No description provided for @shareWithHousehold.
  ///
  /// In fr, this message translates to:
  /// **'Partager avec le foyer'**
  String get shareWithHousehold;

  /// No description provided for @onlyYouWillSee.
  ///
  /// In fr, this message translates to:
  /// **'Visible par toi uniquement'**
  String get onlyYouWillSee;

  /// No description provided for @partnerWillSeeAndEdit.
  ///
  /// In fr, this message translates to:
  /// **'{name} la verra et pourra la modifier'**
  String partnerWillSeeAndEdit(String name);

  /// No description provided for @deleteList.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la liste'**
  String get deleteList;

  /// No description provided for @deleteListSub.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Supprime 1 élément. Tu pourras annuler.} other{Supprime {count} éléments. Tu pourras annuler.}}'**
  String deleteListSub(int count);

  /// No description provided for @dragToReorder.
  ///
  /// In fr, this message translates to:
  /// **'Glisser pour déplacer'**
  String get dragToReorder;

  /// No description provided for @firstItemPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Écris ton premier élément…'**
  String get firstItemPlaceholder;

  /// No description provided for @addItem.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un élément'**
  String get addItem;

  /// No description provided for @doneSection.
  ///
  /// In fr, this message translates to:
  /// **'Fait'**
  String get doneSection;

  /// No description provided for @listHint.
  ///
  /// In fr, this message translates to:
  /// **'Touche un élément pour le modifier, glisse les points pour le déplacer, ou vers la gauche pour le supprimer.'**
  String get listHint;

  /// No description provided for @allLists.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les listes'**
  String get allLists;

  /// No description provided for @home.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get home;

  /// No description provided for @personalShareWith.
  ///
  /// In fr, this message translates to:
  /// **'Perso. Partager avec {name}'**
  String personalShareWith(String name);

  /// No description provided for @listOptions.
  ///
  /// In fr, this message translates to:
  /// **'Options de la liste'**
  String get listOptions;

  /// No description provided for @mascot.
  ///
  /// In fr, this message translates to:
  /// **'Mascotte'**
  String get mascot;

  /// No description provided for @sharedList.
  ///
  /// In fr, this message translates to:
  /// **'Liste partagée'**
  String get sharedList;

  /// No description provided for @personalListOnlyYou.
  ///
  /// In fr, this message translates to:
  /// **'Liste perso, visible par toi uniquement'**
  String get personalListOnlyYou;

  /// No description provided for @allListsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les listes.'**
  String get allListsTitle;

  /// No description provided for @noListsYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucune liste. Touche + pour en créer une.'**
  String get noListsYet;

  /// No description provided for @deleteNamed.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer {name}'**
  String deleteNamed(String name);

  /// No description provided for @nowPersonalNote.
  ///
  /// In fr, this message translates to:
  /// **'Note passée en perso'**
  String get nowPersonalNote;

  /// No description provided for @noteDeleted.
  ///
  /// In fr, this message translates to:
  /// **'{name} supprimée'**
  String noteDeleted(String name);

  /// No description provided for @lastEditedBy.
  ///
  /// In fr, this message translates to:
  /// **'Dernière modification par'**
  String get lastEditedBy;

  /// No description provided for @reminderOff.
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get reminderOff;

  /// No description provided for @inviteToShareNote.
  ///
  /// In fr, this message translates to:
  /// **'Pour partager cette note avec l’autre'**
  String get inviteToShareNote;

  /// No description provided for @deleteNote.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la note'**
  String get deleteNote;

  /// No description provided for @youCanUndo.
  ///
  /// In fr, this message translates to:
  /// **'Tu pourras annuler.'**
  String get youCanUndo;

  /// No description provided for @noteOptions.
  ///
  /// In fr, this message translates to:
  /// **'Options de la note'**
  String get noteOptions;

  /// No description provided for @sharedNote.
  ///
  /// In fr, this message translates to:
  /// **'Note partagée'**
  String get sharedNote;

  /// No description provided for @personalNoteOnlyYou.
  ///
  /// In fr, this message translates to:
  /// **'Note perso, visible par toi uniquement'**
  String get personalNoteOnlyYou;

  /// No description provided for @slashHint.
  ///
  /// In fr, this message translates to:
  /// **'Tape / pour ajouter un titre, une liste ou un lien.'**
  String get slashHint;

  /// No description provided for @reminderTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rappel.'**
  String get reminderTitle;

  /// No description provided for @removeReminder.
  ///
  /// In fr, this message translates to:
  /// **'Retirer le rappel'**
  String get removeReminder;

  /// No description provided for @reminderBothNotified.
  ///
  /// In fr, this message translates to:
  /// **'Toi et {name} recevez une notification.'**
  String reminderBothNotified(String name);

  /// No description provided for @blockText.
  ///
  /// In fr, this message translates to:
  /// **'Texte'**
  String get blockText;

  /// No description provided for @blockTextDesc.
  ///
  /// In fr, this message translates to:
  /// **'Écris, tout simplement'**
  String get blockTextDesc;

  /// No description provided for @blockHeading.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get blockHeading;

  /// No description provided for @blockHeadingDesc.
  ///
  /// In fr, this message translates to:
  /// **'Titre de section'**
  String get blockHeadingDesc;

  /// No description provided for @blockBullet.
  ///
  /// In fr, this message translates to:
  /// **'Liste à puces'**
  String get blockBullet;

  /// No description provided for @blockBulletDesc.
  ///
  /// In fr, this message translates to:
  /// **'Liste simple'**
  String get blockBulletDesc;

  /// No description provided for @blockCheckbox.
  ///
  /// In fr, this message translates to:
  /// **'Case à cocher'**
  String get blockCheckbox;

  /// No description provided for @blockCheckboxDesc.
  ///
  /// In fr, this message translates to:
  /// **'Choses à cocher'**
  String get blockCheckboxDesc;

  /// No description provided for @blockLink.
  ///
  /// In fr, this message translates to:
  /// **'Lien'**
  String get blockLink;

  /// No description provided for @blockLinkDesc.
  ///
  /// In fr, this message translates to:
  /// **'Colle une adresse web'**
  String get blockLinkDesc;

  /// No description provided for @formatBold.
  ///
  /// In fr, this message translates to:
  /// **'Gras'**
  String get formatBold;

  /// No description provided for @formatItalic.
  ///
  /// In fr, this message translates to:
  /// **'Italique'**
  String get formatItalic;

  /// No description provided for @formatUnderline.
  ///
  /// In fr, this message translates to:
  /// **'Souligné'**
  String get formatUnderline;

  /// No description provided for @blockListItem.
  ///
  /// In fr, this message translates to:
  /// **'Élément'**
  String get blockListItem;

  /// No description provided for @blockTodo.
  ///
  /// In fr, this message translates to:
  /// **'À faire'**
  String get blockTodo;

  /// No description provided for @blockLinkHint.
  ///
  /// In fr, this message translates to:
  /// **'Colle un lien'**
  String get blockLinkHint;

  /// No description provided for @blockTextHint.
  ///
  /// In fr, this message translates to:
  /// **'Tape / pour les blocs'**
  String get blockTextHint;

  /// No description provided for @noBlockNamed.
  ///
  /// In fr, this message translates to:
  /// **'Aucun bloc nommé « {query} »'**
  String noBlockNamed(String query);

  /// No description provided for @leaveHouseholdQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Quitter le foyer ?'**
  String get leaveHouseholdQuestion;

  /// No description provided for @leaveHousehold.
  ///
  /// In fr, this message translates to:
  /// **'Quitter le foyer'**
  String get leaveHousehold;

  /// No description provided for @sharedStayIn.
  ///
  /// In fr, this message translates to:
  /// **'Les listes et notes partagées restent dans {household} avec {name}.'**
  String sharedStayIn(String household, String name);

  /// No description provided for @lastMemberLeave.
  ///
  /// In fr, this message translates to:
  /// **'Tu es le dernier membre : {household} et toutes ses listes et notes seront supprimés définitivement.'**
  String lastMemberLeave(String household);

  /// No description provided for @keepAccount.
  ///
  /// In fr, this message translates to:
  /// **'Tu gardes ton compte et tu peux créer ou rejoindre un autre foyer.'**
  String get keepAccount;

  /// No description provided for @removeQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Retirer {name} ?'**
  String removeQuestion(String name);

  /// No description provided for @removeNamed.
  ///
  /// In fr, this message translates to:
  /// **'Retirer {name}'**
  String removeNamed(String name);

  /// No description provided for @loseAccess.
  ///
  /// In fr, this message translates to:
  /// **'{name} n’a plus accès à {household}.'**
  String loseAccess(String name, String household);

  /// No description provided for @sharedStayInHousehold.
  ///
  /// In fr, this message translates to:
  /// **'Les listes et notes partagées restent dans le foyer.'**
  String get sharedStayInHousehold;

  /// No description provided for @wasRemoved.
  ///
  /// In fr, this message translates to:
  /// **'{name} a été retiré'**
  String wasRemoved(String name);

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réglages.'**
  String get settingsTitle;

  /// No description provided for @myAccount.
  ///
  /// In fr, this message translates to:
  /// **'Mon compte'**
  String get myAccount;

  /// No description provided for @householdSection.
  ///
  /// In fr, this message translates to:
  /// **'Foyer.'**
  String get householdSection;

  /// No description provided for @householdName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du foyer'**
  String get householdName;

  /// No description provided for @householdRenamed.
  ///
  /// In fr, this message translates to:
  /// **'Foyer renommé'**
  String get householdRenamed;

  /// No description provided for @justYouForNow.
  ///
  /// In fr, this message translates to:
  /// **'Juste toi pour l’instant'**
  String get justYouForNow;

  /// No description provided for @member.
  ///
  /// In fr, this message translates to:
  /// **'Membre'**
  String get member;

  /// No description provided for @remove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get remove;

  /// No description provided for @invitationResent.
  ///
  /// In fr, this message translates to:
  /// **'Invitation renvoyée'**
  String get invitationResent;

  /// No description provided for @invitationCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Invitation annulée'**
  String get invitationCancelled;

  /// No description provided for @inviteSomeoneSub.
  ///
  /// In fr, this message translates to:
  /// **'Par e-mail, pour partager listes et notes'**
  String get inviteSomeoneSub;

  /// No description provided for @householdFullNote.
  ///
  /// In fr, this message translates to:
  /// **'Ton foyer est complet : 2 membres au maximum pour l’instant.'**
  String get householdFullNote;

  /// No description provided for @notificationsSection.
  ///
  /// In fr, this message translates to:
  /// **'Notifications.'**
  String get notificationsSection;

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsOnAt.
  ///
  /// In fr, this message translates to:
  /// **'Activées, rappels à {time}'**
  String notificationsOnAt(String time);

  /// No description provided for @notificationsOff.
  ///
  /// In fr, this message translates to:
  /// **'Coupées'**
  String get notificationsOff;

  /// No description provided for @aboutSection.
  ///
  /// In fr, this message translates to:
  /// **'À propos.'**
  String get aboutSection;

  /// No description provided for @termsOfUse.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d’utilisation'**
  String get termsOfUse;

  /// No description provided for @privacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité'**
  String get privacyPolicy;

  /// No description provided for @contactAndBugs.
  ///
  /// In fr, this message translates to:
  /// **'Contact et bugs'**
  String get contactAndBugs;

  /// No description provided for @opensInBrowser.
  ///
  /// In fr, this message translates to:
  /// **'S’ouvre dans ton navigateur'**
  String get opensInBrowser;

  /// No description provided for @opensMailApp.
  ///
  /// In fr, this message translates to:
  /// **'Ouvre ton app e-mail'**
  String get opensMailApp;

  /// No description provided for @aboutFooter.
  ///
  /// In fr, this message translates to:
  /// **'Picnote 1.0.0. L’apparence et la langue suivent les réglages du téléphone.'**
  String get aboutFooter;

  /// No description provided for @deletionCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Suppression annulée.'**
  String get deletionCancelled;

  /// No description provided for @deletionBanner.
  ///
  /// In fr, this message translates to:
  /// **'Ton compte sera supprimé le {date}. D’ici là, tu peux changer d’avis.'**
  String deletionBanner(String date);

  /// No description provided for @cancelDeletion.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la suppression'**
  String get cancelDeletion;

  /// No description provided for @personalBothDeleted.
  ///
  /// In fr, this message translates to:
  /// **'{lists, plural, =1{Ta liste} other{Tes {lists} listes}} et {notes, plural, =1{ta note} other{tes {notes} notes}} perso seront supprimées.'**
  String personalBothDeleted(int lists, int notes);

  /// No description provided for @personalListsDeleted.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Ta liste perso sera supprimée.} other{Tes {count} listes perso seront supprimées.}}'**
  String personalListsDeleted(int count);

  /// No description provided for @personalNotesDeleted.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Ta note perso sera supprimée.} other{Tes {count} notes perso seront supprimées.}}'**
  String personalNotesDeleted(int count);

  /// No description provided for @deleteAccountQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ton compte ?'**
  String get deleteAccountQuestion;

  /// No description provided for @deleteMyAccount.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get deleteMyAccount;

  /// No description provided for @accountDeletedOn.
  ///
  /// In fr, this message translates to:
  /// **'Ton compte sera supprimé le {date}'**
  String accountDeletedOn(String date);

  /// No description provided for @lastMemberDelete.
  ///
  /// In fr, this message translates to:
  /// **'Tu es le dernier membre : {household} et tout son contenu seront supprimés aussi.'**
  String lastMemberDelete(String household);

  /// No description provided for @deactivatedFor15Days.
  ///
  /// In fr, this message translates to:
  /// **'Ton compte est désactivé pendant 15 jours, puis effacé définitivement. Reconnecte-toi d’ici là pour changer d’avis.'**
  String get deactivatedFor15Days;

  /// No description provided for @accountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte.'**
  String get accountTitle;

  /// No description provided for @avatarColor.
  ///
  /// In fr, this message translates to:
  /// **'Couleur de l’avatar'**
  String get avatarColor;

  /// No description provided for @colorShownTo.
  ///
  /// In fr, this message translates to:
  /// **'{name} voit cette couleur à côté de ce que tu modifies.'**
  String colorShownTo(String name);

  /// No description provided for @colorShown.
  ///
  /// In fr, this message translates to:
  /// **'Cette couleur s’affiche à côté de ce que tu modifies.'**
  String get colorShown;

  /// No description provided for @profileSection.
  ///
  /// In fr, this message translates to:
  /// **'Profil.'**
  String get profileSection;

  /// No description provided for @firstNameSaved.
  ///
  /// In fr, this message translates to:
  /// **'Prénom enregistré'**
  String get firstNameSaved;

  /// No description provided for @signInSection.
  ///
  /// In fr, this message translates to:
  /// **'Connexion.'**
  String get signInSection;

  /// No description provided for @codeByEmail.
  ///
  /// In fr, this message translates to:
  /// **'Code par e-mail'**
  String get codeByEmail;

  /// No description provided for @codeByEmailSub.
  ///
  /// In fr, this message translates to:
  /// **'Pas de mot de passe : un code à 6 chiffres à chaque fois'**
  String get codeByEmailSub;

  /// No description provided for @logOut.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logOut;

  /// No description provided for @fifteenDays.
  ///
  /// In fr, this message translates to:
  /// **'15 jours pour changer d’avis'**
  String get fifteenDays;

  /// No description provided for @notificationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications.'**
  String get notificationsTitle;

  /// No description provided for @generalSection.
  ///
  /// In fr, this message translates to:
  /// **'Général.'**
  String get generalSection;

  /// No description provided for @allowNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser les notifications'**
  String get allowNotifications;

  /// No description provided for @allowNotificationsOn.
  ///
  /// In fr, this message translates to:
  /// **'Rappels et activité du foyer'**
  String get allowNotificationsOn;

  /// No description provided for @allowNotificationsOff.
  ///
  /// In fr, this message translates to:
  /// **'Coupées : ni rappels ni alertes'**
  String get allowNotificationsOff;

  /// No description provided for @remindersSection.
  ///
  /// In fr, this message translates to:
  /// **'Rappels.'**
  String get remindersSection;

  /// No description provided for @dailyReminders.
  ///
  /// In fr, this message translates to:
  /// **'Ce qu’il reste à faire'**
  String get dailyReminders;

  /// No description provided for @dailyRemindersSub.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les 3 h de 9 h à 21 h, s’il reste des choses pour aujourd’hui ou demain'**
  String get dailyRemindersSub;

  /// No description provided for @defaultTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure par défaut'**
  String get defaultTime;

  /// No description provided for @defaultTimeSub.
  ///
  /// In fr, this message translates to:
  /// **'Proposée quand tu ajoutes un rappel'**
  String get defaultTimeSub;

  /// No description provided for @whenPartnerEdits.
  ///
  /// In fr, this message translates to:
  /// **'Quand {name} coche ou modifie'**
  String whenPartnerEdits(String name);

  /// No description provided for @eachTime.
  ///
  /// In fr, this message translates to:
  /// **'Une notification à chaque fois'**
  String get eachTime;

  /// No description provided for @phoneNotificationSettings.
  ///
  /// In fr, this message translates to:
  /// **'Tu peux aussi gérer Picnote dans les réglages de notifications du téléphone.'**
  String get phoneNotificationSettings;

  /// No description provided for @visibilityShared.
  ///
  /// In fr, this message translates to:
  /// **'Partagée'**
  String get visibilityShared;

  /// No description provided for @noDeadline.
  ///
  /// In fr, this message translates to:
  /// **'Non due'**
  String get noDeadline;

  /// No description provided for @noReminder.
  ///
  /// In fr, this message translates to:
  /// **'Pas de rappel'**
  String get noReminder;

  /// No description provided for @editNoteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la note.'**
  String get editNoteTitle;

  /// No description provided for @editNote.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la note'**
  String get editNote;

  /// No description provided for @whoSeesItTitle.
  ///
  /// In fr, this message translates to:
  /// **'Qui la voit.'**
  String get whoSeesItTitle;

  /// No description provided for @deadlineTitle.
  ///
  /// In fr, this message translates to:
  /// **'Échéance.'**
  String get deadlineTitle;

  /// No description provided for @deadline.
  ///
  /// In fr, this message translates to:
  /// **'Échéance'**
  String get deadline;

  /// No description provided for @removeDeadline.
  ///
  /// In fr, this message translates to:
  /// **'Retirer l’échéance'**
  String get removeDeadline;

  /// No description provided for @reminderOnlyYou.
  ///
  /// In fr, this message translates to:
  /// **'Toi seul reçois une notification.'**
  String get reminderOnlyYou;

  /// No description provided for @defaultListName.
  ///
  /// In fr, this message translates to:
  /// **'Liste'**
  String get defaultListName;

  /// No description provided for @renameList.
  ///
  /// In fr, this message translates to:
  /// **'Renommer la liste'**
  String get renameList;

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @householdAndSettings.
  ///
  /// In fr, this message translates to:
  /// **'Foyer et réglages'**
  String get householdAndSettings;

  /// No description provided for @whosHere.
  ///
  /// In fr, this message translates to:
  /// **'Qui est là'**
  String get whosHere;

  /// No description provided for @memberYou.
  ///
  /// In fr, this message translates to:
  /// **'{name} (toi)'**
  String memberYou(String name);

  /// No description provided for @quoted.
  ///
  /// In fr, this message translates to:
  /// **'« {item} »'**
  String quoted(String item);

  /// No description provided for @aListLower.
  ///
  /// In fr, this message translates to:
  /// **'une liste'**
  String get aListLower;

  /// No description provided for @aNoteLower.
  ///
  /// In fr, this message translates to:
  /// **'une note'**
  String get aNoteLower;

  /// No description provided for @youEditedAgo.
  ///
  /// In fr, this message translates to:
  /// **'Tu as modifié {what}, {ago}'**
  String youEditedAgo(String what, String ago);

  /// No description provided for @theyEditedAgo.
  ///
  /// In fr, this message translates to:
  /// **'A modifié {what}, {ago}'**
  String theyEditedAgo(String what, String ago);

  /// No description provided for @nothingChangedYet.
  ///
  /// In fr, this message translates to:
  /// **'Rien de modifié pour l’instant'**
  String get nothingChangedYet;

  /// No description provided for @pinnedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Épinglées.'**
  String get pinnedTitle;

  /// No description provided for @otherListsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Autres listes.'**
  String get otherListsTitle;

  /// No description provided for @pinHint.
  ///
  /// In fr, this message translates to:
  /// **'Épingle jusqu’à 4 listes pour les voir sur l’accueil.'**
  String get pinHint;

  /// No description provided for @homeFull.
  ///
  /// In fr, this message translates to:
  /// **'L’accueil est plein. Retire une liste pour en épingler une autre.'**
  String get homeFull;

  /// No description provided for @pinNamed.
  ///
  /// In fr, this message translates to:
  /// **'Épingler {name}'**
  String pinNamed(String name);

  /// No description provided for @unpinNamed.
  ///
  /// In fr, this message translates to:
  /// **'Désépingler {name}'**
  String unpinNamed(String name);

  /// No description provided for @latestChanges.
  ///
  /// In fr, this message translates to:
  /// **'Dernières modifs'**
  String get latestChanges;

  /// No description provided for @toShareThisList.
  ///
  /// In fr, this message translates to:
  /// **'Pour partager cette liste'**
  String get toShareThisList;

  /// No description provided for @toShareThisNote.
  ///
  /// In fr, this message translates to:
  /// **'Pour partager cette note'**
  String get toShareThisNote;

  /// No description provided for @theListLower.
  ///
  /// In fr, this message translates to:
  /// **'la liste'**
  String get theListLower;

  /// No description provided for @theNoteLower.
  ///
  /// In fr, this message translates to:
  /// **'la note'**
  String get theNoteLower;

  /// No description provided for @logByYou.
  ///
  /// In fr, this message translates to:
  /// **'{verb, select, check{Tu as coché} uncheck{Tu as décoché} add{Tu as ajouté} edit{Tu as modifié} del{Tu as supprimé} other{Tu as créé}} {what}'**
  String logByYou(String verb, String what);

  /// No description provided for @logByName.
  ///
  /// In fr, this message translates to:
  /// **'{name} {verb, select, check{a coché} uncheck{a décoché} add{a ajouté} edit{a modifié} del{a supprimé} other{a créé}} {what}'**
  String logByName(String name, String verb, String what);

  /// No description provided for @logSolo.
  ///
  /// In fr, this message translates to:
  /// **'{verb, select, check{Coché} uncheck{Décoché} add{Ajouté} edit{Modifié} del{Supprimé} other{Créé}} {what}'**
  String logSolo(String verb, String what);

  /// No description provided for @logSoloList.
  ///
  /// In fr, this message translates to:
  /// **'{verb, select, edit{Liste modifiée} other{Liste créée}}'**
  String logSoloList(String verb);

  /// No description provided for @logSoloNote.
  ///
  /// In fr, this message translates to:
  /// **'{verb, select, edit{Note modifiée} other{Note créée}}'**
  String logSoloNote(String verb);

  /// No description provided for @listDoneUnpin.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » est terminée. La désépingler ?'**
  String listDoneUnpin(String name);

  /// No description provided for @unpin.
  ///
  /// In fr, this message translates to:
  /// **'Désépingler'**
  String get unpin;

  /// No description provided for @partnerCreatedList.
  ///
  /// In fr, this message translates to:
  /// **'{who} a créé la liste « {name} »'**
  String partnerCreatedList(String who, String name);

  /// No description provided for @partnerCreatedNote.
  ///
  /// In fr, this message translates to:
  /// **'{who} a créé la note « {name} »'**
  String partnerCreatedNote(String who, String name);

  /// No description provided for @see.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get see;

  /// No description provided for @isTyping.
  ///
  /// In fr, this message translates to:
  /// **'{name} écrit…'**
  String isTyping(String name);

  /// No description provided for @tableTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tableau.'**
  String get tableTitle;

  /// No description provided for @tableRemoveColumn.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la colonne'**
  String get tableRemoveColumn;

  /// No description provided for @tableRemoveRow.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la ligne'**
  String get tableRemoveRow;

  /// No description provided for @tableHeaderHint.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get tableHeaderHint;

  /// No description provided for @tableAddRow.
  ///
  /// In fr, this message translates to:
  /// **'+ Ligne'**
  String get tableAddRow;

  /// No description provided for @tableAddColumn.
  ///
  /// In fr, this message translates to:
  /// **'+ Colonne'**
  String get tableAddColumn;

  /// No description provided for @blockTable.
  ///
  /// In fr, this message translates to:
  /// **'Tableau'**
  String get blockTable;

  /// No description provided for @blockTableDesc.
  ///
  /// In fr, this message translates to:
  /// **'Lignes et colonnes'**
  String get blockTableDesc;

  /// No description provided for @blockHeadingLevel.
  ///
  /// In fr, this message translates to:
  /// **'Titre {level}'**
  String blockHeadingLevel(int level);

  /// No description provided for @formatHeading.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get formatHeading;

  /// No description provided for @headingColor.
  ///
  /// In fr, this message translates to:
  /// **'Couleur du titre'**
  String get headingColor;

  /// No description provided for @headingColorName.
  ///
  /// In fr, this message translates to:
  /// **'{color, select, terra{Terracotta} sage{Vert} mustard{Moutarde} rose{Rouge} cocoa{Marron} grey{Gris} other{Noir}}'**
  String headingColorName(String color);

  /// No description provided for @formatUndo.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get formatUndo;

  /// No description provided for @formatRedo.
  ///
  /// In fr, this message translates to:
  /// **'Rétablir'**
  String get formatRedo;

  /// No description provided for @createdBy.
  ///
  /// In fr, this message translates to:
  /// **'Créée par {name}'**
  String createdBy(String name);

  /// No description provided for @createdByYou.
  ///
  /// In fr, this message translates to:
  /// **'Créée par toi'**
  String get createdByYou;

  /// No description provided for @askAuthor.
  ///
  /// In fr, this message translates to:
  /// **'Pour la passer en perso ou la supprimer, demande à {name}.'**
  String askAuthor(String name);

  /// No description provided for @pinToHome.
  ///
  /// In fr, this message translates to:
  /// **'Épingler sur l’accueil'**
  String get pinToHome;

  /// No description provided for @unpinFromHome.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de l’accueil'**
  String get unpinFromHome;

  /// No description provided for @pinnedToHome.
  ///
  /// In fr, this message translates to:
  /// **'Liste épinglée sur l’accueil'**
  String get pinnedToHome;

  /// No description provided for @unpinnedFromHome.
  ///
  /// In fr, this message translates to:
  /// **'Liste retirée de l’accueil'**
  String get unpinnedFromHome;

  /// No description provided for @partnerEditedList.
  ///
  /// In fr, this message translates to:
  /// **'{who} a modifié la liste « {name} »'**
  String partnerEditedList(String who, String name);

  /// No description provided for @partnerEditedNote.
  ///
  /// In fr, this message translates to:
  /// **'{who} a modifié la note « {name} »'**
  String partnerEditedNote(String who, String name);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
