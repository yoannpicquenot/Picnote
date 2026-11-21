import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../domain/models/household.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/auth_shell.dart';
import '../../core/ui/avatar.dart';
import '../../core/ui/buttons.dart';
import '../../core/ui/controls.dart';
import '../../core/ui/invite_form.dart';
import '../../core/ui/mascot.dart';
import '../../core/ui/pn_icon.dart';
import '../view_models/onboarding_viewmodel.dart';
import 'household_start.dart';
import 'invite_animations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.viewModel, required this.onFinished});

  final OnboardingViewModel viewModel;
  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _shareKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (widget.viewModel.finished) widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final l10n = AppLocalizations.of(context);
        final (mood, children) = switch (vm.step) {
          OnboardingStep.name => (MascotMood.cheerful, _name(vm, l10n)),
          OnboardingStep.householdStart => (MascotMood.happy, _householdStart(vm, l10n)),
          OnboardingStep.household => (MascotMood.cheerful, _household(vm, l10n)),
          OnboardingStep.create => (MascotMood.joy, _create(vm, l10n)),
          OnboardingStep.avatar => (MascotMood.love, _avatar(vm, l10n)),
          OnboardingStep.inviteHow => (MascotMood.wink, _inviteHow(vm, l10n)),
          OnboardingStep.inviteEmail => (vm.sentTo != null ? MascotMood.joy : MascotMood.wink, _inviteEmail(vm, l10n)),
          OnboardingStep.inviteCode => (vm.codeCopied ? MascotMood.joy : MascotMood.cheerful, _inviteCode(vm, l10n)),
          OnboardingStep.joinCode => (
            vm.joinState == JoinCodeState.error ? MascotMood.surprised : MascotMood.peek,
            _joinCode(vm, l10n),
          ),
          OnboardingStep.join => (
            vm.preview?.isFull ?? false ? MascotMood.surprised : MascotMood.love,
            _join(vm, l10n),
          ),
        };
        // "Invitation sent." slides in over the email form.
        final stepKey = (vm.step, vm.step == OnboardingStep.inviteEmail && vm.sentTo != null);
        return AuthShell(mood: mood, stepKey: stepKey, children: children);
      },
    );
  }

  Widget _back(OnboardingViewModel vm, AppLocalizations l10n) => BackSquare(label: l10n.back, onPressed: vm.goBack);

  Widget _row(OnboardingViewModel vm, AppLocalizations l10n, String cta, VoidCallback? onPressed) => Row(
    children: [
      _back(vm, l10n),
      const SizedBox(width: 8),
      Expanded(
        child: PnButton(label: cta, onPressed: onPressed),
      ),
    ],
  );

  /// Two cards side by side, as tall as the taller one.
  Widget _choices(Widget a, Widget b) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: a),
        const SizedBox(width: 10),
        Expanded(child: b),
      ],
    ),
  );

  Widget _me(OnboardingViewModel vm) =>
      Avatar(initial: vm.initial, color: Color(vm.color), size: 44, ring: PnColors.snow);

  Widget _meAndPlus(OnboardingViewModel vm) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _me(vm),
      Transform.translate(offset: const Offset(-10, 0), child: const DashedPlus(size: 44)),
    ],
  );

  List<Widget> _name(OnboardingViewModel vm, AppLocalizations l10n) {
    final ok = vm.name.trim().isNotEmpty;
    void next() => vm.goTo(OnboardingStep.householdStart);
    return [
      StepHeader(l10n.nameTitle),
      _Field(
        initial: vm.name,
        hint: l10n.firstName,
        autofillHints: const [AutofillHints.givenName],
        onChanged: vm.setName,
        onSubmitted: ok ? next : null,
      ),
      PnButton(label: l10n.continueLabel, onPressed: ok ? next : null),
    ];
  }

  List<Widget> _householdStart(OnboardingViewModel vm, AppLocalizations l10n) => [
    HouseholdStart(
      title: l10n.householdStartTitle,
      sub: l10n.householdStartSub,
      backLabel: l10n.back,
      onBack: vm.goBack,
      playIntro: !vm.householdIntroPlayed,
      onIntroDone: vm.householdIntroDone,
      choices: _choices(
        _Choice(visual: _meAndPlus(vm), title: l10n.createAHousehold, onTap: () => vm.goTo(OnboardingStep.household)),
        _Choice(
          visual: const _IconDisc(PnIcons.mail),
          title: l10n.joinAHousehold,
          onTap: () => vm.goTo(OnboardingStep.joinCode),
        ),
      ),
    ),
  ];

  List<Widget> _household(OnboardingViewModel vm, AppLocalizations l10n) => [
    StepHeader(l10n.householdTitle, sub: Text(l10n.householdSub)),
    _choices(
      _Choice(visual: _me(vm), title: l10n.justMe, onTap: () => vm.choose(solo: true)),
      _Choice(visual: _meAndPlus(vm), title: l10n.twoOfUs, onTap: () => vm.choose(solo: false)),
    ),
    Row(children: [_back(vm, l10n)]),
  ];

  List<Widget> _create(OnboardingViewModel vm, AppLocalizations l10n) {
    final ok = vm.householdName.trim().isNotEmpty;
    return [
      StepHeader(l10n.createTitle, sub: Text(vm.solo ? l10n.createSubSolo : l10n.createSubDuo)),
      _Field(
        initial: vm.householdName,
        hint: l10n.householdNameHint,
        onChanged: vm.setHouseholdName,
        onSubmitted: ok ? vm.submitHouseholdName : null,
      ),
      _row(vm, l10n, l10n.continueLabel, ok ? vm.submitHouseholdName : null),
    ];
  }

  List<Widget> _avatar(OnboardingViewModel vm, AppLocalizations l10n) {
    final owners = vm.colorOwners;
    final goesHome = vm.joining || vm.solo;
    return [
      StepHeader(l10n.avatarTitle, sub: Text(l10n.avatarSub)),
      Row(
        children: [
          TweenAnimationBuilder<double>(
            key: ValueKey(vm.color),
            tween: Tween(begin: 0.85, end: 1),
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutBack,
            builder: (context, s, child) => Transform.scale(scale: s, child: child),
            child: Avatar(initial: vm.initial, color: Color(vm.color), size: 72),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: _ColorDots(
              selected: vm.color,
              onSelect: vm.setColor,
              ring: PnColors.snow,
              taken: {for (final m in owners) m.color: m.initial},
            ),
          ),
        ],
      ),
      for (final m in owners)
        if (_colorKey(m.color) case final key?) Text(l10n.colorTakenBy(m.name, key), style: PnText.sub),
      _row(vm, l10n, goesHome ? l10n.seeMyLists : l10n.continueLabel, vm.busy ? null : vm.confirmAvatar),
    ];
  }

  List<Widget> _inviteHow(OnboardingViewModel vm, AppLocalizations l10n) => [
    StepHeader(l10n.inviteHowTitle, sub: Text(l10n.inviteHowSub)),
    _choices(
      _Choice(visual: const _IconDisc(PnIcons.mail), title: l10n.byEmail, onTap: vm.inviteByEmail),
      _Choice(visual: const _IconDisc(PnIcons.code, size: 24), title: l10n.byCode, onTap: vm.inviteByCode),
    ),
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _back(vm, l10n),
        LinkButton(label: l10n.later, onPressed: vm.finish),
      ],
    ),
  ];

  List<Widget> _inviteEmail(OnboardingViewModel vm, AppLocalizations l10n) {
    final sentTo = vm.sentTo;
    if (sentTo != null) {
      return [InviteSent(title: l10n.invitationSent, to: l10n.invitationSentTo(sentTo), email: sentTo)];
    }
    return [
      StepHeader(l10n.inviteTheOther, sub: Text(l10n.inviteSub(vm.currentHouseholdName))),
      if (vm.inviteFailed) Notice(text: l10n.offlineTryAgain),
      // Always the email field here: a code given by hand may already be
      // pending, and sending by email keeps it.
      InviteForm(
        invite: null,
        onSend: vm.sendInvite,
        onResend: () {},
        onCancel: () {},
        sendButton: (send) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _row(vm, l10n, l10n.sendInvitation, vm.busy ? null : send),
            const SizedBox(height: 4),
            Center(
              child: LinkButton(label: l10n.later, onPressed: vm.finish),
            ),
          ],
        ),
        after: const SizedBox.shrink(),
      ),
    ];
  }

  List<Widget> _inviteCode(OnboardingViewModel vm, AppLocalizations l10n) {
    final code = vm.inviteCode;
    return [
      StepHeader(l10n.inviteCodeTitle, sub: Text(l10n.inviteCodeSub)),
      InviteCodeBoxes(code: code, label: l10n.inviteCodeGroupLabel(code?.split('').join(' ') ?? '')),
      if (vm.inviteCodeFailed) Notice(text: l10n.offlineTryAgain),
      Semantics(
        liveRegion: true,
        child: PnButton(
          key: _shareKey,
          label: vm.codeCopied ? l10n.codeCopied : l10n.shareCode,
          icon: vm.codeCopied ? PnIcons.check : PnIcons.share,
          background: PnColors.peach,
          foreground: PnColors.terraDark,
          onPressed: code == null ? null : () => _shareCode(vm, l10n, code),
        ),
      ),
      _row(vm, l10n, l10n.seeMyLists, vm.finish),
    ];
  }

  /// Opens the device's share sheet. Closing it without choosing does
  /// nothing; without a share sheet, the code is copied instead.
  Future<void> _shareCode(OnboardingViewModel vm, AppLocalizations l10n, String code) async {
    final box = _shareKey.currentContext?.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: l10n.shareCodeText(code),
          // Where the sheet points from on iPad.
          sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } on Object {
      await Clipboard.setData(ClipboardData(text: code));
      vm.showCodeCopied();
    }
  }

  List<Widget> _joinCode(OnboardingViewModel vm, AppLocalizations l10n) {
    final error = vm.joinState == JoinCodeState.error;
    return [
      StepHeader(l10n.joinCodeTitle, sub: Text(l10n.joinCodeSub)),
      CodeBoxes(
        alphanumeric: true,
        value: vm.joinCode,
        label: l10n.inviteCodeFieldLabel,
        onChanged: vm.setJoinCode,
        state: switch (vm.joinState) {
          JoinCodeState.idle => CodeBoxesState.idle,
          JoinCodeState.loading => CodeBoxesState.loading,
          JoinCodeState.error => CodeBoxesState.error,
        },
      ),
      Text(
        error
            ? l10n.joinCodeInvalid
            : vm.joinState == JoinCodeState.loading
            ? l10n.joinCodeChecking
            : l10n.joinCodeAlphabet,
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          fontWeight: FontWeight.w500,
          color: error ? PnColors.terraDark : PnColors.muted,
        ),
      ),
      Row(children: [_back(vm, l10n)]),
    ];
  }

  List<Widget> _join(OnboardingViewModel vm, AppLocalizations l10n) {
    final preview = vm.preview!;
    final hostName = preview.members.isEmpty ? '' : preview.members.first.name;
    if (preview.isFull) {
      return [
        StepHeader(l10n.householdFullTitle, sub: Text(l10n.householdFullSub)),
        _HouseholdCard(
          name: preview.name,
          members: preview.members,
          who: l10n.householdFullWho(preview.members.map((m) => m.name).join(l10n.and)),
        ),
        _row(vm, l10n, l10n.createMyHousehold, () => vm.goTo(OnboardingStep.household)),
      ];
    }
    return [
      StepHeader(l10n.partnerInvitesYou(hostName), sub: Text(l10n.joinSub(hostName))),
      _HouseholdCard(
        name: preview.name,
        members: [...preview.members, vm.me.copyWithInitial(vm.initial)],
        who: l10n.joinWho(hostName),
      ),
      PnButton(label: l10n.joinHousehold, onPressed: vm.previewJoin),
    ];
  }

  /// The name of an avatar color, for "Yoann already has green."
  static String? _colorKey(int color) => switch (PnColors.avatars.indexWhere((c) => c.toARGB32() == color)) {
    0 => 'terra',
    1 => 'sage',
    2 => 'mustard',
    3 => 'rose',
    4 => 'cocoa',
    _ => null,
  };
}

