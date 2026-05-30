import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/fomo_summary.dart';
import '../theme/app_colors.dart';

/// A gradient "fear of missing out" banner summarizing missed and upcoming
/// payout amounts.
class FomoBanner extends StatelessWidget {
  const FomoBanner({super.key, required this.summary});

  final FomoSummary summary;

  static final NumberFormat _currency = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 0,
  );

  String get _timeframeLabel {
    switch (summary.timeframe) {
      case FomoTimeframe.threeMonths:
        return 'last 3 months';
      case FomoTimeframe.sixMonths:
        return 'last 6 months';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String missed = _currency.format(summary.missedAmount);
    final String upcoming = _currency.format(summary.upcomingAmount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.navy, AppColors.primary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'In the $_timeframeLabel you may have missed $missed in claims 💔',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              height: 28 / 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$upcoming still available in the next 30 days.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 24 / 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
