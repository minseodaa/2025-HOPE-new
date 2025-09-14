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

  int? _selectedIndex; // 차트에서 선택된 포인트 인덱스

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _stripPrefix(String s) =>
      s.replaceFirst(RegExp(r'^data:image/[^;]+;base64,'), '');

  double _normalizeScore(num raw) {
    final d = raw.toDouble();
    // 서버가 0~1 스케일로 줄 수도 있어 자동 노멀라이즈
    return d <= 1.5 ? (d * 100.0) : d;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _selectedIndex = null;
    });

    try {
      Map<String, dynamic> list;
      try {
        list = await _api.fetchSessions(
          expr: widget.expressionType.name,
          status: 'completed',
          pageSize: 50,
        );
      } catch (_) {
        list = await _api.fetchSessions(
          expr: widget.expressionType.name,
          pageSize: 50,
        );
      }

      final sessions = (list['sessions'] as List?) ?? const [];
      final result = <_Point>[];

      for (final raw in sessions) {
        if (raw is! Map) continue;

        final sid = raw['sid']?.toString();
        final updatedAtStr = (raw['updatedAt'] ?? raw['createdAt'])?.toString();
        if (sid == null || updatedAtStr == null) continue;

        final date = DateTime.tryParse(updatedAtStr);
        if (date == null) continue;

        double? score =
        (raw['finalScore'] is num) ? _normalizeScore(raw['finalScore']) : null;

        String? lastFrameImageB64;
        double? lastSetScore;

        try {
          final detail = await _api.fetchSessionDetail(sid);
          final sets = (detail['session']?['sets'] as List?) ?? const [];
          if (sets.isNotEmpty) {
            final lastSet = (sets.last as Map?) ?? const {};
            final img = lastSet['lastFrameImage'];
            final setScore = lastSet['score'];
            if (img is String && img.isNotEmpty) {
              lastFrameImageB64 = _stripPrefix(img);
            }
            if (setScore is num) {
              lastSetScore = _normalizeScore(setScore);
            }
          }
        } catch (_) {
          // 상세 실패는 무시
        }

        score ??= lastSetScore;
        if (score == null) continue;

        result.add(_Point(
          date: date,
          score: score.clamp(0, 100),
          lastImageBase64: lastFrameImageB64,
        ));
      }

      result.sort((a, b) => a.date.compareTo(b.date));
      setState(() => _points = result);
    } catch (e) {
      setState(() => _error = e.toString());
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
          ? Center(child: Text('오류: $_error'))
          : Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: LineChart(_chartData(df))),
            const SizedBox(height: AppSizes.md),
            _buildSelectedPreview(df),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPreview(DateFormat df) {
    if (_selectedIndex == null ||
        _selectedIndex! < 0 ||
        _selectedIndex! >= _points.length) {
      return const SizedBox.shrink();
    }
    final p = _points[_selectedIndex!];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            if ((p.lastImageBase64 ?? '').isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  base64Decode(p.lastImageBase64!),
                  width: 96,
                  height: 72,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              )
            else
              Container(
                width: 96,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.image_not_supported, size: 28),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(df.format(p.date),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('진척도: ${p.score.toStringAsFixed(1)}'),
                ],
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _selectedIndex = null),
              icon: const Icon(Icons.close),
              tooltip: '닫기',
            )
          ],
        ),
      ),
    );
  }

  LineChartData _chartData(DateFormat df) {
    if (_points.isEmpty) {
      return LineChartData(
        titlesData: const FlTitlesData(show: false),
        lineBarsData: const [],
      );
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < _points.length; i++) {
      spots.add(FlSpot(i.toDouble(), _points[i].score));
    }

    return LineChartData(
      minY: 0,
      maxY: 100,
      gridData: const FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 32),
        ),
        rightTitles:
        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= _points.length) {
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
      borderData: FlBorderData(show: true),
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchCallback: (event, response) {
          if (!event.isInterestedForInteractions ||
              response == null ||
              response.lineBarSpots == null ||
              response.lineBarSpots!.isEmpty) {
            setState(() => _selectedIndex = null);
            return;
          }
          final idx = response.lineBarSpots!.first.x.toInt();
          if (idx >= 0 && idx < _points.length) {
            setState(() => _selectedIndex = idx);
          }
        },
        touchTooltipData: LineTouchTooltipData(
          tooltipRoundedRadius: 10,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItems: (list) {
            return list.map((s) {
              final idx = s.x.toInt();
              final p = _points[idx];
              return LineTooltipItem(
                '${df.format(p.date)}\n점수: ${p.score.toStringAsFixed(1)}',
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
  final String? lastImageBase64; // base64 (nullable)

  _Point({
    required this.date,
    required this.score,
    required this.lastImageBase64,
  });
}