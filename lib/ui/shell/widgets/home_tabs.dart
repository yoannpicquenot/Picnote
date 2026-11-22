import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/ui/home_header.dart';
import '../../invite/widgets/invite_sheet.dart';
import '../../join_household/widgets/join_household_sheet.dart';
import '../view_models/header_viewmodel.dart';
import 'tab_pager.dart';

/// Lists (home) and Notes in a [TabPager], under one header and one
/// watermark that stay in place while swiping between them.
class HomeTabs extends StatefulWidget {
  const HomeTabs({
    super.key,
    required this.viewModel,
    required this.index,
    required this.pages,
    required this.onSettled,
  });

  final HeaderViewModel viewModel;
  final int index;
  final List<Widget> pages;
  final ValueChanged<int> onSettled;

  @override
  State<HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<HomeTabs> {
  bool _wink = false;
  Timer? _winkTimer;

  @override
  void dispose() {
    _winkTimer?.cancel();
    super.dispose();
  }

  void _winkWatermark() {
    _winkTimer?.cancel();
    setState(() => _wink = true);
    _winkTimer = Timer(const Duration(milliseconds: 1500), () => setState(() => _wink = false));
  }

  @override
  Widget build(BuildContext context) {
    final day = isDaytime();
    return TabPager(
      index: widget.index,
      pages: widget.pages,
      onSettled: widget.onSettled,
      backdrop: Stack(
        clipBehavior: Clip.none,
        children: [
          const SizedBox(width: double.infinity),
          Positioned(
            right: day ? -70 : -12,
            top: day ? 18 : 34,
            child: Watermark(winking: _wink),
          ),
        ],
      ),
      header: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) => HomeHeader(
          whoIsHere: widget.viewModel.whoIsHere,
          onWordmark: _winkWatermark,
          onInvite: () => showInviteSheet(context),
          onJoin: () => showJoinHouseholdSheet(context),
          onSettings: () => context.go(Routes.settings),
        ),
      ),
    );
  }
}
