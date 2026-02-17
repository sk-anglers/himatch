import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/routing/app_routes.dart';
import 'package:himatch/features/schedule/presentation/calendar_tab.dart';
import 'package:himatch/features/group/presentation/groups_tab.dart';
import 'package:himatch/features/suggestion/presentation/suggestions_tab.dart';
import 'package:himatch/features/profile/presentation/profile_tab.dart';
import 'package:himatch/features/group/presentation/providers/notification_providers.dart';
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

    return Scaffold(
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
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: totalNotifications > 0,
              label: Text('$totalNotifications'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              context.pushNamed(AppRoute.themeSettings.name);
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
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
      ),
    );
  }
}
