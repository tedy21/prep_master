import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/practice_session_model.dart';

abstract class PracticeRemoteDataSource {
  Future<PracticeSessionModel> getDailyPractice(ExamType examType);
}

class PracticeRemoteDataSourceImpl implements PracticeRemoteDataSource {
  PracticeRemoteDataSourceImpl(this.client);

  /// Wired for real API calls; unused while stubs are active.
  // ignore: unused_field
  final DioClient client;

  @override
  Future<PracticeSessionModel> getDailyPractice(ExamType examType) async {
    try {
      // Placeholder until API is live — returns a stub session.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return PracticeSessionModel(
        id: 'daily-${examType.name}',
        title: 'Daily ${examType.name.toUpperCase()} Practice',
        examType: examType,
        skill: examType == ExamType.sat ? 'Algebra' : 'Reading',
        estimatedMinutes: AppConstants.dailyPracticeMinMinutes,
        questionCount: 12,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
