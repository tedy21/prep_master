import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/data/firestore_quiz_datasource.dart';
import 'core/data/local_quiz_bank_datasource.dart';
import 'core/firebase/firebase_service.dart';
import 'core/network/dio_client.dart';
import 'core/network/network_info.dart';
import 'core/network/open_trivia_client.dart';
import 'core/network/quiz_api_client.dart';
import 'core/network/trivia_api_client.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/college_guides/data/datasources/college_guide_local_datasource.dart';
import 'features/college_guides/data/datasources/college_guide_remote_datasource.dart';
import 'features/college_guides/data/repositories/college_guide_repository_impl.dart';
import 'features/college_guides/domain/repositories/college_guide_repository.dart';
import 'features/college_guides/domain/usecases/get_college_guides.dart';
import 'features/college_guides/presentation/bloc/college_guides_bloc.dart';
import 'features/exams/data/datasources/exam_local_datasource.dart';
import 'features/exams/data/datasources/exam_remote_datasource.dart';
import 'features/exams/data/repositories/exam_repository_impl.dart';
import 'features/exams/domain/repositories/exam_repository.dart';
import 'features/exams/domain/usecases/get_mock_tests.dart';
import 'features/exams/presentation/bloc/exams_bloc.dart';
import 'features/practice/data/datasources/practice_local_datasource.dart';
import 'features/practice/data/datasources/practice_remote_datasource.dart';
import 'features/practice/data/repositories/practice_repository_impl.dart';
import 'features/practice/domain/repositories/practice_repository.dart';
import 'features/practice/domain/usecases/get_adaptive_pools.dart';
import 'features/practice/domain/usecases/get_daily_practice.dart';
import 'features/practice/domain/usecases/get_quiz_questions.dart';
import 'features/practice/presentation/bloc/practice_bloc.dart';
import 'features/quiz/data/datasources/quiz_session_remote_datasource.dart';
import 'features/quiz/data/repositories/quiz_session_repository_impl.dart';
import 'features/quiz/domain/repositories/quiz_session_repository.dart';
import 'features/quiz/domain/usecases/record_quiz_session.dart';
import 'features/quiz/presentation/bloc/quiz_session_bloc.dart';
import 'features/progress/data/datasources/progress_ai_remote_datasource.dart';
import 'features/progress/data/datasources/progress_local_datasource.dart';
import 'features/progress/data/datasources/progress_remote_datasource.dart';
import 'features/progress/data/repositories/progress_repository_impl.dart';
import 'features/progress/domain/repositories/progress_repository.dart';
import 'features/progress/domain/usecases/get_progress_dashboard.dart';
import 'features/progress/domain/usecases/get_user_progress.dart';
import 'features/progress/domain/usecases/refresh_ai_insights.dart';
import 'features/progress/presentation/bloc/progress_bloc.dart';
import 'features/settings/presentation/cubit/adaptive_practice_cubit.dart';
import 'features/settings/presentation/cubit/theme_cubit.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<Connectivity>(() => Connectivity());

  // Firebase
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFunctions>(() => FirebaseFunctions.instance);
  sl.registerLazySingleton<FirebaseService>(
    () => FirebaseService(
      firestore: sl(),
      auth: sl(),
      functions: sl(),
    ),
  );

  // Network / free APIs
  sl.registerLazySingleton<DioClient>(() => DioClient());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<OpenTriviaClient>(() => OpenTriviaClient());
  sl.registerLazySingleton<TriviaApiClient>(() => TriviaApiClient());
  sl.registerLazySingleton<QuizApiClient>(() => QuizApiClient());
  sl.registerLazySingleton<FirestoreQuizDataSource>(
    () => FirestoreQuizDataSource(sl()),
  );
  sl.registerLazySingleton<LocalQuizBankDataSource>(
    () => LocalQuizBankDataSource(),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSource(sl()));
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
  sl.registerLazySingleton(() => ThemeCubit(sl()));
  sl.registerLazySingleton(() => AdaptivePracticeCubit(sl()));

  // Quiz sessions (history)
  sl.registerLazySingleton<QuizSessionRemoteDataSource>(
    () => QuizSessionRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<QuizSessionRepository>(
    () => QuizSessionRepositoryImpl(remote: sl()),
  );

  // Practice
  sl.registerLazySingleton<PracticeRemoteDataSource>(
    () => PracticeRemoteDataSourceImpl(
      firebase: sl(),
      firestoreQuiz: sl(),
      localQuizBank: sl(),
      openTrivia: sl(),
      triviaApi: sl(),
    ),
  );
  sl.registerLazySingleton<PracticeLocalDataSource>(
    () => PracticeLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<PracticeRepository>(
    () => PracticeRepositoryImpl(
      remote: sl(),
      local: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetDailyPractice(sl()));
  sl.registerLazySingleton(() => GetQuizQuestions(sl()));
  sl.registerLazySingleton(() => GetAdaptivePools(sl()));
  sl.registerFactory(() => PracticeBloc(getDailyPractice: sl()));
  sl.registerFactory(
    () => QuizSessionBloc(
      getQuizQuestions: sl(),
      getAdaptivePools: sl(),
    ),
  );

  // Exams
  sl.registerLazySingleton<ExamRemoteDataSource>(
    () => ExamRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ExamLocalDataSource>(
    () => ExamLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ExamRepository>(
    () => ExamRepositoryImpl(
      remote: sl(),
      local: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetMockTests(sl()));
  sl.registerFactory(() => ExamsBloc(getMockTests: sl()));

  // Progress
  sl.registerLazySingleton<ProgressRemoteDataSource>(
    () => ProgressRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ProgressLocalDataSource>(
    () => ProgressLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ProgressAiRemoteDataSource>(
    () => ProgressAiRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ProgressRepository>(
    () => ProgressRepositoryImpl(
      remote: sl(),
      local: sl(),
      networkInfo: sl(),
      sessionRepository: sl(),
      aiRemote: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetUserProgress(sl()));
  sl.registerLazySingleton(() => GetProgressDashboard(sl()));
  sl.registerLazySingleton(() => RefreshAiInsights(sl()));
  sl.registerLazySingleton(() => RecordQuizSession(
        sessionRepository: sl(),
        progressRepository: sl(),
      ));
  sl.registerFactory(
    () => ProgressBloc(
      getProgressDashboard: sl(),
      refreshAiInsights: sl(),
    ),
  );

  // College guides
  sl.registerLazySingleton<CollegeGuideRemoteDataSource>(
    () => CollegeGuideRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<CollegeGuideLocalDataSource>(
    () => CollegeGuideLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<CollegeGuideRepository>(
    () => CollegeGuideRepositoryImpl(
      remote: sl(),
      local: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetCollegeGuides(sl()));
  sl.registerFactory(() => CollegeGuidesBloc(getCollegeGuides: sl()));
}
