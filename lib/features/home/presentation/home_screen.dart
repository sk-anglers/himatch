import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/constants/app_spacing.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/core/widgets/gradient_scaffold.dart';
import 'package:himatch/routing/app_router.dart';
import 'package:himatch/features/schedule/presentation/calendar_tab.dart';
import 'package:himatch/features/group/presentation/groups_tab.dart';
import 'package:himatch/features/suggestion/presentation/suggestions_tab.dart';
import 'package:himatch/features/profile/presentation/profile_tab.dart';
import 'package:himatch/features/group/presentation/providers/notification_providers.dart';
import 'package:himatch/providers/theme_providers.dart';
import 'package:himatch/widgets/lazy_indexed_stack.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  static const _tabTitles = ['カレンダー', '提案', 'グループ', 'マイページ'];

  @override
  Widget build(BuildContext context) {
    final totalNotifications = ref.watch(totalGroupNotificationsProvider);
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final glassEnabled = ref.watch(
      themeSettingsProvider.select((s) => s.glassEffectEnabled),
    );

    return GradientScaffold(
      extendBody: true,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(Icons.event_available, color: colors.primary),
        ),
        title: Text(
          _selectedIndex == 0 ? 'Himatch' : _tabTitles[_selectedIndex],
          style: _selectedIndex == 0
              ? Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)
              : Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
        ),
        flexibleSpace: glassEnabled
            ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: AppSpacing.glassBlurLite,
                    sigmaY: AppSpacing.glassBlurLite,
                  ),
                  child: Container(color: Colors.transparent),
                ),
              )
            : null,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: totalNotifications > 0,
              label: Text('$totalNotifications'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () {
              ref.read(appRouterProvider).push('/settings/notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              ref.read(appRouterProvider).push('/settings/theme');
            },
          ),
        ],
      ),
      body: LazyIndexedStack(
        index: _selectedIndex,
        children: const [
          CalendarTab(),
          SuggestionsTab(),
          GroupsTab(),
          ProfileTab(),
        ],
      ),
      bottomNavigationBar: _GlassNavigationBar(
        selectedIndex: _selectedIndex,
        totalNotifications: totalNotifications,
        glassEnabled: glassEnabled,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}

class _GlassNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final int totalNotifications;
  final bool glassEnabled;
  final ValueChanged<int> onDestinationSelected;

  const _GlassNavigationBar({
    required this.selectedIndex,
    required this.totalNotifications,
    required this.glassEnabled,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final navBar = NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'カレンダー',
        ),
        const NavigationDestination(
          icon: Icon(Icons.lightbulb_outline),
          selectedIcon: Icon(Icons.lightbulb),
          label: '提案',
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: totalNotifications > 0,
            label: Text('$totalNotifications'),
            child: const Icon(Icons.group_outlined),
          ),
          selectedIcon: Badge(
            isLabelVisible: totalNotifications > 0,
            label: Text('$totalNotifications'),
            child: const Icon(Icons.group),
          ),
          label: 'グループ',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'マイページ',
        ),
      ],
    );

    if (!glassEnabled) return navBar;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppSpacing.glassBlur,
          sigmaY: AppSpacing.glassBlur,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context)
                .extension<AppColorsExtension>()!
                .glassBackground,
            border: Border(
              top: BorderSide(
                color: Theme.of(context)
                    .extension<AppColorsExtension>()!
                    .glassBorder,
              ),
            ),
          ),
          child: navBar,
        ),
      ),
    );
  }
}
