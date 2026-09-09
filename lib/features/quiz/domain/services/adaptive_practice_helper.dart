import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/question_difficulty.dart';
import '../../../../core/models/exam_section.dart';
import '../../../progress/domain/entities/progress_dashboard.dart';
import '../../../progress/domain/entities/user_progress.dart';

abstract final class AdaptivePracticeHelper {
  static String seedDifficulty({
    UserProgress? progress,
    ProgressDashboard? dashboard,
    ExamSection? section,
  }) {
    if (dashboard != null && dashboard.skillStats.isNotEmpty) {
      final relevant = dashboard.skillStats.where((s) {
        if (section == null) return true;
        final key = s.skillArea.toLowerCase();
        final label = section.label.toLowerCase();
        final id = section.id.toLowerCase();
        return key.contains(label) ||
            key.contains(id) ||
            label.contains(key);
      }).toList();

      final pool = relevant.isNotEmpty ? relevant : dashboard.skillStats;
      final weakest = pool.reduce(
        (a, b) => a.accuracyPercent <= b.accuracyPercent ? a : b,
      );
      if (weakest.total >= 2 && weakest.accuracyPercent < 50) {
        return QuestionDifficulty.easy;
      }
      if (weakest.total >= 2 && weakest.accuracyPercent > 75) {
        return QuestionDifficulty.hard;
      }
    }

    final accuracy = progress?.accuracyPercent ??
        dashboard?.progress.accuracyPercent ??
        0;
    final sessions = progress?.sessionsCompleted ??
        dashboard?.progress.sessionsCompleted ??
        0;
    if (sessions == 0) return QuestionDifficulty.medium;
    return QuestionDifficulty.fromAccuracy(accuracy);
  }

  static ({ExamType examType, ExamSection section}) sectionForSkill(
    String? skillArea,
  ) {
    final skill = (skillArea ?? '').toLowerCase();
    for (final section in ExamSection.values) {
      final label = section.label.toLowerCase();
      final id = section.id.toLowerCase();
      if (skill.contains(label) ||
          skill.contains(id) ||
          (skill.isNotEmpty && label.contains(skill))) {
        return (examType: section.examType, section: section);
      }
    }
    if (skill.contains('math') ||
        skill.contains('algebra') ||
        skill.contains('geometry')) {
      return (examType: ExamType.sat, section: ExamSection.math);
    }
    if (skill.contains('grammar') || skill.contains('vocabulary')) {
      return (examType: ExamType.sat, section: ExamSection.english);
    }
    if (skill.contains('listening')) {
      return (examType: ExamType.ielts, section: ExamSection.listening);
    }
    if (skill.contains('reading')) {
      return (examType: ExamType.ielts, section: ExamSection.reading);
    }
    if (skill.contains('writing')) {
      return (examType: ExamType.ielts, section: ExamSection.writing);
    }
    if (skill.contains('speaking')) {
      return (examType: ExamType.ielts, section: ExamSection.speaking);
    }
    return (examType: ExamType.sat, section: ExamSection.math);
  }
}
