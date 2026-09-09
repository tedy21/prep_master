import 'package:equatable/equatable.dart';

import '../../../quiz/domain/entities/quiz_session_record.dart';
import 'ai_insight.dart';
import 'difficulty_stat.dart';
import 'skill_stat.dart';
import 'user_progress.dart';

class ProgressDashboard extends Equatable {
  const ProgressDashboard({
    required this.progress,
    required this.skillStats,
    required this.recentSessions,
    this.aiInsight,
  });

  final UserProgress progress;
  final List<SkillStat> skillStats;
  final List<QuizSessionRecord> recentSessions;
  final AiInsight? aiInsight;

  List<double> get accuracyTrend {
    final sessions = recentSessions.take(14).toList().reversed.toList();
    return sessions.map((s) => s.percent).toList();
  }

  SkillStat? get weakestSkill {
    if (skillStats.isEmpty) return null;
    return skillStats.reduce(
      (a, b) => a.accuracyPercent <= b.accuracyPercent ? a : b,
    );
  }

  SkillStat? get strongestSkill {
    if (skillStats.isEmpty) return null;
    return skillStats.reduce(
      (a, b) => a.accuracyPercent >= b.accuracyPercent ? a : b,
    );
  }

  double get levelProgress {
    final xp = progress.xpPoints;
    return (xp % 100) / 100.0;
  }

  int get xpToNextLevel => 100 - (progress.xpPoints % 100);

  List<DifficultyStat> get difficultyStats {
    final map = <String, ({int correct, int total})>{};
    for (final session in recentSessions) {
      for (final o in session.questionOutcomes) {
        final diff = (o.difficulty ?? '').trim().toLowerCase();
        if (diff.isEmpty) continue;
        final prev = map[diff] ?? (correct: 0, total: 0);
        map[diff] = (
          correct: prev.correct + (o.isCorrect ? 1 : 0),
          total: prev.total + 1,
        );
      }
    }
    const order = ['easy', 'medium', 'hard'];
    return order
        .where((d) => map.containsKey(d))
        .map(
          (d) => DifficultyStat(
            difficulty: d,
            correct: map[d]!.correct,
            total: map[d]!.total,
          ),
        )
        .toList();
  }

  double? recentSkillAccuracy(String skillArea, {int lookbackSessions = 5}) {
    var correct = 0;
    var total = 0;
    for (final session in recentSessions.take(lookbackSessions)) {
      for (final o in session.questionOutcomes) {
        final skill = (o.skillArea ?? '').trim();
        if (skill.toLowerCase() != skillArea.toLowerCase()) continue;
        total++;
        if (o.isCorrect) correct++;
      }
    }
    if (total == 0) return null;
    return (correct / total) * 100;
  }

  ProgressDashboard copyWith({
    UserProgress? progress,
    List<SkillStat>? skillStats,
    List<QuizSessionRecord>? recentSessions,
    AiInsight? aiInsight,
    bool clearInsight = false,
  }) {
    return ProgressDashboard(
      progress: progress ?? this.progress,
      skillStats: skillStats ?? this.skillStats,
      recentSessions: recentSessions ?? this.recentSessions,
      aiInsight: clearInsight ? null : (aiInsight ?? this.aiInsight),
    );
  }

  @override
  List<Object?> get props =>
      [progress, skillStats, recentSessions, aiInsight];
}
