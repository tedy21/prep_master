import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/exam_section.dart';
import '../../../../core/widgets/app_views.dart';
import '../../../../core/widgets/exam_section_picker.dart';
import '../../../quiz/domain/entities/quiz_session_args.dart';
import '../../../quiz/presentation/pages/quiz_session_page.dart';
import '../bloc/practice_bloc.dart';

class PracticePage extends StatelessWidget {
  const PracticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PracticeBloc, PracticeState>(
      builder: (context, state) {
        if (state is PracticeLoading || state is PracticeInitial) {
          return const AppLoadingView(message: 'Loading daily practice…');
        }
        if (state is PracticeError) {
          return AppErrorView(
            message: state.message,
            onRetry: () => context.read<PracticeBloc>().add(
                  LoadDailyPractice(
                    examType: ExamType.sat,
                    section: ExamSection.math,
                  ),
                ),
          );
        }
        if (state is PracticeLoaded) {
          final s = state.session;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                s.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${s.section.label} · ${s.estimatedMinutes} min · ${s.questionCount} questions',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              SegmentedButton<ExamType>(
                segments: const [
                  ButtonSegment(value: ExamType.sat, label: Text('SAT')),
                  ButtonSegment(value: ExamType.ielts, label: Text('IELTS')),
                ],
                selected: {s.examType},
                onSelectionChanged: (set) {
                  final examType = set.first;
                  context.read<PracticeBloc>().add(
                        LoadDailyPractice(
                          examType: examType,
                          section: ExamSection.defaultFor(examType),
                        ),
                      );
                },
              ),
              const SizedBox(height: 24),
              ExamSectionPicker(
                examType: s.examType,
                selected: s.section,
                onSelected: (section) {
                  if (section == s.section) return;
                  context.read<PracticeBloc>().add(
                        LoadDailyPractice(
                          examType: s.examType,
                          section: section,
                        ),
                      );
                },
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => QuizSessionPage.open(
                  context,
                  QuizSessionArgs(
                    title: s.title,
                    examType: s.examType,
                    section: s.section,
                    questionCount: s.questionCount,
                  ),
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start session'),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
