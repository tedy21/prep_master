import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/mock_test.dart';
import '../repositories/exam_repository.dart';

class GetMockTests implements UseCase<List<MockTest>, GetMockTestsParams> {
  GetMockTests(this._repository);

  final ExamRepository _repository;

  @override
  Future<Either<Failure, List<MockTest>>> call(GetMockTestsParams params) {
    return _repository.getMockTests(params.examType);
  }
}

class GetMockTestsParams extends Equatable {
  const GetMockTestsParams({required this.examType});

  final ExamType examType;

  @override
  List<Object?> get props => [examType];
}
