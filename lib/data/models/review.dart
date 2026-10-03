class Review {
  const Review({
    required this.id,
    required this.barId,
    required this.authorId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      barId: json['barId'] as String,
      authorId: json['authorId'] as String,
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Author id used for reviews written by the current user.
  static const String myAuthorId = 'me';

  final String id;
  final String barId;
  final String authorId;

  /// 1–5 stars.
  final int rating;
  final String comment;
  final DateTime createdAt;

  bool get isMine => authorId == myAuthorId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'barId': barId,
        'authorId': authorId,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
      };
}
