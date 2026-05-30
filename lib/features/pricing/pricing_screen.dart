import 'package:flutter/material.dart';

/// Pricing / paywall screen (route `/pricing`). Placeholder for Phase 5.
class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pricing')),
      body: const Center(child: Text('Pricing')),
    );
  }
}
