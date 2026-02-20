import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/core/widgets/glass_card.dart';
import 'package:himatch/core/widgets/gradient_scaffold.dart';
import 'package:himatch/providers/theme_providers.dart';

/// Theme customization screen.
/// Allows users to customize color theme, dark mode, glass effects, and font.
class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeSettingsProvider);
    final selectedPreset = themeSettings.preset;
    final isDarkMode = themeSettings.isDarkMode;
    final glassEnabled = themeSettings.glassEffectEnabled;

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('テーマ設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Color theme section
          _SectionHeader(title: 'カラーテーマ'),
          const SizedBox(height: 12),
          _ColorThemeGrid(
            selectedPreset: selectedPreset,
            onSelected: (preset) {
              ref.read(themeSettingsProvider.notifier).setPreset(preset);
            },
          ),
          const SizedBox(height: 24),

          // Dark mode section
          _SectionHeader(title: 'ダークモード'),
          const SizedBox(height: 8),
          _DarkModeToggle(
            isDarkMode: isDarkMode,
            onChanged: (value) {
              ref.read(themeSettingsProvider.notifier).setDarkMode(value);
            },
          ),
          const SizedBox(height: 24),

          // Glass effect toggle
          _SectionHeader(title: 'グラスエフェクト'),
          const SizedBox(height: 8),
          _GlassEffectToggle(
            isEnabled: glassEnabled,
            onChanged: (value) {
              ref.read(themeSettingsProvider.notifier).setGlassEffect(value);
            },
          ),
          const SizedBox(height: 24),

          // Font section (placeholder)
          _SectionHeader(title: 'フォント'),
          const SizedBox(height: 8),
          const _FontSelector(selectedFont: 'gothic'),
          const SizedBox(height: 24),

          // Live preview
          _SectionHeader(title: 'プレビュー'),
          const SizedBox(height: 8),
          _ThemePreviewCard(
            preset: selectedPreset,
            isDarkMode: isDarkMode,
            glassEnabled: glassEnabled,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Glass effect toggle ──

class _GlassEffectToggle extends StatelessWidget {
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const _GlassEffectToggle({
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        title: const Text('グラスモーフィズム'),
        subtitle: Text(
          isEnabled ? 'フロストガラス効果ON' : 'パフォーマンス優先モード',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context)
                .extension<AppColorsExtension>()!
                .textSecondary,
          ),
        ),
        value: isEnabled,
        onChanged: onChanged,
        secondary: Icon(
          isEnabled ? Icons.blur_on : Icons.blur_off,
          color: Theme.of(context).extension<AppColorsExtension>()!.primary,
        ),
      ),
    );
  }
}

// ── Color theme grid ──

class _ColorThemeGrid extends StatelessWidget {
  final ThemePreset selectedPreset;
  final ValueChanged<ThemePreset> onSelected;

  const _ColorThemeGrid({
    required this.selectedPreset,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
        children: ThemePreset.values.map((preset) {
          final isSelected = preset == selectedPreset;
          return _ColorSwatch(
            preset: preset,
            isSelected: isSelected,
            onTap: () => onSelected(preset),
          );
        }).toList(),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final ThemePreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: preset.seedColor, width: 3)
              : Border.all(
                  color: Theme.of(context)
                      .extension<AppColorsExtension>()!
                      .glassBorder,
                  width: 1,
                ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: preset.seedColor,
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: preset.seedColor.withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check, color: Colors.white, size: 22),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              preset.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? preset.seedColor
                    : Theme.of(context)
                        .extension<AppColorsExtension>()!
                        .textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dark mode toggle ──

class _DarkModeToggle extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  const _DarkModeToggle({
    required this.isDarkMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        title: const Text('ダークモード'),
        subtitle: Text(
          isDarkMode ? 'ダークテーマ適用中' : 'ライトテーマ適用中',
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
        value: isDarkMode,
        onChanged: onChanged,
        secondary: Icon(
          isDarkMode ? Icons.dark_mode : Icons.light_mode,
          color: isDarkMode ? colors.primary : AppColors.warning,
        ),
      ),
    );
  }
}

// ── Font selector ──

class _FontSelector extends StatelessWidget {
  final String selectedFont;

  static const _fonts = [
    ('gothic', 'ゴシック', 'デフォルト'),
    ('rounded', '丸ゴシック', '近日公開'),
    ('handwritten', '手書き風', '近日公開'),
  ];

  const _FontSelector({required this.selectedFont});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: _fonts.asMap().entries.map((entry) {
          final index = entry.key;
          final (id, label, note) = entry.value;
          final isSelected = selectedFont == id;
          final isAvailable = id == 'gothic';

          return Column(
            children: [
              if (index > 0) const Divider(height: 1),
              ListTile(
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? colors.primary
                      : isAvailable
                          ? colors.textHint
                          : colors.textHint.withValues(alpha: 0.5),
                ),
                title: Text(
                  label,
                  style: TextStyle(
                    color: isAvailable ? colors.textPrimary : colors.textHint,
                  ),
                ),
                trailing: !isAvailable
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          note,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textHint,
                          ),
                        ),
                      )
                    : null,
                onTap: isAvailable ? () {} : null,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Theme preview card ──

class _ThemePreviewCard extends StatelessWidget {
  final ThemePreset preset;
  final bool isDarkMode;
  final bool glassEnabled;

  const _ThemePreviewCard({
    required this.preset,
    required this.isDarkMode,
    required this.glassEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final grad = AppColorsExtension.gradientFromSeed(
      preset.seedColor,
      isDark: isDarkMode,
    );
    final textColor = isDarkMode ? Colors.white : AppColors.textPrimary;
    final textSecondary =
        isDarkMode ? Colors.white70 : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [grad.start, grad.middle, grad.end],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context)
              .extension<AppColorsExtension>()!
              .glassBorder,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mini app bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (isDarkMode ? Colors.white : Colors.black)
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(
                  'Himatch',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: preset.seedColor,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: preset.seedColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person,
                      size: 14, color: preset.seedColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Mini calendar preview
          Text(
            '2月のスケジュール',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: ['月', '火', '水', '木', '金', '土', '日'].map((d) {
              final isWeekend = d == '土' || d == '日';
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  alignment: Alignment.center,
                  child: Text(
                    d,
                    style: TextStyle(
                      fontSize: 10,
                      color: isWeekend
                          ? preset.seedColor.withValues(alpha: 0.7)
                          : textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(7, (i) {
              final hasEvent = i == 2 || i == 5;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.all(1),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: hasEvent
                        ? preset.seedColor.withValues(alpha: 0.15)
                        : (isDarkMode ? Colors.white : Colors.black)
                            .withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: hasEvent
                          ? preset.seedColor
                          : Colors.transparent,
                      width: hasEvent ? 1 : 0,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${10 + i}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          hasEvent ? FontWeight.bold : FontWeight.normal,
                      color: hasEvent ? preset.seedColor : textColor,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          // Glass effect label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isDarkMode ? Colors.white : Colors.black)
                  .withValues(alpha: glassEnabled ? 0.1 : 0.05),
              borderRadius: BorderRadius.circular(8),
              border: glassEnabled
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    )
                  : null,
            ),
            child: Text(
              glassEnabled ? 'Glass ON' : 'Glass OFF',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Mini button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: preset.seedColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '候補日を提案',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ──

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context)
                .extension<AppColorsExtension>()!
                .textSecondary,
          ),
    );
  }
}
