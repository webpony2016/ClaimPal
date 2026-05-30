import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Subtle reassurance badge: a lock icon plus a privacy guarantee label.
class PrivacyBadge extends StatelessWidget {
  const PrivacyBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(Icons.lock_outline, color: AppColors.successDark, size: 16),
        const SizedBox(width: 6),
        Text(
          '100% Privacy Protected',
          style: TextStyle(
            color: AppColors.successDark,
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
