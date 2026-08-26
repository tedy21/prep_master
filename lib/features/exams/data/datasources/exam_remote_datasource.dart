import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/mock_test_model.dart';

abstract class ExamRemoteDataSource {
  Future<List<MockTestModel>> getMockTests(ExamType examType);
}

class ExamRemoteDataSourceImpl implements ExamRemoteDataSource {
  ExamRemoteDataSourceImpl(this.client);

  // ignore: unused_field
  final DioClient client;

  @override
  Future<List<MockTestModel>> getMockTests(ExamType examType) async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (examType == ExamType.ielts) {
        return const [
          MockTestModel(
            id: 'ielts-full-1',
            title: 'IELTS Academic Full Mock',
            examType: ExamType.ielts,
            durationMinutes: 165,
            sectionCount: 4,
            isTimed: true,
          ),
          MockTestModel(
            id: 'ielts-listening-1',
            title: 'IELTS Listening Practice Test',
            examType: ExamType.ielts,
            durationMinutes: 40,
            sectionCount: 1,
            isTimed: true,
          ),
        ];
      }
      return const [
        MockTestModel(
          id: 'sat-full-1',
          title: 'SAT Full-Length Mock',
          examType: ExamType.sat,
          durationMinutes: 134,
          sectionCount: 2,
          isTimed: true,
        ),
        MockTestModel(
          id: 'sat-math-1',
          title: 'SAT Math Module Practice',
          examType: ExamType.sat,
          durationMinutes: 70,
          sectionCount: 1,
          isTimed: true,
        ),
      ];
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
