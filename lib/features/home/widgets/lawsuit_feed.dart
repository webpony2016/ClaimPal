import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/lawsuit_card.dart';
import '../../../data/models/lawsuit.dart';

/// Renders the mixed active/expired lawsuit feed.
///
/// Active lawsuits always render (vivid); expired lawsuits append below them
/// (dimmed via [LawsuitCard]'s own styling) only when [showExpired] is true.
/// Async states are handled via `.when`: a spinner while loading and an inline
/// retry row on error.
class LawsuitFeed extends StatelessWidget {
  const LawsuitFeed({
    super.key,
    required this.activeAsync,
    required this.expiredAsync,
    required this.showExpired,
    required this.onTap,
    required this.onRetry,
    this.activeFilter,
  });

  final AsyncValue<List<Lawsuit>> activeAsync;
  final AsyncValue<List<Lawsuit>> expiredAsync;
  final bool showExpired;
  final ValueChanged<Lawsuit> onTap;
  final VoidCallback onRetry;

  /// Optional predicate (e.g. search) applied to both lists.
  final bool Function(Lawsuit)? activeFilter;

  List<Lawsuit> _apply(List<Lawsuit> list) {
    final filter = activeFilter;
    if (filter == null) return list;
    return list.where(filter).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return activeAsync.when(
      loading: () => const _FeedLoading(),
      error: (error, _) => _FeedError(onRetry: onRetry),
      data: (active) {
        final visibleActive = _apply(active);

        Widget expiredSection = const SizedBox.shrink();
        if (showExpired) {
          expiredSection = expiredAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => _FeedError(onRetry: onRetry),
            data: (expired) => _CardList(
              lawsuits: _apply(expired),
              onTap: onTap,
            ),
          );
        }

        if (visibleActive.isEmpty && !showExpired) {
          return const _FeedEmpty();
        }

        return Column(
          children: <Widget>[
            _CardList(lawsuits: visibleActive, onTap: onTap),
            expiredSection,
          ],
        );
      },
    );
  }
}

class _CardList extends StatelessWidget {
  const _CardList({required this.lawsuits, required this.onTap});

  final List<Lawsuit> lawsuits;
  final ValueChanged<Lawsuit> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (final lawsuit in lawsuits)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: LawsuitCard(
              lawsuit: lawsuit,
              onTap: () => onTap(lawsuit),
            ),
          ),
      ],
    );
  }
}

class _FeedLoading extends StatelessWidget {
  const _FeedLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _FeedError extends StatelessWidget {
  const _FeedError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: <Widget>[
          const Icon(Icons.error_outline, size: 40, color: AppColors.error),
          const SizedBox(height: 12),
          Text("Couldn't load settlements", style: AppTextStyles.bodyMd),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class _FeedEmpty extends StatelessWidget {
  const _FeedEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          'No settlements found',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.mutedText),
        ),
      ),
    );
  }
}
