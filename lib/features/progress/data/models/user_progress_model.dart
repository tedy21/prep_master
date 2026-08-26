import '../../domain/entities/user_progress.dart';

class UserProgressModel extends UserProgress {
  const UserProgressModel({
    required super.streakDays,
    required super.xpPoints,
    required super.level,
    required super.sessionsCompleted,
    required super.accuracyPercent,
  });

  factory UserProgressModel.fromJson(Map<String, dynamic> json) {
    return UserProgressModel(
      streakDays: json['streakDays'] as int,
      xpPoints: json['xpPoints'] as int,
      level: json['level'] as int,
      sessionsCompleted: json['sessionsCompleted'] as int,
      accuracyPercent: (json['accuracyPercent'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'streakDays': streakDays,
        'xpPoints': xpPoints,
        'level': level,
        'sessionsCompleted': sessionsCompleted,
        'accuracyPercent': accuracyPercent,
      };

  UserProgress toEntity() => this;
}
