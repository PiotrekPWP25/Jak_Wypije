import '../../data/models/achievement.dart';
import 'profile_providers.dart';

const List<Achievement> allAchievements = [
  Achievement(
    id: 'first_check_in',
    title: 'Pierwszy łyk',
    description: 'Zamelduj się w dowolnym barze.',
    emoji: '🍻',
  ),
  Achievement(
    id: 'explorer',
    title: 'Odkrywca szlaków',
    description: 'Odwiedź 5 różnych barów.',
    emoji: '🧭',
  ),
  Achievement(
    id: 'hidden_gems',
    title: 'Łowca perełek',
    description: 'Odwiedź 3 ukryte perełki.',
    emoji: '💎',
  ),
  Achievement(
    id: 'districts',
    title: 'Obieżyświat',
    description: 'Zamelduj się w 3 różnych dzielnicach.',
    emoji: '🗺️',
  ),
  Achievement(
    id: 'critic',
    title: 'Krytyk',
    description: 'Wystaw 3 oceny.',
    emoji: '📝',
  ),
  Achievement(
    id: 'planner',
    title: 'Strateg',
    description: 'Zaplanuj wieczór z co najmniej 3 przystankami.',
    emoji: '🗓️',
  ),
  Achievement(
    id: 'supporter',
    title: 'Barobrańca',
    description: 'Wesprzyj dowolną zbiórkę w Barobraniu.',
    emoji: '🤝',
  ),
  Achievement(
    id: 'saver',
    title: 'Ratownik',
    description: 'Wesprzyj zbiórkę, która zakończyła się sukcesem.',
    emoji: '🛟',
  ),
];

class AchievementProgress {
  const AchievementProgress({
    required this.achievement,
    required this.unlocked,
  });

  final Achievement achievement;
  final bool unlocked;
}

bool isAchievementUnlocked(String id, ProfileStats stats) => switch (id) {
      'first_check_in' => stats.checkIns >= 1,
      'explorer' => stats.uniqueBars >= 5,
      'hidden_gems' => stats.hiddenGems >= 3,
      'districts' => stats.districts >= 3,
      'critic' => stats.reviews >= 3,
      'planner' => stats.planStops >= 3,
      'supporter' => stats.supportedFundraisers >= 1,
      'saver' => stats.savedFundraisersSupported >= 1,
      _ => false,
    };
