// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PICNOTE.';

  @override
  String get appName => 'Picnote';

  @override
  String get listEmpty => 'Empty';

  @override
  String listRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count left',
      one: '1 left',
      zero: 'All done',
    );
    return '$_temp0';
  }

  @override
  String get listPersonal => 'Only you';

  @override
  String get homeLoadError => 'Couldn’t load your lists';

  @override
  String get tryAgain => 'Try again';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get yesterday => 'Yesterday';

  @override
  String inDays(int n) {
    return 'in $n days';
  }

  @override
  String reminderAt(String date, String time) {
    return '$date at $time';
  }

  @override
  String get dateNone => 'None';

  @override
  String get dateThisWeekend => 'This weekend';

  @override
  String get dateNextWeek => 'Next week';

  @override
  String get datePick => 'Pick a date';

  @override
  String get optional => 'Optional';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get datePickDay => 'Pick a day';

  @override
  String get calendarDone => 'Done';

  @override
  String get time => 'Time';

  @override
  String get reminder => 'Reminder';

  @override
  String reminderForBoth(String name) {
    return 'A notification for you and $name';
  }

  @override
  String get reminderForYou => 'A notification for you';

  @override
  String get remindMeOn => 'Remind me on';

  @override
  String get whoSeesIt => 'Who sees it';

  @override
  String get onlyMe => 'Only me';

  @override
  String get personalNote => 'Personal note';

  @override
  String get personalList => 'Personal list';

  @override
  String get theHousehold => 'Household';

  @override
  String partnerSeesItToo(String name) {
    return '$name sees it too';
  }

  @override
  String get cantBeEmpty => 'Can’t be empty.';

  @override
  String editField(String label) {
    return 'Edit $label';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get undo => 'Undo';

  @override
  String get delete => 'Delete';

  @override
  String get markDone => 'Mark as done';

  @override
  String get markNotDone => 'Mark as not done';

  @override
  String get ok => 'Done';

  @override
  String get back => 'Back';

  @override
  String get continueLabel => 'Continue';

  @override
  String get create => 'Create';

  @override
  String get later => 'Later';

  @override
  String get edit => 'Edit';

  @override
  String get you => 'you';

  @override
  String get youLabel => 'You';

  @override
  String get and => ' and ';

  @override
  String get editListTitle => 'Edit list.';

  @override
  String get newListTitle => 'New list.';

  @override
  String get createList => 'Create list';

  @override
  String get changeIconAndColor => 'Change icon and color';

  @override
  String get listName => 'List name';

  @override
  String get day => 'Day';

  @override
  String get dayHint => 'Shows in Today and Tomorrow';

  @override
  String get color => 'Color';

  @override
  String get icon => 'Icon';

  @override
  String get newNoteTitle => 'New note.';

  @override
  String get createNote => 'Create note';

  @override
  String get titleOptional => 'Title (optional)';

  @override
  String get makePersonalQuestion => 'Make it personal?';

  @override
  String get shareListQuestion => 'Share this list?';

  @override
  String get shareNoteQuestion => 'Share this note?';

  @override
  String get makePersonal => 'Make it personal';

  @override
  String get share => 'Share';

  @override
  String partnerWontSee(String name, String item) {
    return '$name won’t see “$item” any more.';
  }

  @override
  String partnerWillSee(String name, String item) {
    return '$name will see “$item” and can edit it.';
  }

  @override
  String get inviteResentStatus => 'Sent again';

  @override
  String get invitePendingStatus => 'Pending';

  @override
  String inviteCode(String code) {
    return 'Code to share: $code';
  }

  @override
  String get copyCode => 'Copy code';

  @override
  String get codeCopied => 'Code copied';

  @override
  String get resend => 'Resend';

  @override
  String get invalidEmail => 'This address doesn’t look valid';

  @override
  String get inviteEmailHelp =>
      'Send them the code above: they type it in Picnote via “I have an invitation”.';

  @override
  String get theirEmail => 'Their email';

  @override
  String get inviteSomeoneTitle => 'Invite someone.';

  @override
  String inviteSentSub(String household) {
    return 'They have 7 days to join $household.';
  }

  @override
  String inviteSub(String household) {
    return 'Enter their email. We’ll send a link to join $household.';
  }

  @override
  String get sendInvitation => 'Send the invitation';

  @override
  String get inviteSomeone => 'Invite someone';

  @override
  String get invite => 'Invite';

  @override
  String get welcomeTitle => 'Hi there,';

  @override
  String get welcomeSub =>
      'Your lists and notes, just for you or shared with your household.';

  @override
  String get continueWithEmail => 'Continue with email';

  @override
  String get emailTitle => 'What’s your email?';

  @override
  String get emailSub => 'We’ll send you a code. No password to remember.';

  @override
  String get emailHint => 'email@example.com';

  @override
  String get offlineTryAgain => 'No connection, try again once you’re online';

  @override
  String get codeTitle => 'Check your inbox.';

  @override
  String get codeSentTo => 'We sent a 6-digit code to ';

  @override
  String get codeFieldLabel => '6-digit code';

  @override
  String get codeWrong => 'This code doesn’t match, check your email';

  @override
  String get codeExpired => 'This code has expired';

  @override
  String get getNewCode => 'Get a new code';

  @override
  String get codeLocked => 'Too many tries, try again in a few minutes';

  @override
  String get changeEmail => 'Change email';

  @override
  String resendIn(int seconds) {
    return 'Resend in $seconds s';
  }

  @override
  String get resendCode => 'Resend code';

  @override
  String get checkSpam => 'Nothing yet? Check your spam folder.';

  @override
  String get nameTitle => 'What should we call you?';

  @override
  String get firstName => 'First name';

  @override
  String get avatarTitle => 'Pick your color.';

  @override
  String get avatarSub => 'It shows next to everything you add or check.';

  @override
  String get householdTitle => 'Who is it for?';

  @override
  String get householdSub =>
      'Start on your own or as a pair. You can invite someone later.';

  @override
  String get justMe => 'Just me';

  @override
  String get justMeSub => 'Your lists and notes, all yours';

  @override
  String get twoOfUs => 'The two of us';

  @override
  String get twoOfUsSub => 'Create the household, invite the other';

  @override
  String get haveInvitation => 'I have an invitation';

  @override
  String get createTitle => 'Name your household.';

  @override
  String get createSubSolo => 'It’s ready for whenever you invite someone.';

  @override
  String get createSubDuo => 'The other will see this name in the invitation.';

  @override
  String get householdNameHint => 'e.g. The flat';

  @override
  String get youAreTwo => 'You’re two now.';

  @override
  String partnerJoinedHousehold(String name) {
    return '$name joined your household.';
  }

  @override
  String get seeMyLists => 'Go to my lists';

  @override
  String get invitationSent => 'Invitation sent.';

  @override
  String get inviteTheOther => 'Invite the other.';

  @override
  String get joinCodeTitle => 'Your invite code.';

  @override
  String get joinCodeSub => 'The 6 characters the other person sent you.';

  @override
  String get inviteCodeFieldLabel => '6-character invite code';

  @override
  String get joinCodeInvalid =>
      'This code is invalid or has expired. Ask for a new invitation.';

  @override
  String get joinCodeChecking => 'Checking the code…';

  @override
  String get joinCodeAlphabet => 'Letters and numbers, never 0, O, 1 or I.';

  @override
  String get householdFullTitle => 'This household is full.';

  @override
  String get householdFullSub =>
      'For now, a household holds 2 people at most. You can create your own.';

  @override
  String householdFullWho(String names) {
    return '$names, 2 of 2';
  }

  @override
  String get createMyHousehold => 'Create my household';

  @override
  String partnerInvitesYou(String name) {
    return '$name invites you.';
  }

  @override
  String joinSub(String name) {
    return 'Join the household to share lists and notes with $name.';
  }

  @override
  String joinWho(String name) {
    return '$name, and you once you join';
  }

  @override
  String colorTaken(String name) {
    return '$name already has your color. Pick another one:';
  }

  @override
  String get colorTakenShort => 'Color taken';

  @override
  String get joinHousehold => 'Join the household';

  @override
  String get tabLists => 'Lists';

  @override
  String get tabNotes => 'Notes';

  @override
  String get newNote => 'New note';

  @override
  String get newList => 'New list';

  @override
  String get settings => 'Settings';

  @override
  String get offline => 'Offline';

  @override
  String taskDeleted(String title) {
    return '“$title” deleted';
  }

  @override
  String greeting(String name) {
    return 'Hi $name,';
  }

  @override
  String get shallWeStart => 'Shall we start?';

  @override
  String get goodDay => 'Having a good day?';

  @override
  String get goodNight => 'Having a good night?';

  @override
  String get todayTitle => 'Today.';

  @override
  String get tomorrowTitle => 'Tomorrow.';

  @override
  String seeAllLists(int count) {
    return 'See all $count lists';
  }

  @override
  String get nothingPlanned => 'Nothing planned. Enjoy it.';

  @override
  String get firstListTitle => 'Your first list.';

  @override
  String get firstListSub =>
      'Groceries, chores, gift ideas: start with whatever is on your mind.';

  @override
  String get createAList => 'Create a list';

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(int n) {
    return '$n min ago';
  }

  @override
  String hoursAgo(int n) {
    return '$n h ago';
  }

  @override
  String get yesterdayLower => 'yesterday';

  @override
  String get noNotesYet => 'No notes yet. Tap + to start one.';

  @override
  String get notesTitle => 'Notes.';

  @override
  String get notesLede => 'Something to remember?';

  @override
  String get untitled => 'Untitled';

  @override
  String get nowPersonalList => 'Now a personal list';

  @override
  String sharedWith(String name) {
    return 'Shared with $name';
  }

  @override
  String listDeleted(String name) {
    return '$name deleted';
  }

  @override
  String get editList => 'Edit list';

  @override
  String get editListSub => 'Name, color, icon, day, reminder';

  @override
  String get inviteToShareList => 'To share this list with them';

  @override
  String get shareWithHousehold => 'Share with the household';

  @override
  String get onlyYouWillSee => 'Only you will see it';

  @override
  String partnerWillSeeAndEdit(String name) {
    return '$name will see it and can edit it';
  }

  @override
  String get deleteList => 'Delete list';

  @override
  String deleteListSub(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Removes $count items. You can undo.',
      one: 'Removes 1 item. You can undo.',
    );
    return '$_temp0';
  }

  @override
  String get dragToReorder => 'Drag to reorder';

  @override
  String get firstItemPlaceholder => 'Start typing your first item…';

  @override
  String get addItem => 'Add an item';

  @override
  String get doneSection => 'Done';

  @override
  String get listHint =>
      'Tap an item to edit it, drag the dots to move it, swipe left to delete it.';

  @override
  String get allLists => 'All lists';

  @override
  String get home => 'Home';

  @override
  String personalShareWith(String name) {
    return 'Personal. Share with $name';
  }

  @override
  String get listOptions => 'List options';

  @override
  String get mascot => 'Mascot';

  @override
  String get sharedList => 'Shared list';

  @override
  String get personalListOnlyYou => 'Personal list, only you can see it';

  @override
  String get allListsTitle => 'All lists.';

  @override
  String get noListsYet => 'No lists yet. Tap + to create one.';

  @override
  String deleteNamed(String name) {
    return 'Delete $name';
  }

  @override
  String get nowPersonalNote => 'Now a personal note';

  @override
  String noteDeleted(String name) {
    return '$name deleted';
  }

  @override
  String get lastEditedBy => 'Last edited by';

  @override
  String get reminderOff => 'Off';

  @override
  String get inviteToShareNote => 'To share this note with them';

  @override
  String get deleteNote => 'Delete note';

  @override
  String get youCanUndo => 'You can undo.';

  @override
  String get noteOptions => 'Note options';

  @override
  String get sharedNote => 'Shared note';

  @override
  String get personalNoteOnlyYou => 'Personal note, only you can see it';

  @override
  String get slashHint => 'Type / to add a heading, checklist or link.';

  @override
  String get reminderTitle => 'Reminder.';

  @override
  String get removeReminder => 'Remove reminder';

  @override
  String reminderBothNotified(String name) {
    return 'You and $name both get a notification.';
  }

  @override
  String get blockText => 'Text';

  @override
  String get blockTextDesc => 'Just start writing';

  @override
  String get blockHeading => 'Heading';

  @override
  String get blockHeadingDesc => 'Section title';

  @override
  String get blockBullet => 'Bulleted list';

  @override
  String get blockBulletDesc => 'Simple list';

  @override
  String get blockCheckbox => 'Checkbox';

  @override
  String get blockCheckboxDesc => 'Things to tick';

  @override
  String get blockLink => 'Link';

  @override
  String get blockLinkDesc => 'Paste a web address';

  @override
  String get formatBold => 'Bold';

  @override
  String get formatItalic => 'Italic';

  @override
  String get formatUnderline => 'Underline';

  @override
  String get blockListItem => 'List item';

  @override
  String get blockTodo => 'To do';

  @override
  String get blockLinkHint => 'Paste a link';

  @override
  String get blockTextHint => 'Type / for blocks';

  @override
  String noBlockNamed(String query) {
    return 'No block called “$query”';
  }

  @override
  String get leaveHouseholdQuestion => 'Leave the household?';

  @override
  String get leaveHousehold => 'Leave household';

  @override
  String sharedStayIn(String household, String name) {
    return 'Shared lists and notes stay in $household with $name.';
  }

  @override
  String lastMemberLeave(String household) {
    return 'You are the last member: $household and all its lists and notes will be deleted for good.';
  }

  @override
  String get keepAccount =>
      'You keep your account and can create or join another household.';

  @override
  String removeQuestion(String name) {
    return 'Remove $name?';
  }

  @override
  String removeNamed(String name) {
    return 'Remove $name';
  }

  @override
  String loseAccess(String name, String household) {
    return '$name loses access to $household.';
  }

  @override
  String get sharedStayInHousehold =>
      'Every shared list and note stays in the household.';

  @override
  String wasRemoved(String name) {
    return '$name was removed';
  }

  @override
  String get settingsTitle => 'Settings.';

  @override
  String get myAccount => 'My account';

  @override
  String get householdSection => 'Household.';

  @override
  String get householdName => 'Household name';

  @override
  String get householdRenamed => 'Household renamed';

  @override
  String get justYouForNow => 'Just you for now';

  @override
  String get member => 'Member';

  @override
  String get remove => 'Remove';

  @override
  String get invitationResent => 'Invitation sent again';

  @override
  String get invitationCancelled => 'Invitation cancelled';

  @override
  String get inviteSomeoneSub => 'By email, to share lists and notes';

  @override
  String get householdFullNote =>
      'Your household is full: 2 members at most for now.';

  @override
  String get notificationsSection => 'Notifications.';

  @override
  String get notifications => 'Notifications';

  @override
  String notificationsOnAt(String time) {
    return 'On, reminders at $time';
  }

  @override
  String get notificationsOff => 'Off';

  @override
  String get aboutSection => 'About.';

  @override
  String get termsOfUse => 'Terms of use';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get contactAndBugs => 'Contact and bugs';

  @override
  String get opensInBrowser => 'Opens in your browser';

  @override
  String get opensMailApp => 'Opens your mail app';

  @override
  String get aboutFooter =>
      'Picnote 1.0.0. Appearance and language follow your phone settings.';

  @override
  String get deletionCancelled => 'Deletion cancelled. Welcome back.';

  @override
  String deletionBanner(String date) {
    return 'Your account will be deleted on $date. Until then you can change your mind.';
  }

  @override
  String get cancelDeletion => 'Cancel deletion';

  @override
  String personalBothDeleted(int lists, int notes) {
    String _temp0 = intl.Intl.pluralLogic(
      lists,
      locale: localeName,
      other: '$lists personal lists',
      one: 'personal list',
    );
    String _temp1 = intl.Intl.pluralLogic(
      notes,
      locale: localeName,
      other: '$notes personal notes',
      one: 'personal note',
    );
    return 'Your $_temp0 and $_temp1 will be deleted.';
  }

  @override
  String personalListsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Your $count personal lists will be deleted.',
      one: 'Your personal list will be deleted.',
    );
    return '$_temp0';
  }

  @override
  String personalNotesDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Your $count personal notes will be deleted.',
      one: 'Your personal note will be deleted.',
    );
    return '$_temp0';
  }

  @override
  String get deleteAccountQuestion => 'Delete your account?';

  @override
  String get deleteMyAccount => 'Delete my account';

  @override
  String accountDeletedOn(String date) {
    return 'Your account will be deleted on $date';
  }

  @override
  String lastMemberDelete(String household) {
    return 'You are the last member: $household and all its content will be deleted too.';
  }

  @override
  String get deactivatedFor15Days =>
      'Your account is deactivated for 15 days, then erased for good. Log back in before then to change your mind.';

  @override
  String get accountTitle => 'Account.';

  @override
  String get avatarColor => 'Avatar color';

  @override
  String colorShownTo(String name) {
    return '$name sees this color next to what you change.';
  }

  @override
  String get colorShown => 'This color shows next to what you change.';

  @override
  String get profileSection => 'Profile.';

  @override
  String get firstNameSaved => 'First name saved';

  @override
  String get signInSection => 'Sign-in.';

  @override
  String get codeByEmail => 'Code by email';

  @override
  String get codeByEmailSub => 'No password: a 6-digit code each time';

  @override
  String get logOut => 'Log out';

  @override
  String get fifteenDays => '15 days to change your mind';

  @override
  String get notificationsTitle => 'Notifications.';

  @override
  String get generalSection => 'General.';

  @override
  String get allowNotifications => 'Allow notifications';

  @override
  String get allowNotificationsOn => 'Reminders and household activity';

  @override
  String get allowNotificationsOff => 'Off: no reminders, no alerts';

  @override
  String get remindersSection => 'Reminders.';

  @override
  String get defaultTime => 'Default time';

  @override
  String get defaultTimeSub => 'Suggested when you add a reminder';

  @override
  String whenPartnerEdits(String name) {
    return 'When $name checks or edits';
  }

  @override
  String get eachTime => 'A notification each time';

  @override
  String get phoneNotificationSettings =>
      'You can also manage Picnote in your phone notification settings.';

  @override
  String get visibilityShared => 'Shared';

  @override
  String get noDeadline => 'No deadline';

  @override
  String get noReminder => 'No reminder';

  @override
  String get editNoteTitle => 'Edit note.';

  @override
  String get editNote => 'Edit note';

  @override
  String get whoSeesItTitle => 'Who sees it.';

  @override
  String get deadlineTitle => 'Deadline.';

  @override
  String get deadline => 'Deadline';

  @override
  String get removeDeadline => 'Remove deadline';

  @override
  String get reminderOnlyYou => 'Only you get a notification.';

  @override
  String get defaultListName => 'List';

  @override
  String get renameList => 'Rename list';

  @override
  String get add => 'Add';

  @override
  String get householdAndSettings => 'Household and settings';

  @override
  String get whosHere => 'Who’s here';

  @override
  String memberYou(String name) {
    return '$name (you)';
  }

  @override
  String quoted(String item) {
    return '“$item”';
  }

  @override
  String get aListLower => 'a list';

  @override
  String get aNoteLower => 'a note';

  @override
  String youEditedAgo(String what, String ago) {
    return 'You edited $what, $ago';
  }

  @override
  String theyEditedAgo(String what, String ago) {
    return 'Edited $what, $ago';
  }

  @override
  String get nothingChangedYet => 'Nothing changed yet';

  @override
  String get pinnedTitle => 'Pinned.';

  @override
  String get otherListsTitle => 'Other lists.';

  @override
  String get pinHint => 'Pin up to 4 lists to see them on home.';

  @override
  String get homeFull => 'Home is full. Unpin a list to pin another.';

  @override
  String pinNamed(String name) {
    return 'Pin $name';
  }

  @override
  String unpinNamed(String name) {
    return 'Unpin $name';
  }

  @override
  String get latestChanges => 'Latest changes';

  @override
  String get toShareThisList => 'To share this list';

  @override
  String get toShareThisNote => 'To share this note';

  @override
  String get theListLower => 'the list';

  @override
  String get theNoteLower => 'the note';

  @override
  String logByYou(String verb, String what) {
    String _temp0 = intl.Intl.selectLogic(verb, {
      'check': 'You checked',
      'uncheck': 'You unchecked',
      'add': 'You added',
      'edit': 'You edited',
      'del': 'You deleted',
      'other': 'You created',
    });
    return '$_temp0 $what';
  }

  @override
  String logByName(String name, String verb, String what) {
    String _temp0 = intl.Intl.selectLogic(verb, {
      'check': 'checked',
      'uncheck': 'unchecked',
      'add': 'added',
      'edit': 'edited',
      'del': 'deleted',
      'other': 'created',
    });
    return '$name $_temp0 $what';
  }

  @override
  String logSolo(String verb, String what) {
    String _temp0 = intl.Intl.selectLogic(verb, {
      'check': 'Checked',
      'uncheck': 'Unchecked',
      'add': 'Added',
      'edit': 'Edited',
      'del': 'Deleted',
      'other': 'Created',
    });
    return '$_temp0 $what';
  }

  @override
  String logSoloList(String verb) {
    String _temp0 = intl.Intl.selectLogic(verb, {
      'edit': 'List edited',
      'other': 'List created',
    });
    return '$_temp0';
  }

  @override
  String logSoloNote(String verb) {
    String _temp0 = intl.Intl.selectLogic(verb, {
      'edit': 'Note edited',
      'other': 'Note created',
    });
    return '$_temp0';
  }

  @override
  String listDoneUnpin(String name) {
    return '“$name” is done. Unpin it?';
  }

  @override
  String get unpin => 'Unpin';

  @override
  String partnerCreatedList(String who, String name) {
    return '$who created the list “$name”';
  }

  @override
  String partnerCreatedNote(String who, String name) {
    return '$who created the note “$name”';
  }

  @override
  String get see => 'See';

  @override
  String isTyping(String name) {
    return '$name is typing…';
  }

  @override
  String get tableTitle => 'Table.';

  @override
  String get tableRemoveColumn => 'Remove column';

  @override
  String get tableRemoveRow => 'Remove row';

  @override
  String get tableHeaderHint => 'Header';

  @override
  String get tableAddRow => '+ Row';

  @override
  String get tableAddColumn => '+ Column';

  @override
  String get blockTable => 'Table';

  @override
  String get blockTableDesc => 'Rows and columns';

  @override
  String blockHeadingLevel(int level) {
    return 'Heading $level';
  }

  @override
  String get formatHeading => 'Heading';

  @override
  String get headingColor => 'Heading color';

  @override
  String headingColorName(String color) {
    String _temp0 = intl.Intl.selectLogic(color, {
      'terra': 'Terracotta',
      'sage': 'Green',
      'mustard': 'Mustard',
      'rose': 'Red',
      'cocoa': 'Brown',
      'grey': 'Grey',
      'other': 'Black',
    });
    return '$_temp0';
  }

  @override
  String get formatUndo => 'Undo';

  @override
  String get formatRedo => 'Redo';

  @override
  String createdBy(String name) {
    return 'Created by $name';
  }

  @override
  String get createdByYou => 'Created by you';

  @override
  String askAuthor(String name) {
    return 'To make it personal or delete it, ask $name.';
  }

  @override
  String get pinToHome => 'Pin to home';

  @override
  String get unpinFromHome => 'Remove from home';

  @override
  String get pinnedToHome => 'List pinned to home';

  @override
  String get unpinnedFromHome => 'List removed from home';

  @override
  String partnerEditedList(String who, String name) {
    return '$who edited the list “$name”';
  }

  @override
  String partnerEditedNote(String who, String name) {
    return '$who edited the note “$name”';
  }
}
