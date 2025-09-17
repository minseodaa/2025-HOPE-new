import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models/expression_type.dart';
import '../utils/constants.dart';
import '../services/training_api_service.dart';

class TrainingLogScreen extends StatefulWidget {
  final ExpressionType expressionType;
  const TrainingLogScreen({super.key, required this.expressionType});

  @override
  State<TrainingLogScreen> createState() => _TrainingLogScreenState();
}

class _TrainingLogScreenState extends State<TrainingLogScreen> {
  final _api = TrainingApiService();

  List<_Point> _points = [];
  bool _loading = true;
  String? _error;

  // ✅ 1. 클릭된 점을 기억하던 상태 변수 삭제
  // int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _stripPrefix(String s) =>
      s.replaceFirst(RegExp(r'^data:image/[^;]+;base64,'), '');

  double _normalizeScore(num raw) {
    final d = raw.toDouble();
    if (d.isNaN) return 0.0; // NaN 값 방어 코드
    // 서버가 0~1 스케일로 줄 수도 있어 자동 노멀라이즈
    return d <= 1.5 ? (d * 100.0) : d;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      // _selectedIndex = null; // ✅ 관련 로직 삭제
    });

    try {
      final list = await _api.fetchSessions(
        expr: widget.expressionType.name,
        pageSize: 50,
      );

      final sessions = (list['sessions'] as List?)?.whereType<Map>().toList() ?? const [];
      final result = <_Point>[];

      for (final raw in sessions) {
        final sid = (raw['sid'] ?? raw['id'])?.toString();
        final timestampObject = raw['completedAt'] ?? raw['startedAt'];

        if (sid == null || timestampObject == null) continue;

        DateTime? date;
        if (timestampObject is Map && timestampObject.containsKey('_seconds')) {
          final int seconds = timestampObject['_seconds'];
          date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        } else if (timestampObject is String) {
          try {
            final format = DateFormat("yyyy년 MM월 dd일 a h시 m분 s초 'UTC'+9", 'ko');
            date = format.parse(timestampObject);
          } catch (e) {
            date = DateTime.tryParse(timestampObject);
          }
        }

        if (date == null) continue;

        double? score = (raw['finalScore'] is num) ? _normalizeScore(raw['finalScore']) : null;
        String? lastFrameImageB64;

        if (score == null) {
          try {
            final detail = await _api.fetchSessionDetail(sid);
            final sets = (detail['session']?['sets'] as List?) ?? const [];
            if (sets.isNotEmpty) {
              final lastSet = (sets.last as Map?) ?? const {};
              if (lastSet['score'] is num) {
                score = _normalizeScore(lastSet['score']);
              }
              final img = lastSet['lastFrameImage'];
              if (img is String && img.isNotEmpty) {
                lastFrameImageB64 = _stripPrefix(img);
              }
            }
          } catch (_) {
            // 상세 정보 조회 실패는 무시합니다.
          }
        }

        if (score == null) continue;

        result.add(_Point(
          date: date,
          score: score.clamp(0, 100),
          lastFrameImageB64: lastFrameImageB64,
        ));
      }

      result.sort((a, b) => a.date.compareTo(b.date));
      setState(() => _points = result);
    } catch (e) {
      setState(() => _error = "데이터를 불러오는 데 실패했습니다: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _title() {
    switch (widget.expressionType) {
      case ExpressionType.smile:
        return '웃는 표정';
      case ExpressionType.sad:
        return '슬픈 표정';
      case ExpressionType.angry:
        return '화난 표정';
      case ExpressionType.neutral:
        return '무표정';
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MM/dd');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('세부 기록: ${_title()}',
            style: const TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        centerTitle: true,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('오류가 발생했습니다:\n$_error', textAlign: TextAlign.center),
      ))
          : Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
                child: _points.isEmpty
                    ? const Center(child: Text('표시할 훈련 기록이 없습니다.'))
                    : LineChart(_chartData(df))
            ),
            // ✅ 2. 화면 하단에 위젯을 표시하던 부분을 삭제
            // const SizedBox(height: AppSizes.md),
            // _buildSelectedPreview(df),
          ],
        ),
      ),
    );
  }

  // ✅ 3. 위젯을 만들던 함수 전체를 삭제
  // Widget _buildSelectedPreview(DateFormat df) { ... }

  LineChartData _chartData(DateFormat df) {
    final spots = <FlSpot>[];
    for (var i = 0; i < _points.length; i++) {
      spots.add(FlSpot(i.toDouble(), _points[i].score));
    }

    return LineChartData(
      minY: 0,
      maxY: 100,
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: 25),
        ),
        rightTitles:
        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= _points.length) {
                return const SizedBox.shrink();
              }
              if (_points.length > 10 && idx % 2 != 0) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(df.format(_points[idx].date),
                    style: const TextStyle(fontSize: 11)),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        // ✅ 4. 터치 시 _selectedIndex를 변경하던 로직 삭제 (툴팁은 그대로 유지됨)
        // touchCallback: (event, response) { ... },
        touchTooltipData: LineTouchTooltipData(
          tooltipRoundedRadius: 10,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItems: (list) {
            return list.map((s) {
              final idx = s.x.toInt();
              final p = _points[idx];
              return LineTooltipItem(
                '${df.format(p.date)}\n점수: ${p.score.toStringAsFixed(1)}%',
                const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.primary,
          barWidth: 4,
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.primary.withOpacity(0.18),
          ),
          dotData: const FlDotData(show: true),
        ),
      ],
    );
  }
}

class _Point {
  final DateTime date;
  final double score; // 0~100
  final String? lastFrameImageB64; // base64 (nullable)

  _Point({
    required this.date,
    required this.score,
    this.lastFrameImageB64,
  });
}