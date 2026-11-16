import 'package:flutter/material.dart';

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
import '../view_models/onboarding_viewmodel.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.viewModel, required this.onFinished});

  final OnboardingViewModel viewModel;
  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
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
          OnboardingStep.avatar => (MascotMood.love, _avatar(vm, l10n)),
          OnboardingStep.household => (MascotMood.happy, _household(vm, l10n)),
          OnboardingStep.create => (MascotMood.joy, _create(vm, l10n)),
          OnboardingStep.invite => (vm.partnerJoined ? MascotMood.love : MascotMood.wink, _invite(vm, l10n)),
          OnboardingStep.joinCode => (
            vm.joinState == JoinCodeState.error ? MascotMood.surprised : MascotMood.peek,
            _joinCode(vm, l10n),
          ),
          OnboardingStep.join => (
            vm.preview?.isFull ?? false ? MascotMood.surprised : MascotMood.love,
            _join(vm, l10n),
          ),
        };
        return AuthShell(mood: mood, stepKey: vm.step, children: children);
      },
    );
  }

  Widget _row(AppLocalizations l10n, OnboardingStep back, String cta, VoidCallback? onPressed) => Row(
    children: [
      BackSquare(label: l10n.back, onPressed: () => widget.viewModel.goTo(back)),
      const SizedBox(width: 8),
      Expanded(
        child: PnButton(label: cta, onPressed: onPressed),
      ),
    ],
  );

  List<Widget> _name(OnboardingViewModel vm, AppLocalizations l10n) {
    final ok = vm.name.trim().isNotEmpty;
    return [
      StepHeader(l10n.nameTitle),
      _Field(
        initial: vm.name,
        hint: l10n.firstName,
        autofillHints: const [AutofillHints.givenName],
        onChanged: vm.setName,
        onSubmitted: ok ? () => vm.goTo(OnboardingStep.avatar) : null,
      ),
      PnButton(label: l10n.continueLabel, onPressed: ok ? () => vm.goTo(OnboardingStep.avatar) : null),
    ];
  }

  List<Widget> _avatar(OnboardingViewModel vm, AppLocalizations l10n) => [
    StepHeader(l10n.avatarTitle),
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
          child: _ColorDots(selected: vm.color, onSelect: vm.setColor, ring: PnColors.snow),
        ),
      ],
    ),
    Text(l10n.avatarSub, style: PnText.sub),
    _row(l10n, OnboardingStep.name, l10n.continueLabel, () => vm.goTo(OnboardingStep.household)),
  ];

  List<Widget> _household(OnboardingViewModel vm, AppLocalizations l10n) {
    final me = Avatar(initial: vm.initial, color: Color(vm.color), size: 44, ring: PnColors.snow);
    return [
      StepHeader(l10n.householdTitle, sub: Text(l10n.householdSub)),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _Choice(visual: me, title: l10n.justMe, sub: l10n.justMeSub, onTap: () => vm.choose(solo: true)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Choice(
                visual: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    me,
                    Transform.translate(offset: const Offset(-10, 0), child: const DashedPlus(size: 44)),
                  ],
                ),
                title: l10n.twoOfUs,
                sub: l10n.twoOfUsSub,
                onTap: () => vm.choose(solo: false),
              ),
            ),
          ],
        ),
      ),
      Center(
        child: LinkButton(label: l10n.haveInvitation, onPressed: () => vm.goTo(OnboardingStep.joinCode)),
      ),
    ];
  }

  List<Widget> _create(OnboardingViewModel vm, AppLocalizations l10n) {
    final ok = vm.householdName.trim().isNotEmpty && !vm.busy;
    return [
      StepHeader(l10n.createTitle, sub: Text(vm.solo ? l10n.createSubSolo : l10n.createSubDuo)),
      _Field(
        initial: vm.householdName,
        hint: l10n.householdNameHint,
        onChanged: vm.setHouseholdName,
        onSubmitted: ok ? vm.createHousehold : null,
      ),
      _row(l10n, OnboardingStep.household, vm.solo ? l10n.create : l10n.continueLabel, ok ? vm.createHousehold : null),
    ];
  }

  List<Widget> _invite(OnboardingViewModel vm, AppLocalizations l10n) {
    final partner = vm.joinedPartner;
    if (vm.partnerJoined && partner != null) {
      return [
        StepHeader(l10n.youAreTwo),
        Row(
          children: [
            Avatar.of(partner, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.partnerJoinedHousehold(partner.name),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: PnColors.sage),
              ),
            ),
          ],
        ),
        PnButton(label: l10n.seeMyLists, onPressed: vm.finish),
      ];
    }
    final sent = vm.invite != null;
    return [
      StepHeader(
        sent ? l10n.invitationSent : l10n.inviteTheOther,
        sub: Text(sent ? l10n.inviteSentSub(vm.currentHouseholdName) : l10n.inviteSub(vm.currentHouseholdName)),
      ),
      InviteForm(
        invite: vm.invite,
        onSend: vm.sendInvite,
        onResend: vm.resendInvite,
        onCancel: vm.cancelInvite,
        sendButton: (send) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _row(l10n, OnboardingStep.create, l10n.sendInvitation, send),
            const SizedBox(height: 4),
            Center(
              child: LinkButton(label: l10n.later, onPressed: vm.finish),
            ),
          ],
        ),
        after: PnButton(label: l10n.seeMyLists, onPressed: vm.finish),
      ),
    ];
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
      Row(
        children: [BackSquare(label: l10n.back, onPressed: () => vm.goTo(OnboardingStep.household))],
      ),
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
        _row(l10n, OnboardingStep.joinCode, l10n.createMyHousehold, () => vm.goTo(OnboardingStep.household)),
      ];
    }
    final taken = vm.takenColors;
    return [
      StepHeader(l10n.partnerInvitesYou(hostName), sub: Text(l10n.joinSub(hostName))),
      _HouseholdCard(
        name: preview.name,
        members: [...preview.members, vm.me.copyWithInitial(vm.initial)],
        who: l10n.joinWho(hostName),
      ),
      if (vm.colorWasTaken)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.colorTaken(hostName),
              style: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500, color: PnColors.ink),
            ),
            const SizedBox(height: 10),
            _ColorDots(
              selected: vm.color,
              onSelect: vm.setColor,
              ring: PnColors.snow,
              disabled: taken,
              initial: vm.initial,
            ),
          ],
        ),
      PnButton(label: l10n.joinHousehold, onPressed: vm.busy ? null : vm.join),
    ];
  }
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

