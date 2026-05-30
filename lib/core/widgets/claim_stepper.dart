import 'package:flutter/material.dart';

import '../../data/models/claim_progress.dart';
import '../theme/app_colors.dart';

/// Horizontal 4-step progress indicator for a filed claim.
///
/// Steps at index <= [ClaimProgress.stageIndex] render as complete (emerald
/// fill + check). Later steps render neutral. Connectors are colored by whether
/// the following step is complete.
class ClaimStepper extends StatelessWidget {
  const ClaimStepper({super.key, required this.progress});

  final ClaimProgress progress;

  static const List<String> _labels = <String>[
    'AI Submitted',
    'Court Review',
    'Settlement Approved',
    'Payout Sent',
  ];

  @override
  Widget build(BuildContext context) {
    final int current = progress.stageIndex;
    final children = <Widget>[];

    for (var i = 0; i < _labels.length; i++) {
      final bool complete = i <= current;
      children.add(
        _Step(label: _labels[i], complete: complete),
      );
      if (i < _labels.length - 1) {
        final bool connectorComplete = (i + 1) <= current;
        children.add(
          Expanded(
            child: _Connector(complete: connectorComplete),
          ),
        );
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.complete});

  final String label;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final Color color = complete ? AppColors.success : AppColors.expired;

    return SizedBox(
      width: 72,
      child: Column(
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: complete ? AppColors.success : Colors.transparent,
              border: Border.all(color: color, width: 2),
            ),
            child: complete
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: complete ? AppColors.onSurface : AppColors.mutedText,
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.complete});

  final bool complete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Vertically center the connector against the 32px step circle.
      padding: const EdgeInsets.only(top: 15),
      child: Container(
        height: 2,
        color: complete ? AppColors.success : AppColors.outlineVariant,
      ),
    );
  }
}
