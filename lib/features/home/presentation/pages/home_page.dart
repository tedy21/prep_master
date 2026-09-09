import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/exam_section.dart';
import '../../../../injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../college_guides/presentation/bloc/college_guides_bloc.dart';
import '../../../college_guides/presentation/pages/college_guides_page.dart';
import '../../../exams/presentation/bloc/exams_bloc.dart';
import '../../../exams/presentation/pages/exams_page.dart';
import '../../../practice/presentation/bloc/practice_bloc.dart';
import '../../../practice/presentation/pages/practice_page.dart';
import '../../../progress/presentation/bloc/progress_bloc.dart';
import '../../../progress/presentation/pages/progress_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const _titles = [
    'Practice',
    'Mock Tests',
    'College Guides',
    'Progress',
  ];

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<AuthBloc>(),
          child: const SettingsPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<PracticeBloc>()
            ..add(const LoadDailyPractice(
              examType: ExamType.sat,
              section: ExamSection.math,
            )),
        ),
        BlocProvider(
          create: (_) =>
              sl<ExamsBloc>()..add(const LoadMockTests(ExamType.sat)),
        ),
        BlocProvider(
          create: (_) =>
              sl<CollegeGuidesBloc>()..add(const LoadCollegeGuides()),
        ),
        BlocProvider(
          create: (_) =>
              sl<ProgressBloc>()..add(const LoadUserProgress()),
        ),
      ],
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text(_titles[_index]),
            ),
            drawer: Drawer(
              child: SafeArea(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    DrawerHeader(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            child: const Icon(
                              Icons.school_outlined,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppConstants.appName,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            'Exam prep made simple',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Colors.white70,
                                ),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: const Text('Settings'),
                      subtitle: const Text('Profile, theme & more'),
                      onTap: () {
                        Navigator.of(context).pop();
                        _openSettings();
                      },
                    ),
                  ],
                ),
              ),
            ),
            body: IndexedStack(
              index: _index,
              children: [
                const PracticePage(),
                const ExamsPage(),
                const CollegeGuidesPage(),
                ProgressPage(
                  onStartPractice: () => setState(() => _index = 0),
                ),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) {
                setState(() => _index = i);
                if (i == 3) {
                  context
                      .read<ProgressBloc>()
                      .add(const LoadUserProgress());
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.fitness_center_outlined),
                  selectedIcon: Icon(Icons.fitness_center),
                  label: 'Practice',
                ),
                NavigationDestination(
                  icon: Icon(Icons.quiz_outlined),
                  selectedIcon: Icon(Icons.quiz),
                  label: 'Exams',
                ),
                NavigationDestination(
                  icon: Icon(Icons.school_outlined),
                  selectedIcon: Icon(Icons.school),
                  label: 'College',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights),
                  label: 'Progress',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
