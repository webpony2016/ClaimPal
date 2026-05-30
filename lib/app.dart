import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Provides the app's [GoRouter] instance (built once).
final routerProvider = Provider<GoRouter>((ref) => buildRouter());

/// Root ClaimPal application widget.
class ClaimPalApp extends ConsumerWidget {
  const ClaimPalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'ClaimPal',
      theme: buildTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
