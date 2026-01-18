import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'providers/daily_message_provider.dart';
import 'providers/power_provider.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/my_screen.dart';
import 'ui/screens/placeholder_screen.dart';
import 'ui/screens/signup_screen.dart';
import 'ui/shell/radio_app_shell.dart';

class _TabConfig {
  const _TabConfig(this.label, this.path);

  final String label;
  final String path;
}

const _tabs = [
  _TabConfig('HOME', '/home'),
  _TabConfig('FREQUENCY', '/freq'),
  _TabConfig('OPEN', '/open'),
  _TabConfig('MY', '/my'),
];

const _authRoutes = ['/login', '/signup'];

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
        authStateListenable.value.isSignedIn ? '/home' : '/login',
    refreshListenable: authStateListenable,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, _) {
              return RadioAppShell(
                indicatorLabel: 'ACCESS',
                tabIndex: _authIndexForLocation(state.uri.path),
                showControls: false,
                onPrev: () => context.go(_authRoutes.last),
                onNext: () => context.go(_authRoutes.last),
                onPower: () {
                  final notifier = ref.read(powerStateProvider.notifier);
                  notifier.state = !notifier.state;
                },
                child: const LoginScreen(),
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, _) {
              return RadioAppShell(
                indicatorLabel: 'ACCESS',
                tabIndex: _authIndexForLocation(state.uri.path),
                showControls: false,
                onPrev: () => context.go(_authRoutes.first),
                onNext: () => context.go(_authRoutes.first),
                onPower: () {
                  final notifier = ref.read(powerStateProvider.notifier);
                  notifier.state = !notifier.state;
                },
                child: const SignUpScreen(),
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
              return RadioAppShell(
                indicatorLabel: _tabs[tabIndex].label,
                tabIndex: tabIndex,
                powerOn: powerOn,
                onPrev: () {
                  if (location.startsWith('/home')) {
                    context.go('/login');
                    return;
                  }
                  final nextIndex =
                      (tabIndex - 1 + _tabs.length) % _tabs.length;
                  context.go(_tabs[nextIndex].path);
                },
                onNext: () {
                  if (location.startsWith('/home')) {
                    context.go('/signup');
                    return;
                  }
                  final nextIndex = (tabIndex + 1) % _tabs.length;
                  context.go(_tabs[nextIndex].path);
                },
                onPower: () {
                  final powerNotifier = ref.read(powerStateProvider.notifier);
                  final nextState = !powerNotifier.state;
                  powerNotifier.state = nextState;
                  if (!location.startsWith('/home')) {
                    context.go('/home');
                  }
                  if (nextState) {
                    ref.read(dailyMessageProvider.notifier).power();
                  }
                },
                child: child,
              );
            },
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/freq',
            builder: (context, state) => const PlaceholderScreen(
              title: 'Frequency Lab',
              subtitle: 'Experiment with the dial and watch the needle shift.',
            ),
          ),
          GoRoute(
            path: '/open',
            builder: (context, state) => const PlaceholderScreen(
              title: 'Open Air',
              subtitle: 'A quiet space for future broadcasts.',
            ),
          ),
          GoRoute(
            path: '/my',
            builder: (context, state) => const MyScreen(),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final signedIn = authStateListenable.value.isSignedIn;
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';
      if (!signedIn && !loggingIn) {
        return '/login';
      }
      if (signedIn && loggingIn) {
        return '/home';
      }
      return null;
    },
  );
});
