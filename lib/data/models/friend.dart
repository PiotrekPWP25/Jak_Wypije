class Friend {
  const Friend({
    required this.id,
    required this.name,
    required this.emoji,
    required this.points,
    required this.favoriteDistrict,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '🙂',
      points: (json['points'] as num?)?.toInt() ?? 0,
      favoriteDistrict: json['favoriteDistrict'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String emoji;
  final int points;
  final String favoriteDistrict;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'points': points,
        'favoriteDistrict': favoriteDistrict,
      };
}
