// ## 파일: lib/views/home_screen.dart ##

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/expression_type.dart';
import '../models/training_record.dart';
import '../services/training_api_service.dart';
import '../utils/constants.dart';
import 'expression_select_screen.dart';
import 'training_summary_screen.dart';

class HomeScreen extends StatelessWidget {
  final CameraDescription camera;

  const HomeScreen({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.appTitle),
        backgroundColor: AppColors.surface,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Get.offAllNamed('/login'),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionHeader(title: '훈련모드'),
              const SizedBox(height: AppSizes.md),
              InkWell(
                onTap: () => Get.to(() => ExpressionSelectScreen(camera: camera)),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Ink(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: AppColors.textTertiary.withOpacity(0.2),
                    ),
                  ),
                  child: _WeekCalendar(initialDate: DateTime.now()),
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              const _SectionHeader(title: '훈련기록'),
              const SizedBox(height: AppSizes.md),
              SizedBox(
                height: 250,
                child: InkWell(
                  onTap: () => Get.to(() => const TrainingSummaryScreen()),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    clipBehavior: Clip.none,
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSizes.lg,
                        AppSizes.lg,
                        AppSizes.lg,
                        AppSizes.sm,
                      ),
                      child: _OverallProgressChart(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------- 그래프 -------------------------------

class _OverallProgressChart extends StatefulWidget {
  const _OverallProgressChart();
  @override
  State<_OverallProgressChart> createState() => _OverallProgressChartState();
}

class _OverallProgressChartState extends State<_OverallProgressChart> {
  final TrainingApiService _apiService = TrainingApiService();

  List<TrainingRecord> _convertApiDataToRecords(List<dynamic> sessions) {
    final records = <TrainingRecord>[];
    for (final session in sessions) {
      if (session is! Map<String, dynamic>) continue;

      final exprString = session['expr'] as String?;
      final score = (session['finalScore'] as num?)?.toDouble();
      final timestampObject = session['completedAt'] ?? session['startedAt'];

      if (exprString == null || score == null || timestampObject == null) continue;

      DateTime? date;
      if (timestampObject is Map && timestampObject.containsKey('_seconds')) {
        date = DateTime.fromMillisecondsSinceEpoch(timestampObject['_seconds'] * 1000);
      } else if (timestampObject is String) {
        date = DateTime.tryParse(timestampObject);
      }

      final expressionType = ExpressionType.values.firstWhereOrNull((e) => e.name == exprString);

      if (date != null && expressionType != null) {
        records.add(TrainingRecord(
          timestamp: date,
          expressionType: expressionType,
          score: score,
        ));
      }
    }
    return records;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _apiService.fetchSessions(pageSize: 100),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('기록을 불러올 수 없습니다.'));
        }

        final sessions = snapshot.data!['sessions'] as List<dynamic>;
        if (sessions.isEmpty) {
          return const Center(child: Text('훈련 기록이 없습니다.'));
        }

        final records = _convertApiDataToRecords(sessions);
        final recordsByDate = groupBy(records, (TrainingRecord r) => r.dateKey);

        final Map<DateTime, double> dailyAverages = {};
        recordsByDate.forEach((dateKey, recordsOnDate) {
          final date = DateFormat('yyyy-MM-dd').parse(dateKey);

          final List<double> trainedScores = [];
          for(var type in ExpressionType.values) {
            final bestScore = recordsOnDate
                .where((r) => r.expressionType == type)
                .map((r) => r.score)
                .maxOrNull;

            if (bestScore != null) {
              trainedScores.add(bestScore);
            }
          }

          if (trainedScores.isNotEmpty) {
            final averageScore = trainedScores.reduce((a, b) => a + b) / trainedScores.length;
            dailyAverages[date] = averageScore * 100.0;
          }
        });

        final sortedDates = dailyAverages.keys.toList()..sort();
        if (sortedDates.isEmpty) {
          return const Center(child: Text('표시할 기록이 없습니다.'));
        }

        final List<FlSpot> spots = sortedDates.asMap().entries.map((entry) {
          final idx = entry.key.toDouble();
          final date = entry.value;
          return FlSpot(idx, dailyAverages[date]!);
        }).toList();

        return LineChart(
          LineChartData(
            minY: 0,
            maxY: 100,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 25,
              getDrawingHorizontalLine: (value) => const FlLine(
                color: AppColors.border,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: 25,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.min || value == meta.max) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: (sortedDates.length / 4).ceilToDouble(),
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx >= sortedDates.length) return const SizedBox.shrink();
                    final date = sortedDates[idx];
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8.0,
                      child: Text(
                        DateFormat('M/d').format(date),
                        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => AppColors.primary.withOpacity(0.8),
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final date = sortedDates[spot.spotIndex];
                    return LineTooltipItem(
                      '${DateFormat('M월 d일').format(date)}\n',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: '평균 ${spot.y.toStringAsFixed(0)}%',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                      ],
                    );
                  }).toList();
                },
              ),
              getTouchedSpotIndicator: (barData, spotIndexes) {
                return spotIndexes.map((index) {
                  return TouchedSpotIndicatorData(
                    const FlLine(color: AppColors.primary, strokeWidth: 2, dashArray: [4, 4]),
                    FlDotData(
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 6,
                            color: AppColors.primary,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                    ),
                  );
                }).toList();
              },
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.primary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.3),
                      AppColors.primary.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// UI 위젯
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(height: 3, width: 140, color: AppColors.textPrimary),
      ],
    );
  }
}

class _WeekCalendar extends StatefulWidget {
  final DateTime initialDate;
  const _WeekCalendar({required this.initialDate});
  @override
  State<_WeekCalendar> createState() => _WeekCalendarState();
}

class _WeekCalendarState extends State<_WeekCalendar> {
  late DateTime _focused;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _focused = _stripTime(widget.initialDate);
    _selected = _focused;
  }

  DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _startOfWeek(DateTime d) {
    final int delta = d.weekday % 7;
    return _stripTime(d.subtract(Duration(days: delta)));
  }

  void _changeWeek(int deltaWeeks) {
    setState(() {
      _focused = _focused.add(Duration(days: 7 * deltaWeeks));
    });
  }

  @override
  Widget build(BuildContext context) {
    final start = _startOfWeek(_focused);
    final days = List<DateTime>.generate(7, (i) => start.add(Duration(days: i)));
    final monthLabel = DateFormat('y년 M월', 'ko').format(_focused);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(monthLabel,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const Spacer(),
            IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => _changeWeek(-1)),
            IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => _changeWeek(1)),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _Dow('일'),
            _Dow('월'),
            _Dow('화'),
            _Dow('수'),
            _Dow('목'),
            _Dow('금'),
            _Dow('토')
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          children: days.map((d) {
            final bool isSelected = _selected == d;
            return Expanded(
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color.fromARGB(255, 0, 106, 255).withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '${d.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _Dow extends StatelessWidget {
  final String text;
  const _Dow(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}