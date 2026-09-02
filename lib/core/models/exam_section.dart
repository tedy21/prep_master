import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// A section (SAT) or skill (IELTS) within an exam track.
enum ExamSection {
  math,
  english,
  listening,
  reading,
  writing,
  speaking;

  /// Sections available for a given exam type.
  static List<ExamSection> forExam(ExamType examType) {
    switch (examType) {
      case ExamType.sat:
        return const [ExamSection.math, ExamSection.english];
      case ExamType.ielts:
        return const [
          ExamSection.listening,
          ExamSection.reading,
          ExamSection.writing,
          ExamSection.speaking,
        ];
      case ExamType.general:
        return const [];
    }
  }

  /// Default section when switching exam tracks.
  static ExamSection defaultFor(ExamType examType) =>
      forExam(examType).first;

  /// Parse from JSON / Firestore id.
  static ExamSection? tryParse(String? value) {
    if (value == null) return null;
    for (final section in ExamSection.values) {
      if (section.id == value || section.name == value) return section;
    }
    if (value == 'readingWriting') return ExamSection.english;
    return null;
  }
}

extension ExamSectionX on ExamSection {
  String get id => name;

  ExamType get examType {
    switch (this) {
      case ExamSection.math:
      case ExamSection.english:
        return ExamType.sat;
      case ExamSection.listening:
      case ExamSection.reading:
      case ExamSection.writing:
      case ExamSection.speaking:
        return ExamType.ielts;
    }
  }

  String get label {
    switch (this) {
      case ExamSection.math:
        return 'Math';
      case ExamSection.english:
        return 'Reading & Writing';
      case ExamSection.listening:
        return 'Listening';
      case ExamSection.reading:
        return 'Reading';
      case ExamSection.writing:
        return 'Writing';
      case ExamSection.speaking:
        return 'Speaking';
    }
  }

  String get description {
    switch (this) {
      case ExamSection.math:
        return 'Algebra, geometry, and problem solving';
      case ExamSection.english:
        return 'Grammar, vocabulary, and reading comprehension';
      case ExamSection.listening:
        return 'Conversations, lectures, and note-taking';
      case ExamSection.reading:
        return 'Academic passages and comprehension';
      case ExamSection.writing:
        return 'Essay structure, task response, and coherence';
      case ExamSection.speaking:
        return 'Fluency, pronunciation, and interview skills';
    }
  }

  IconData get icon {
    switch (this) {
      case ExamSection.math:
        return Icons.calculate_outlined;
      case ExamSection.english:
        return Icons.menu_book_outlined;
      case ExamSection.listening:
        return Icons.headphones_outlined;
      case ExamSection.reading:
        return Icons.article_outlined;
      case ExamSection.writing:
        return Icons.edit_outlined;
      case ExamSection.speaking:
        return Icons.mic_outlined;
    }
  }

  /// Firestore subcollection key under `questions/{examType}/`.
  String get firestoreKey {
    if (this == ExamSection.english) return 'readingWriting';
    return id;
  }

  int get estimatedMinutes {
    switch (this) {
      case ExamSection.math:
        return 35;
      case ExamSection.english:
        return 32;
      case ExamSection.listening:
        return 30;
      case ExamSection.reading:
        return 60;
      case ExamSection.writing:
        return 60;
      case ExamSection.speaking:
        return 15;
    }
  }

  int get defaultQuestionCount {
    switch (this) {
      case ExamSection.math:
      case ExamSection.english:
        return 8;
      case ExamSection.listening:
      case ExamSection.reading:
        return 6;
      case ExamSection.writing:
      case ExamSection.speaking:
        return 5;
    }
  }

  String practiceTitle(ExamType examType) =>
      '${examType.name.toUpperCase()} $label Practice';
}
