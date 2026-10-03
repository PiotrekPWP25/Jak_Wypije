import 'dart:math' as math;

enum FundraiserStatus { rescuing, saved }

class Reward {
  const Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.minAmount,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      minAmount: (json['minAmount'] as num).toDouble(),
    );
  }

  final String id;
  final String title;
  final String description;
  final double minAmount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'minAmount': minAmount,
      };
}

/// "Barobranie" – a community fundraiser for a bar at risk of closing.
class Fundraiser {
  const Fundraiser({
    required this.id,
    required this.barId,
    required this.title,
    required this.story,
    required this.goal,
    required this.raised,
    required this.backers,
    required this.deadline,
    required this.rewards,
    this.myContribution = 0,
  });

  factory Fundraiser.fromJson(Map<String, dynamic> json) {
    return Fundraiser(
      id: json['id'] as String,
      barId: json['barId'] as String,
      title: json['title'] as String,
      story: json['story'] as String? ?? '',
      goal: (json['goal'] as num).toDouble(),
      raised: (json['raised'] as num).toDouble(),
      backers: (json['backers'] as num).toInt(),
      deadline: DateTime.parse(json['deadline'] as String),
      rewards: List<Reward>.unmodifiable(
        (json['rewards'] as List<dynamic>? ?? const <dynamic>[])
            .cast<Map<String, dynamic>>()
            .map(Reward.fromJson),
      ),
    );
  }

  final String id;
  final String barId;
  final String title;
  final String story;
  final double goal;
  final double raised;
  final int backers;
  final DateTime deadline;
  final List<Reward> rewards;

  /// Amount the current user has pledged locally (not part of the JSON).
  final double myContribution;

  double get progress => goal <= 0 ? 1.0 : math.min(1.0, raised / goal);

  double get remaining => math.max(0.0, goal - raised);

  bool get isSaved => raised >= goal;

  FundraiserStatus get status =>
      isSaved ? FundraiserStatus.saved : FundraiserStatus.rescuing;

  int daysLeft(DateTime now) => deadline.difference(now).inDays;

  /// Returns a copy that includes the user's local pledge.
  Fundraiser withContribution(double amount) {
    if (amount <= 0) return this;
    return copyWith(
      raised: raised + amount,
      backers: backers + 1,
      myContribution: myContribution + amount,
    );
  }

  Fundraiser copyWith({
    double? raised,
    int? backers,
    double? myContribution,
  }) {
    return Fundraiser(
      id: id,
      barId: barId,
      title: title,
      story: story,
      goal: goal,
      raised: raised ?? this.raised,
      backers: backers ?? this.backers,
      deadline: deadline,
      rewards: rewards,
      myContribution: myContribution ?? this.myContribution,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'barId': barId,
        'title': title,
        'story': story,
        'goal': goal,
        'raised': raised,
        'backers': backers,
        'deadline': deadline.toIso8601String(),
        'rewards': [for (final reward in rewards) reward.toJson()],
      };
}
