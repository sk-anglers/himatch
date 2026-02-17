import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:himatch/models/group.dart';
import 'package:himatch/models/schedule.dart';
import 'package:himatch/routing/app_routes.dart';

// ── Auth ──
import 'package:himatch/features/auth/presentation/login_screen.dart';
import 'package:himatch/features/auth/providers/auth_providers.dart';

// ── Home ──
import 'package:himatch/features/home/presentation/home_screen.dart';

// ── Schedule ──
import 'package:himatch/features/schedule/presentation/schedule_form_screen.dart';
import 'package:himatch/features/schedule/presentation/calendar_sync_settings_screen.dart';
import 'package:himatch/features/schedule/presentation/template_screen.dart';

// ── Group ──
import 'package:himatch/features/group/presentation/group_detail_screen.dart';
import 'package:himatch/features/group/presentation/group_calendar_screen.dart';
import 'package:himatch/features/group/presentation/shift_list_calendar_screen.dart';
import 'package:himatch/features/chat/presentation/chat_screen.dart';
import 'package:himatch/features/group/presentation/poll_screen.dart';
import 'package:himatch/features/group/presentation/board_screen.dart';
import 'package:himatch/features/group/presentation/todo_list_screen.dart';
import 'package:himatch/features/group/presentation/album_screen.dart';
import 'package:himatch/features/group/presentation/activity_feed_screen.dart';

// ── Expense ──
import 'package:himatch/features/expense/presentation/expense_screen.dart';
import 'package:himatch/features/expense/presentation/settlement_screen.dart';

// ── Suggestion ──
import 'package:himatch/features/booking/presentation/booking_screen.dart';
import 'package:himatch/features/suggestion/presentation/share_card_screen.dart';
import 'package:himatch/features/suggestion/presentation/public_vote_screen.dart';

// ── Shift / Salary ──
import 'package:himatch/features/shift/presentation/workplace_settings_screen.dart';
import 'package:himatch/features/shift/presentation/salary_summary_screen.dart';
import 'package:himatch/features/shift/presentation/shift_pattern_screen.dart';

// ── Profile / Settings ──
import 'package:himatch/features/profile/presentation/weather_location_screen.dart';
import 'package:himatch/features/profile/presentation/theme_settings_screen.dart';
import 'package:himatch/features/profile/presentation/notification_settings_screen.dart';
import 'package:himatch/features/profile/presentation/terms_of_service_screen.dart';
import 'package:himatch/features/profile/presentation/privacy_policy_screen.dart';
import 'package:himatch/features/profile/presentation/contact_screen.dart';

