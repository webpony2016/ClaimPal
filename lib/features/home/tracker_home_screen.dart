import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/lawsuit.dart';
import '../../data/providers.dart';
import 'home_filter_provider.dart';
import 'tracker_claim_status.dart';
import 'widgets/home_filter_controls.dart';
import 'widgets/lawsuit_feed.dart';
import 'widgets/search_field.dart';
import 'widgets/tracker_lawsuit_card.dart';

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
  static final NumberFormat _currency = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  String _query = '';

  // The Tracker now defaults to active/in-progress work only. Users can still
  // toggle the expired list back on when they want to revisit closed cases.
  bool _showExpired = false;

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
    final payoutTotal = ref.watch(trackerPayoutTotalProvider);

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
                    showExpired: _showExpired,
                    timeframe: filter.timeframe,
                    onShowExpiredChanged: (value) =>
                        setState(() => _showExpired = value),
                    onTimeframeChanged: (value) => ref
                        .read(homeFilterProvider.notifier)
                        .setTimeframe(value),
                  ),
                  if (!_showExpired && payoutTotal > 0) ...<Widget>[
                    const SizedBox(height: 16),
                    _PayoutSummaryCard(total: _currency.format(payoutTotal)),
                  ],
                  const SizedBox(height: 24),
                  LawsuitFeed(
                    activeAsync: activeAsync,
                    expiredAsync: expiredAsync,
                    showExpired: _showExpired,
                    activeFilter: _matches,
                    // Tracker surfaces expired/closing settlements first and
                    // overlays the user's per-claim status on each card.
                    expiredFirst: true,
                    cardBuilder: (lawsuit, onTap) =>
                        TrackerLawsuitCard(
                          lawsuit: lawsuit,
                          onTap: onTap,
                        ),
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

class _PayoutSummaryCard extends StatelessWidget {
  const _PayoutSummaryCard({required this.total});

  final String total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.verified_outlined,
              color: AppColors.successDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Received payouts',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  total,
                  style: AppTextStyles.headlineSm.copyWith(
                    color: AppColors.successDark,
                  ),
                ),
              ],
            ),
          ),
        ],
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
