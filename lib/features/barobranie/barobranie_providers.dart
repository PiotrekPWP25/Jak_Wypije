import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/local_storage.dart';
import '../../data/models/fundraiser.dart';
import '../../data/repositories/fundraiser_repository.dart';

/// Local (mock) pledges made by the user: fundraiserId -> amount in PLN.
class ContributionsNotifier extends Notifier<Map<String, double>> {
  @override
  Map<String, double> build() =>
      ref.watch(localStorageProvider).loadContributions();

  Future<void> contribute(String fundraiserId, double amount) async {
    if (amount <= 0) return;
    final next = Map<String, double>.of(state)
      ..update(
        fundraiserId,
        (value) => value + amount,
        ifAbsent: () => amount,
      );
    state = Map<String, double>.unmodifiable(next);
    await ref.read(localStorageProvider).saveContributions(state);
  }
}

final contributionsProvider =
    NotifierProvider<ContributionsNotifier, Map<String, double>>(
  ContributionsNotifier.new,
);

/// Fundraisers with the user's local pledges applied.
final fundraisersProvider = Provider<AsyncValue<List<Fundraiser>>>((ref) {
  final contributions = ref.watch(contributionsProvider);
  return ref.watch(baseFundraisersProvider).whenData(
        (fundraisers) => [
          for (final fundraiser in fundraisers)
            fundraiser.withContribution(contributions[fundraiser.id] ?? 0.0),
        ],
      );
});

final fundraiserByBarIdProvider = Provider<Map<String, Fundraiser>>((ref) {
  final fundraisers =
      ref.watch(fundraisersProvider).valueOrNull ?? const <Fundraiser>[];
  return {for (final fundraiser in fundraisers) fundraiser.barId: fundraiser};
});