// ── Other ──
import 'package:himatch/features/history/presentation/history_screen.dart';
import 'package:himatch/features/wellbeing/presentation/wellbeing_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isOnLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isOnLogin) return '/login';
      if (isLoggedIn && isOnLogin) return '/';
      return null;
    },
    routes: [
      // ── Top-level ──
      GoRoute(
        path: '/',
        name: AppRoute.home.name,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: AppRoute.login.name,
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Schedule ──
      GoRoute(
        path: '/schedule/new',
        name: AppRoute.scheduleForm.name,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ScheduleFormScreen(
            initialDate:
                extra?['initialDate'] as DateTime? ?? DateTime.now(),
            schedule: extra?['schedule'] as Schedule?,
          );
        },
      ),
      GoRoute(
        path: '/schedule/calendar-sync',
        name: AppRoute.calendarSyncSettings.name,
        builder: (context, state) => const CalendarSyncSettingsScreen(),
      ),
      GoRoute(
        path: '/schedule/templates',
        name: AppRoute.templateEditor.name,
        builder: (context, state) => const TemplateScreen(),
      ),

      // ── Group ──
      GoRoute(
        path: '/group/:groupId',
        name: AppRoute.groupDetail.name,
        builder: (context, state) {
          final group = state.extra as Group;
          return GroupDetailScreen(group: group);
        },
        routes: [
          GoRoute(
            path: 'calendar',
            name: AppRoute.groupCalendar.name,
            builder: (context, state) {
              final group = state.extra as Group;
              return GroupCalendarScreen(group: group);
            },
          ),
          GoRoute(
            path: 'shift-calendar',
            name: AppRoute.shiftListCalendar.name,
            builder: (context, state) {
              final group = state.extra as Group;
              return ShiftListCalendarScreen(group: group);
            },
          ),
          GoRoute(
            path: 'chat',
            name: AppRoute.chat.name,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return ChatScreen(
                groupId: extra['groupId'] as String,
                groupName: extra['groupName'] as String,
                memberCount: extra['memberCount'] as int,
              );
            },
          ),
          GoRoute(
            path: 'poll',
            name: AppRoute.poll.name,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return PollScreen(
                groupId: extra['groupId'] as String,
                groupName: extra['groupName'] as String,
              );
            },
          ),
          GoRoute(
            path: 'board',
            name: AppRoute.board.name,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return BoardScreen(
                groupId: extra['groupId'] as String,
                groupName: extra['groupName'] as String,
              );
            },
          ),
          GoRoute(
            path: 'todo',
            name: AppRoute.todoList.name,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return TodoListScreen(
                groupId: extra['groupId'] as String,
                groupName: extra['groupName'] as String,
              );
            },
          ),
          GoRoute(
            path: 'album',
            name: AppRoute.album.name,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return AlbumScreen(
                groupId: extra['groupId'] as String,
                groupName: extra['groupName'] as String,
              );
            },
          ),
          GoRoute(
            path: 'activity',
            name: AppRoute.activityFeed.name,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return ActivityFeedScreen(
                groupId: extra['groupId'] as String,
                groupName: extra['groupName'] as String,
              );
            },
          ),
          GoRoute(
            path: 'expense',
            name: AppRoute.expense.name,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return ExpenseScreen(
                groupId: extra['groupId'] as String,
                groupName: extra['groupName'] as String,
              );
            },
          ),
          GoRoute(
            path: 'settlement',
            name: AppRoute.settlement.name,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return SettlementScreen(
                groupId: extra['groupId'] as String,
                groupName: extra['groupName'] as String,
              );
            },
          ),
        ],
      ),

      // ── Suggestion ──
      GoRoute(
        path: '/booking',
        name: AppRoute.booking.name,
        builder: (context, state) => const BookingScreen(),
      ),
      GoRoute(
        path: '/share-card',
        name: AppRoute.shareCard.name,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ShareCardScreen(
            date: extra['date'] as String?,
            activity: extra['activity'] as String?,
            groupName: extra['groupName'] as String?,
            memberNames:
                (extra['memberNames'] as List<String>?) ?? const [],
            weatherIcon: extra['weatherIcon'] as String?,
            weatherCondition: extra['weatherCondition'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/public-vote',
        name: AppRoute.publicVote.name,
        builder: (context, state) => const PublicVoteScreen(),
      ),

      // ── Shift / Salary ──
      GoRoute(
        path: '/shift/workplace-settings',
        name: AppRoute.workplaceSettings.name,
        builder: (context, state) => const WorkplaceSettingsScreen(),
      ),
      GoRoute(
        path: '/shift/salary-summary',
        name: AppRoute.salarySummary.name,
        builder: (context, state) => const SalarySummaryScreen(),
      ),
      GoRoute(
        path: '/shift/patterns',
        name: AppRoute.shiftPattern.name,
        builder: (context, state) => const ShiftPatternScreen(),
      ),

      // ── Profile / Settings ──
      GoRoute(
        path: '/settings/weather-location',
        name: AppRoute.weatherLocation.name,
        builder: (context, state) => const WeatherLocationScreen(),
      ),
      GoRoute(
        path: '/settings/theme',
        name: AppRoute.themeSettings.name,
        builder: (context, state) => const ThemeSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        name: AppRoute.notificationSettings.name,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/terms',
        name: AppRoute.termsOfService.name,
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
      GoRoute(
        path: '/settings/privacy',
        name: AppRoute.privacyPolicy.name,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/settings/contact',
        name: AppRoute.contact.name,
        builder: (context, state) => const ContactScreen(),
      ),

      // ── Other ──
      GoRoute(
        path: '/history',
        name: AppRoute.history.name,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/wellbeing',
        name: AppRoute.wellbeing.name,
        builder: (context, state) => const WellbeingScreen(),
      ),
    ],
  );
});
