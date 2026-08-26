import 'package:flutter_test/flutter_test.dart';
import 'package:prep_master/core/constants/app_constants.dart';

void main() {
  test('app name is PrepMaster', () {
    expect(AppConstants.appName, 'PrepMaster');
  });
}
