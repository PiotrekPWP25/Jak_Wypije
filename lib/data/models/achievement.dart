class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '🏅',
    );
  }

  final String id;
  final String title;
  final String description;
  final String emoji;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'emoji': emoji,
      };
}
