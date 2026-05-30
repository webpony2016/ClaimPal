import 'package:flutter/material.dart';

/// Lawsuit detail screen (route `/lawsuit/:id`). Placeholder for Phase 5.
class LawsuitDetailScreen extends StatelessWidget {
  const LawsuitDetailScreen({super.key, required this.lawsuitId});

  final String lawsuitId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lawsuit Detail')),
      body: Center(child: Text('Lawsuit Detail: $lawsuitId')),
    );
  }
}
