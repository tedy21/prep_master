import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/exam_section.dart';
import '../../../../injection.dart';
import '../../../college_guides/presentation/bloc/college_guides_bloc.dart';
import '../../../college_guides/presentation/pages/college_guides_page.dart';
import '../../../exams/presentation/bloc/exams_bloc.dart';
import '../../../exams/presentation/pages/exams_page.dart';
import '../../../practice/presentation/bloc/practice_bloc.dart';
import '../../../practice/presentation/pages/practice_page.dart';
import '../../../progress/presentation/bloc/progress_bloc.dart';
import '../../../progress/presentation/pages/progress_page.dart';

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
      child: Scaffold(
        appBar: AppBar(title: Text(_titles[_index])),
        body: IndexedStack(
          index: _index,
          children: const [
            PracticePage(),
            ExamsPage(),
            CollegeGuidesPage(),
            ProgressPage(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
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
      ),
    );
  }
}
