import 'dart:convert';
import 'package:intl/intl.dart';
import 'expression_type.dart';

class TrainingRecord {
  final DateTime timestamp;
  final ExpressionType expressionType;
  final double score;

  TrainingRecord({
    required this.timestamp,
    required this.expressionType,
    required this.score,
  });

  String get dateKey => DateFormat('yyyy-MM-dd').format(timestamp);

  Map<String, dynamic> toJson() => {
    'ts': timestamp.toIso8601String(),
    'type': expressionType.name,
    'score': score,
  };

  static TrainingRecord fromJson(Map<String, dynamic> json) {
    return TrainingRecord(
      timestamp: DateTime.parse(json['ts'] as String),
      expressionType: ExpressionType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => ExpressionType.neutral,
      ),
      score: (json['score'] as num).toDouble(),
    );
  }

  static String encodeList(List<TrainingRecord> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<TrainingRecord> decodeList(String s) {
    final List<dynamic> arr = jsonDecode(s);
    return arr.map((e) => TrainingRecord.fromJson(e)).toList();
  }
}