import 'package:flutter/material.dart';

/// Claim filing screen (route `/filing/:id`). Placeholder for Phase 5.
class FilingScreen extends StatelessWidget {
  const FilingScreen({super.key, required this.lawsuitId});

  final String lawsuitId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File Claim')),
      body: Center(child: Text('Filing: $lawsuitId')),
    );
  }
}
