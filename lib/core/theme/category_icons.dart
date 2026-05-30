import 'package:flutter/material.dart';

import '../../data/models/lawsuit.dart';

/// Maps a [LawsuitCategory] to the icon used across the UI.
///
/// Icon selection lives here (the presentation layer), not on the model.
IconData iconForCategory(LawsuitCategory category) {
  switch (category) {
    case LawsuitCategory.privacy:
      return Icons.account_balance_wallet_outlined;
    case LawsuitCategory.finance:
      return Icons.credit_card_off_outlined;
    case LawsuitCategory.health:
      return Icons.monitor_heart_outlined;
    case LawsuitCategory.security:
      return Icons.security_outlined;
    case LawsuitCategory.other:
      return Icons.gavel;
  }
}
