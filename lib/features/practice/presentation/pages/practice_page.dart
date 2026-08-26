import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_views.dart';
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
                  const LoadDailyPractice(ExamType.sat),
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
                '${s.skill} · ${s.estimatedMinutes} min · ${s.questionCount} questions',
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
                  context
                      .read<PracticeBloc>()
                      .add(LoadDailyPractice(set.first));
                },
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {},
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
