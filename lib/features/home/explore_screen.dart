import 'package:flutter/material.dart';

/// Explore tab (route `/explore`). Placeholder; Phase 5 fills in search.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: const Center(child: Text('Explore')),
    );
  }
}
