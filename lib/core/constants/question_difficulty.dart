abstract final class QuestionDifficulty {
  static const easy = 'easy';
  static const medium = 'medium';
  static const hard = 'hard';

  static const all = [easy, medium, hard];

  static String normalize(String? raw) {
    final v = (raw ?? medium).trim().toLowerCase();
    if (v == easy || v == hard) return v;
    return medium;
  }

  static String label(String difficulty) {
    switch (normalize(difficulty)) {
      case easy:
        return 'Easy';
      case hard:
        return 'Hard';
      default:
        return 'Medium';
    }
  }

  static int rank(String difficulty) {
    switch (normalize(difficulty)) {
      case easy:
        return 0;
      case hard:
        return 2;
      default:
        return 1;
    }
  }

  static String fromRank(int rank) {
    if (rank <= 0) return easy;
    if (rank >= 2) return hard;
    return medium;
  }

  static String harder(String current) =>
      fromRank(rank(current) + 1);

  static String easier(String current) =>
      fromRank(rank(current) - 1);

  static String fromAccuracy(double accuracyPercent) {
    if (accuracyPercent <= 0) return medium;
    if (accuracyPercent < 50) return easy;
    if (accuracyPercent > 75) return hard;
    return medium;
  }
}
