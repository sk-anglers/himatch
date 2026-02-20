import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/core/widgets/glass_card.dart';
import 'package:himatch/core/widgets/gradient_scaffold.dart';
import 'package:himatch/features/auth/providers/auth_providers.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return GradientScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // App icon with glass card + pulse
              GlassCard(
                borderRadius: BorderRadius.circular(30),
                padding: const EdgeInsets.all(24),
                child: Icon(
                  Icons.calendar_month,
                  size: 60,
                  color: colors.primary,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.04, 1.04),
                    duration: 2000.ms,
                    curve: Curves.easeInOut,
                  )
                  .animate() // stagger entry
                  .fadeIn(duration: 600.ms)
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),
              const SizedBox(height: 24),
              Text(
                'Himatch',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 200.ms)
                  .slideY(begin: 0.2, duration: 500.ms, delay: 200.ms),
              const SizedBox(height: 8),
              Text(
                'みんなのヒマをマッチング',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.textSecondary,
                    ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 400.ms)
                  .slideY(begin: 0.2, duration: 500.ms, delay: 400.ms),
              const Spacer(flex: 2),
              // Apple Sign In
              _GlassSignInButton(
                label: 'Appleでサインイン',
                icon: Icons.apple,
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Apple サインインは Supabase 接続後に有効になります'),
                    ),
                  );
                },
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 600.ms)
                  .slideY(begin: 0.1, duration: 400.ms, delay: 600.ms),
              const SizedBox(height: 12),
              // Google Sign In
              _GlassSignInButton(
                label: 'Googleでサインイン',
                icon: Icons.g_mobiledata,
                iconSize: 28,
                isOutlined: true,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Google サインインは Supabase 接続後に有効になります'),
                    ),
                  );
                },
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 700.ms)
                  .slideY(begin: 0.1, duration: 400.ms, delay: 700.ms),
              const SizedBox(height: 12),
              // LINE Sign In
              _GlassSignInButton(
                label: 'LINEでサインイン',
                icon: Icons.chat_bubble,
                backgroundColor: const Color(0xFF06C755),
                foregroundColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('LINE サインインは Supabase 接続後に有効になります'),
                    ),
                  );
                },
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 800.ms)
                  .slideY(begin: 0.1, duration: 400.ms, delay: 800.ms),
              const SizedBox(height: 24),
              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'または',
                      style: TextStyle(
                        color: colors.textHint,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 900.ms),
              const SizedBox(height: 16),
              // Demo mode
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () {
                    ref.read(authNotifierProvider.notifier).signInDemo();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: colors.textSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: colors.glassBorder,
                      ),
                    ),
                  ),
                  child: const Text('デモモードで始める'),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 1000.ms)
                  .slideY(begin: 0.1, duration: 400.ms, delay: 1000.ms),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassSignInButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final double iconSize;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isOutlined;
  final VoidCallback onPressed;

  const _GlassSignInButton({
    required this.label,
    required this.icon,
    this.iconSize = 24,
    this.backgroundColor,
    this.foregroundColor,
    this.isOutlined = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: isOutlined
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: iconSize),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: colors.glassBorder),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: iconSize),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
    );
  }
}
