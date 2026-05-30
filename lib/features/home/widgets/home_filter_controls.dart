import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/models/fomo_summary.dart';

/// Control row bound to the home filter: a "Show Expired" switch plus a
/// timeframe selector (3 months / 6 months).
class HomeFilterControls extends StatelessWidget {
  const HomeFilterControls({
    super.key,
    required this.showExpired,
    required this.timeframe,
    required this.onShowExpiredChanged,
    required this.onTimeframeChanged,
  });

  final bool showExpired;
  final FomoTimeframe timeframe;
  final ValueChanged<bool> onShowExpiredChanged;
  final ValueChanged<FomoTimeframe> onTimeframeChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Switch(
          value: showExpired,
          onChanged: onShowExpiredChanged,
          activeThumbColor: AppColors.success,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Show Expired',
            style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        _TimeframeSelector(
          timeframe: timeframe,
          onChanged: onTimeframeChanged,
        ),
      ],
    );
  }
}

class _TimeframeSelector extends StatelessWidget {
  const _TimeframeSelector({required this.timeframe, required this.onChanged});

  final FomoTimeframe timeframe;
  final ValueChanged<FomoTimeframe> onChanged;

  String _label(FomoTimeframe value) {
    switch (value) {
      case FomoTimeframe.threeMonths:
        return '3 months';
      case FomoTimeframe.sixMonths:
        return '6 months';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<FomoTimeframe>(
        value: timeframe,
        borderRadius: BorderRadius.circular(6),
        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.navy),
        style: AppTextStyles.labelLg.copyWith(color: AppColors.navy),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
        items: <DropdownMenuItem<FomoTimeframe>>[
          for (final value in FomoTimeframe.values)
            DropdownMenuItem<FomoTimeframe>(
              value: value,
              child: Text(_label(value)),
            ),
        ],
      ),
    );
  }
}
