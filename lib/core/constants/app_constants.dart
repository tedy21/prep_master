/// App-wide string and numeric constants.
abstract final class AppConstants {
  static const String appName = 'PrepMaster';
  static const String appTagline =
      'Your pocket-sized exam coach for IELTS, SAT & college apps';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const int dailyPracticeMinMinutes = 15;
  static const int dailyPracticeMaxMinutes = 30;
}

///  tracks.
enum ExamType {
  ielts,
  sat,
  general,
}

/// College application guide categories.
enum GuideCategory {
  essays,
  recommendations,
  extracurriculars,
  deadlines,
  scholarships,
  interviews,
  commonApp,
  financialAid,
}
