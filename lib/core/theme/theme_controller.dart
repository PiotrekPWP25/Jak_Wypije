import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/local_storage.dart';

/// Light (cream, like the logo) by default; the user can switch to dark.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(localStorageProvider).loadThemeMode();

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(localStorageProvider).saveThemeMode(mode);
  }

  Future<void> toggle() =>
      set(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
