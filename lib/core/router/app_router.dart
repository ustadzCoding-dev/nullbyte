import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nullbyte/core/router/nullbyte_shell.dart';
import 'package:nullbyte/features/active_session/screens/active_session_screen.dart';
import 'package:nullbyte/features/achievements/screens/achievements_screen.dart';
import 'package:nullbyte/features/auth/data/auth_provider.dart';
import 'package:nullbyte/features/auth/screens/auth_screen.dart';
import 'package:nullbyte/features/dictionary/screens/dictionary_screen.dart';
import 'package:nullbyte/features/home/screens/main_menu_screen.dart';
import 'package:nullbyte/features/mission/screens/mission_clear_screen.dart';
import 'package:nullbyte/features/mission/screens/mission_select_screen.dart';
import 'package:nullbyte/features/onboarding/screens/disclaimer_screen.dart';
import 'package:nullbyte/features/onboarding/screens/onboarding_screen.dart';
import 'package:nullbyte/features/onboarding/screens/splash_screen.dart';
import 'package:nullbyte/features/profile/screens/profile_screen.dart';
import 'package:nullbyte/features/settings/screens/settings_screen.dart';
import 'package:nullbyte/shared/models/player_profile.dart';
import 'package:nullbyte/shared/screens/v1_focus_screen.dart';

class LocalAuthNotifier extends ChangeNotifier {
  final Ref _ref;
  bool _isAuthenticated = false;

  LocalAuthNotifier(this._ref) {
    _ref.listen<PlayerProfile?>(authNotifierProvider, (previous, next) {
      final wasAuthenticated = _isAuthenticated;
      _isAuthenticated = next != null;
      if (wasAuthenticated != _isAuthenticated) {
        notifyListeners();
      }
    });
  }

  bool get isAuthenticated => _isAuthenticated;
}

class DisclaimerNotifier extends ValueNotifier<bool> {
  DisclaimerNotifier() : super(false);

  bool get isAccepted => value;

  void setAccepted(bool accepted) => value = accepted;
}

class AppRouter {
  AppRouter._();

  static final disclaimerNotifier = DisclaimerNotifier();

  static GoRouter createRouter(Ref ref) {
    final authNotifier = LocalAuthNotifier(ref);

    final refreshListenable = Listenable.merge([
      authNotifier,
      disclaimerNotifier,
    ]);

    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: refreshListenable,
      redirect: (context, state) => _guard(state, authNotifier: authNotifier),
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(
          path: '/disclaimer',
          builder: (_, __) => const DisclaimerScreen(),
        ),
        GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
        GoRoute(
          path: '/onboarding',
          builder: (_, __) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/session/:levelId',
          builder: (_, state) =>
              ActiveSessionScreen(levelId: state.pathParameters['levelId']!),
          routes: [
            GoRoute(
              path: 'result',
              builder: (_, state) =>
                  MissionClearScreen(levelId: state.pathParameters['levelId']!),
            ),
          ],
        ),
        GoRoute(
          path: '/inventory',
          builder: (_, __) => const V1FocusScreen(
            title: 'INVENTORY',
            summary:
                'Inventory belum dijadikan sistem inti di NULLBYTE v1. Fokus rilis saat ini adalah mission progression, terminal challenge, score, dan unlock level.',
            recommendation:
                'Lanjutkan mission utama dulu. Inventory akan diaktifkan kembali setelah core loop v1 benar-benar stabil.',
          ),
        ),
        GoRoute(
          path: '/skills',
          builder: (_, __) => const V1FocusScreen(
            title: 'SKILL TREE',
            summary:
                'Skill tree masih ditunda agar arah produk tetap jelas. V1 dipusatkan pada pembelajaran command path dan progression level.',
            recommendation:
                'Gunakan mission flow sebagai progression utama. Skill effects akan ditambahkan kembali setelah balancing gameplay inti matang.',
          ),
        ),
        GoRoute(
          path: '/leaderboard',
          builder: (_, __) => const V1FocusScreen(
            title: 'LEADERBOARD',
            summary:
                'Leaderboard remote belum dijadikan fitur aktif di v1 karena datanya belum menjadi sumber kebenaran utama.',
            recommendation:
                'Prioritas sekarang adalah menuntaskan mission, score, stars, dan unlock level secara lokal dengan konsisten.',
          ),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              NullbyteShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (_, __) => const MainMenuScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/mission',
                  builder: (_, __) => const MissionSelectScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/dictionary',
                  builder: (_, __) => const DictionaryScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/achievements',
                  builder: (_, __) => const AchievementsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (_, __) => const ProfileScreen(),
                  routes: [
                    GoRoute(
                      path: 'settings',
                      builder: (_, __) => const SettingsScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static String? _guard(
    GoRouterState state, {
    required LocalAuthNotifier authNotifier,
  }) {
    final location = state.matchedLocation;
    final disclaimerAccepted = disclaimerNotifier.isAccepted;
    final isAuthenticated = authNotifier.isAuthenticated;

    if (location == '/splash') return null;

    if (!disclaimerAccepted) {
      if (location == '/disclaimer') return null;
      return '/disclaimer';
    }

    if (!isAuthenticated) {
      if (location == '/auth' || location == '/onboarding') return null;
      return '/auth';
    }

    if (location == '/auth' || location == '/disclaimer') return '/home';

    return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) => AppRouter.createRouter(ref));
