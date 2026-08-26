import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_progress_model.dart';

abstract class ProgressRemoteDataSource {
  Future<UserProgressModel> getUserProgress();
}

class ProgressRemoteDataSourceImpl implements ProgressRemoteDataSource {
  ProgressRemoteDataSourceImpl(this.client);

  // ignore: unused_field
  final DioClient client;

  @override
  Future<UserProgressModel> getUserProgress() async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return const UserProgressModel(
        streakDays: 3,
        xpPoints: 450,
        level: 2,
        sessionsCompleted: 8,
        accuracyPercent: 72.5,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
