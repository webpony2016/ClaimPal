import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A small pill badge used to convey a lawsuit/claim status.
///
/// Active badges use the emerald success color with a check icon; inactive
/// badges use a muted slate color and omit the icon.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.isActive});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final Color color = isActive ? AppColors.success : AppColors.expired;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (isActive) ...<Widget>[
            Icon(Icons.check_circle_outline, color: color, size: 16),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
