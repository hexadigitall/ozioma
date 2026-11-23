import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/secure_db.dart';
import 'services/sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  final db = SecureDatabase();
  await db.init();
  final sync = SyncService(db: db);
  await sync.init();

  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      syncServiceProvider.overrideWithValue(sync),
    ],
    child: const OziomaApp(),
  ));
}

final databaseProvider = Provider<SecureDatabase>((_) => throw UnimplementedError());
final syncServiceProvider = Provider<SyncService>((_) => throw UnimplementedError());
