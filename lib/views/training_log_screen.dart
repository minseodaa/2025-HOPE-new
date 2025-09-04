// ## 파일: lib/views/training_log_screen.dart ##

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/expression_type.dart';
import '../models/training_record.dart';
import '../services/training_record_service.dart';
import '../utils/constants.dart';
import 'expression_select_screen.dart';

class TrainingLogScreen extends StatefulWidget {
  final ExpressionType expressionType;

  const TrainingLogScreen({super.key, required this.expressionType});

  @override
  State<TrainingLogScreen> createState() => _TrainingLogScreenState();
}

class _TrainingLogScreenState extends State<TrainingLogScreen> {
  final TrainingRecordService _recordService = TrainingRecordService();
  late Future<List<TrainingRecord>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    _recordsFuture = _recordService.getRecordsForType(widget.expressionType);
  }

  String _getTitle() {
    // ExpressionType enum에 따라 제목을 반환하는 로직 (예시)
    switch(widget.expressionType) {
      case ExpressionType.smile: return '웃는 표정';
      case ExpressionType.sad: return '슬픈 표정';
      case ExpressionType.angry: return '화난 표정';
      case ExpressionType.neutral: return '무표정';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('세부 기록: ${_getTitle()}', style: const TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_getTitle(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Divider(height: 30),
            const Text('표정 진척도', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
            const SizedBox(height: AppSizes.xl),
            Expanded(
              child: FutureBuilder<List<TrainingRecord>>(
                future: _recordsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('저장된 훈련 기록이 없습니다.'));
                  }
                  final records = snapshot.data!;
                  // 날짜순으로 정렬
                  records.sort((a, b) => a.timestamp.compareTo(b.timestamp));

                  return LineChart(
                    _buildChartData(records),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            ElevatedButton(
              onPressed: () {
                // 스택의 맨 처음 페이지(표정 선택 화면)까지 모두 pop
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('훈련하러 가기'),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildChartData(List<TrainingRecord> records) {
    List<FlSpot> spots = records.asMap().entries.map((entry) {
      int index = entry.key;
      TrainingRecord record = entry.value;
      return FlSpot(index.toDouble(), record.score * 100);
    }).toList();

    return LineChartData(
      minY: 0,
      maxY: 100,

      // 터치 이벤트 설정
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final record = records[spot.x.toInt()];
              return LineTooltipItem(
                  '${DateFormat('M월 d일').format(record.timestamp)}\n진척도: ${record.score.toStringAsFixed(2)}%',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  children: [
                    // TODO: 여기에 이미지 위젯 추가
                    // 예: WidgetSpan(child: Image.file(File(record.imagePath!)))
                  ]
              );
            }).toList();
          },
        ),
      ),
      // 그리드, 축, 타이틀 등 UI 설정
      gridData: const FlGridData(show: true),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              int index = value.toInt();
              if (index >= 0 && index < records.length) {
                // x축에 날짜 표시 (간격을 봐서 일부만 표시하도록 조정 가능)
                if(records.length > 5 && index % (records.length ~/ 5) != 0) return const SizedBox.shrink();
                return Text(DateFormat('MM/dd').format(records[index].timestamp), style: const TextStyle(fontSize: 10));
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.primary,
          barWidth: 4,
          belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.2)),
        ),
      ],
    );
  }
}