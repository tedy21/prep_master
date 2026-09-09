import '../entities/ai_insight.dart';
import '../entities/progress_dashboard.dart';

class FallbackCoach {
  const FallbackCoach._();

  static AiInsight build(ProgressDashboard dashboard) {
    final p = dashboard.progress;
    final weak = dashboard.weakestSkill;
    final strong = dashboard.strongestSkill;

    final strengths = <String>[];
    final weakAreas = <String>[];
    final nextActions = <String>[];

    if (strong != null && strong.accuracyPercent >= 70) {
      strengths.add(
        '${strong.skillArea} (${strong.accuracyPercent.toStringAsFixed(0)}% accuracy)',
      );
    } else if (p.streakDays >= 3) {
      strengths.add('${p.streakDays}-day practice streak');
    } else if (p.sessionsCompleted > 0) {
      strengths.add('${p.sessionsCompleted} sessions completed');
    }

    if (weak != null && weak.total >= 2) {
      weakAreas.add(
        '${weak.skillArea} (${weak.accuracyPercent.toStringAsFixed(0)}%)',
      );
      nextActions.add(
        'Do a short ${weak.skillArea} practice set and review every miss.',
      );
    } else if (p.sessionsCompleted == 0) {
      weakAreas.add('Not enough practice data yet');
      nextActions.add(
        'Complete your first practice session to unlock insights.',
      );
    } else {
      weakAreas.add('Keep building a broader skill sample');
      nextActions.add('Practice a different section to balance your skills.');
    }

    if (p.accuracyPercent < 70 && p.sessionsCompleted > 0) {
      nextActions.add(
        'Slow down on the next quiz — aim for accuracy over speed.',
      );
    } else if (p.streakDays == 0) {
      nextActions.add('Practice today to start a streak.');
    } else {
      nextActions.add('Keep your streak alive with one short session tomorrow.');
    }

    final headline = p.sessionsCompleted == 0
        ? 'Ready when you are'
        : (weak != null
            ? 'Focus on ${weak.skillArea}'
            : 'Solid progress — keep going');

    final summary = p.sessionsCompleted == 0
        ? 'Finish a practice or mock test and your AI coach will personalize tips here.'
        : 'Overall accuracy is ${p.accuracyPercent.toStringAsFixed(0)}% across '
            '${p.sessionsCompleted} sessions. '
            '${weak != null ? "Your biggest opportunity is ${weak.skillArea}." : "Keep stacking consistent practice."}';

    return AiInsight.fallback(
      headline: headline,
      summary: summary,
      strengths: strengths.isEmpty ? ['Showing up to practice'] : strengths,
      weakAreas: weakAreas,
      nextActions: nextActions.take(3).toList(),
      encouragement: p.streakDays >= 5
          ? 'That streak shows real discipline — protect it.'
          : 'Small daily reps beat cramming. You have this.',
    );
  }
}
