import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/city_district.dart';
import '../../data/models/landmark.dart';
import '../../data/repositories/place_repository.dart';
import '../../widgets/section_header.dart';
import '../checkin/check_in_controller.dart';
import '../gamification/gamification_providers.dart';

/// "Paszport Krakowa": stamps for the 18 districts and visited landmarks –
/// a long-term goal for locals who only know the centre.
class PassportScreen extends ConsumerWidget {
  const PassportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final districts =
        ref.watch(districtsProvider).valueOrNull ?? const <CityDistrict>[];
    final stamped = ref.watch(stampedDistrictsProvider);
    final landmarks =
        ref.watch(landmarksProvider).valueOrNull ?? const <Landmark>[];
    final visitedIds =
        ref.watch(checkInsProvider).map((c) => c.placeId).toSet();
    final visitedLandmarks =
        landmarks.where((l) => visitedIds.contains(l.id)).length;
    final total = districts.isEmpty ? 18 : districts.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Paszport Krakowa')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stamped.length}/$total dzielnic · '
                  '$visitedLandmarks/${landmarks.length} atrakcji',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: stamped.length / total,
                    minHeight: 10,
                    color: AppColors.green,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pieczątkę dostajesz za pierwszy meldunek w dzielnicy '
                  '(+20 pkt). Większość mieszkańców zna tylko 2–3 dzielnice – '
                  'ile Ty zbierzesz?',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 20) / 3;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final district in districts)
                      SizedBox(
                        width: width,
                        child: _Stamp(
                          district: district,
                          stamped: stamped.contains(district.no),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SectionHeader(title: 'Atrakcje'),
          for (final landmark in landmarks)
            ListTile(
              leading: Text(
                landmark.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(landmark.name),
              subtitle:
                  Text('${landmark.district} · ${landmark.category.label}'),
              trailing: Icon(
                visitedIds.contains(landmark.id)
                    ? Icons.verified
                    : Icons.radio_button_unchecked,
                color: visitedIds.contains(landmark.id)
                    ? AppColors.green
                    : theme.colorScheme.outline,
              ),
              onTap: () => context.push('/landmark/${landmark.id}'),
            ),
        ],
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.district, required this.stamped});

  final CityDistrict district;
  final bool stamped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = stamped ? AppColors.green : theme.colorScheme.outlineVariant;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: stamped
              ? AppColors.green.withAlpha(30)
              : theme.colorScheme.surfaceContainerLow,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: stamped ? 3 : 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              district.roman,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: stamped ? AppColors.green : theme.colorScheme.outline,
              ),
            ),
            Text(
              district.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
            ),
            Icon(
              stamped ? Icons.check_circle : Icons.lock_outline,
              size: 14,
              color: stamped ? AppColors.green : theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}
