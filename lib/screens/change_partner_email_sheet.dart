import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/pair_service.dart';

enum _Phase { idle, checking, found, notFound, acting }

class ChangePartnerEmailSheet extends StatefulWidget {
  final String currentEmail;
  const ChangePartnerEmailSheet({super.key, required this.currentEmail});

  @override
  State<ChangePartnerEmailSheet> createState() => _ChangePartnerEmailSheetState();
}

class _ChangePartnerEmailSheetState extends State<ChangePartnerEmailSheet> {
  late final TextEditingController _controller;
  _Phase _phase = _Phase.idle;
  String? _error;
  bool _wasFound = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentEmail)
      ..addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    if (_phase != _Phase.idle && _phase != _Phase.checking) {
      setState(() { _phase = _Phase.idle; _error = null; });
    }
  }

  bool get _isValidEmail {
    final v = _controller.text.trim();
    return v.isNotEmpty && v.contains('@') && v.contains('.');
  }

  Future<void> _check() async {
    if (!_isValidEmail) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    setState(() { _phase = _Phase.checking; _error = null; });
    try {
      final exists = await PairService.partnerExists(_controller.text.trim());
      if (mounted) setState(() => _phase = exists ? _Phase.found : _Phase.notFound);
    } catch (_) {
      if (mounted) setState(() { _phase = _Phase.idle; _error = 'Something went wrong. Please try again.'; });
    }
  }

  Future<void> _connect() async {
    _wasFound = true;
    setState(() => _phase = _Phase.acting);
    try {
      await PairService.connectExistingPartner(_controller.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() { _phase = _Phase.found; _error = 'Something went wrong. Please try again.'; });
    }
  }

  Future<void> _invite() async {
    _wasFound = false;
    setState(() => _phase = _Phase.acting);
    try {
      await PairService.resendInvite(_controller.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() { _phase = _Phase.notFound; _error = 'Something went wrong. Please try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isActing = _phase == _Phase.acting;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.beigeCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.beigeCard.withOpacity(0.2)
                    : AppColors.brownDark.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Find your partner',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Enter their email — we\'ll check if they\'re already on Picnote.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.beigeCard.withOpacity(0.55)
                  : AppColors.brownDark.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            enabled: !isActing,
            onSubmitted: (_) { if (_phase == _Phase.idle) _check(); },
            style: TextStyle(
              color: isDark ? AppColors.beigeCard : AppColors.brownDark,
            ),
            decoration: InputDecoration(
              hintText: 'partner@email.com',
              hintStyle: TextStyle(
                color: isDark
                    ? AppColors.beigeCard.withOpacity(0.35)
                    : AppColors.brownDark.withOpacity(0.35),
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkCardLight : AppColors.beige,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              errorText: _error,
              errorStyle: const TextStyle(fontSize: 12),
            ),
          ),

          // Result banners
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: switch (_phase) {
              _Phase.found => Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _FoundBanner(isDark: isDark),
                ),
              _Phase.notFound => Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _NotFoundBanner(
                    isDark: isDark,
                    onInvite: _invite,
                  ),
                ),
              _ => const SizedBox.shrink(),
            },
          ),

          const SizedBox(height: 20),

          // Bottom button — only shown for idle/checking/found/acting states
          if (_phase != _Phase.notFound) _buildButton(isDark),
        ],
      ),
    );
  }

  Widget _buildButton(bool isDark) {
    final bg = isDark ? AppColors.brownMedium : AppColors.brownDark;
    return switch (_phase) {
      _Phase.idle => _ActionButton(label: 'Check', bg: bg, onTap: _check),
      _Phase.checking => _ActionButton(label: 'Checking...', bg: bg, loading: true),
      _Phase.found => _ActionButton(label: 'Connect', bg: bg, onTap: _connect),
      _Phase.acting => _ActionButton(label: '', bg: bg, loading: true),
      _Phase.notFound => const SizedBox.shrink(),
    };
  }
}

class _FoundBanner extends StatelessWidget {
  final bool isDark;
  const _FoundBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF4CAF50);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Already on Picnote! Tap Connect to pair up.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotFoundBanner extends StatelessWidget {
  final bool isDark;
  final VoidCallback onInvite;
  const _NotFoundBanner({required this.isDark, required this.onInvite});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.brownMedium : AppColors.brownDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.person_add_outlined, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Not on Picnote yet.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: color,
              ),
            ),
          ),
          GestureDetector(
            onTap: onInvite,
            child: Text(
              'Send invite',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color bg;
  final VoidCallback? onTap;
  final bool loading;

  const _ActionButton({
    required this.label,
    required this.bg,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: bg.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
              )
            : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
