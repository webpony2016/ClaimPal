import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/detail/lawsuit_detail_screen.dart';
import '../../features/filing/filing_screen.dart';
import '../../features/home/explore_screen.dart';
import '../../features/home/guest_home_screen.dart';
import '../../features/home/tracker_home_screen.dart';
import '../../features/pricing/pricing_screen.dart';
import '../../features/profile/my_claims_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/referral/referral_screen.dart';
import '../../features/referral/wallet_screen.dart';

/// Builds the app's [GoRouter].
///
/// Top-level routes cover guest home, lawsuit detail, filing, pricing,
/// referral and wallet. A [StatefulShellRoute.indexedStack] hosts the four
/// bottom-nav tabs (Tracker / Explore / My Claims / Profile) with preserved
/// per-tab state.
GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const GuestHomeScreen(),
      ),
      GoRoute(
        path: '/lawsuit/:id',
        builder: (context, state) =>
            LawsuitDetailScreen(lawsuitId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/filing/:id',
        builder: (context, state) =>
            FilingScreen(lawsuitId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/pricing',
        builder: (context, state) => const PricingScreen(),
      ),
      GoRoute(
        path: '/referral',
        builder: (context, state) => const ReferralScreen(),
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _ShellScaffold(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/tracker',
                builder: (context, state) => const TrackerHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/explore',
                builder: (context, state) => const ExploreScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/my-claims',
                builder: (context, state) => const MyClaimsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Shell scaffold hosting the indexed-stack tab content with a bottom
/// [NavigationBar] that switches branches.
class _ShellScaffold extends StatelessWidget {
  const _ShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            label: 'Tracker',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_turned_in_outlined),
            label: 'My Claims',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
