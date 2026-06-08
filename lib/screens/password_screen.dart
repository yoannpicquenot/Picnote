import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/picnote_face.dart';
import 'home_screen.dart';

class PasswordScreen extends StatefulWidget {
  final String email;
  const PasswordScreen({super.key, required this.email});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
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
                ),
              ),

              const Spacer(),
              Center(child: PicnoteFace(size: 120)),
              const Spacer(),

              Text(
                'Welcome back!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _controller,
                obscureText: _obscure,
                style: TextStyle(
                  color: isDark ? AppColors.beigeCard : AppColors.brownDark,
                  letterSpacing: _obscure ? 4 : 1,
                ),
                decoration: InputDecoration(
                  hintText: '••••••••••',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.beigeCard.withOpacity(0.35)
                        : AppColors.brownDark.withOpacity(0.35),
                    letterSpacing: 4,
                  ),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(
                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: isDark ? AppColors.brownMedium : AppColors.brown,
                      size: 20,
                    ),
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCardLight : AppColors.beigeCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                            (_) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.charcoal,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isDark ? AppColors.brownMedium : AppColors.brown,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.white, size: 20),
      ),
    );
  }
}
