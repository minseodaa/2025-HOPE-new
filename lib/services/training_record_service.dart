// ## 파일: lib/services/training_record_service.dart ##

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/training_record.dart';
import '../models/expression_type.dart';

class TrainingRecordService {
  static const _recordKey = 'training_records_v2';

  // 모든 기록 불러오기
  Future<List<TrainingRecord>> getAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJsonList = prefs.getStringList(_recordKey) ?? [];
    try {
      return rawJsonList
          .map((jsonString) => TrainingRecord.fromJson(jsonDecode(jsonString)))
          .toList();
    } catch (e) {
      print('Error decoding records: $e');
      await clearAll();
      return [];
    }
  }

  // 특정 표정 타입의 모든 기록 불러오기 (상세 기록 차트 페이지용)
  Future<List<TrainingRecord>> getRecordsForType(ExpressionType type) async {
    final allRecords = await getAllRecords();
    return allRecords.where((record) => record.expressionType == type).toList();
  }

  // 각 표정 타입별 가장 최근 기록 하나씩만 불러오기 (기록 요약 페이지용)
  Future<Map<ExpressionType, TrainingRecord?>> getLatestRecordForEachType() async {
    final allRecords = await getAllRecords();
    Map<ExpressionType, TrainingRecord> latestRecords = {};

    for (var record in allRecords) {
      if (!latestRecords.containsKey(record.expressionType) ||
          record.timestamp.isAfter(latestRecords[record.expressionType]!.timestamp)) {
        latestRecords[record.expressionType] = record;
      }
    }
    return latestRecords;
  }


  // 새로운 기록 추가하기
  Future<void> addRecord(TrainingRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final allRecords = await getAllRecords();
    allRecords.add(record);

    final jsonStringList = allRecords.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_recordKey, jsonStringList);
  }

  // 모든 기록 삭제하기
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recordKey);
  }
}