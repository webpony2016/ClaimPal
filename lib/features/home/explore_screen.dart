import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/lawsuit.dart';
import '../../data/providers.dart';
import 'widgets/lawsuit_feed.dart';
import 'widgets/search_field.dart';

/// Explore tab (route `/explore`).
///
/// A search-forward browse screen over the active lawsuits. Rendered inside
/// the shell scaffold, so it adds no bottom navigation of its own.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  String _query = '';

  bool _matches(Lawsuit lawsuit) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return lawsuit.title.toLowerCase().contains(q) ||
        lawsuit.brand.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final activeAsync = ref.watch(activeLawsuitsProvider);
    final expiredAsync = ref.watch(expiredLawsuitsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Explore Settlements',
                    style: AppTextStyles.headlineMd),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: <Widget>[
                  SearchField(
                    hintText: 'Search settlements...',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 24),
                  LawsuitFeed(
                    activeAsync: activeAsync,
                    expiredAsync: expiredAsync,
                    // Explore browses open settlements only.
                    showExpired: false,
                    activeFilter: _matches,
                    onTap: (lawsuit) => context.go('/lawsuit/${lawsuit.id}'),
                    onRetry: () =>
                        ref.invalidate(activeLawsuitsProvider),
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
