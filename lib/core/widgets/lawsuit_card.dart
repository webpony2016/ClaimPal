import 'package:flutter/material.dart';

import '../../data/models/lawsuit.dart';
import '../theme/app_colors.dart';
import '../theme/category_icons.dart';
import 'status_badge.dart';

/// A card summarizing a single [Lawsuit].
///
/// Active lawsuits render at full opacity on a white surface with a solid
/// "File Claim" button. Expired lawsuits are dimmed to 0.72 opacity on a tonal
/// container with a non-interactive "View Final Verdict" row. The card's own
/// [onTap] remains active in both states for navigation.
class LawsuitCard extends StatelessWidget {
  const LawsuitCard({super.key, required this.lawsuit, this.onTap});

  final Lawsuit lawsuit;
  final VoidCallback? onTap;

  bool get _isActive => lawsuit.status == LawsuitStatus.active;

  String get _statusLabel {
    if (_isActive) return 'Active';
    final days = lawsuit.expiredDaysAgo;
    if (days != null) return 'Expired $days Days Ago';
    return 'Expired';
  }

  @override
  Widget build(BuildContext context) {
    final bool disabled = !_isActive;
    final Color titleColor =
        disabled ? AppColors.mutedText : AppColors.onSurface;
    final Color payoutColor =
        disabled ? AppColors.expired : AppColors.successDark;
    final Color iconColor = disabled ? AppColors.expired : AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: disabled ? 0.72 : 1,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: disabled
                ? AppColors.surfaceContainerLow
                : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
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
                        StatusBadge(label: _statusLabel, isActive: _isActive),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
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
                          lawsuit.payoutLabel.toUpperCase(),
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
                  if (disabled)
                    const _ExpiredAction()
                  else
                    _ActiveAction(onPressed: onTap),
                ],
              ),
            ],
          ),
        ),
      ),
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

class _ActiveAction extends StatelessWidget {
  const _ActiveAction({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
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
}

class _ExpiredAction extends StatelessWidget {
  const _ExpiredAction();

  @override
  Widget build(BuildContext context) {
    // Non-interactive: tapping the card itself navigates instead.
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'View Final Verdict',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.expired,
            fontSize: 20,
            height: 28 / 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 4),
        Icon(Icons.chevron_right, color: AppColors.expired, size: 24),
      ],
    );
  }
}
