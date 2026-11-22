import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/auth_shell.dart';
import '../../core/ui/sheet.dart';
import '../../core/ui/toast.dart';
import '../view_models/join_household_viewmodel.dart';

/// "Join a household." sheet, from the avatars' menu. Once joined, it closes
/// and says so.
Future<void> showJoinHouseholdSheet(BuildContext context) async {
  final viewModel = JoinHouseholdViewModel(
    authRepository: context.read(),
    householdRepository: context.read(),
    listRepository: context.read(),
    noteRepository: context.read(),
  );
  final joined = await showPnSheet<String>(context, JoinHouseholdSheet(viewModel: viewModel), editing: true);
  viewModel.dispose();
  if (joined != null && context.mounted) showToast(context, AppLocalizations.of(context).joinedHousehold(joined));
}

class JoinHouseholdSheet extends StatefulWidget {
  const JoinHouseholdSheet({super.key, required this.viewModel});

  final JoinHouseholdViewModel viewModel;

  @override
  State<JoinHouseholdSheet> createState() => _JoinHouseholdSheetState();
}

class _JoinHouseholdSheetState extends State<JoinHouseholdSheet> {
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
    final vm = widget.viewModel;
    if (vm.state == JoinHouseholdState.joined && mounted) Navigator.pop(context, vm.householdName);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final error = switch (vm.state) {
          JoinHouseholdState.invalid => l10n.joinCodeInvalid,
          JoinHouseholdState.full => l10n.householdFullTitle,
          JoinHouseholdState.failed => l10n.offlineTryAgain,
          _ => null,
        };
        return PnSheet(
          title: l10n.joinHouseholdTitle,
          children: [
            Text(l10n.joinHouseholdSub, style: PnText.sub),
            CodeBoxes(
              alphanumeric: true,
              value: vm.code,
              label: l10n.inviteCodeFieldLabel,
              onChanged: vm.setCode,
              state: error != null
                  ? CodeBoxesState.error
                  : vm.state == JoinHouseholdState.loading
                  ? CodeBoxesState.loading
                  : CodeBoxesState.idle,
            ),
            Text(
              error ?? (vm.state == JoinHouseholdState.loading ? l10n.joinCodeChecking : l10n.joinCodeAlphabet),
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: error != null ? PnColors.terraDark : PnColors.muted,
              ),
            ),
          ],
        );
      },
    );
  }
}
