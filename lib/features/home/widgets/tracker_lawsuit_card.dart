import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/category_icons.dart';
import '../../../core/widgets/claim_stepper.dart';
import '../../../data/models/claim_progress.dart';
import '../../../data/models/lawsuit.dart';
import '../../../data/providers.dart';
import '../tracker_claim_status.dart';

/// Tracker-home card that overlays the user's claim status onto a [Lawsuit].
///
/// Beyond the plain catalog card it conveys, per the tracker design:
/// - the settlement's expiry/deadline date on every card;
/// - a clear "Claim Filed" marker plus a progress stepper for filed claims;
/// - a prominent, non-dimmed "Payout Received" highlight for paid claims, so
///   they stand out even within the expired list;
/// - an "ineligible" treatment that reuses the dimmed expired palette but adds
///   a "Not Eligible" note and stays tappable so the user can revisit/edit it.
class TrackerLawsuitCard extends ConsumerWidget {
  const TrackerLawsuitCard({
    super.key,
    required this.lawsuit,
    this.onTap,
    this.enableUserOverlay = true,
  });

  final Lawsuit lawsuit;
  final VoidCallback? onTap;
  final bool enableUserOverlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlay = enableUserOverlay
        ? ref.watch(trackerClaimStatusProvider)
        : const <String, TrackerClaimEntry>{};
    final submitted = enableUserOverlay
        ? ref.watch(submittedClaimIdsProvider).maybeWhen(
          data: (ids) => ids.toSet(),
          orElse: () => const <String>{},
        )
        : const <String>{};

    final status = resolveTrackerStatus(
      lawsuitId: lawsuit.id,
      overlay: overlay,
      submittedIds: submitted,
    );
    final ClaimStage stage =
        overlay[lawsuit.id]?.stage ?? ClaimStage.aiSubmitted;

    final bool isExpiredLawsuit = lawsuit.status == LawsuitStatus.expired;
    final bool paid = status == TrackerClaimStatus.paid;
    final bool filed = status == TrackerClaimStatus.filed;
    final bool ineligible = status == TrackerClaimStatus.ineligible;

    // Paid always pops; expired or user-declared-ineligible cards dim.
    final bool dimmed = (isExpiredLawsuit || ineligible) && !paid;

    final Color titleColor = dimmed ? AppColors.mutedText : AppColors.onSurface;
    final Color payoutColor = dimmed ? AppColors.expired : AppColors.successDark;
    final Color iconColor = dimmed ? AppColors.expired : AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: dimmed ? 0.72 : 1,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: dimmed ? AppColors.surfaceContainerLow : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: paid ? AppColors.success : AppColors.outlineVariant,
              width: paid ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _CategoryIconTile(
                    icon: iconForCategory(lawsuit.category),
                    color: iconColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          lawsuit.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 24,
                            height: 32 / 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _StatusChip(
                          status: status,
                          isExpiredLawsuit: isExpiredLawsuit,
                          expiredDaysAgo: lawsuit.expiredDaysAgo,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _DeadlineRow(
                deadline: lawsuit.deadline,
                isExpiredLawsuit: isExpiredLawsuit,
                dimmed: dimmed,
              ),
              if (ineligible) ...<Widget>[
                const SizedBox(height: 8),
                const Text(
                  "You marked this as not a match — tap to review or edit.",
                  style: TextStyle(
                    color: AppColors.expired,
                    fontSize: 14,
                    height: 18 / 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (filed || paid) ...<Widget>[
                const SizedBox(height: 16),
                ClaimStepper(progress: ClaimProgress(currentStage: stage)),
              ],
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.outlineVariant),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          (paid ? 'Payout Received' : lawsuit.payoutLabel)
                              .toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: payoutColor,
                            fontSize: 32,
                            height: 40 / 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _CardAction(
                    status: status,
                    isExpiredLawsuit: isExpiredLawsuit,
                    onPressed: onTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
    required this.isExpiredLawsuit,
    required this.expiredDaysAgo,
  });

  final TrackerClaimStatus status;
  final bool isExpiredLawsuit;
  final int? expiredDaysAgo;

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData? icon, String label) = switch (status) {
      TrackerClaimStatus.paid => (
          AppColors.success,
          Icons.verified_outlined,
          'Payout Received',
        ),
      TrackerClaimStatus.filed => (
          AppColors.primary,
          Icons.assignment_turned_in_outlined,
          'Claim Filed',
        ),
      TrackerClaimStatus.ineligible => (
          AppColors.expired,
          Icons.do_not_disturb_on_outlined,
          'Not Eligible',
        ),
      TrackerClaimStatus.none => isExpiredLawsuit
          ? (
              AppColors.expired,
              null,
              expiredDaysAgo != null
                  ? 'Expired $expiredDaysAgo Days Ago'
                  : 'Expired',
            )
          : (AppColors.success, Icons.check_circle_outline, 'Active'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeadlineRow extends StatelessWidget {
  const _DeadlineRow({
    required this.deadline,
    required this.isExpiredLawsuit,
    required this.dimmed,
  });

  final DateTime? deadline;
  final bool isExpiredLawsuit;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final Color color = dimmed ? AppColors.expired : AppColors.mutedText;
    final String text;
    if (deadline == null) {
      text = isExpiredLawsuit ? 'Claim window closed' : 'No deadline announced';
    } else {
      final formatted = DateFormat('MMM d, yyyy').format(deadline!);
      text = isExpiredLawsuit ? 'Closed $formatted' : 'Deadline $formatted';
    }

    return Row(
      children: <Widget>[
        Icon(
          isExpiredLawsuit ? Icons.event_busy_outlined : Icons.event_outlined,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryIconTile extends StatelessWidget {
  const _CategoryIconTile({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Icon(icon, color: color, size: 32),
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.status,
    required this.isExpiredLawsuit,
    required this.onPressed,
  });

  final TrackerClaimStatus status;
  final bool isExpiredLawsuit;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // An open, untouched settlement keeps the solid "File Claim" CTA.
    if (status == TrackerClaimStatus.none && !isExpiredLawsuit) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.successDark,
          foregroundColor: Colors.white,
          minimumSize: const Size(144, 64),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: const Text(
          'File Claim',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 20,
            height: 28 / 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final (String label, Color color) = switch (status) {
      TrackerClaimStatus.filed => ('View Progress', AppColors.primary),
      TrackerClaimStatus.paid => ('View Details', AppColors.successDark),
      TrackerClaimStatus.ineligible => ('Review Eligibility', AppColors.expired),
      TrackerClaimStatus.none => ('View Final Verdict', AppColors.expired),
    };

    // The whole card is tappable; this row is a textual affordance.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 20,
              height: 28 / 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right, color: color, size: 24),
      ],
    );
  }
}
