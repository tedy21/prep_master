import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdaptivePracticeCubit extends Cubit<bool> {
  AdaptivePracticeCubit(this._prefs) : super(_prefs.getBool(_key) ?? true);

  static const _key = 'adaptive_practice_enabled';

  final SharedPreferences _prefs;

  Future<void> setEnabled(bool enabled) async {
    await _prefs.setBool(_key, enabled);
    emit(enabled);
  }
}
