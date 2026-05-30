import 'package:flutter/material.dart';

/// Guest landing screen (route `/`). Filled in by Phase 5.
class GuestHomeScreen extends StatelessWidget {
  const GuestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guest Home')),
      body: const Center(child: Text('Guest Home')),
    );
  }
}