extension on Member {
  Member copyWithInitial(String initial) => Member(id: id, name: name.isEmpty ? initial : name, color: color);
}

/// Text field that keeps its own controller across rebuilds.
class _Field extends StatefulWidget {
  const _Field({
    required this.initial,
    required this.hint,
    required this.onChanged,
    this.onSubmitted,
    this.autofillHints,
  });

  final String initial;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PnTextField(
      controller: _controller,
      hint: widget.hint,
      tall: true,
      autofocus: true,
      textCapitalization: TextCapitalization.words,
      autofillHints: widget.autofillHints,
      onChanged: widget.onChanged,
      onSubmitted: (_) => widget.onSubmitted?.call(),
    );
  }
}

/// The avatar colors. Those in [taken] are already worn in the household
/// being joined: faded, with the wearer's initial, and not selectable.
class _ColorDots extends StatelessWidget {
  const _ColorDots({required this.selected, required this.onSelect, required this.ring, this.taken = const {}});

  final int selected;
  final ValueChanged<int> onSelect;
  final Color ring;

  /// Color → initial of whoever wears it.
  final Map<int, String> taken;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final c in PnColors.avatars)
          if (taken[c.toARGB32()] case final initial?)
            Semantics(
              label: l10n.colorTakenShort,
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.withValues(alpha: 0.45), shape: BoxShape.circle),
                child: Text(
                  initial,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: PnColors.snow),
                ),
              ),
            )
          else
            Semantics(
              button: true,
              selected: c.toARGB32() == selected,
              label: l10n.color,
              child: GestureDetector(
                onTap: () => onSelect(c.toARGB32()),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    // A gap, then a ring of the color. Flutter paints shadows in
                    // order, so the outer ring goes first.
                    boxShadow: c.toARGB32() == selected
                        ? [BoxShadow(color: c, spreadRadius: 5), BoxShadow(color: ring, spreadRadius: 3)]
                        : null,
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

/// A 44 px peach disc holding an icon, for the choice cards.
class _IconDisc extends StatelessWidget {
  const _IconDisc(this.icon, {this.size = 22});

  final String icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: PnColors.peach, shape: BoxShape.circle),
      child: PnIcon(icon, color: PnColors.terraDark, size: size),
    );
  }
}

/// A card with a visual and a title, side by side with another.
class _Choice extends StatelessWidget {
  const _Choice({required this.visual, required this.title, required this.onTap});

  final Widget visual;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PnColors.snow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: PnColors.peachLine, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 44,
              child: Align(alignment: Alignment.centerLeft, child: visual),
            ),
            const SizedBox(height: 14),
            Text(title, style: PnText.cardTitle.copyWith(fontSize: 19, color: PnColors.terraDark)),
          ],
        ),
      ),
    );
  }
}

class _HouseholdCard extends StatelessWidget {
  const _HouseholdCard({required this.name, required this.members, required this.who});

  final String name;
  final List<Member> members;
  final String who;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          AvatarStack(members: members, size: 30, ring: PnColors.snow, overlap: 6),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: PnText.cardTitle.copyWith(fontSize: 18, color: PnColors.terra)),
                const SizedBox(height: 4),
                Text(who, style: PnText.meta),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
