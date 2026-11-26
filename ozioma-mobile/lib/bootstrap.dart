import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/database/powersync_manager.dart';
import 'core/encryption/secure_key_manager.dart';
import 'app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Hardware Keystore Master Key
  final keyManager = SecureKeyManager();
  await keyManager.getOrCreateMasterKey();

  // 2. Initialize Supabase Client with graceful offline fallback
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://placeholder.supabase.co');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'placeholder_anon_key');

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase offline initialization: $e');
  }

  // 3. Initialize Single Unified PowerSync SQLite Database
  await PowerSyncManager.instance.initialize();

  runApp(
    const ProviderScope(
      child: OziomaApp(),
    ),
  );
}
