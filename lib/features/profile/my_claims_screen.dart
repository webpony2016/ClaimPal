import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/claim_stepper.dart';
import '../../data/providers.dart';

/// My Claims tab (shell route `/my-claims`).
///
/// Lists the lawsuits the user has submitted this session (from
/// [submittedClaimIdsProvider]) and renders each with its title and a
/// [ClaimStepper] driven by [claimProgressProvider]. Shows an empty state when
/// nothing has been filed. The bottom nav is owned by the shell.
class MyClaimsScreen extends ConsumerWidget {
  const MyClaimsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idsAsync = ref.watch(submittedClaimIdsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Claims')),
      body: idsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorState(
          onRetry: () => ref.invalidate(submittedClaimIdsProvider),
        ),
        data: (ids) {
          if (ids.isEmpty) return const _EmptyState();
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: ids.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _ClaimCard(lawsuitId: ids[index]),
          );
        },
      ),
    );
  }
}

class _ClaimCard extends ConsumerWidget {
  const _ClaimCard({required this.lawsuitId});

  final String lawsuitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lawsuitAsync = ref.watch(lawsuitByIdProvider(lawsuitId));
    final progressAsync = ref.watch(claimProgressProvider(lawsuitId));

    final String title = lawsuitAsync.maybeWhen(
      data: (lawsuit) => lawsuit?.title ?? lawsuitId,
      orElse: () => lawsuitId,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: AppTextStyles.headlineSm),
          const SizedBox(height: 16),
          progressAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => Text(
              "Couldn't load progress",
              style:
                  AppTextStyles.bodySm.copyWith(color: AppColors.mutedText),
            ),
            data: (progress) => ClaimStepper(progress: progress),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.assignment_outlined,
              size: 48,
              color: AppColors.expired,
            ),
            const SizedBox(height: 16),
            Text(
              'No claims yet',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSm,
            ),
            const SizedBox(height: 8),
            Text(
              'File one from the tracker to see its progress here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.mutedText),
            ),
          ],
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
              "Couldn't load your claims",
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
