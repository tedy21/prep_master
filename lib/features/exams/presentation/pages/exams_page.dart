import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/exam_section.dart';
import '../../../../core/widgets/app_views.dart';
import '../../../quiz/domain/entities/quiz_session_args.dart';
import '../../../quiz/presentation/pages/quiz_session_page.dart';
import '../../domain/entities/mock_test.dart';
import '../bloc/exams_bloc.dart';

class ExamsPage extends StatefulWidget {
  const ExamsPage({super.key});

  @override
  State<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> {
  ExamType _selected = ExamType.sat;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SegmentedButton<ExamType>(
            segments: const [
              ButtonSegment(value: ExamType.sat, label: Text('SAT')),
              ButtonSegment(value: ExamType.ielts, label: Text('IELTS')),
            ],
            selected: {_selected},
            onSelectionChanged: (set) {
              setState(() => _selected = set.first);
              context.read<ExamsBloc>().add(LoadMockTests(set.first));
            },
          ),
        ),
        Expanded(
          child: BlocBuilder<ExamsBloc, ExamsState>(
            builder: (context, state) {
              if (state is ExamsLoading || state is ExamsInitial) {
                return const AppLoadingView(message: 'Loading mock tests…');
              }
              if (state is ExamsError) {
                return AppErrorView(
                  message: state.message,
                  onRetry: () => context
                      .read<ExamsBloc>()
                      .add(LoadMockTests(_selected)),
                );
              }
              if (state is ExamsLoaded) {
                final fullMocks =
                    state.tests.where((t) => t.isFullMock).toList();
                final sectionTests =
                    state.tests.where((t) => !t.isFullMock).toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (fullMocks.isNotEmpty) ...[
                      _SectionHeader(
                        title: _selected == ExamType.sat
                            ? 'Full SAT Mock'
                            : 'Full IELTS Mock',
                      ),
                      ...fullMocks.map(
                        (t) => _MockTestTile(
                          test: t,
                          onTap: () => _openQuiz(context, t),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _SectionHeader(
                      title: _selected == ExamType.sat
                          ? 'Section Practice'
                          : 'Skill Practice',
                    ),
                    ...sectionTests.map(
                      (t) => _MockTestTile(
                        test: t,
                        onTap: () => _openQuiz(context, t),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  void _openQuiz(BuildContext context, MockTest test) {
    final questionCount = test.section?.defaultQuestionCount ??
        (test.examType == ExamType.sat ? 8 : 6);

    final timed = test.isTimed || test.durationMinutes > 0;

    QuizSessionPage.open(
      context,
      QuizSessionArgs(
        title: test.title,
        examType: test.examType,
        section: test.section,
        questionCount: questionCount,
        mockTestId: test.id,
        adaptive: false,
        timeLimitMinutes: timed ? test.durationMinutes : null,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _MockTestTile extends StatelessWidget {
  const _MockTestTile({required this.test, required this.onTap});

  final MockTest test;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sectionLabel = test.section?.label;
    final subtitle = [
      if (sectionLabel != null) sectionLabel,
      '${test.durationMinutes} min',
      if (test.isFullMock) '${test.sectionCount} sections',
      if (test.isTimed) 'Timed',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        tileColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: test.section != null
            ? Icon(test.section!.icon)
            : Icon(
                test.examType == ExamType.sat
                    ? Icons.assignment_outlined
                    : Icons.school_outlined,
              ),
        title: Text(test.title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
