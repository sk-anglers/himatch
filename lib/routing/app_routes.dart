/// Named route definitions for go_router.
///
/// Usage: `context.goNamed(AppRoute.groupDetail.name, pathParameters: {'id': groupId})`
enum AppRoute {
  // ── Top-level ──
  home,
  login,

  // ── Schedule ──
  scheduleForm,
  calendarSyncSettings,
  templateEditor,

  // ── Group ──
  groupDetail,
  groupCalendar,
  shiftListCalendar,
  chat,
  poll,
  board,
  todoList,
  album,
  activityFeed,
  expense,
  settlement,

  // ── Suggestion ──
  booking,
  shareCard,
  publicVote,

  // ── Shift / Salary ──
  workplaceSettings,
  salarySummary,
  shiftPattern,

  // ── Profile / Settings ──
  weatherLocation,
  themeSettings,
  notificationSettings,
  calendarSync,
  termsOfService,
  privacyPolicy,
  contact,

  // ── Other ──
  history,
  wellbeing,
}
