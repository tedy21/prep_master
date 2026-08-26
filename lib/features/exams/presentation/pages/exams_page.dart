import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_views.dart';
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
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.tests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final t = state.tests[i];
                    return ListTile(
                      tileColor: Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(t.title),
                      subtitle: Text(
                        '${t.durationMinutes} min · ${t.sectionCount} sections'
                        '${t.isTimed ? ' · Timed' : ''}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}
