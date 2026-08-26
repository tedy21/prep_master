import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/college_guide.dart';
import '../repositories/college_guide_repository.dart';

class GetCollegeGuides
    implements UseCase<List<CollegeGuide>, GetCollegeGuidesParams> {
  GetCollegeGuides(this._repository);

  final CollegeGuideRepository _repository;

  @override
  Future<Either<Failure, List<CollegeGuide>>> call(
    GetCollegeGuidesParams params,
  ) {
    return _repository.getGuides(category: params.category);
  }
}

class GetCollegeGuidesParams extends Equatable {
  const GetCollegeGuidesParams({this.category});

  final GuideCategory? category;

  @override
  List<Object?> get props => [category];
}
