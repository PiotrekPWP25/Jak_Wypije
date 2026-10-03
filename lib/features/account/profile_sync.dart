import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/auth/auth_repository.dart';
import '../../data/local/local_storage.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/profile_repository.dart';
import 'account_providers.dart';

enum ProfileSyncStatus {
  /// No backend configured – everything stays on the device.
  demo,
  signedOut,
  syncing,
  synced,

  /// Saved on the device, waiting for the network.
  pending;

  String get label => switch (this) {
        ProfileSyncStatus.demo => 'Wersja demo – dane tylko na tym telefonie',
        ProfileSyncStatus.signedOut => 'Niezalogowany – dane na tym telefonie',
        ProfileSyncStatus.syncing => 'Synchronizuję…',
        ProfileSyncStatus.synced => 'Profil zsynchronizowany z kontem',
        ProfileSyncStatus.pending =>
          'Zapisano na telefonie, zsynchronizujemy później',
      };
}

/// Offline-first profile sync: the device is the source for the UI, every
/// change is pushed to `profiles` in the background, and signing in merges
/// the account profile into the device (see [mergeProfiles]).
class ProfileSyncNotifier extends Notifier<ProfileSyncStatus> {
  String? _userId;
  UserProfile? _lastSynced;

  @override
  ProfileSyncStatus build() {
    if (ref.watch(profileRepositoryProvider) == null) {
      return ProfileSyncStatus.demo;
    }
    var building = true;
    ref
      ..listen<User?>(authUserProvider, (_, user) {
        if (user?.id == _userId) return;
        _userId = user?.id;
        _lastSynced = null;
        if (user == null) {
          if (!building) state = ProfileSyncStatus.signedOut;
        } else {
          unawaited(Future.microtask(pullAndMerge));
        }
      }, fireImmediately: true)
      ..listen<UserProfile>(profileProvider, (_, profile) {
        unawaited(_push(profile));
      });
    building = false;
    return _userId == null
        ? ProfileSyncStatus.signedOut
        : ProfileSyncStatus.syncing;
  }

  /// After signing in (and to retry): account and device profiles merge.
  Future<void> pullAndMerge() async {
    final repository = ref.read(profileRepositoryProvider);
    final userId = _userId;
    if (repository == null || userId == null) return;
    state = ProfileSyncStatus.syncing;
    final storage = ref.read(localStorageProvider);
    try {
      final local = storage.loadProfile();
      final remote = await repository.fetch(userId);
      if (userId != _userId) return;
      // Unsent changes from this device win over the account.
      final merged = storage.loadProfileDirty() && remote != null
          ? mergeProfiles(remote, local)
          : mergeProfiles(local, remote);
      _lastSynced = merged;
      if (merged != local) {
        await storage.saveProfile(merged);
        ref.invalidate(localStorageProvider);
      }
      if (merged != remote) await repository.upsert(userId, merged);
      await storage.saveProfileDirty(false);
      state = ProfileSyncStatus.synced;
    } on Exception {
      _lastSynced = null;
      await storage.saveProfileDirty(true);
      state = ProfileSyncStatus.pending;
    }
  }

  Future<void> _push(UserProfile profile) async {
    final repository = ref.read(profileRepositoryProvider);
    final userId = _userId;
    if (repository == null || userId == null || profile == _lastSynced) {
      return;
    }
    final storage = ref.read(localStorageProvider);
    await storage.saveProfileDirty(true);
    state = ProfileSyncStatus.syncing;
    try {
      await repository.upsert(userId, profile);
      _lastSynced = profile;
      await storage.saveProfileDirty(false);
      state = ProfileSyncStatus.synced;
    } on Exception {
      state = ProfileSyncStatus.pending;
    }
  }
}

final profileSyncProvider =
    NotifierProvider<ProfileSyncNotifier, ProfileSyncStatus>(
  ProfileSyncNotifier.new,
);
