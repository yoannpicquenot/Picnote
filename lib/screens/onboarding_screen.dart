import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../widgets/picnote_face.dart';
import '../models/app_state.dart';
import '../services/pair_service.dart';
import 'home_screen.dart';

enum _Step { choice, create, join }

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  _Step _step = _Step.choice;
  String _generatedCode = '';
  bool _loading = false;
  String? _error;

  void _goHome() => Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );

  Future<void> _onCreate() async {
    setState(() { _loading = true; _error = null; });
    try {
      final code = await PairService.createFamilySpace();
      if (!mounted) return;
      await context.read<AppState>().reload();
      if (mounted) setState(() { _generatedCode = code; _step = _Step.create; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _onJoin(String code) async {
    setState(() { _loading = true; _error = null; });
    try {
      await PairService.joinFamilySpace(code);
      if (!mounted) return;
      await context.read<AppState>().reload();
      if (mounted) _goHome();
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PICNOTE.',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 36,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    const Center(child: PicnoteFace(size: 140)),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkCard
                  : const Color(0xFFF0E0D0),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
            child: SafeArea(
              top: false,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: switch (_step) {
                  _Step.choice => _ChoicePanel(
                      key: const ValueKey('choice'),
                      loading: _loading,
                      error: _error,
                      onCreate: _onCreate,
                      onJoin: () => setState(() { _step = _Step.join; _error = null; }),
                      onLater: _goHome,
                    ),
                  _Step.create => _CreatePanel(
                      key: const ValueKey('create'),
                      code: _generatedCode,
                      onDone: _goHome,
                    ),
                  _Step.join => _JoinPanel(
                      key: const ValueKey('join'),
                      loading: _loading,
                      error: _error,
                      onJoin: _onJoin,
                      onBack: () => setState(() { _step = _Step.choice; _error = null; }),
                    ),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Choice ────────────────────────────────────────────────────────────────────

class _ChoicePanel extends StatelessWidget {
  final bool loading;
  final String? error;
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  final VoidCallback onLater;

  const _ChoicePanel({
    super.key,
    required this.loading,
    required this.error,
    required this.onCreate,
    required this.onJoin,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your family space', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Create a new shared space or join one your partner already set up.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: loading ? null : onCreate,
            icon: loading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.add_home_outlined, size: 20),
            label: const Text('Create a family space',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.darkCardLight : AppColors.charcoal,
              foregroundColor: isDark ? AppColors.beigeCard : AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: loading ? null : onJoin,
            icon: const Icon(Icons.group_add_outlined, size: 20),
            label: const Text('Join a family space',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? AppColors.beigeCard : AppColors.charcoal,
              side: BorderSide(
                color: isDark ? AppColors.darkCardLight : AppColors.charcoal,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: loading ? null : onLater,
            child: Text(
              'Later',
              style: TextStyle(
                color: isDark ? AppColors.brownMedium : AppColors.brown,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Create ────────────────────────────────────────────────────────────────────

class _CreatePanel extends StatelessWidget {
  final String code;
  final VoidCallback onDone;

  const _CreatePanel({super.key, required this.code, required this.onDone});

  void _share() {
    Share.share(
      'Join my Picnote family space! Enter the code $code in the app to sync up. 🏡',
      subject: 'Join my Picnote space',
    );
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copied to clipboard'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final codeColor = isDark ? AppColors.beigeCard : AppColors.brownDark;
    final cardBg = isDark ? AppColors.darkCardLight : AppColors.beigeCard;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your space is ready!', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Share this code with your partner so they can join.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),

        // Code card
        GestureDetector(
          onTap: () => _copy(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Format as XXX·XXX for readability
                Text(
                  '${code.substring(0, 3)} · ${code.substring(3)}',
                  style: TextStyle(
                    fontFamily: 'Chillax',
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 6,
                    color: codeColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap to copy',
                  style: TextStyle(
                    fontSize: 12,
                    color: codeColor.withValues(alpha:0.45),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Share button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _share,
            icon: const Icon(Icons.share_outlined, size: 20),
            label: const Text('Share code',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.darkCardLight : AppColors.charcoal,
              foregroundColor: isDark ? AppColors.beigeCard : AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Done / go home
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onDone,
            child: Text(
              'Done',
              style: TextStyle(
                color: isDark ? AppColors.brownMedium : AppColors.brown,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Join ──────────────────────────────────────────────────────────────────────

class _JoinPanel extends StatefulWidget {
  final bool loading;
  final String? error;
  final void Function(String code) onJoin;
  final VoidCallback onBack;

  const _JoinPanel({
    super.key,
    required this.loading,
    required this.error,
    required this.onJoin,
    required this.onBack,
  });

  @override
  State<_JoinPanel> createState() => _JoinPanelState();
}

class _JoinPanelState extends State<_JoinPanel> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Enter the code', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Ask your partner for their 6-character space code.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          enableSuggestions: false,
          maxLength: 6,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            _UpperCaseFormatter(),
          ],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Chillax',
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 8,
            color: isDark ? AppColors.beigeCard : AppColors.brownDark,
          ),
          decoration: InputDecoration(
            hintText: '······',
            hintStyle: TextStyle(
              fontFamily: 'Chillax',
              fontSize: 28,
              letterSpacing: 8,
              color: isDark
                  ? AppColors.beigeCard.withValues(alpha:0.25)
                  : AppColors.brownDark.withValues(alpha:0.25),
            ),
            counterText: '',
            filled: true,
            fillColor: isDark ? AppColors.darkCardLight : AppColors.beigeCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            errorText: widget.error,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: widget.loading ? null : () => widget.onJoin(_controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.darkCardLight : AppColors.charcoal,
              foregroundColor: isDark ? AppColors.beigeCard : AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: widget.loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Join space',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: widget.loading ? null : widget.onBack,
            child: Text(
              'Back',
              style: TextStyle(
                color: isDark ? AppColors.brownMedium : AppColors.brown,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue _, TextEditingValue next) =>
      next.copyWith(text: next.text.toUpperCase());
}
