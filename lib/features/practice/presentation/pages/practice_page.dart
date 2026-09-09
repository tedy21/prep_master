import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/question_difficulty.dart';
import '../../../../core/models/exam_section.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/widgets/exam_section_picker.dart';
import '../../../../injection.dart';
import '../../../progress/domain/usecases/get_progress_dashboard.dart';
import '../../../quiz/domain/entities/quiz_session_args.dart';
import '../../../quiz/domain/services/adaptive_practice_helper.dart';
import '../../../quiz/presentation/pages/quiz_session_page.dart';
import '../../../settings/presentation/cubit/adaptive_practice_cubit.dart';
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
        final adaptive = context.watch<AdaptivePracticeCubit>().state;

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
            if (adaptive) ...[
              const SizedBox(height: 10),
              Text(
                'Adaptive mode is on — difficulty adjusts as you answer. Change this in Settings.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
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
              onSelected: (section) =>
                  _startSection(context, examType, section, adaptive),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startSection(
    BuildContext context,
    ExamType examType,
    ExamSection section,
    bool adaptive,
  ) async {
    var seed = QuestionDifficulty.medium;
    if (adaptive) {
      final dash = await sl<GetProgressDashboard>()(const NoParams());
      dash.fold((_) {}, (dashboard) {
        seed = AdaptivePracticeHelper.seedDifficulty(
          dashboard: dashboard,
          section: section,
        );
      });
    }

    if (!context.mounted) return;
    QuizSessionPage.open(
      context,
      QuizSessionArgs(
        title: section.practiceTitle(examType),
        examType: examType,
        section: section,
        questionCount: section.defaultQuestionCount,
        adaptive: adaptive,
        initialDifficulty: seed,
      ),
    );
  }
}
