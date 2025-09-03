import 'package:shared_preferences/shared_preferences.dart';
import '../models/training_record.dart';

class TrainingRecordService {
  static const String _key = 'training_records_v1';

  Future<List<TrainingRecord>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return TrainingRecord.decodeList(raw);
    } catch (_) {
      return [];
    }
  }

  Future<void> add(TrainingRecord rec) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadAll();
    list.add(rec);
    await prefs.setString(_key, TrainingRecord.encodeList(list));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}