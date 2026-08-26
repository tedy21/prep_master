import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/dio_client.dart';
import 'core/network/network_info.dart';
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
import 'features/practice/domain/usecases/get_daily_practice.dart';
import 'features/practice/presentation/bloc/practice_bloc.dart';
import 'features/progress/data/datasources/progress_local_datasource.dart';
import 'features/progress/data/datasources/progress_remote_datasource.dart';
import 'features/progress/data/repositories/progress_repository_impl.dart';
import 'features/progress/domain/repositories/progress_repository.dart';
import 'features/progress/domain/usecases/get_user_progress.dart';
import 'features/progress/presentation/bloc/progress_bloc.dart';

final sl = GetIt.instance;

/// Registers core services and feature dependencies.
///
/// Run `dart run build_runner build` later if you migrate modules to
/// `@injectable` code generation; this manual setup keeps the arch runnable now.
Future<void> configureDependencies() async {
  // External
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<Connectivity>(() => Connectivity());

  // Core
  sl.registerLazySingleton<DioClient>(() => DioClient());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // —— Practice ——
  sl.registerLazySingleton<PracticeRemoteDataSource>(
    () => PracticeRemoteDataSourceImpl(sl()),
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
  sl.registerFactory(() => PracticeBloc(getDailyPractice: sl()));

  // —— Exams (IELTS / SAT) ——
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

  // —— Progress ——
  sl.registerLazySingleton<ProgressRemoteDataSource>(
    () => ProgressRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ProgressLocalDataSource>(
    () => ProgressLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ProgressRepository>(
    () => ProgressRepositoryImpl(
      remote: sl(),
      local: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetUserProgress(sl()));
  sl.registerFactory(() => ProgressBloc(getUserProgress: sl()));

  // —— College Guides ——
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
