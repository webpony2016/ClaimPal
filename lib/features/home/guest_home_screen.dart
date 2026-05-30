import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/fomo_banner.dart';
import '../../data/models/lawsuit.dart';
import '../../data/providers.dart';
import '../account/account_provider.dart';
import 'home_filter_provider.dart';
import 'widgets/home_filter_controls.dart';
import 'widgets/lawsuit_feed.dart';

/// Guest landing screen (route `/`).
///
/// A FOMO-driven entry point: a gradient banner summarizing missed/upcoming
/// payouts, a control panel (Show Expired switch + timeframe selector), then a
/// mixed feed of active (vivid) and — when toggled — expired (dimmed) lawsuits.
/// A "Get started" action registers the guest and enters the tracker.
class GuestHomeScreen extends ConsumerWidget {
  const GuestHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(homeFilterProvider);
    final fomoAsync = ref.watch(fomoSummaryProvider);
    final activeAsync = ref.watch(activeLawsuitsProvider);
    final expiredAsync = ref.watch(expiredLawsuitsProvider);

    void openDetail(Lawsuit lawsuit) => context.go('/lawsuit/${lawsuit.id}');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Row(
          children: <Widget>[
            const Icon(Icons.gavel, color: AppColors.navy, size: 28),
            const SizedBox(width: 8),
            Text(
              'ClaimPal',
              style: AppTextStyles.headlineSm.copyWith(color: AppColors.navy),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              ref.read(accountProvider.notifier).register();
              context.go('/tracker');
            },
            child: const Text('Sign in'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          fomoAsync.when(
            loading: () => const _BannerPlaceholder(),
            error: (error, _) => _FomoError(
              onRetry: () => ref.invalidate(fomoSummaryProvider),
            ),
            data: (summary) => FomoBanner(
              summary: summary.copyWith(timeframe: filter.timeframe),
            ),
          ),
          const SizedBox(height: 24),
          Text('Discover Claims', style: AppTextStyles.headlineSm),
          const SizedBox(height: 12),
          HomeFilterControls(
            showExpired: filter.showExpired,
            timeframe: filter.timeframe,
            onShowExpiredChanged: (value) =>
                ref.read(homeFilterProvider.notifier).toggleShowExpired(value),
            onTimeframeChanged: (value) =>
                ref.read(homeFilterProvider.notifier).setTimeframe(value),
          ),
          const SizedBox(height: 16),
          LawsuitFeed(
            activeAsync: activeAsync,
            expiredAsync: expiredAsync,
            showExpired: filter.showExpired,
            onTap: openDetail,
            onRetry: () {
              ref.invalidate(activeLawsuitsProvider);
              ref.invalidate(expiredLawsuitsProvider);
            },
          ),
          const SizedBox(height: 24),
          _GetStartedBanner(
            onPressed: () {
              ref.read(accountProvider.notifier).register();
              context.go('/tracker');
            },
          ),
        ],
      ),
    );
  }
}

class _BannerPlaceholder extends StatelessWidget {
  const _BannerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.surfaceContainerLow,
      ),
      child: const CircularProgressIndicator(),
    );
  }
}

class _FomoError extends StatelessWidget {
  const _FomoError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Couldn't load your summary",
              style: AppTextStyles.bodyMd,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _GetStartedBanner extends StatelessWidget {
  const _GetStartedBanner({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          Text(
            "Don't lose another dollar.",
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMd.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Track open settlements and file claims in minutes.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successDark,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Get started'),
          ),
        ],
      ),
    );
  }
}
