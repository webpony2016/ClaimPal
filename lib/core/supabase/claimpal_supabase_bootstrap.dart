import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/claimpal_environment.dart';

/// Initializes Supabase only when compile-time credentials are provided.
class ClaimPalSupabaseBootstrap {
  const ClaimPalSupabaseBootstrap._();

  static Future<void> initialize() async {
    if (!ClaimPalEnvironment.hasSupabaseConfig) {
      return;
    }

    await Supabase.initialize(
      url: ClaimPalEnvironment.supabaseUrl,
      anonKey: ClaimPalEnvironment.supabaseAnonKey,
    );

    final client = Supabase.instance.client;
    if (client.auth.currentSession != null) {
      return;
    }

    try {
      await client.auth.signInAnonymously();
    } on AuthException catch (error) {
      throw StateError(
        'Supabase 已初始化，但匿名登录失败：${error.message}。请确认项目已启用 Anonymous Sign-Ins。',
      );
    }
  }
}