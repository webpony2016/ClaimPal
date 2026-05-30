import 'package:flutter/material.dart';

class ClaimPalClaimTrackerScreen extends StatelessWidget {
  const ClaimPalClaimTrackerScreen({
    super.key,
    this.showExpired = false,
    this.claims = _defaultClaims,
    this.onShowExpiredChanged,
    this.onTimeframeTap,
    this.onNotificationsTap,
    this.onSearchChanged,
    this.onClaimTap,
    this.onBottomNavTap,
    this.selectedBottomNavIndex = 0,
  });

  final bool showExpired;
  final List<ClaimPalClaim> claims;
  final ValueChanged<bool>? onShowExpiredChanged;
  final VoidCallback? onTimeframeTap;
  final VoidCallback? onNotificationsTap;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<ClaimPalClaim>? onClaimTap;
  final ValueChanged<int>? onBottomNavTap;
  final int selectedBottomNavIndex;

  static const List<ClaimPalClaim> _defaultClaims = <ClaimPalClaim>[
    ClaimPalClaim(
      title: 'Facebook Data Privacy Settlement',
      status: 'Active',
      payoutLabel: 'Estimated Payout',
      payoutValue: 'Up to \$350',
      actionLabel: 'File Claim',
      icon: Icons.account_balance_wallet_outlined,
      isActive: true,
      iconColor: Color(0xFF0E7490),
    ),
    ClaimPalClaim(
      title: 'Capital One Data Breach',
      status: 'Expired 12 Days Ago',
      payoutLabel: 'Final Settlement',
      payoutValue: '\$25.00',
      actionLabel: 'View Final Verdict',
      icon: Icons.credit_card_off_outlined,
      isActive: false,
      iconColor: Color(0xFF64748B),
    ),
    ClaimPalClaim(
      title: 'Fitbit Heart Rate Accuracy',
      status: 'Active',
      payoutLabel: 'Estimated Payout',
      payoutValue: 'Up to \$150',
      actionLabel: 'File Claim',
      icon: Icons.monitor_heart_outlined,
      isActive: true,
      iconColor: Color(0xFF0F172A),
    ),
    ClaimPalClaim(
      title: 'Equifax Data Settlement',
      status: 'Expired 45 Days Ago',
      payoutLabel: 'Final Settlement',
      payoutValue: 'Up to \$125',
      actionLabel: 'View Final Verdict',
      icon: Icons.security_outlined,
      isActive: false,
      iconColor: Color(0xFF64748B),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visibleClaims = showExpired
        ? claims
        : claims.where((claim) => claim.isActive).toList(growable: false);

    return Scaffold(
      backgroundColor: _ClaimPalColors.background,
      bottomNavigationBar: ClaimPalBottomNavBar(
        selectedIndex: selectedBottomNavIndex,
        onTap: onBottomNavTap,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _TopAppBar(onNotificationsTap: onNotificationsTap),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: _SearchField(onChanged: onSearchChanged),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: _FilterRow(
                      showExpired: showExpired,
                      onShowExpiredChanged: onShowExpiredChanged,
                      onTimeframeTap: onTimeframeTap,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: visibleClaims
                          .map(
                            (claim) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _ClaimCard(
                                claim: claim,
                                onTap: onClaimTap == null
                                    ? null
                                    : () => onClaimTap!(claim),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClaimPalClaim {
  const ClaimPalClaim({
    required this.title,
    required this.status,
    required this.payoutLabel,
    required this.payoutValue,
    required this.actionLabel,
    required this.icon,
    required this.isActive,
    required this.iconColor,
  });

  final String title;
  final String status;
  final String payoutLabel;
  final String payoutValue;
  final String actionLabel;
  final IconData icon;
  final bool isActive;
  final Color iconColor;
}

class ClaimPalBottomNavBar extends StatelessWidget {
  const ClaimPalBottomNavBar({super.key, this.selectedIndex = 0, this.onTap});

  final int selectedIndex;
  final ValueChanged<int>? onTap;

  static const _items = <_BottomNavItem>[
    _BottomNavItem(Icons.analytics_outlined, 'Tracker'),
    _BottomNavItem(Icons.search, 'Explore'),
    _BottomNavItem(Icons.assignment_turned_in_outlined, 'My Claims'),
    _BottomNavItem(Icons.person_outline, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _ClaimPalColors.surface,
        border: Border(top: BorderSide(color: _ClaimPalColors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: List<Widget>.generate(_items.length, (index) {
              final item = _items[index];
              final selected = selectedIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: onTap == null ? null : () => onTap!(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          item.icon,
                          color: selected
                              ? _ClaimPalColors.success
                              : _ClaimPalColors.onSurface,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? _ClaimPalColors.success
                                : _ClaimPalColors.onSurface,
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TopAppBar extends StatelessWidget {
  const _TopAppBar({this.onNotificationsTap});

  final VoidCallback? onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: _ClaimPalColors.surface,
        border: Border(
          bottom: BorderSide(color: _ClaimPalColors.outlineVariant),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.gavel, color: _ClaimPalColors.navy, size: 32),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'ClaimPal',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _ClaimPalColors.navy,
                fontSize: 32,
                height: 40 / 32,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: onNotificationsTap,
            icon: const Icon(Icons.notifications_none),
            color: _ClaimPalColors.onSurface,
            iconSize: 32,
            tooltip: 'Notifications',
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({this.onChanged});

  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(
        color: _ClaimPalColors.onSurface,
        fontSize: 16,
        height: 24 / 16,
      ),
      decoration: InputDecoration(
        hintText: 'Search class actions...',
        hintStyle: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 24,
          height: 32 / 24,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: Color(0xFF6B7280),
          size: 32,
        ),
        filled: true,
        fillColor: _ClaimPalColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _ClaimPalColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _ClaimPalColors.navy, width: 2),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.showExpired,
    this.onShowExpiredChanged,
    this.onTimeframeTap,
  });

  final bool showExpired;
  final ValueChanged<bool>? onShowExpiredChanged;
  final VoidCallback? onTimeframeTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Switch(
          value: showExpired,
          onChanged: onShowExpiredChanged,
          activeThumbColor: _ClaimPalColors.success,
          inactiveThumbColor: _ClaimPalColors.surface,
          inactiveTrackColor: const Color(0xFFC4C6CF),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Show Expired',
            style: TextStyle(
              color: _ClaimPalColors.onSurface,
              fontSize: 18,
              height: 28 / 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onTimeframeTap,
          icon: const Text(
            'Timeframe',
            style: TextStyle(
              fontSize: 18,
              height: 28 / 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          label: const Icon(Icons.keyboard_arrow_down),
          style: OutlinedButton.styleFrom(
            foregroundColor: _ClaimPalColors.navy,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            side: const BorderSide(color: _ClaimPalColors.outlineVariant),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ],
    );
  }
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({required this.claim, this.onTap});

  final ClaimPalClaim claim;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = !claim.isActive;
    final titleColor = disabled
        ? _ClaimPalColors.mutedText
        : _ClaimPalColors.onSurface;
    final payoutColor = disabled
        ? const Color(0xFFA1A7B0)
        : _ClaimPalColors.successDark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: disabled ? 0.72 : 1,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: disabled
                ? _ClaimPalColors.surfaceContainerLow
                : _ClaimPalColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _ClaimPalColors.outlineVariant),
          ),
          child: Column(
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _ClaimIcon(
                    icon: claim.icon,
                    color: disabled ? const Color(0xFF6B7280) : claim.iconColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          claim.title,
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
                        _StatusBadge(
                          label: claim.status,
                          isActive: claim.isActive,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: _ClaimPalColors.outlineVariant),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          claim.payoutLabel.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF74777F),
                            fontSize: 14,
                            height: 16 / 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          claim.payoutValue,
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
                  disabled
                      ? _ExpiredAction(label: claim.actionLabel)
                      : _ActiveAction(label: claim.actionLabel),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClaimIcon extends StatelessWidget {
  const _ClaimIcon({required this.icon, required this.color});

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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.isActive});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _ClaimPalColors.success : const Color(0xFF8A9099);

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

class _ActiveAction extends StatelessWidget {
  const _ActiveAction({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 144, minHeight: 64),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: _ClaimPalColors.successDark,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          height: 28 / 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ExpiredAction extends StatelessWidget {
  const _ExpiredAction({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF52677E),
            fontSize: 20,
            height: 28 / 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, color: Color(0xFF52677E), size: 24),
      ],
    );
  }
}

class _BottomNavItem {
  const _BottomNavItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

abstract final class _ClaimPalColors {
  static const navy = Color(0xFF0F172A);
  static const background = Color(0xFFF7FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF1F4F6);
  static const outline = Color(0xFF74777F);
  static const outlineVariant = Color(0xFFC4C6CF);
  static const onSurface = Color(0xFF181C1E);
  static const mutedText = Color(0xFF6F767D);
  static const success = Color(0xFF10B981);
  static const successDark = Color(0xFF007A4D);
}
