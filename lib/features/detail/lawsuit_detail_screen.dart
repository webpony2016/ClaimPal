import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/category_icons.dart';
import '../../core/widgets/privacy_badge.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/lawsuit.dart';
import '../../data/providers.dart';
import '../filing/start_filing.dart';

/// Lawsuit detail screen (route `/lawsuit/:id`).
///
/// Shows the brand, estimated payout, eligibility and required proof, plus a
/// "File Claim" CTA that routes through the access guard via [startFiling].
class LawsuitDetailScreen extends ConsumerWidget {
  const LawsuitDetailScreen({super.key, required this.lawsuitId});

  final String lawsuitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lawsuitAsync = ref.watch(lawsuitByIdProvider(lawsuitId));

    return Scaffold(
      appBar: AppBar(title: const Text('Settlement Details')),
      body: lawsuitAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorState(
          onRetry: () => ref.invalidate(lawsuitByIdProvider(lawsuitId)),
        ),
        data: (lawsuit) {
          if (lawsuit == null) return const _NotFoundState();
          return _DetailBody(lawsuit: lawsuit);
        },
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.lawsuit});

  final Lawsuit lawsuit;

  bool get _isActive => lawsuit.status == LawsuitStatus.active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _BrandBlock(lawsuit: lawsuit),
                const SizedBox(height: 24),
                Text(
                  lawsuit.payoutLabel.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.outline,
                    fontSize: 14,
                    height: 16 / 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lawsuit.payoutValue,
                  style: AppTextStyles.headlineLg.copyWith(
                    color: _isActive
                        ? AppColors.successDark
                        : AppColors.expired,
                  ),
                ),
                const SizedBox(height: 24),
                _Section(
                  title: 'Am I eligible?',
                  child: Text(
                    lawsuit.eligibility,
                    style: AppTextStyles.bodyMd
                        .copyWith(color: AppColors.mutedText),
                  ),
                ),
                const SizedBox(height: 24),
                _Section(
                  title: "What you'll need",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (final proof in lawsuit.requiredProof)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Icon(
                                Icons.check_circle_outline,
                                size: 20,
                                color: AppColors.successDark,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  proof,
                                  style: AppTextStyles.bodyMd,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const PrivacyBadge(),
              ],
            ),
          ),
        ),
        _BottomBar(lawsuit: lawsuit, isActive: _isActive),
      ],
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock({required this.lawsuit});

  final Lawsuit lawsuit;

  @override
  Widget build(BuildContext context) {
    final bool active = lawsuit.status == LawsuitStatus.active;
    final Color color = active ? AppColors.primary : AppColors.expired;
    final String statusLabel = active
        ? 'Active'
        : 'Expired ${lawsuit.expiredDaysAgo ?? 0} Days Ago';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.32)),
          ),
          child: Icon(iconForCategory(lawsuit.category), color: color, size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                lawsuit.brand,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 2),
              Text(lawsuit.title, style: AppTextStyles.headlineSm),
              const SizedBox(height: 8),
              StatusBadge(label: statusLabel, isActive: active),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: AppTextStyles.headlineSm),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.lawsuit, required this.isActive});

  final Lawsuit lawsuit;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.outlineVariant)),
        ),
        child: isActive
            ? ElevatedButton(
                onPressed: () => startFiling(context, ref, lawsuit),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successDark,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                ),
                child: const Text(
                  'File Claim',
                  style: TextStyle(
                    fontSize: 20,
                    height: 28 / 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  disabledBackgroundColor: AppColors.surfaceContainerLow,
                  disabledForegroundColor: AppColors.expired,
                ),
                child: const Text(
                  'Claim Window Closed',
                  style: TextStyle(
                    fontSize: 20,
                    height: 28 / 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              "Couldn't load this lawsuit",
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSm,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotFoundState extends StatelessWidget {
  const _NotFoundState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.search_off,
              size: 48,
              color: AppColors.expired,
            ),
            const SizedBox(height: 16),
            Text(
              'Lawsuit not found',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSm,
            ),
            const SizedBox(height: 8),
            Text(
              "We couldn't find this settlement. It may have been removed.",
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.bodyMd.copyWith(color: AppColors.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}
