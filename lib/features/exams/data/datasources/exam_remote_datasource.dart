import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/firebase/firebase_service.dart';
import '../../../../core/models/exam_section.dart';
import '../models/mock_test_model.dart';

abstract class ExamRemoteDataSource {
  Future<List<MockTestModel>> getMockTests(ExamType examType);
}

class ExamRemoteDataSourceImpl implements ExamRemoteDataSource {
  ExamRemoteDataSourceImpl(this.firebase);

  final FirebaseService firebase;

  @override
  Future<List<MockTestModel>> getMockTests(ExamType examType) async {
    try {
      final snap = await firebase.firestore
          .collection(FirestorePaths.mockTests)
          .where('examType', isEqualTo: examType.name)
          .get();

      if (snap.docs.isNotEmpty) {
        return snap.docs.map((doc) {
          final d = doc.data();
          return MockTestModel(
            id: doc.id,
            title: d['title'] as String? ?? 'Mock Test',
            examType: examType,
            durationMinutes: d['durationMinutes'] as int? ?? 60,
            sectionCount: d['sectionCount'] as int? ?? 1,
            isTimed: d['isTimed'] as bool? ?? true,
            section: ExamSection.tryParse(d['section'] as String?),
          );
        }).toList()
          ..sort((a, b) {
            // Full mocks first, then section tests alphabetically.
            if (a.isFullMock != b.isFullMock) {
              return a.isFullMock ? -1 : 1;
            }
            return a.title.compareTo(b.title);
          });
      }

      throw const ServerException('No mock tests in Firestore — run seed script');
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Firestore error');
    }
  }
}
