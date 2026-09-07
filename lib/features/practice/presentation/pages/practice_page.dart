import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/exam_section.dart';
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
        final examType = state is PracticeLoaded
            ? state.session.examType
            : ExamType.sat;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Text(
              'Daily practice',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              examType == ExamType.sat
                  ? 'Pick a SAT section and jump straight in.'
                  : 'Pick an IELTS skill and jump straight in.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            SegmentedButton<ExamType>(
              segments: const [
                ButtonSegment(
                  value: ExamType.sat,
                  label: Text('SAT'),
                  icon: Icon(Icons.calculate_outlined, size: 18),
                ),
                ButtonSegment(
                  value: ExamType.ielts,
                  label: Text('IELTS'),
                  icon: Icon(Icons.language, size: 18),
                ),
              ],
              selected: {examType},
              onSelectionChanged: (set) {
                final next = set.first;
                context.read<PracticeBloc>().add(
                      LoadDailyPractice(
                        examType: next,
                        section: ExamSection.defaultFor(next),
                      ),
                    );
              },
            ),
            const SizedBox(height: 24),
            ExamSectionPicker(
              examType: examType,
              onSelected: (section) => _startSection(context, examType, section),
            ),
          ],
        );
      },
    );
  }

  void _startSection(
    BuildContext context,
    ExamType examType,
    ExamSection section,
  ) {
    QuizSessionPage.open(
      context,
      QuizSessionArgs(
        title: section.practiceTitle(examType),
        examType: examType,
        section: section,
        questionCount: section.defaultQuestionCount,
      ),
    );
  }
}