class _ColorDots extends StatelessWidget {
  const _ColorDots({
    required this.selected,
    required this.onSelect,
    required this.ring,
    this.disabled = const {},
    this.initial,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final Color ring;
  final Set<int> disabled;
  final String? initial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final c in PnColors.avatars)
          Semantics(
            button: true,
            selected: c.toARGB32() == selected,
            label: disabled.contains(c.toARGB32()) ? l10n.colorTakenShort : l10n.color,
            child: GestureDetector(
              onTap: disabled.contains(c.toARGB32()) ? null : () => onSelect(c.toARGB32()),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: disabled.contains(c.toARGB32()) ? c.withValues(alpha: 0.45) : c,
                  shape: BoxShape.circle,
                  // A gap, then a ring of the color. Flutter paints shadows in
                  // order, so the outer ring goes first.
                  boxShadow: c.toARGB32() == selected
                      ? [BoxShadow(color: c, spreadRadius: 5), BoxShadow(color: ring, spreadRadius: 3)]
                      : null,
                ),
                child: initial != null && c.toARGB32() == selected
                    ? Text(
                        initial!,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: PnColors.snow),
                      )
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.visual, required this.title, required this.sub, required this.onTap});

  final Widget visual;
  final String title;
  final String sub;
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
            const SizedBox(height: 4),
            Text(sub, style: PnText.meta.copyWith(height: 1.35)),
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
