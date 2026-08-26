import 'package:equatable/equatable.dart';

class UserProgress extends Equatable {
  const UserProgress({
    required this.streakDays,
    required this.xpPoints,
    required this.level,
    required this.sessionsCompleted,
    required this.accuracyPercent,
  });

  final int streakDays;
  final int xpPoints;
  final int level;
  final int sessionsCompleted;
  final double accuracyPercent;

  @override
  List<Object?> get props =>
      [streakDays, xpPoints, level, sessionsCompleted, accuracyPercent];
}
