import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'data/local/local_storage.dart';
import 'data/remote/supabase_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pl_PL');
  Intl.defaultLocale = 'pl_PL';
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        supabaseClientProvider.overrideWithValue(await _initSupabase()),
      ],
      child: const JakWypijeApp(),
    ),
  );
}

/// Accounts are optional: without keys, or if Supabase fails to start, the
/// app runs in demo mode with everything on the device.
Future<SupabaseClient?> _initSupabase() async {
  if (!Env.hasBackend) return null;
  try {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseKey,
    ).timeout(const Duration(seconds: 8));
    return Supabase.instance.client;
  } on Object catch (error) {
    debugPrint('Supabase unavailable, running in demo mode: $error');
    return null;
  }
}
