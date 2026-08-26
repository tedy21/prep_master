import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_views.dart';
import '../bloc/college_guides_bloc.dart';

class CollegeGuidesPage extends StatelessWidget {
  const CollegeGuidesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CollegeGuidesBloc, CollegeGuidesState>(
      builder: (context, state) {
        if (state is CollegeGuidesLoading || state is CollegeGuidesInitial) {
          return const AppLoadingView(message: 'Loading guides…');
        }
        if (state is CollegeGuidesError) {
          return AppErrorView(
            message: state.message,
            onRetry: () => context
                .read<CollegeGuidesBloc>()
                .add(const LoadCollegeGuides()),
          );
        }
        if (state is CollegeGuidesLoaded) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.guides.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final g = state.guides[i];
              return ListTile(
                tileColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(g.title),
                subtitle: Text(
                  '${g.category.name} · ${g.readMinutes} min read\n${g.summary}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
