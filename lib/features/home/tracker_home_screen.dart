import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/lawsuit.dart';
import '../../data/providers.dart';
import 'home_filter_provider.dart';
import 'widgets/home_filter_controls.dart';
import 'widgets/lawsuit_feed.dart';
import 'widgets/search_field.dart';

/// Tracker tab home (route `/tracker`).
///
/// The registered user's home: a search field, a filter row bound to
/// [homeFilterProvider], and a provider-backed feed of active (and optionally
/// expired) lawsuits. Rendered inside the shell scaffold, so it adds no bottom
/// navigation of its own.
class TrackerHomeScreen extends ConsumerStatefulWidget {
  const TrackerHomeScreen({super.key});

  @override
  ConsumerState<TrackerHomeScreen> createState() => _TrackerHomeScreenState();
}

class _TrackerHomeScreenState extends ConsumerState<TrackerHomeScreen> {
  String _query = '';

  bool _matches(Lawsuit lawsuit) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return lawsuit.title.toLowerCase().contains(q) ||
        lawsuit.brand.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(homeFilterProvider);
    final activeAsync = ref.watch(activeLawsuitsProvider);
    final expiredAsync = ref.watch(expiredLawsuitsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _TopAppBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                children: <Widget>[
                  SearchField(
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 16),
                  HomeFilterControls(
                    showExpired: filter.showExpired,
                    timeframe: filter.timeframe,
                    onShowExpiredChanged: (value) => ref
                        .read(homeFilterProvider.notifier)
                        .toggleShowExpired(value),
                    onTimeframeChanged: (value) => ref
                        .read(homeFilterProvider.notifier)
                        .setTimeframe(value),
                  ),
                  const SizedBox(height: 24),
                  LawsuitFeed(
                    activeAsync: activeAsync,
                    expiredAsync: expiredAsync,
                    showExpired: filter.showExpired,
                    activeFilter: _matches,
                    onTap: (lawsuit) => context.go('/lawsuit/${lawsuit.id}'),
                    onRetry: () {
                      ref.invalidate(activeLawsuitsProvider);
                      ref.invalidate(expiredLawsuitsProvider);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.gavel, color: AppColors.navy, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'ClaimPal',
              style: AppTextStyles.headlineSm.copyWith(color: AppColors.navy),
            ),
          ),
          const Icon(
            Icons.notifications_none,
            color: AppColors.onSurface,
            size: 28,
          ),
        ],
      ),
    );
  }
}
