/// A friend or another member of the user's weekly league.
class Friend {
  const Friend({
    required this.id,
    required this.name,
    required this.emoji,
    required this.points,
    required this.favoriteDistrict,
    required this.weeklyXp,
    required this.leagueId,
    required this.streakWeeks,
    required this.isFriend,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '🙂',
      points: (json['points'] as num?)?.toInt() ?? 0,
      favoriteDistrict: json['favoriteDistrict'] as String? ?? '',
      weeklyXp: (json['weeklyXp'] as num?)?.toInt() ?? 0,
      leagueId: json['league'] as String? ?? 'bronze',
      streakWeeks: (json['streakWeeks'] as num?)?.toInt() ?? 0,
      isFriend: json['isFriend'] as bool? ?? true,
    );
  }

  final String id;
  final String name;
  final String emoji;

  /// All-time points.
  final int points;
  final String favoriteDistrict;

  /// XP earned since Monday – decides the weekly league table.
  final int weeklyXp;
  final String leagueId;

  /// Consecutive weeks with at least one check-in.
  final int streakWeeks;

  /// `false` for other league members the user does not follow.
  final bool isFriend;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'points': points,
        'favoriteDistrict': favoriteDistrict,
        'weeklyXp': weeklyXp,
        'league': leagueId,
        'streakWeeks': streakWeeks,
        'isFriend': isFriend,
      };
}
