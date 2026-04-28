import 'package:shared_preferences/shared_preferences.dart';

class LocalSettingsService {
  static const String _turmaKey = 'selected_turma_id';

  Future<String?> getTurmaId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_turmaKey);
  }

  Future<void> setTurmaId(String turmaId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_turmaKey, turmaId);
  }
}
