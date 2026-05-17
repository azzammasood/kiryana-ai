import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/screens/splash_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/voice/screens/voice_input_screen.dart';
import '../features/logs/screens/logs_screen.dart';
import '../features/logs/screens/ai_system_logs_screen.dart';
import '../features/logs/screens/ai_logs_list_screen.dart';
import '../features/logs/screens/manual_entry_screen.dart';
import '../features/insights/screens/insights_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/settings/screens/profile_edit_screen.dart';
import '../features/settings/screens/change_phone_screen.dart';

/// App route names — use these constants for navigation, never raw strings.
abstract class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String voiceInput = '/voice-input';
  static const String transactions = '/transactions';
  static const String logs = '/logs';
  static const String aiLogs = '/ai-logs';
  static const String aiLogDetail = '/ai-logs/:traceId';
  static const String manualEntry = '/manual-entry';
  static const String editEntry = '/manual-entry/:id';
  static const String transactionDetail = '/transactions/:id';
  static const String insights = '/insights';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String profileEdit = '/profile-edit';
  static const String changePhone = '/change-phone';
}

/// GoRouter configuration provider.
/// All navigation logic lives here — screens just call context.go(AppRoutes.xxx).
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      // ── Splash ──────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Onboarding ──────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ── Auth ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Logs ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.logs,
        name: 'logs',
        builder: (context, state) => const LogsScreen(),
      ),
      GoRoute(
        path: AppRoutes.aiLogs,
        name: 'aiLogs',
        builder: (context, state) => const AiLogsListScreen(),
        routes: [
          GoRoute(
            path: ':traceId',
            name: 'aiLogDetail',
            builder: (context, state) {
              final traceId = state.pathParameters['traceId'] ?? '';
              return AiSystemLogsScreen(traceId: traceId);
            },
          ),
        ],
      ),

      // ── Dashboard ───────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),

      // ── Voice Input ─────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.voiceInput,
        name: 'voiceInput',
        builder: (context, state) => const VoiceInputScreen(),
      ),

      // ── Manual Entry ────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.manualEntry,
        name: 'manualEntry',
        builder: (context, state) => const ManualEntryScreen(),
      ),
      GoRoute(
        path: AppRoutes.editEntry,
        name: 'editEntry',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ManualEntryScreen(transactionId: id);
        },
      ),

      // ── Transactions ─────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.transactions,
        name: 'transactions',
        builder: (context, state) => const LogsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'transactionDetail',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return _StubScreen(title: 'Transaction #$id');
            },
          ),
        ],
      ),

      // ── Insights ────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.insights,
        name: 'insights',
        builder: (context, state) => const InsightsScreen(),
      ),

      // ── Settings ────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileEdit,
        name: 'profileEdit',
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePhone,
        name: 'changePhone',
        builder: (context, state) => const ChangePhoneScreen(),
      ),

      // ── Notifications ───────────────────────────────────────────
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) =>
            const _StubScreen(title: 'Notifications'),
      ),

      // ── Profile ─────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const _StubScreen(title: 'Profile'),
      ),
    ],

    // 404 error handler
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Page not found: ${state.uri}',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    ),
  );
});

/// Generic stub screen for routes not yet implemented.
class _StubScreen extends StatelessWidget {
  final String title;
  const _StubScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title screen\n(Coming soon)',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
