import 'package:flutter/material.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/features/schedule/presentation/calendar_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Himatch',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          CalendarTab(),
          _SuggestionsTab(),
          _GroupsTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'カレンダー',
          ),
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outline),
            selectedIcon: Icon(Icons.lightbulb),
            label: '提案',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'グループ',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'マイページ',
          ),
        ],
      ),
    );
  }
}


class _SuggestionsTab extends StatelessWidget {
  const _SuggestionsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb, size: 64, color: AppColors.primary),
          SizedBox(height: 16),
          Text('候補日提案', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text(
            'グループに参加すると候補日が表示されます',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _GroupsTab extends StatelessWidget {
  const _GroupsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group, size: 64, color: AppColors.primary),
          SizedBox(height: 16),
          Text('グループ', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text(
            'グループを作成して友達と共有しましょう',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 64, color: AppColors.primary),
          SizedBox(height: 16),
          Text('マイページ', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text(
            'プロフィールと設定',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
