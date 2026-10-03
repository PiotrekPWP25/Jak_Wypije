import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/local_storage.dart';

/// Tourists get curated trips and must-sees; locals get weekly challenges,
/// events, deals and new places – reasons to come back every week.
enum UserMode { tourist, local }

extension UserModeX on UserMode {
  String get label => switch (this) {
        UserMode.tourist => 'Zwiedzam Kraków',
        UserMode.local => 'Mieszkam w Krakowie',
      };
}

class UserModeNotifier extends Notifier<UserMode?> {
  @override
  UserMode? build() {
    final stored = ref.watch(localStorageProvider).loadUserMode();
    return UserMode.values.where((mode) => mode.name == stored).firstOrNull;
  }

  Future<void> set(UserMode mode) async {
    state = mode;
    await ref.read(localStorageProvider).saveUserMode(mode.name);
  }
}

final userModeProvider = NotifierProvider<UserModeNotifier, UserMode?>(
  UserModeNotifier.new,
);
