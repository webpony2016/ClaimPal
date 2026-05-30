import 'package:flutter/material.dart';

/// Tracker tab home (route `/tracker`). Placeholder; Phase 5.1 wires the
/// existing `ClaimPalClaimTrackerScreen` here.
class TrackerHomeScreen extends StatelessWidget {
  const TrackerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tracker')),
      body: const Center(child: Text('Tracker')),
    );
  }
}
