import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'providers/daily_message_provider.dart';
import 'providers/power_provider.dart';
import 'providers/theater_provider.dart';
import 'ui/screens/access_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/my_detail_screen.dart';
import 'ui/screens/my_screen.dart';
import 'ui/screens/open_detail_screen.dart';
import 'ui/screens/open_screen.dart';
import 'ui/screens/tune_screen.dart';
import 'ui/shell/radio_app_shell.dart';

class _TabConfig {
  const _TabConfig(this.label, this.path);

  final String label;
  final String path;
}

const _tabs = [
  _TabConfig('HOME', '/home'),
  _TabConfig('주파수 조절', '/tune'),
  _TabConfig('열린 주파수', '/open'),
  _TabConfig('내 라디오', '/my'),
];

const _tabViews = [
  HomeScreen(),
  TuneScreen(),
  OpenScreen(),
  MyScreen(),
];

const _authRoutes = ['/access'];

int _tabIndexForLocation(String location) {
  final index = _tabs.indexWhere((tab) => location.startsWith(tab.path));
  return index == -1 ? 0 : index;
}

int _authIndexForLocation(String location) {
  final index = _authRoutes.indexWhere((route) => location.startsWith(route));
  return index == -1 ? 0 : index;
}

final routerProvider = Provider<GoRouter>((ref) {
  final authStateListenable = ValueNotifier<AuthState>(ref.read(authProvider));
  ref.listen<AuthState>(authProvider, (_, next) {
    authStateListenable.value = next;
  });
  ref.onDispose(authStateListenable.dispose);

  return GoRouter(
    initialLocation:
        authStateListenable.value.isSignedIn ? '/home' : '/access',
    refreshListenable: authStateListenable,
    routes: [
      GoRoute(
        path: '/access',
        builder: (context, state) {
          final modeParam = state.uri.queryParameters['mode'];
          final mode =
              modeParam == 'signup' ? AccessMode.signup : AccessMode.login;
          return Consumer(
            builder: (context, ref, _) {
              final isLoggedIn = ref.watch(authProvider).isSignedIn;
              return RadioAppShell(
                indicatorLabel: 'ACCESS',
                tabIndex: _authIndexForLocation(state.uri.path),
                showControls: false,
                enableIndicatorNudge: false,
                needlePositionOverride: 0.0,
                needleColor: const Color(0xFF9A9A9A),
                isLoggedIn: isLoggedIn,
                onPower: () async {
                  await ref.read(powerStateProvider.notifier).toggle();
                },
                child: AccessScreen(mode: mode),
              );
            },
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          final location = state.uri.path;
          final tabIndex = _tabIndexForLocation(location);
              return Consumer(
            builder: (context, ref, _) {
              final powerOn = ref.watch(powerStateProvider);
              final isLoggedIn = ref.watch(authProvider).isSignedIn;
              final isOpenDetail = location.startsWith('/open/') &&
                  location != '/open';
              final contentOverride = isOpenDetail ? child : null;
              return RadioAppShell(
                indicatorLabel: _tabs[tabIndex].label,
                tabIndex: tabIndex,
                powerOn: powerOn,
                isLoggedIn: isLoggedIn,
                tabViews: _tabViews,
                child: contentOverride,
                onPrev: () {
                  ref.read(powerStateProvider.notifier).playTick();
                  final nextIndex =
                      (tabIndex - 1 + _tabs.length) % _tabs.length;
                  context.go(_tabs[nextIndex].path);
                },
                onNext: () {
                  ref.read(powerStateProvider.notifier).playTick();
                  final nextIndex = (tabIndex + 1) % _tabs.length;
                  context.go(_tabs[nextIndex].path);
                },
                onPower: () async {
                  final powerNotifier = ref.read(powerStateProvider.notifier);
                  final nextState = await powerNotifier.toggle();
                  if (nextState == null) return;
                  if (!location.startsWith('/home')) {
                    context.go('/home');
                  }
                  if (nextState) {
                    ref.read(dailyMessageProvider.notifier).power();
                  }
                },
              );
            },
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: const HomeScreen(),
                transitionDuration: const Duration(milliseconds: 220),
                transitionsBuilder: (context, animation, secondary, child) {
                  final fade = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  );
                  final scale = Tween<double>(begin: 0.98, end: 1.0)
                      .chain(CurveTween(curve: Curves.easeOutCubic))
                      .animate(animation);
                  return FadeTransition(
                    opacity: fade,
                    child: ScaleTransition(scale: scale, child: child),
                  );
                },
              );
            },
          ),
          GoRoute(
            path: '/tune',
            builder: (context, state) => const TuneScreen(),
          ),
          GoRoute(
            path: '/open',
            builder: (context, state) => const OpenScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return PopScope(
                    onPopInvoked: (didPop) {
                      if (!didPop) return;
                      // ✅ 뒤로가기/돌아가기 시 theater 복귀
                      ref.read(theaterProvider.notifier).resume();
                      },
                   child: OpenDetailScreen(postId: id),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/my',
            builder: (context, state) => const MyScreen(),
            routes: [
              GoRoute(
                path: 'detail/:id',
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return MyDetailScreen(postId: id);
                },
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final signedIn = authStateListenable.value.isSignedIn;
      final loggingIn = state.matchedLocation == '/access';
      if (!signedIn && !loggingIn) {
        return '/access';
      }
      if (signedIn && loggingIn) {
        return '/home';
      }
      return null;
    },
  );
});
